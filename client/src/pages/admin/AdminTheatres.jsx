import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useSelector } from 'react-redux'
import { Building2, MapPin, Loader } from 'lucide-react'
import { selectCurrentToken } from '../../store/authSlice'

export default function AdminTheatres() {
  const token = useSelector(selectCurrentToken)
  const [theatres, setTheatres] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchTheatres() {
      try {
        const res = await fetch('/api/v1/theatres', { headers: { Authorization: `Bearer ${token}` } })
        const data = await res.json()
        setTheatres(Array.isArray(data) ? data : [])
      } catch (err) { console.error(err) }
      finally { setLoading(false) }
    }
    fetchTheatres()
  }, [token])

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Theatres</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-1">All theatres across the platform</p>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader className="w-10 h-10 text-rose-500 animate-spin" /></div>
      ) : theatres.length === 0 ? (
        <div className="glass-card p-16 text-center hover:translate-y-0">
          <Building2 className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
          <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No theatres registered</h3>
        </div>
      ) : (
        <div className="glass-card overflow-hidden hover:translate-y-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-neutral-200 dark:border-neutral-800">
                <th className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Theatre</th>
                <th className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">City</th>
                <th className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Address</th>
                <th className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Vendor</th>
                <th className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Created</th>
              </tr>
            </thead>
            <tbody>
              <AnimatePresence>
                {theatres.map((t, i) => (
                  <motion.tr key={t.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.03 }}
                    className="border-b border-neutral-100 dark:border-neutral-800/50 hover:bg-neutral-50 dark:hover:bg-neutral-900/30 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-lg bg-primary-500/10 flex items-center justify-center shrink-0">
                          <Building2 className="w-4 h-4 text-primary-500" />
                        </div>
                        <span className="text-sm font-semibold text-neutral-900 dark:text-white">{t.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5 text-sm text-neutral-600 dark:text-neutral-300">
                        <MapPin className="w-3.5 h-3.5 text-neutral-400" />
                        {t.city?.name}, {t.city?.state}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-neutral-500 dark:text-neutral-400">
                      {[t.building_name, t.street_address, t.pincode].filter(Boolean).join(', ') || '—'}
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-xs font-mono text-neutral-400 dark:text-neutral-500">{t.vendor_id?.slice(0, 8)}…</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-neutral-400">{new Date(t.created_at).toLocaleDateString()}</td>
                  </motion.tr>
                ))}
              </AnimatePresence>
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
