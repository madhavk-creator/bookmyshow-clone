import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { useSelector } from 'react-redux'
import { Building2, Monitor, Ticket, TrendingUp } from 'lucide-react'
import { selectCurrentUser, selectCurrentToken } from '../../store/authSlice'

export default function VendorDashboard() {
  const user = useSelector(selectCurrentUser)
  const token = useSelector(selectCurrentToken)
  const [theatres, setTheatres] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchTheatres() {
      try {
        const res = await fetch(`/api/v1/theatres?vendor_id=${user?.id}`, {
          headers: { Authorization: `Bearer ${token}` }
        })
        if (!res.ok) throw new Error('Failed to fetch')
        const data = await res.json()
        setTheatres(Array.isArray(data) ? data : [])
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }
    if (user?.id) fetchTheatres()
  }, [user?.id, token])

  const totalScreens = theatres.reduce((sum) => sum, 0) // placeholder

  const stats = [
    { label: 'Total Theatres', value: theatres.length, icon: Building2, color: 'amber' },
    { label: 'Active Screens', value: '—', icon: Monitor, color: 'blue' },
    { label: 'Total Bookings', value: '—', icon: Ticket, color: 'green' },
    { label: 'Revenue', value: '—', icon: TrendingUp, color: 'purple' },
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
