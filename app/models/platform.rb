class Platform < ApplicationRecord
  has_many :steps, dependent: :destroy
  has_many :investments, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  # Get ordered steps with caching
  def steps_ordered
    Rails.cache.fetch("platform:#{id}:steps_ordered", expires_in: 1.hour) do
      steps.order(:order)
    end
  end

  # Cache platform configuration
  def cache_configuration
    config_data = {
      id: id,
      name: name,
      slug: slug,
      active: active,
      steps: steps_ordered.map do |step|
        {
          id: step.id,
          order: step.order,
          title: step.title,
          component_type: step.component_type,
          config: step.config
        }
      end
    }

    Rails.cache.write("platform:#{id}:config", config_data, expires_in: 1.hour)
    config_data
  end

  # Get cached configuration
  def cached_configuration
    Rails.cache.fetch("platform:#{id}:config", expires_in: 1.hour) do
      cache_configuration
    end
  end

  # Invalidate cache when platform is updated
  after_update :invalidate_cache
  after_destroy :invalidate_cache

  private

  def invalidate_cache
    Rails.cache.delete_matched("platform:#{id}:*")
  end
end
