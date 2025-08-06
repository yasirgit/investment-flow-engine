require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @platform = platforms(:one)
    @step = steps(:one)
  end

  test "should get index" do
    get investments_url
    assert_response :success
  end

  test "should get new investment" do
    get new_platform_investment_url(@platform)
    assert_redirected_to investment_path(Investment.last)
  end

  test "should create investment" do
    assert_difference('Investment.count') do
      post platform_investments_url(@platform), params: { investment: { platform_id: @platform.id } }
    end

    assert_redirected_to investment_url(Investment.last)
  end

  test "should show investment" do
    @investment = Investment.create!(platform: @platform, status: :draft)
    get investment_url(@investment)
    assert_response :success
  end

  test "should update investment step" do
    @investment = Investment.create!(platform: @platform, status: :draft)
    @step = @platform.steps_ordered.first
    
    # Use a valid amount that passes validation (between min and max)
    patch investment_url(@investment, step: @step.order), params: {
      value: "1000"  # This should be within the min/max range
    }
    
    assert_redirected_to investment_url(@investment, step: @step.order + 1)
  end
end 