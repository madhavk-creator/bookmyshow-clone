import { motion } from 'framer-motion'
import { useMemo } from 'react'
import { useSelector } from 'react-redux'
import { CalendarDays, CheckCircle2, Clock3, IndianRupee, Ticket, TrendingUp, Video } from 'lucide-react'
import { selectCurrentUser } from '../../store/authSlice'
import { useGetVendorShowsSummaryQuery } from '../../store/apiSlice'

function formatCurrency(value) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2,
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

export default function VendorShowPerformance() {
  const user = useSelector(selectCurrentUser)
  const { data: shows = [], isLoading, isFetching } = useGetVendorShowsSummaryQuery(user?.id, {
    skip: !user?.id,
  })

  const loading = isLoading || isFetching

  const { scheduledShows, completedShows, totals } = useMemo(() => {
    const scheduled = shows.filter((show) => show.status === 'scheduled')
    const completed = shows.filter((show) => show.status === 'completed')

    return {
      scheduledShows: scheduled,
      completedShows: completed,
      totals: {
        showCount: shows.length,
        seatsBooked: shows.reduce((sum, show) => sum + Number(show.seats_booked || 0), 0),
        bookings: shows.reduce((sum, show) => sum + Number(show.confirmed_bookings_count || 0), 0),
        income: shows.reduce((sum, show) => sum + Number(show.total_income || 0), 0),
      },
    }
  }, [shows])

  const statCards = [
    { label: 'Tracked Shows', value: totals.showCount, icon: Video, color: 'from-amber-500 to-orange-500 shadow-amber-500/20' },
    { label: 'Seats Booked', value: totals.seatsBooked, icon: Ticket, color: 'from-blue-500 to-cyan-500 shadow-blue-500/20' },
    { label: 'Confirmed Bookings', value: totals.bookings, icon: CheckCircle2, color: 'from-emerald-500 to-green-500 shadow-emerald-500/20' },
    { label: 'Net Income', value: formatCurrency(totals.income), icon: TrendingUp, color: 'from-primary-500 to-indigo-500 shadow-primary-500/20' },
  ]

  const sections = [
    { title: 'Scheduled Shows', icon: Clock3, records: scheduledShows, empty: 'No scheduled shows right now.' },
    { title: 'Completed Shows', icon: CalendarDays, records: completedShows, empty: 'Completed shows will appear here once they finish.' },
  ]

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Show Performance</h1>
        <p className="mt-1 text-neutral-500 dark:text-neutral-400">
          Track scheduled and completed shows across all your theatres, including bookings and revenue.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6 mb-10">
        {statCards.map((stat, index) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.06 }}
            className="glass-card p-6 flex items-start gap-4"
          >
            <div className={`p-3 rounded-xl bg-gradient-to-br ${stat.color} text-white shadow-lg`}>
              <stat.icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-neutral-500 dark:text-neutral-400">{stat.label}</p>
              <p className="mt-1 text-2xl font-bold text-neutral-900 dark:text-white">
                {loading ? <span className="inline-block h-6 w-20 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : stat.value}
              </p>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="space-y-8">
        {sections.map((section, sectionIndex) => (
          <div key={section.title} className="glass-card p-6">
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
            </div>

            {loading ? (
              <div className="space-y-4">
                {[1, 2, 3].map((item) => (
                  <div key={item} className="h-28 rounded-2xl bg-neutral-100 dark:bg-neutral-800/50 animate-pulse" />
                ))}
              </div>
            ) : section.records.length === 0 ? (
              <div className="py-14 text-center text-neutral-500 dark:text-neutral-400">
                {section.empty}
              </div>
            ) : (
              <div className="space-y-4">
                {section.records.map((show, index) => (
                  <motion.div
                    key={show.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: sectionIndex * 0.05 + index * 0.04 }}
                    className="rounded-2xl border border-neutral-200 bg-white/80 p-5 dark:border-neutral-800 dark:bg-neutral-900/50"
                  >
                    <div className="flex flex-col gap-5 xl:flex-row xl:items-start xl:justify-between">
                      <div>
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
                        <h3 className="text-lg font-bold text-neutral-900 dark:text-white">{show.movie.title}</h3>
                        <p className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">
                          {show.theatre.name} · {show.screen.name}
                        </p>
                      </div>

                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 xl:min-w-[520px]">
                        <div>
                          <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Seats Booked</p>
                          <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">
                            {show.seats_booked} / {show.total_capacity}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Occupancy</p>
                          <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">{show.occupancy_rate}%</p>
                        </div>
                        <div>
                          <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Bookings</p>
                          <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">{show.confirmed_bookings_count}</p>
                        </div>
                        <div>
                          <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Net Income</p>
                          <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">{formatCurrency(show.total_income)}</p>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div className="rounded-xl bg-neutral-50 px-4 py-3 dark:bg-neutral-800/50">
                        <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Gross Sales</p>
                        <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">{formatCurrency(show.gross_income)}</p>
                      </div>
                      <div className="rounded-xl bg-neutral-50 px-4 py-3 dark:bg-neutral-800/50">
                        <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Refunds</p>
                        <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">{formatCurrency(show.refund_amount)}</p>
                      </div>
                      <div className="rounded-xl bg-neutral-50 px-4 py-3 dark:bg-neutral-800/50">
                        <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Show Ends</p>
                        <p className="mt-1 text-sm font-semibold text-neutral-900 dark:text-white">{formatDateTime(show.end_time)}</p>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
