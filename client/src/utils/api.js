import axios from 'axios'

const FIELD_LABELS = {
  base: '',
  booking: 'Booking',
  booking_amount: 'Booking amount',
  coupon: 'Coupon',
  coupon_code: 'Coupon code',
  discount_amount: 'Discount amount',
  discount_percentage: 'Discount percentage',
  format: 'Format',
  language: 'Language',
  movie: 'Movie',
  movie_format: 'Format',
  movie_language: 'Language',
  payment: 'Payment',
  seat: 'Seat',
  seat_ids: 'Selected seats',
  show: 'Show',
  valid_from: 'Start date',
  valid_until: 'End date',
}

function humanizeApiMessage(message, fallback) {
  if (!message) return fallback

  const normalized = String(message).trim()

  const exactMatches = {
    Unauthorized: 'Please sign in to continue.',
    Forbidden: "You don't have permission to do that.",
    'Invalid credentials': 'That email or password did not match.',
    'Invalid coupon code': "That coupon code doesn't look right.",
    'Coupon not found': "We couldn't find that coupon.",
    'Coupon is not applicable to this booking': "This coupon can't be used for this booking.",
    'Coupon is not applicable to this booking amount or has expired': "This coupon can't be used for this booking.",
    'This coupon can only be used by registered users': 'Please sign in to use this coupon.',
    'You have already used this coupon the maximum number of times': "You've already used this coupon as many times as allowed.",
    'This coupon has reached its maximum global redemptions': 'This coupon is no longer available.',
    'No pending payment found for this booking': "We couldn't find a pending payment for this booking.",
    'Booking has expired or seat locks are no longer valid': 'Your seat hold has expired. Please choose your seats again.',
    'Booking has expired or seat locks changed before confirmation': 'The selected seats are no longer available. Please select different seats and try again.',
    'Booking is no longer pending': 'This checkout session is no longer active.',
    'Booking is expired and cannot be confirmed': 'This checkout session has expired.',
    'This show has already started': 'This show has already started.',
    'Show not found or not available for booking': "This show isn't available for booking right now.",
    'Show not found or not schedulable': "This show isn't available right now.",
    'No seats selected': 'Please select at least one seat.',
    'Seats no longer available': 'Some of those seats are no longer available.',
    'Could not acquire seat locks': 'We could not hold those seats right now. Please try again.',
    'Booking could not be created': "We couldn't start your booking. Please try again.",
    'Booking could not be cancelled': "We couldn't cancel this booking right now.",
    'Payment confirmation failed': 'We could not confirm your payment right now.',
    'Could not load seat availability': "We couldn't load seat availability right now.",
    'Could not load seat layout': "We couldn't load this seat layout right now.",
  }

  if (exactMatches[normalized]) return exactMatches[normalized]

  const patternMatches = [
    [/^Not authorized/i, () => "You don't have permission to do that."],
    [/^Not found$/i, () => "We couldn't find what you were looking for."],
    [/not found/i, () => "We couldn't find what you were looking for."],
    [/already started/i, () => 'This show has already started.'],
    [/already has a show scheduled during:\s*(.+)$/i, (_, conflicts) => `This screen already has shows scheduled on ${conflicts}. Choose a different time or shorten the date range.`],
    [/already has a show scheduled during this time/i, () => 'There is already another show scheduled in this screen at that time.'],
    [/seats no longer available/i, () => 'Some of those seats are no longer available.'],
    [/unknown seat ids/i, () => 'Some selected seats are no longer available.'],
    [/inactive seat ids/i, () => 'Some selected seats are not available right now.'],
    [/contains duplicate seat ids/i, () => 'Please remove duplicate seats and try again.'],
    [/must include at least one seat/i, () => 'Please select at least one seat.'],
    [/one or more seats are invalid for this show/i, () => 'Some selected seats are not available for this show.'],
    [/show not found/i, () => "We couldn't find that show."],
    [/booking is .* cannot be confirmed/i, () => 'This booking can no longer be completed.'],
    [/only pending or confirmed bookings can be cancelled/i, () => 'This booking can no longer be cancelled.'],
    [/only confirmed bookings can be cancelled/i, () => 'Only confirmed bookings can be cancelled.'],
    [/ticket is already cancelled/i, () => 'This ticket has already been cancelled.'],
    [/ticket not found/i, () => "We couldn't find that ticket."],
    [/booking amount is required/i, () => 'Enter the booking amount to validate this coupon.'],
    [/must be a valid number/i, () => 'Please enter a valid amount.'],
    [/can only apply coupons to pending bookings/i, () => 'Coupons can only be changed before payment is completed.'],
    [/cannot be greater than the minimum booking amount/i, () => 'Discount amount cannot be greater than the minimum booking amount.'],
    [/must contain only uppercase letters and numbers/i, () => 'Use only letters and numbers in the coupon code.'],
    [/cannot delete a city that still has theatres/i, () => "You can't delete this city while theatres are still assigned to it."],
    [/cannot delete a format that is still enabled on screens/i, () => "You can't delete this format while it is still enabled on one or more screens."],
    [/cannot delete a format that still has scheduled shows/i, () => "You can't delete this format while shows in that format are still scheduled."],
    [/cannot delete a format that is still used by movies/i, () => "You can't delete this format while movies still use it."],
    [/cannot delete a language that still has scheduled shows/i, () => "You can't delete this language while shows in that language are still scheduled."],
    [/cannot delete a language that is still used by movies/i, () => "You can't delete this language while movies still use it."],
    [/cannot remove formats with scheduled shows:\s*(.+)$/i, (_, formats) => `You can't remove ${formats} from this screen while shows in that format are still scheduled.`],
  ]

  for (const [pattern, replacement] of patternMatches) {
    const match = normalized.match(pattern)
    if (match) return replacement(...match)
  }

  return normalized || fallback
}

function formatErrorEntry(field, value, fallback) {
  const label = FIELD_LABELS[field] ?? field.replace(/_/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase())
  const message = humanizeApiMessage([].concat(value).join(', '), fallback)
  return label ? `${label}: ${message}` : message
}

export const api = axios.create({
  headers: {
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')

  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

export function extractApiError(error, fallback = 'Something went wrong') {
  const data = axios.isAxiosError(error)
    ? error.response?.data
    : error?.data || error

  if (!data) return error?.message || fallback
  if (data.errors) {
    if (Array.isArray(data.errors)) {
      return data.errors.map((message) => humanizeApiMessage(message, fallback)).join(', ')
    }
    if (typeof data.errors === 'object') {
      return Object.entries(data.errors)
        .map(([key, value]) => formatErrorEntry(key, value, fallback))
        .join('; ')
    }
    return humanizeApiMessage(String(data.errors), fallback)
  }

  return humanizeApiMessage(data.error || error?.message, fallback)
}

export function getVendors(config = {}) {
  return api.get('/api/v1/vendors', config)
}

export function getVendorIncome(vendorId, config = {}) {
  return api.get(`/api/v1/vendors/${vendorId}/income`, config)
}

export function normalizeCollectionResponse(data, key) {
  if (Array.isArray(data)) return data
  return data?.[key] || []
}

export async function getCities(config = {}) {
  const { data } = await api.get('/api/v1/cities', config)
  return normalizeCollectionResponse(data, 'cities')
}

export async function getMovies(config = {}) {
  const { data } = await api.get('/api/v1/movies', config)
  return normalizeCollectionResponse(data, 'movies')
}

export async function getMovie(movieId, config = {}) {
  const { data } = await api.get(`/api/v1/movies/${movieId}`, config)
  return data
}

export async function getShows(config = {}) {
  const { data } = await api.get('/api/v1/shows', config)
  return normalizeCollectionResponse(data, 'shows')
}
