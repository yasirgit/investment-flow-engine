require "test_helper"

class InvestmentFlowServiceTest < ActiveSupport::TestCase
  setup do
    @platform = platforms(:one)
    @investment = Investment.create!(platform: @platform, status: :draft)
    @service = InvestmentFlowService.new(@investment)
  end

  test "should get current step" do
    step = @service.current_step(1)
    assert_equal 1, step.order
    assert_equal "Investment Amount", step.title
  end

  test "should get next step" do
    current_step = @service.current_step(1)
    next_step = @service.next_step(current_step)
    assert_equal 2, next_step.order
    assert_equal "Accept Terms", next_step.title
  end

  test "should get previous step" do
    current_step = @service.current_step(2)
    previous_step = @service.previous_step(current_step)
    assert_equal 1, previous_step.order
    assert_equal "Investment Amount", previous_step.title
  end

  test "should check if step is first" do
    first_step = @service.current_step(1)
    assert @service.first_step?(first_step)
    
    second_step = @service.current_step(2)
    assert_not @service.first_step?(second_step)
  end

  test "should check if step is last" do
    last_step = @service.all_steps.last
    assert @service.last_step?(last_step)
    
    first_step = @service.all_steps.first
    assert_not @service.last_step?(first_step)
  end

  test "should calculate progress percentage" do
    first_step = @service.current_step(1)
    assert_equal 50, @service.progress_percentage(first_step)
    
    last_step = @service.all_steps.last
    assert_equal 100, @service.progress_percentage(last_step)
  end

  test "should validate amount input" do
    step = @service.current_step(1)
    valid_params = { value: "1000" }
    invalid_params_low = { value: "50" }
    invalid_params_high = { value: "10000" }
    
    assert @service.validate_step_data(step, valid_params)
    assert_not @service.validate_step_data(step, invalid_params_low)
    assert_not @service.validate_step_data(step, invalid_params_high)
  end

  test "should validate checkbox" do
    step = @service.current_step(2)
    valid_params = { checked: "true" }
    invalid_params = { checked: "false" }
    
    assert @service.validate_step_data(step, valid_params)
    assert_not @service.validate_step_data(step, invalid_params)
  end

  test "should get validation error message" do
    step = @service.current_step(1)
    params = { value: "50" }
    
    error_message = @service.validation_error_message(step, params)
    assert_includes error_message, "Amount must be at least"
  end

  test "should save step data" do
    step = @service.current_step(1)
    params = { value: "1000" }
    
    @service.save_step_data(step, params)
    
    saved_data = @service.step_data(step)
    assert_equal "1000", saved_data["value"]
  end

  test "should check if step is completed" do
    step = @service.current_step(1)
    
    # Initially not completed
    assert_not @service.step_completed?(step)
    
    # Save data and check again
    @service.save_step_data(step, { value: "1000" })
    assert @service.step_completed?(step)
  end

  test "should submit investment" do
    assert_equal "draft", @investment.status
    
    @service.submit_investment
    
    @investment.reload
    assert_equal "submitted", @investment.status
  end

  test "should get all steps" do
    steps = @service.all_steps
    assert_equal 2, steps.count
    assert_equal "Investment Amount", steps.first.title
    assert_equal "Accept Terms", steps.last.title
  end

  test "should get step by order" do
    step = @service.step_by_order(1)
    assert_equal "Investment Amount", step.title
    
    step = @service.step_by_order(2)
    assert_equal "Accept Terms", step.title
  end

  test "should check if previous steps are completed" do
    first_step = @service.current_step(1)
    second_step = @service.current_step(2)
    
    # First step should always be accessible
    assert @service.previous_steps_completed?(first_step)
    
    # Second step should not be accessible if first is not completed
    assert_not @service.previous_steps_completed?(second_step)
    
    # Complete first step
    @service.save_step_data(first_step, { value: "1000" })
    assert @service.previous_steps_completed?(second_step)
  end

  test "should get next incomplete step" do
    # Should return first step initially
    next_incomplete = @service.next_incomplete_step
    assert_equal 1, next_incomplete.order
    
    # Complete first step
    first_step = @service.current_step(1)
    @service.save_step_data(first_step, { value: "1000" })
    
    # Should return second step
    next_incomplete = @service.next_incomplete_step
    assert_equal 2, next_incomplete.order
  end

  test "should get first incomplete step" do
    # Should return first step initially
    first_incomplete = @service.first_incomplete_step
    assert_equal 1, first_incomplete.order
    
    # Complete first step
    first_step = @service.current_step(1)
    @service.save_step_data(first_step, { value: "1000" })
    
    # Should return second step
    first_incomplete = @service.first_incomplete_step
    assert_equal 2, first_incomplete.order
  end
end 