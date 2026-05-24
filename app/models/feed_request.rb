class FeedRequest < ApplicationRecord
  STATUSES = %w[pending processing done failed].freeze
  MODES    = %w[full fallback].freeze

  belongs_to :user
  has_many :feed_items, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :mode,   inclusion: { in: MODES }
  validates :urls,   presence: true
end
