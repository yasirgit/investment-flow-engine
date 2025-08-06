class HealthController < ApplicationController
  def index
    redis_service = RedisStateService.new
    
    health_status = {
      application: "healthy",
      database: database_healthy?,
      redis: redis_service.health_check,
      timestamp: Time.current
    }
    
    render json: health_status
  end

  def redis_stats
    redis_service = RedisStateService.new
    
    stats = {
      step_completions_today: redis_service.get_step_completion_stats,
      cache_keys: $redis.dbsize,
      memory_usage: $redis.info("memory"),
      timestamp: Time.current
    }
    
    render json: stats
  end

  private

  def database_healthy?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue ActiveRecord::StatementInvalid
    false
  end
end 