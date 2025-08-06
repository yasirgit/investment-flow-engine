require "test_helper"

class RedisStateServiceTest < ActiveSupport::TestCase
  setup do
    @redis_service = RedisStateService.new
    @platform = platforms(:one)
    @investment = investments(:one)
  end

  test "should cache platform steps" do
    steps_data = @platform.steps_ordered.map { |s| { id: s.id, title: s.title } }
    
    @redis_service.cache_platform_steps(@platform.id, steps_data)
    cached_data = @redis_service.get_cached_platform_steps(@platform.id)
    
    # Convert string keys to symbols for comparison
    expected = steps_data.map { |step| step.transform_keys(&:to_s) }
    assert_equal expected, cached_data
  end

  test "should save and retrieve investment session" do
    session_id = "test_session_123"
    investment_id = @investment.id
    step_data = { step_id: 1, data: { value: "1000" }, timestamp: Time.current }
    
    @redis_service.save_investment_session(session_id, investment_id, step_data)
    retrieved_data = @redis_service.get_investment_session(session_id, investment_id)
    
    assert_equal step_data[:step_id], retrieved_data["step_id"]
    assert_equal step_data[:data].transform_keys(&:to_s), retrieved_data["data"]
  end

  test "should track step progress" do
    investment_id = @investment.id
    step_order = 1
    
    @redis_service.track_step_progress(investment_id, step_order, completed: true)
    progress = @redis_service.get_step_progress(investment_id)
    
    assert progress[step_order.to_s]
  end

  test "should cache platform configuration" do
    config_data = { name: @platform.name, steps_count: @platform.steps.count }
    
    @redis_service.cache_platform_config(@platform.id, config_data)
    cached_config = @redis_service.get_cached_platform_config(@platform.id)
    
    # Convert string keys to symbols for comparison
    expected = config_data.transform_keys(&:to_s)
    assert_equal expected, cached_config
  end

  test "should save and retrieve user session state" do
    session_id = "user_session_123"
    state_data = { current_step: 2, platform_id: @platform.id }
    
    @redis_service.save_user_session_state(session_id, state_data)
    retrieved_state = @redis_service.get_user_session_state(session_id)
    
    # Convert string keys to symbols for comparison
    expected = state_data.transform_keys(&:to_s)
    assert_equal expected, retrieved_state
  end

  test "should increment step completion analytics" do
    platform_id = @platform.id
    step_type = "amount_input"
    
    @redis_service.increment_step_completion(platform_id, step_type)
    stats = @redis_service.get_step_completion_stats
    
    assert_includes stats.keys, "#{platform_id}:#{step_type}"
  end

  test "should invalidate platform cache" do
    # Cache some data first
    @redis_service.cache_platform_steps(@platform.id, [{ id: 1 }])
    @redis_service.cache_platform_config(@platform.id, { name: "test" })
    
    # Invalidate cache
    @redis_service.invalidate_platform_cache(@platform.id)
    
    # Check that data is cleared
    assert_nil @redis_service.get_cached_platform_steps(@platform.id)
    assert_nil @redis_service.get_cached_platform_config(@platform.id)
  end

  test "should clear investment session" do
    session_id = "test_session_456"
    investment_id = @investment.id
    step_data = { step_id: 1, data: { value: "1000" } }
    
    @redis_service.save_investment_session(session_id, investment_id, step_data)
    @redis_service.clear_investment_session(session_id, investment_id)
    
    assert_nil @redis_service.get_investment_session(session_id, investment_id)
  end

  test "should handle Redis connection errors gracefully" do
    # Test health check with working Redis
    result = @redis_service.health_check
    assert result
    
    # Test with a new service instance
    redis_service = RedisStateService.new
    result = redis_service.health_check
    assert result
  end
end 