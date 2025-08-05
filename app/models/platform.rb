class Platform < ApplicationRecord
  has_many :steps, dependent: :destroy
  has_many :investments, dependent: :destroy
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :active, inclusion: { in: [true, false] }
  
  scope :active, -> { where(active: true) }
  
  def steps_ordered
    steps.order(:order)
  end
end
