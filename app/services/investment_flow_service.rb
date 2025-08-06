class InvestmentFlowService
  attr_reader :investment, :platform, :current_step

  def initialize(investment)
    @investment = investment
    @platform = investment.platform
    @redis_service = RedisStateService.new

    # Sync Redis progress with database data
    sync_progress_with_database
  end

  # Sync Redis progress with database data
  def sync_progress_with_database
    @platform.steps_ordered.each do |step|
      step_data = @investment.step_data(step.id)
      completed = case step.component_type
      when "amount_input"
        step_data["value"].present?
      when "checkbox"
        step_data["checked"] == "1" || step_data["checked"] == "true"
      when "text_input"
        step_data["text"].present?
      when "disclaimer"
        step_data["checked"] == "1" || step_data["checked"] == "true"
      else
        false
      end

      @redis_service.track_step_progress(@investment.id, step.order, completed: completed)
    end
  end

  # Get current step by order
  def current_step(step_order = nil)
    step_order ||= 1
    Rails.cache.fetch("platform:#{@platform.id}:step:#{step_order}", expires_in: 1.hour) do
      @platform.steps_ordered.find_by(order: step_order)
    end
  end

  # Get next step
  def next_step(current_step)
    Rails.cache.fetch("platform:#{@platform.id}:next_step:#{current_step.order}", expires_in: 1.hour) do
      @platform.steps_ordered.where('"order" > ?', current_step.order).first
    end
  end

  # Get previous step
  def previous_step(current_step)
    Rails.cache.fetch("platform:#{@platform.id}:prev_step:#{current_step.order}", expires_in: 1.hour) do
      @platform.steps_ordered.where('"order" < ?', current_step.order).last
    end
  end

  # Check if step is first
  def first_step?(step)
    step.order == 1
  end

  # Check if step is last
  def last_step?(step)
    step == @platform.steps_ordered.last
  end

  # Calculate progress percentage
  def progress_percentage(step)
    return 0 if @platform.steps_ordered.count == 0

    total_steps = @platform.steps_ordered.count
    current_position = step.order
    ((current_position.to_f / total_steps) * 100).round
  end

  # Validate step data based on component type
  def validate_step_data(step, step_params)
    Rails.logger.info "=== VALIDATION DEBUG ==="
    Rails.logger.info "Step component type: #{step.component_type}"
    Rails.logger.info "Step params: #{step_params}"

    result = case step.component_type
    when "amount_input"
      validate_amount_input(step, step_params)
    when "checkbox"
      validate_checkbox(step, step_params)
    when "text_input"
      validate_text_input(step, step_params)
    when "disclaimer"
      validate_disclaimer(step, step_params)
    else
      false
    end

    Rails.logger.info "Validation PASSED" if result
    Rails.logger.info "Validation FAILED" unless result

    # Track analytics in Redis
    @redis_service.increment_step_completion(@platform.id, step.component_type) if result

    result
  end

  # Get validation error message
  def validation_error_message(step, step_params)
    case step.component_type
    when "amount_input"
      amount_validation_error_message(step, step_params)
    when "checkbox"
      checkbox_validation_error_message(step)
    when "text_input"
      text_input_validation_error_message(step)
    when "disclaimer"
      disclaimer_validation_error_message(step)
    else
      "Invalid step type"
    end
  end

  # Save step data to database and Redis
  def save_step_data(step, step_params)
    # Save to database
    @investment.set_step_data(step.id, step_params)

    # Cache in Redis for faster access
    @redis_service.save_investment_session(
      session_id,
      @investment.id,
      { step_id: step.id, data: step_params, timestamp: Time.current }
    )

    # Track progress in Redis - mark as completed
    @redis_service.track_step_progress(@investment.id, step.order, completed: true)

    # Invalidate step cache to ensure fresh data
    Rails.cache.delete("platform:#{@platform.id}:all_steps")
  end

  # Submit investment
  def submit_investment
    @investment.update!(status: :submitted)

    # Clear Redis session data after submission
    @redis_service.clear_investment_session(session_id, @investment.id)
  end

  # Get all steps with caching
  def all_steps
    Rails.cache.fetch("platform:#{@platform.id}:all_steps", expires_in: 1.hour) do
      @platform.steps_ordered.to_a
    end
  end

  # Get step by order with caching
  def step_by_order(order)
    Rails.cache.fetch("platform:#{@platform.id}:step_by_order:#{order}", expires_in: 1.hour) do
      @platform.steps_ordered.find_by(order: order)
    end
  end

  # Check if step is completed (has data)
  def step_completed?(step)
    # First check Redis for cached completion status
    redis_progress = @redis_service.get_step_progress(@investment.id)
    if redis_progress[step.order.to_s] == true
      return true
    end

    # Fallback to database check
    step_data = @investment.step_data(step.id)
    case step.component_type
    when "amount_input"
      step_data["value"].present?
    when "checkbox"
      step_data["checked"] == "1" || step_data["checked"] == "true"
    when "text_input"
      step_data["text"].present?
    when "disclaimer"
      step_data["checked"] == "1" || step_data["checked"] == "true"
    else
      false
    end
  end

  # Get step data for a specific step
  def step_data(step)
    @investment.step_data(step.id)
  end

  # Check if all previous steps are completed
  def previous_steps_completed?(current_step)
    return true if first_step?(current_step)

    previous_steps = @platform.steps_ordered.where('"order" < ?', current_step.order)
    previous_steps.all? { |step| step_completed?(step) }
  end

  # Get the next incomplete step
  def next_incomplete_step
    @platform.steps_ordered.find { |step| !step_completed?(step) }
  end

  # Get the first incomplete step
  def first_incomplete_step
    @platform.steps_ordered.find { |step| !step_completed?(step) } || @platform.steps_ordered.first
  end

  # Get Redis session ID
  def session_id
    @session_id ||= "session_#{@investment.id}_#{Time.current.to_i}"
  end

  private

  def validate_amount_input(step, step_params)
    amount = step_params[:value].to_f
    min = step.config["min"].to_f
    max = step.config["max"].to_f

    amount >= min && amount <= max
  end

  def validate_checkbox(step, step_params)
    # Checkbox sends "1" when checked, nil when unchecked
    checked_value = step_params[:checked]
    Rails.logger.info "Checkbox validation - checked value: '#{checked_value}' (class: #{checked_value.class})"
    result = checked_value == "1" || checked_value == "on" || checked_value == "true"
    Rails.logger.info "Checkbox validation result: #{result}"
    result
  end

  def validate_text_input(step, step_params)
    step_params[:text].present?
  end

  def validate_disclaimer(step, step_params)
    # Checkbox sends "1" when checked, nil when unchecked
    checked_value = step_params[:checked]
    Rails.logger.info "Disclaimer validation - checked value: '#{checked_value}' (class: #{checked_value.class})"
    result = checked_value == "1" || checked_value == "on" || checked_value == "true"
    Rails.logger.info "Disclaimer validation result: #{result}"
    result
  end

  def amount_validation_error_message(step, step_params)
    amount = step_params[:value].to_f
    min = step.config["min"].to_f
    max = step.config["max"].to_f

    if amount < min
      "Amount must be at least $#{min}"
    elsif amount > max
      "Amount must be no more than $#{max}"
    else
      "Please enter a valid amount"
    end
  end

  def checkbox_validation_error_message(step)
    "You must accept the terms to continue"
  end

  def text_input_validation_error_message(step)
    "This field is required"
  end

  def disclaimer_validation_error_message(step)
    "You must acknowledge the risks to continue"
  end
end
