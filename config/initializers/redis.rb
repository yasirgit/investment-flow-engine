# Redis configuration and connection setup
require 'redis'

# Configure Redis connection
$redis = Redis.new(url: Rails.application.config.redis_url)

# Test Redis connection on startup
begin
  $redis.ping
  Rails.logger.info "Redis connected successfully"
rescue Redis::CannotConnectError => e
  Rails.logger.warn "Redis connection failed: #{e.message}"
  Rails.logger.warn "Application will continue without Redis caching"
end

# Configure Rails cache store to use Redis
Rails.application.config.cache_store = :redis_cache_store, {
  url: Rails.application.config.redis_url,
  connect_timeout: 30,
  read_timeout: 0.2,
  write_timeout: 0.2,
  reconnect_attempts: 1,
  error_handler: -> (method:, returning:, exception:) {
    Rails.logger.error "Redis error: #{exception.message}"
  }
} 