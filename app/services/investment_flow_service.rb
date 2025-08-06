class InvestmentFlowService
  attr_reader :investment, :platform, :current_step

  def initialize(investment)
    @investment = investment
    @platform = investment.platform
    @current_step = nil
  end

  # Get the current step based on step order parameter
  def current_step(step_order = nil)
    step_order ||= 1
    @current_step = platform.steps_ordered.find_by(order: step_order) || platform.steps_ordered.first
  end

  # Get the next step in the flow
  def next_step(current_step)
    platform.steps_ordered.where('"order" > ?', current_step.order).first
  end

  # Get the previous step in the flow
  def previous_step(current_step)
    platform.steps_ordered.where('"order" < ?', current_step.order).last
  end

  # Check if this is the first step
  def first_step?(step)
    step.order == 1
  end

  # Check if this is the last step
  def last_step?(step)
    step == platform.steps_ordered.last
  end

  # Get progress percentage (0-100)
  def progress_percentage(step)
    return 0 if platform.steps_ordered.count == 0
    ((step.order.to_f / platform.steps_ordered.count) * 100).round
  end

  # Validate step data based on component type
  def validate_step_data(step, step_params)
    Rails.logger.info "=== VALIDATION DEBUG ==="
    Rails.logger.info "Step component type: #{step.component_type}"
    Rails.logger.info "Step params: #{step_params.inspect}"
    
    case step.component_type
    when 'amount_input'
      result = validate_amount_input(step, step_params)
      Rails.logger.info "Amount validation result: #{result}"
      result
    when 'checkbox'
      result = validate_checkbox(step, step_params)
      Rails.logger.info "Checkbox validation result: #{result}"
      result
    when 'text_input'
      result = validate_text_input(step, step_params)
      Rails.logger.info "Text input validation result: #{result}"
      result
    when 'disclaimer'
      result = validate_disclaimer(step, step_params)
      Rails.logger.info "Disclaimer validation result: #{result}"
      result
    else
      Rails.logger.info "Unknown component type, defaulting to true"
      true
    end
  end

  # Get validation error message for a step
  def validation_error_message(step, step_params)
    case step.component_type
    when 'amount_input'
      amount_validation_error_message(step, step_params)
    when 'checkbox'
      checkbox_validation_error_message(step)
    when 'text_input'
      text_input_validation_error_message(step)
    when 'disclaimer'
      disclaimer_validation_error_message(step)
    else
      "Invalid step type"
    end
  end

  # Save step data to investment
  def save_step_data(step, step_params)
    investment.set_step_data(step.id, step_params)
    investment.save!
  end

  # Submit the investment (mark as submitted)
  def submit_investment
    investment.update!(status: :submitted)
  end

  # Get all steps for the platform
  def all_steps
    platform.steps_ordered
  end

  # Get step by order
  def step_by_order(order)
    platform.steps_ordered.find_by(order: order)
  end

  # Check if step is completed (has data)
  def step_completed?(step)
    step_data = investment.step_data(step.id)
    case step.component_type
    when 'amount_input'
      step_data['value'].present?
    when 'checkbox'
      step_data['checked'] == '1' || step_data['checked'] == 'true'
    when 'text_input'
      step_data['text'].present?
    when 'disclaimer'
      step_data['checked'] == '1' || step_data['checked'] == 'true'
    else
      false
    end
  end

  # Get step data for a specific step
  def step_data(step)
    investment.step_data(step.id)
  end

  # Check if all previous steps are completed
  def previous_steps_completed?(current_step)
    return true if first_step?(current_step)
    
    previous_steps = platform.steps_ordered.where('"order" < ?', current_step.order)
    previous_steps.all? { |step| step_completed?(step) }
  end

  # Get the next incomplete step
  def next_incomplete_step
    platform.steps_ordered.find { |step| !step_completed?(step) }
  end

  # Get the first incomplete step
  def first_incomplete_step
    platform.steps_ordered.find { |step| !step_completed?(step) } || platform.steps_ordered.first
  end

  private

  def validate_amount_input(step, step_params)
    amount = step_params[:value].to_f
    min = step.config['min'].to_f
    max = step.config['max'].to_f
    
    amount >= min && amount <= max
  end

  def validate_checkbox(step, step_params)
    # Checkbox sends "1" when checked, nil when unchecked
    checked_value = step_params[:checked]
    Rails.logger.info "Checkbox validation - checked value: '#{checked_value}' (class: #{checked_value.class})"
    result = checked_value == '1' || checked_value == 'on' || checked_value == 'true'
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
    result = checked_value == '1' || checked_value == 'on' || checked_value == 'true'
    Rails.logger.info "Disclaimer validation result: #{result}"
    result
  end

  def amount_validation_error_message(step, step_params)
    amount = step_params[:value].to_f
    min = step.config['min'].to_f
    max = step.config['max'].to_f
    
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