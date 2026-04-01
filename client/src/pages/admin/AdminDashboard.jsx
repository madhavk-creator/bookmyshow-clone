import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { useSelector } from 'react-redux'
import { Clapperboard, MapPin, Globe, MonitorPlay, Building2, Users } from 'lucide-react'
import { selectCurrentToken } from '../../store/authSlice'

export default function AdminDashboard() {
  const token = useSelector(selectCurrentToken)
  const [counts, setCounts] = useState({ movies: '—', cities: '—', languages: '—', formats: '—', theatres: '—' })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchCounts() {
      const headers = { Authorization: `Bearer ${token}` }
      try {
        const [movies, cities, languages, formats, theatres] = await Promise.all([
          fetch('/api/v1/movies').then(r => r.json()),
          fetch('/api/v1/cities').then(r => r.json()),
          fetch('/api/v1/languages').then(r => r.json()),
          fetch('/api/v1/formats').then(r => r.json()),
          fetch('/api/v1/theatres', { headers }).then(r => r.json()),
        ])
        setCounts({
          movies: Array.isArray(movies) ? movies.length : 0,
          cities: Array.isArray(cities) ? cities.length : 0,
          languages: Array.isArray(languages) ? languages.length : 0,
          formats: Array.isArray(formats) ? formats.length : 0,
          theatres: Array.isArray(theatres) ? theatres.length : 0,
        })
      } catch (err) { console.error(err) }
      finally { setLoading(false) }
    }
    fetchCounts()
  }, [token])

  const stats = [
    { label: 'Movies',    value: counts.movies,    icon: Clapperboard, color: 'from-rose-500 to-pink-500 shadow-rose-500/20' },
    { label: 'Cities',    value: counts.cities,    icon: MapPin,       color: 'from-blue-500 to-cyan-500 shadow-blue-500/20' },
    { label: 'Languages', value: counts.languages, icon: Globe,        color: 'from-emerald-500 to-green-500 shadow-emerald-500/20' },
    { label: 'Formats',   value: counts.formats,   icon: MonitorPlay,  color: 'from-amber-500 to-orange-500 shadow-amber-500/20' },
    { label: 'Theatres',  value: counts.theatres,  icon: Building2,    color: 'from-primary-500 to-purple-500 shadow-primary-500/20' },
  ]

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Admin Console</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-1">Platform overview and management</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-6 mb-10">
        {stats.map((stat, i) => (
          <motion.div key={stat.label} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08, duration: 0.4 }} className="glass-card p-6 flex flex-col items-center text-center hover:translate-y-0">
            <div className={`p-3 rounded-xl bg-gradient-to-br ${stat.color} shadow-lg text-white mb-3`}>
              <stat.icon className="w-6 h-6" />
            </div>
            <p className="text-2xl font-bold text-neutral-900 dark:text-white">
              {loading ? <span className="inline-block w-8 h-6 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : stat.value}
            </p>
            <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium mt-1">{stat.label}</p>
          </motion.div>
        ))}
      </div>
    </div>
  )
}
