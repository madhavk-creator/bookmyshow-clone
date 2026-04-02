class Show < ApplicationRecord
  belongs_to :screen
  belongs_to :seat_layout
  belongs_to :movie
  belongs_to :movie_language
  belongs_to :movie_format

  has_many :show_section_prices, dependent: :destroy
  has_many :seat_sections, through: :show_section_prices
  has_many :show_seat_states, dependent: :destroy
  has_many :bookings, dependent: :restrict_with_error
  has_many :tickets, dependent: :restrict_with_error

  enum :status, { scheduled: "scheduled", cancelled: "cancelled", completed: "completed" }, prefix: true

  validates :start_time, :end_time, :total_capacity, :status, presence: true
  validates :total_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :end_time_after_start_time
  validate :seat_layout_belongs_to_screen
  validate :language_belongs_to_movie
  validate :format_belongs_to_movie
  validate :screen_supports_movie_format

  def release_expired_locks!
    show_seat_states.expired_locks.delete_all
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end

  def seat_layout_belongs_to_screen
    return if screen.blank? || seat_layout.blank?
    return if seat_layout.screen_id == screen_id

    errors.add(:seat_layout, "must belong to the selected screens")
  end

  def language_belongs_to_movie
    return if movie.blank? || movie_language.blank?
    return if movie_language.movie_id == movie_id

    errors.add(:movie_language, "must belong to the selected movies")
  end

  def format_belongs_to_movie
    return if movie.blank? || movie_format.blank?
    return if movie_format.movie_id == movie_id

    errors.add(:movie_format, "must belong to the selected movies")
  end

  def screen_supports_movie_format
    return if screen.blank? || movie_format.blank?
    return if screen.screen_capabilities.exists?(format_id: movie_format.format_id)

    errors.add(:movie_format, "is not supported by the selected screens")
  end
end
