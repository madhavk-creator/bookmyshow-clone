import { motion } from 'framer-motion'
import { useMemo, useState } from 'react'
import { useSelector } from 'react-redux'
import {
  ArrowDownRight, ArrowUpRight, CalendarDays, CheckCircle2,
  Clock3, Filter, Gauge, IndianRupee, Minus, Search, Ticket,
  TrendingUp, Video, AlertTriangle,
} from 'lucide-react'
import { selectCurrentUser } from '../../store/authSlice'
import { useGetVendorShowsSummaryQuery } from '../../store/apiSlice'
import { Skeleton } from '../../components/ui/Skeleton'
import {
  enrichShowsWithAnalytics,
  getOccupancySparklineData,
  getAveragePerformanceScore,
  getAverageRefundRate,
} from '../../utils/showAnalytics'

// ── Formatters ───────────────────────────────────────────────────────

function formatCurrency(value) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(Number(value || 0))
}

function formatDateTime(value) {
  return new Date(value).toLocaleString([], {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// ── Sub-components ───────────────────────────────────────────────────

function ContextualTrend({ current, baseline, label }) {
  if (baseline == null || baseline === 0) return null
  const diff = ((current - baseline) / baseline) * 100
  const isUp = diff > 2
  const isDown = diff < -2
  const Icon = isUp ? ArrowUpRight : isDown ? ArrowDownRight : Minus
  const color = isUp
    ? 'text-emerald-600 dark:text-emerald-400'
    : isDown
      ? 'text-red-500 dark:text-red-400'
      : 'text-neutral-400'

  return (
    <span className={`flex items-center gap-0.5 text-[9px] font-semibold ${color}`}>
      <Icon className="w-3 h-3 shrink-0" />
      {Math.abs(diff).toFixed(0)}% {label}
    </span>
  )
}

function OccupancyBar({ rate }) {
  const pct = Math.min(100, Math.max(0, Number(rate || 0)))
  const color = pct >= 75 ? 'bg-emerald-500' : pct >= 40 ? 'bg-amber-500' : 'bg-red-500'
  return (
    <div className="flex items-center gap-3 w-full">
      <div className="flex-1 h-2 rounded-full bg-neutral-200 dark:bg-neutral-700 overflow-hidden">
        <motion.div
          className={`h-full rounded-full ${color}`}
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
        />
      </div>
      <span className="text-xs font-bold text-neutral-600 dark:text-neutral-300 tabular-nums w-10 text-right">{pct}%</span>
    </div>
  )
}

function ScoreRing({ score, size = 44 }) {
  const radius = (size - 6) / 2
  const circumference = 2 * Math.PI * radius
  const offset = circumference - (Math.min(100, score) / 100) * circumference
  const color = score >= 70 ? '#22c55e' : score >= 40 ? '#f59e0b' : '#ef4444'
  const label = score >= 70 ? 'Great' : score >= 40 ? 'Okay' : 'Low'

  return (
    <div className="flex flex-col items-center gap-1 shrink-0" title={`Performance Score: ${score}/100`}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none"
          stroke="currentColor" className="text-neutral-200 dark:text-neutral-700" strokeWidth={3} />
        <motion.circle
          cx={size / 2} cy={size / 2} r={radius} fill="none"
          stroke={color} strokeWidth={3} strokeLinecap="round"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset: offset }}
          transition={{ duration: 1, ease: 'easeOut' }}
        />
      </svg>
      <div className="absolute flex flex-col items-center justify-center" style={{ width: size, height: size }}>
        <span className="text-xs font-black tabular-nums" style={{ color }}>{score}</span>
      </div>
      <span className="text-[9px] font-bold uppercase tracking-widest" style={{ color }}>{label}</span>
    </div>
  )
}

function Sparkline({ data, width = 120, height = 32 }) {
  if (!data || data.length < 2) return null
  const max = Math.max(...data, 1)
  const min = Math.min(...data, 0)
  const range = max - min || 1
  const points = data.map((v, i) => {
    const x = (i / (data.length - 1)) * width
    const y = height - ((v - min) / range) * (height - 4) - 2
    return `${x},${y}`
  }).join(' ')

  const trending = data[data.length - 1] >= data[0]
  const strokeColor = trending ? '#22c55e' : '#ef4444'

  return (
    <svg width={width} height={height} className="opacity-80">
      <polyline
        fill="none"
        stroke={strokeColor}
        strokeWidth={1.5}
        strokeLinecap="round"
        strokeLinejoin="round"
        points={points}
      />
      {/* dot on last point */}
      {(() => {
        const lastX = width
        const lastY = height - ((data[data.length - 1] - min) / range) * (height - 4) - 2
        return <circle cx={lastX} cy={lastY} r={2.5} fill={strokeColor} />
      })()}
    </svg>
  )
}

// ── Main Component ───────────────────────────────────────────────────

export default function VendorShowPerformance() {
  const user = useSelector(selectCurrentUser)
  const { data: shows = [], isLoading, isFetching } = useGetVendorShowsSummaryQuery(user?.id, {
    skip: !user?.id,
  })
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const loading = isLoading || isFetching

  const { enrichedShows, scheduledShows, completedShows, totals, fleetAvgScore, fleetAvgRefundRate } = useMemo(() => {
    const enriched = enrichShowsWithAnalytics(shows)
    const scheduled = enriched.filter(s => s.status === 'scheduled')
    const completed = enriched.filter(s => s.status === 'completed')

    return {
      enrichedShows: enriched,
      scheduledShows: scheduled,
      completedShows: completed,
      totals: {
        showCount: shows.length,
        seatsBooked: shows.reduce((sum, s) => sum + Number(s.seats_booked || 0), 0),
        bookings: shows.reduce((sum, s) => sum + Number(s.confirmed_bookings_count || 0), 0),
        income: shows.reduce((sum, s) => sum + Number(s.total_income || 0), 0),
      },
      fleetAvgScore: Math.round(getAveragePerformanceScore(shows)),
      fleetAvgRefundRate: getAverageRefundRate(shows).toFixed(1),
    }
  }, [shows])

  const filterShows = (list) => {
    if (!search) return list
    const q = search.toLowerCase()
    return list.filter(s =>
      s.movie?.title?.toLowerCase().includes(q) ||
      s.theatre?.name?.toLowerCase().includes(q) ||
      s.screen?.name?.toLowerCase().includes(q)
    )
  }

  const statCards = [
    { label: 'Tracked Shows', value: totals.showCount, icon: Video, color: 'from-amber-500 to-orange-500 shadow-amber-500/20' },
    { label: 'Seats Booked', value: totals.seatsBooked.toLocaleString(), icon: Ticket, color: 'from-blue-500 to-cyan-500 shadow-blue-500/20' },
    { label: 'Net Income', value: formatCurrency(totals.income), icon: TrendingUp, color: 'from-primary-500 to-indigo-500 shadow-primary-500/20' },
    { label: 'Avg Score', value: fleetAvgScore, icon: Gauge, color: 'from-emerald-500 to-teal-500 shadow-emerald-500/20' },
    { label: 'Confirmed Bookings', value: totals.bookings.toLocaleString(), icon: CheckCircle2, color: 'from-violet-500 to-purple-500 shadow-violet-500/20' },
    { label: 'Avg Refund Rate', value: `${fleetAvgRefundRate}%`, icon: AlertTriangle, color: 'from-rose-500 to-pink-500 shadow-rose-500/20' },
  ]

  const sections = statusFilter === 'completed'
    ? [{ title: 'Completed Shows', icon: CalendarDays, records: filterShows(completedShows), allRecords: completedShows, empty: 'Completed shows will appear here once they finish.' }]
    : statusFilter === 'scheduled'
      ? [{ title: 'Scheduled Shows', icon: Clock3, records: filterShows(scheduledShows), allRecords: scheduledShows, empty: 'No scheduled shows right now.' }]
      : [
          { title: 'Scheduled Shows', icon: Clock3, records: filterShows(scheduledShows), allRecords: scheduledShows, empty: 'No scheduled shows right now.' },
          { title: 'Completed Shows', icon: CalendarDays, records: filterShows(completedShows), allRecords: completedShows, empty: 'Completed shows will appear here once they finish.' },
        ]

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Show Performance</h1>
        <p className="mt-1 text-neutral-500 dark:text-neutral-400">
          Track scheduled and completed shows with contextual analytics, trend comparisons, and performance scoring.
        </p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-4 mb-10">
        {statCards.map((stat, index) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            className="glass-card p-5 flex flex-col gap-3"
          >
            <div className={`p-2.5 rounded-xl bg-gradient-to-br ${stat.color} text-white shadow-lg w-fit`}>
              <stat.icon className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[10px] font-bold uppercase tracking-widest text-neutral-400">{stat.label}</p>
              <p className="mt-1 text-xl font-black text-neutral-900 dark:text-white tabular-nums">
                {loading ? <Skeleton className="h-6 w-16 rounded" /> : stat.value}
              </p>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            placeholder="Search by movie, theatre, or screen…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-neutral-200 dark:border-neutral-700 bg-white dark:bg-neutral-900 text-sm text-neutral-900 dark:text-white placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500 transition-all"
          />
        </div>
        <div className="flex gap-2">
          {['all', 'scheduled', 'completed'].map(val => (
            <button
              key={val}
              onClick={() => setStatusFilter(val)}
              className={`px-4 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider border transition-all cursor-pointer ${
                statusFilter === val
                  ? 'bg-primary-500 text-white border-primary-500 shadow-md shadow-primary-500/20'
                  : 'border-neutral-200 dark:border-neutral-700 text-neutral-500 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800'
              }`}
            >
              {val}
            </button>
          ))}
        </div>
      </div>

      {/* Show Sections */}
      <div className="space-y-8">
        {sections.map((section, sectionIndex) => {
          const sparklineData = getOccupancySparklineData(section.allRecords)

          return (
            <div key={section.title} className="glass-card p-6">
              {/* Section Header */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-primary-500/10 text-primary-500 flex items-center justify-center">
                    <section.icon className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-neutral-900 dark:text-white">{section.title}</h2>
                    <p className="text-sm text-neutral-500 dark:text-neutral-400">{section.records.length} shows</p>
                  </div>
                </div>
                {/* Occupancy Sparkline */}
                {sparklineData.length >= 2 && (
                  <div className="hidden sm:flex flex-col items-end gap-1">
                    <span className="text-[9px] font-bold uppercase tracking-widest text-neutral-400">Occupancy Trend</span>
                    <Sparkline data={sparklineData} />
                  </div>
                )}
              </div>

              {loading ? (
                <div className="space-y-4">
                  {[1, 2, 3].map((item) => (
                    <Skeleton key={item} className="h-48 w-full rounded-2xl" />
                  ))}
                </div>
              ) : section.records.length === 0 ? (
                <div className="py-14 text-center text-neutral-500 dark:text-neutral-400">
                  {section.empty}
                </div>
              ) : (
                <div className="space-y-4">
                  {section.records.map((show, index) => {
                    const a = show.analytics
                    const occupancy = Number(show.occupancy_rate || 0)
                    const income = Number(show.total_income || 0)
                    const bookings = Number(show.confirmed_bookings_count || 0)
                    const seatsBooked = Number(show.seats_booked || 0)

                    return (
                      <motion.div
                        key={show.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: sectionIndex * 0.04 + index * 0.03 }}
                        className="rounded-2xl border border-neutral-200 bg-white/80 dark:border-neutral-800 dark:bg-neutral-900/50 overflow-hidden hover:border-primary-500/30 transition-colors"
                      >
                        {/* Card Header — Title + Score */}
                        <div className="p-5 pb-0">
                          <div className="flex items-start justify-between gap-4">
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-2">
                                <span className={`text-[10px] font-bold uppercase tracking-[0.2em] px-2.5 py-1 rounded-full border ${
                                  show.status === 'completed'
                                    ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20 dark:text-emerald-400'
                                    : 'bg-amber-500/10 text-amber-600 border-amber-500/20 dark:text-amber-400'
                                }`}>
                                  {show.status}
                                </span>
                                <span className="text-xs text-neutral-400 dark:text-neutral-500">{formatDateTime(show.start_time)}</span>
                              </div>
                              <h3 className="text-lg font-bold text-neutral-900 dark:text-white truncate">{show.movie.title}</h3>
                              <p className="mt-0.5 text-sm text-neutral-500 dark:text-neutral-400">
                                {show.theatre.name} · {show.screen.name}
                              </p>
                            </div>
                            {/* Performance Score Ring */}
                            <div className="relative">
                              <ScoreRing score={a.performanceScore} />
                            </div>
                          </div>
                        </div>

                        {/* KPI Grid */}
                        <div className="p-5 pt-4">
                          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                            {/* Seats / Occupancy */}
                            <div className="bg-neutral-50 dark:bg-neutral-800/40 rounded-xl px-4 py-3">
                              <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold mb-1">Occupancy</p>
                              <OccupancyBar rate={occupancy} />
                              <p className="text-xs text-neutral-500 mt-1 tabular-nums">
                                {seatsBooked}<span className="text-neutral-400">/{show.total_capacity} seats</span>
                              </p>
                              <div className="mt-2 flex flex-col gap-0.5">
                                {a.prevShow && (
                                  <ContextualTrend current={occupancy} baseline={a.prevShow.occupancy} label="vs prev" />
                                )}
                                {a.movieAvg && (
                                  <ContextualTrend current={occupancy} baseline={a.movieAvg.occupancy} label="vs movie avg" />
                                )}
                                {a.timeSlotAvg && (
                                  <ContextualTrend current={occupancy} baseline={a.timeSlotAvg.occupancy} label="vs timeslot" />
                                )}
                              </div>
                            </div>

                            {/* Revenue */}
                            <div className="bg-neutral-50 dark:bg-neutral-800/40 rounded-xl px-4 py-3">
                              <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold mb-1">Revenue</p>
                              <p className="text-lg font-black text-neutral-900 dark:text-white tabular-nums">{formatCurrency(income)}</p>
                              <div className="mt-2 flex flex-col gap-0.5">
                                {a.prevShow && (
                                  <ContextualTrend current={income} baseline={a.prevShow.income} label="vs prev" />
                                )}
                                {a.movieAvg && (
                                  <ContextualTrend current={income} baseline={a.movieAvg.income} label="vs movie" />
                                )}
                                {a.screenAvg && (
                                  <ContextualTrend current={income} baseline={a.screenAvg.income} label="vs screen" />
                                )}
                              </div>
                            </div>

                            {/* Bookings */}
                            <div className="bg-neutral-50 dark:bg-neutral-800/40 rounded-xl px-4 py-3">
                              <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold mb-1">Bookings</p>
                              <p className="text-lg font-black text-neutral-900 dark:text-white tabular-nums">{bookings}</p>
                              <div className="mt-2 flex flex-col gap-0.5">
                                {a.prevShow && (
                                  <ContextualTrend current={bookings} baseline={a.prevShow.bookings} label="vs prev" />
                                )}
                                {a.movieAvg && (
                                  <ContextualTrend current={bookings} baseline={a.movieAvg.bookings} label="vs movie avg" />
                                )}
                              </div>
                            </div>

                            {/* Refunds */}
                            <div className="bg-neutral-50 dark:bg-neutral-800/40 rounded-xl px-4 py-3">
                              <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold mb-1">Refunds</p>
                              <p className={`text-lg font-black tabular-nums ${Number(show.refund_amount) > 0 ? 'text-red-500' : 'text-neutral-900 dark:text-white'}`}>
                                {Number(show.refund_amount) > 0 ? '-' : ''}{formatCurrency(show.refund_amount)}
                              </p>
                              <div className="mt-2 flex flex-col gap-0.5">
                                <span className={`flex items-center gap-0.5 text-[9px] font-semibold ${
                                  a.refundRate > a.avgRefundRate + 1 ? 'text-red-500' : a.refundRate < a.avgRefundRate - 1 ? 'text-emerald-600 dark:text-emerald-400' : 'text-neutral-400'
                                }`}>
                                  {a.refundRate > a.avgRefundRate + 1 ? <ArrowUpRight className="w-3 h-3" /> : a.refundRate < a.avgRefundRate - 1 ? <ArrowDownRight className="w-3 h-3" /> : <Minus className="w-3 h-3" />}
                                  {a.refundRate.toFixed(1)}% rate (avg {a.avgRefundRate.toFixed(1)}%)
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>

                        {/* Card Footer */}
                        <div className="grid grid-cols-3 gap-px border-t border-neutral-100 dark:border-neutral-800 bg-neutral-100 dark:bg-neutral-800">
                          <div className="bg-white dark:bg-neutral-900/70 px-5 py-3">
                            <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold">Gross Sales</p>
                            <p className="mt-0.5 text-sm font-bold text-neutral-900 dark:text-white">{formatCurrency(show.gross_income)}</p>
                          </div>
                          <div className="bg-white dark:bg-neutral-900/70 px-5 py-3">
                            <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold">Score vs Avg</p>
                            <p className="mt-0.5 text-sm font-bold text-neutral-900 dark:text-white">
                              {a.performanceScore} <span className="text-neutral-400 font-medium">/ {Math.round(a.avgPerformanceScore)}</span>
                            </p>
                          </div>
                          <div className="bg-white dark:bg-neutral-900/70 px-5 py-3">
                            <p className="text-[10px] uppercase tracking-widest text-neutral-400 font-bold">Show Ends</p>
                            <p className="mt-0.5 text-sm font-bold text-neutral-900 dark:text-white">{formatDateTime(show.end_time)}</p>
                          </div>
                        </div>
                      </motion.div>
                    )
                  })}
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
