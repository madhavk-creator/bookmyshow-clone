// ── Helpers ──────────────────────────────────────────────────────────

function avg(arr) {
  if (!arr.length) return 0
  return arr.reduce((s, v) => s + v, 0) / arr.length
}

function pctChange(current, baseline) {
  if (!baseline || baseline === 0) return null
  return ((current - baseline) / baseline) * 100
}

function getHourBucket(dateStr) {
  const h = new Date(dateStr).getHours()
  if (h < 12) return 'morning'
  if (h < 17) return 'afternoon'
  return 'evening'
}

// ── Per-show lookups ─────────────────────────────────────────────────

/**
 * Find the chronologically previous show on the same screen.
 * Shows are ordered desc by start_time from the API.
 */
export function getPreviousShowOnScreen(show, shows) {
  const sameScreen = shows
    .filter(s => s.screen.id === show.screen.id && s.id !== show.id)
    .sort((a, b) => new Date(b.start_time) - new Date(a.start_time))

  const showTime = new Date(show.start_time).getTime()
  return sameScreen.find(s => new Date(s.start_time).getTime() < showTime) || null
}

/**
 * Average occupancy, revenue, bookings across all shows of the same movie.
 */
export function getAveragesForMovie(show, shows) {
  const sameMovie = shows.filter(s => s.movie.id === show.movie.id && s.id !== show.id)
  if (!sameMovie.length) return null
  return {
    occupancy: avg(sameMovie.map(s => Number(s.occupancy_rate || 0))),
    income: avg(sameMovie.map(s => Number(s.total_income || 0))),
    bookings: avg(sameMovie.map(s => Number(s.confirmed_bookings_count || 0))),
  }
}

/**
 * Average revenue across all shows on the same screen.
 */
export function getAveragesForScreen(show, shows) {
  const sameScreen = shows.filter(s => s.screen.id === show.screen.id && s.id !== show.id)
  if (!sameScreen.length) return null
  return {
    income: avg(sameScreen.map(s => Number(s.total_income || 0))),
  }
}

/**
 * Average occupancy for same movie + same time-of-day bucket.
 */
export function getTimeSlotAverages(show, shows) {
  const bucket = getHourBucket(show.start_time)
  const matching = shows.filter(s =>
    s.movie.id === show.movie.id &&
    s.id !== show.id &&
    getHourBucket(s.start_time) === bucket
  )
  if (!matching.length) return null
  return {
    occupancy: avg(matching.map(s => Number(s.occupancy_rate || 0))),
  }
}

/**
 * Refund rate for a single show (refund_amount / gross_income * 100).
 */
export function getRefundRate(show) {
  const gross = Number(show.gross_income || 0)
  if (gross === 0) return 0
  return (Number(show.refund_amount || 0) / gross) * 100
}

/**
 * Fleet-wide average refund rate.
 */
export function getAverageRefundRate(shows) {
  const rates = shows.map(s => getRefundRate(s))
  return avg(rates)
}

// ── Performance Score ────────────────────────────────────────────────

const OCCUPANCY_WEIGHT = 0.6
const REVENUE_WEIGHT = 0.4

/**
 * Composite performance score (0-100).
 * occupancy component: raw occupancy% (already 0-100)
 * revenue component: show income / avg income, capped at 200%, mapped to 0-100
 */
export function computePerformanceScore(show, avgIncome) {
  const occupancy = Math.min(100, Number(show.occupancy_rate || 0))
  const revenueRatio = avgIncome > 0
    ? Math.min(2, Number(show.total_income || 0) / avgIncome)
    : 1
  const revenueScore = revenueRatio * 50 // map 0-2 → 0-100

  return Math.round(OCCUPANCY_WEIGHT * occupancy + REVENUE_WEIGHT * revenueScore)
}

/**
 * Fleet-wide average performance score.
 */
export function getAveragePerformanceScore(shows) {
  const avgIncome = avg(shows.map(s => Number(s.total_income || 0)))
  return avg(shows.map(s => computePerformanceScore(s, avgIncome)))
}

// ── Master enrichment ────────────────────────────────────────────────

/**
 * Takes the raw shows array and returns a new array where each show
 * has an `analytics` property containing all computed metrics.
 */
export function enrichShowsWithAnalytics(shows) {
  if (!shows.length) return []

  const avgIncome = avg(shows.map(s => Number(s.total_income || 0)))
  const fleetAvgRefundRate = getAverageRefundRate(shows)
  const fleetAvgScore = getAveragePerformanceScore(shows)

  return shows.map(show => {
    const prevShow = getPreviousShowOnScreen(show, shows)
    const movieAvg = getAveragesForMovie(show, shows)
    const screenAvg = getAveragesForScreen(show, shows)
    const timeSlotAvg = getTimeSlotAverages(show, shows)
    const refundRate = getRefundRate(show)
    const score = computePerformanceScore(show, avgIncome)

    return {
      ...show,
      analytics: {
        prevShow: prevShow
          ? {
              occupancy: Number(prevShow.occupancy_rate || 0),
              income: Number(prevShow.total_income || 0),
              bookings: Number(prevShow.confirmed_bookings_count || 0),
            }
          : null,
        movieAvg,
        screenAvg,
        timeSlotAvg,
        refundRate,
        avgRefundRate: fleetAvgRefundRate,
        performanceScore: score,
        avgPerformanceScore: fleetAvgScore,
      },
    }
  })
}

// ── Sparkline data ───────────────────────────────────────────────────

/**
 * Given a list of shows (already filtered to a section), return an
 * array of occupancy values ordered chronologically (oldest first)
 * for rendering as a sparkline.
 */
export function getOccupancySparklineData(shows) {
  return [...shows]
    .sort((a, b) => new Date(a.start_time) - new Date(b.start_time))
    .map(s => Number(s.occupancy_rate || 0))
}
