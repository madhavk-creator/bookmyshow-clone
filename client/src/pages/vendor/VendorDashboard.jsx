import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { useSelector } from 'react-redux'
import { ArrowRight, Building2, Clapperboard, Monitor, Ticket, TrendingUp } from 'lucide-react'
import { selectCurrentUser } from '../../store/authSlice'
import { useGetTheatresQuery, useGetVendorIncomeQuery } from '../../store/apiSlice'

export default function VendorDashboard() {
  const user = useSelector(selectCurrentUser)
  const { data: theatres = [], isLoading: theatresLoading, isFetching: theatresFetching } = useGetTheatresQuery(
    { vendor_id: user?.id },
    { skip: !user?.id }
  )
  const {
    data: income = {
      theatres_count: 0,
      completed_bookings_count: 0,
      tickets_sold_count: 0,
      gross_income: 0,
      refund_amount: 0,
      total_income: 0,
    },
    isLoading: incomeLoading,
    isFetching: incomeFetching,
  } = useGetVendorIncomeQuery(user?.id, { skip: !user?.id })
  const loading = theatresLoading || theatresFetching || incomeLoading || incomeFetching

  const formatCurrency = (value) => {
    const amount = Number(value || 0)
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 2,
    }).format(amount)
  }

  const stats = [
    { label: 'Total Theatres', value: theatres.length, icon: Building2, color: 'amber' },
    { label: 'Tickets Sold', value: income?.tickets_sold_count ?? 0, icon: Monitor, color: 'blue' },
    { label: 'Confirmed Bookings', value: income?.completed_bookings_count ?? 0, icon: Ticket, color: 'green' },
    { label: 'Net Revenue', value: formatCurrency(income?.total_income), icon: TrendingUp, color: 'purple' },
  ]

  const colorMap = {
    amber:  'from-amber-500 to-orange-500 shadow-amber-500/20',
    blue:   'from-blue-500 to-cyan-500 shadow-blue-500/20',
    green:  'from-emerald-500 to-green-500 shadow-emerald-500/20',
    purple: 'from-primary-500 to-purple-500 shadow-primary-500/20',
  }

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">
          Welcome back, <span className="text-amber-500">{user?.name}</span>
        </h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-1">Here's an overview of your cinematic empire.</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
        {stats.map((stat, i) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.1, duration: 0.4 }}
            className="glass-card p-6 flex items-start gap-4 hover:translate-y-0"
          >
            <div className={`p-3 rounded-xl bg-gradient-to-br ${colorMap[stat.color]} shadow-lg text-white`}>
              <stat.icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">{stat.label}</p>
              <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-1">
                {loading ? <span className="inline-block w-8 h-6 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : stat.value}
              </p>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-10">
        <div className="glass-card p-6 hover:translate-y-0">
          <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Gross Ticket Sales</p>
          <p className="text-3xl font-bold text-neutral-900 dark:text-white mt-2">
            {loading ? <span className="inline-block w-24 h-8 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : formatCurrency(income?.gross_income)}
          </p>
          <p className="text-xs text-neutral-400 dark:text-neutral-500 mt-2">All completed ticket payments across your theatres.</p>
        </div>

        <div className="glass-card p-6 hover:translate-y-0">
          <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Refunded Amount</p>
          <p className="text-3xl font-bold text-neutral-900 dark:text-white mt-2">
            {loading ? <span className="inline-block w-24 h-8 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : formatCurrency(income?.refund_amount)}
          </p>
          <p className="text-xs text-neutral-400 dark:text-neutral-500 mt-2">Completed refunds deducted from your total income.</p>
        </div>

        <div className="glass-card p-6 hover:translate-y-0">
          <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Revenue per Theatre</p>
          <p className="text-3xl font-bold text-neutral-900 dark:text-white mt-2">
            {loading ? (
              <span className="inline-block w-24 h-8 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" />
            ) : (
              formatCurrency(theatres.length ? Number(income?.total_income || 0) / theatres.length : 0)
            )}
          </p>
          <p className="text-xs text-neutral-400 dark:text-neutral-500 mt-2">Average net income across your active theatre portfolio.</p>
        </div>

        <Link
          to="/vendor/show-performance"
          className="glass-card p-6 hover:translate-y-0 border border-amber-500/20 bg-gradient-to-br from-amber-500/10 via-white to-orange-500/10 dark:from-amber-500/10 dark:via-neutral-950 dark:to-orange-500/10"
        >
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Show Performance</p>
              <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">See show-wise bookings and revenue</p>
              <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-2">
                Review scheduled and completed shows with occupancy, booked seats, and income.
              </p>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-amber-500/15 flex items-center justify-center text-amber-500 shrink-0">
              <Clapperboard className="w-6 h-6" />
            </div>
          </div>
          <div className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-amber-600 dark:text-amber-400">
            Open performance page
            <ArrowRight className="w-4 h-4" />
          </div>
        </Link>
      </div>

      {/* Recent Theatres */}
      <div className="glass-card p-6 hover:translate-y-0">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-bold text-neutral-900 dark:text-white">Your Theatres</h2>
          <span className="text-xs font-bold uppercase tracking-widest px-3 py-1 rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20">
            {theatres.length} total
          </span>
        </div>

        {loading ? (
          <div className="space-y-4">
            {[1,2,3].map(i => (
              <div key={i} className="h-16 rounded-xl bg-neutral-100 dark:bg-neutral-800/50 animate-pulse" />
            ))}
          </div>
        ) : theatres.length === 0 ? (
          <div className="py-12 text-center">
            <Building2 className="w-12 h-12 mx-auto text-neutral-300 dark:text-neutral-600 mb-3" />
            <p className="text-neutral-500 dark:text-neutral-400 font-medium">No theatres yet</p>
            <p className="text-sm text-neutral-400 dark:text-neutral-500 mt-1">Create your first theatre from the Theatres page.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {theatres.map((theatre, i) => (
              <motion.div
                key={theatre.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.05 }}
                className="flex items-center justify-between p-4 rounded-xl bg-neutral-50 dark:bg-neutral-900/40 border border-neutral-200 dark:border-neutral-800 hover:border-amber-500/30 hover:bg-amber-500/5 transition-all"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
                    <Building2 className="w-5 h-5 text-amber-500" />
                  </div>
                  <div>
                    <p className="font-semibold text-neutral-900 dark:text-white">{theatre.name}</p>
                    <p className="text-xs text-neutral-500 dark:text-neutral-400">
                      {theatre.city?.name}, {theatre.city?.state}
                      {theatre.building_name && ` · ${theatre.building_name}`}
                    </p>
                  </div>
                </div>
                <span className="text-xs text-neutral-400 dark:text-neutral-500 hidden sm:block">
                  {new Date(theatre.created_at).toLocaleDateString()}
                </span>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
