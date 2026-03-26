class ScreenCapability < ApplicationRecord
  belongs_to :screen
  belongs_to :format

  validates :screen_id, :format_id, presence: true
end