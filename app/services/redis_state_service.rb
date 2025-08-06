class RedisStateService
  def initialize
    @redis = $redis
  end

  # Cache platform configurations
  def cache_platform_steps(platform_id, steps_data, expires_in: 1.hour)
    key = "platform:#{platform_id}:steps"
    @redis.setex(key, expires_in.to_i, steps_data.to_json)
  end

  def get_cached_platform_steps(platform_id)
    key = "platform:#{platform_id}:steps"
    data = @redis.get(key)
    return nil unless data
    
    JSON.parse(data)
  end

  # Session-based investment state
  def save_investment_session(session_id, investment_id, step_data)
    key = "investment_session:#{session_id}"
    @redis.hset(key, investment_id.to_s, step_data.to_json)
    @redis.expire(key, 24.hours.to_i) # Expire after 24 hours
  end

  def get_investment_session(session_id, investment_id)
    key = "investment_session:#{session_id}"
    data = @redis.hget(key, investment_id.to_s)
    return nil unless data
    
    JSON.parse(data)
  end

  def clear_investment_session(session_id, investment_id)
    key = "investment_session:#{session_id}"
    @redis.hdel(key, investment_id.to_s)
  end

  # Real-time progress tracking
  def track_step_progress(investment_id, step_order, completed: true)
    key = "investment_progress:#{investment_id}"
    @redis.hset(key, step_order.to_s, completed ? "1" : "0")
    @redis.expire(key, 24.hours.to_i)
  end

  def get_step_progress(investment_id)
    key = "investment_progress:#{investment_id}"
    progress = @redis.hgetall(key)
    progress.transform_values { |v| v == "1" }
  end

  # Platform configuration caching
  def cache_platform_config(platform_id, config_data, expires_in: 1.hour)
    key = "platform_config:#{platform_id}"
    @redis.setex(key, expires_in.to_i, config_data.to_json)
  end

  def get_cached_platform_config(platform_id)
    key = "platform_config:#{platform_id}"
    data = @redis.get(key)
    return nil unless data
    
    JSON.parse(data)
  end

  # User session state
  def save_user_session_state(session_id, state_data)
    key = "user_session:#{session_id}"
    @redis.setex(key, 2.hours.to_i, state_data.to_json)
  end

  def get_user_session_state(session_id)
    key = "user_session:#{session_id}"
    data = @redis.get(key)
    return nil unless data
    
    JSON.parse(data)
  end

  # Analytics and monitoring
  def increment_step_completion(platform_id, step_type)
    key = "analytics:step_completions:#{Date.current}"
    @redis.hincrby(key, "#{platform_id}:#{step_type}", 1)
    @redis.expire(key, 30.days.to_i)
  end

  def get_step_completion_stats(date = Date.current)
    key = "analytics:step_completions:#{date}"
    @redis.hgetall(key)
  end

  # Cache invalidation
  def invalidate_platform_cache(platform_id)
    @redis.del("platform:#{platform_id}:steps")
    @redis.del("platform_config:#{platform_id}")
  end

  # Health check
  def health_check
    @redis.ping == "PONG"
  rescue Redis::CannotConnectError
    false
  end

  private

  def safe_redis_operation
    yield
  rescue Redis::CannotConnectError => e
    Rails.logger.error "Redis operation failed: #{e.message}"
    nil
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing failed: #{e.message}"
    nil
  end
end 