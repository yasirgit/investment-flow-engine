class InvestmentsController < ApplicationController
  before_action :set_platform, only: [:new, :create, :show, :update]
  before_action :set_investment, only: [:show, :update]
  before_action :set_flow_service, only: [:show, :update]
  before_action :set_current_step, only: [:show, :update]

  def index
    @platforms = Platform.active
  end

  def new
    @investment = Investment.create!(platform: @platform, status: :draft)
    @flow_service = InvestmentFlowService.new(@investment)
    @current_step = @flow_service.current_step
    redirect_to investment_path(@investment)
  end

  def show
    @current_step = @flow_service.current_step(params[:step])
  end

  # Implement update action to validate and advance steps using the service.
  def update
    Rails.logger.info "=== UPDATE ACTION DEBUG ==="
    Rails.logger.info "Raw params: #{params.inspect}"
    Rails.logger.info "Step params: #{step_params.inspect}"
    Rails.logger.info "Current step component type: #{@current_step.component_type}"
    Rails.logger.info "Current step order: #{@current_step.order}"
    
    if @flow_service.validate_step_data(@current_step, step_params)
      Rails.logger.info "Validation PASSED"
      @flow_service.save_step_data(@current_step, step_params)
      
      if @flow_service.last_step?(@current_step)
        # This is the final step, submit the investment
        @flow_service.submit_investment
        redirect_to investment_path(@investment), notice: 'Investment submitted successfully!'
      else
        # Move to next step
        next_step = @flow_service.next_step(@current_step)
        Rails.logger.info "Current step: #{@current_step.order}, Next step: #{next_step&.order}"
        redirect_to investment_path(@investment, step: next_step.order)
      end
    else
      # Validation failed, re-render current step
      @validation_error = @flow_service.validation_error_message(@current_step, step_params)
      Rails.logger.info "Validation FAILED: #{@validation_error}"
      render :show, status: :unprocessable_entity
    end
  end

  def create
    @investment = Investment.new(investment_params)
    @investment.status = :draft
    
    if @investment.save
      redirect_to investment_path(@investment)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_platform
    if params[:platform_id]
      @platform = Platform.active.find(params[:platform_id])
    elsif params[:id]
      @investment = Investment.find(params[:id])
      @platform = @investment.platform
    else
      @platform = nil
    end
  end

  def set_investment
    @investment = Investment.find(params[:id])
  end

  def set_flow_service
    @flow_service = InvestmentFlowService.new(@investment)
  end

  def set_current_step
    step_order = params[:step]&.to_i || 1
    @current_step = @flow_service.current_step(step_order)
  end

  def investment_params
    params.require(:investment).permit(:platform_id)
  end

  def step_params
    # Extract the actual step data from the form parameters
    {
      value: params[:value],
      checked: params[:checked],
      text: params[:text]
    }.compact
  end
end 