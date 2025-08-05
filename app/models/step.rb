class Step < ApplicationRecord
  belongs_to :platform
  
  enum :component_type, {
    amount_input: 0,
    checkbox: 1,
    disclaimer: 2,
    text_input: 3
  }
  
  validates :title, presence: true
  validates :component_type, presence: true
  validates :order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  
  scope :ordered, -> { order(:order) }
  
  # Ensure config is always a hash
  def config
    self[:config] || {}
  end
  
  def config=(value)
    self[:config] = value.is_a?(Hash) ? value : {}
  end
end
