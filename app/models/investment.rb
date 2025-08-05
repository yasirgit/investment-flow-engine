class Investment < ApplicationRecord
  belongs_to :platform
  
  enum :status, {
    draft: 0,
    submitted: 1,
    approved: 2,
    rejected: 3
  }
  
  validates :platform, presence: true
  validates :status, presence: true
  
  # Ensure user_data is always a hash
  def user_data
    self[:user_data] || {}
  end
  
  def user_data=(value)
    self[:user_data] = value.is_a?(Hash) ? value : {}
  end
  
  # Helper method to get data for a specific step
  def step_data(step_id)
    user_data[step_id.to_s] || {}
  end
  
  # Helper method to set data for a specific step
  def set_step_data(step_id, data)
    self.user_data = user_data.merge(step_id.to_s => data)
  end
end
