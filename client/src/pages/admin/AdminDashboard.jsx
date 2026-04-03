import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { Clapperboard, MapPin, Globe, MonitorPlay, Building2, Users, TrendingUp, Ticket } from 'lucide-react'
import { api, getVendorIncome, getVendors } from '../../utils/api'

export default function AdminDashboard() {
  const [counts, setCounts] = useState({ movies: '—', cities: '—', languages: '—', formats: '—', theatres: '—', vendors: '—' })
  const [vendorSummaries, setVendorSummaries] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchDashboard() {
      try {
        const [
          { data: movies },
          { data: cities },
          { data: languages },
          { data: formats },
          { data: theatres },
          { data: vendorsData },
        ] = await Promise.all([
          api.get('/api/v1/movies'),
          api.get('/api/v1/cities'),
          api.get('/api/v1/languages'),
          api.get('/api/v1/formats'),
          api.get('/api/v1/theatres'),
          getVendors(),
        ])

        const vendors = Array.isArray(vendorsData) ? vendorsData : (vendorsData?.vendors || [])
        const incomeResponses = await Promise.all(
          vendors.map(async (vendor) => {
            try {
              const { data } = await getVendorIncome(vendor.id)
              return {
                id: vendor.id,
                name: vendor.name,
                email: vendor.email,
                theatres_count: vendor.theatres_count ?? data.theatres_count ?? 0,
                tickets_sold_count: data.tickets_sold_count ?? 0,
                completed_bookings_count: data.completed_bookings_count ?? 0,
                total_income: Number(data.total_income || 0),
                gross_income: Number(data.gross_income || 0),
                refund_amount: Number(data.refund_amount || 0),
              }
            } catch (error) {
              console.error(error)
              return {
                id: vendor.id,
                name: vendor.name,
                email: vendor.email,
                theatres_count: vendor.theatres_count ?? 0,
                tickets_sold_count: 0,
                completed_bookings_count: 0,
                total_income: 0,
                gross_income: 0,
                refund_amount: 0,
              }
            }
          })
        )

        setCounts({
          movies: Array.isArray(movies) ? movies.length : (movies?.pagination?.total_count ?? movies?.movies?.length ?? 0),
          cities: Array.isArray(cities) ? cities.length : 0,
          languages: Array.isArray(languages) ? languages.length : 0,
          formats: Array.isArray(formats) ? formats.length : 0,
          theatres: Array.isArray(theatres) ? theatres.length : (theatres?.pagination?.total_count ?? theatres?.theatres?.length ?? 0),
          vendors: vendors.length,
        })
        setVendorSummaries(incomeResponses.sort((a, b) => b.total_income - a.total_income))
      } catch (err) { console.error(err) }
      finally { setLoading(false) }
    }

    fetchDashboard()
  }, [])

  const formatCurrency = (value) => new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2,
  }).format(Number(value || 0))

  const totalVendorRevenue = vendorSummaries.reduce((sum, vendor) => sum + vendor.total_income, 0)
  const totalVendorBookings = vendorSummaries.reduce((sum, vendor) => sum + vendor.completed_bookings_count, 0)
  const totalVendorTickets = vendorSummaries.reduce((sum, vendor) => sum + vendor.tickets_sold_count, 0)

  const stats = [
    { label: 'Movies',    value: counts.movies,    icon: Clapperboard, color: 'from-rose-500 to-pink-500 shadow-rose-500/20' },
    { label: 'Cities',    value: counts.cities,    icon: MapPin,       color: 'from-blue-500 to-cyan-500 shadow-blue-500/20' },
    { label: 'Languages', value: counts.languages, icon: Globe,        color: 'from-emerald-500 to-green-500 shadow-emerald-500/20' },
    { label: 'Formats',   value: counts.formats,   icon: MonitorPlay,  color: 'from-amber-500 to-orange-500 shadow-amber-500/20' },
    { label: 'Theatres',  value: counts.theatres,  icon: Building2,    color: 'from-primary-500 to-purple-500 shadow-primary-500/20' },
    { label: 'Vendors',   value: counts.vendors,   icon: Users,        color: 'from-fuchsia-500 to-pink-500 shadow-fuchsia-500/20' },
  ]

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Admin Console</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-1">Platform overview and management</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-6 gap-6 mb-10">
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

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
        <div className="glass-card p-6 hover:translate-y-0">
          <div className="flex items-center gap-3 mb-3">
            <div className="p-3 rounded-xl bg-gradient-to-br from-emerald-500 to-green-500 shadow-lg shadow-emerald-500/20 text-white">
              <TrendingUp className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Vendor Revenue</p>
              <p className="text-2xl font-bold text-neutral-900 dark:text-white">
                {loading ? <span className="inline-block w-20 h-6 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : formatCurrency(totalVendorRevenue)}
              </p>
            </div>
          </div>
          <p className="text-xs text-neutral-400 dark:text-neutral-500">Combined net income across all vendors on the platform.</p>
        </div>

        <div className="glass-card p-6 hover:translate-y-0">
          <div className="flex items-center gap-3 mb-3">
            <div className="p-3 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-500 shadow-lg shadow-blue-500/20 text-white">
              <Ticket className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Vendor Bookings</p>
              <p className="text-2xl font-bold text-neutral-900 dark:text-white">
                {loading ? <span className="inline-block w-20 h-6 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : totalVendorBookings}
              </p>
            </div>
          </div>
          <p className="text-xs text-neutral-400 dark:text-neutral-500">Confirmed bookings attributed to vendor theatres.</p>
        </div>

        <div className="glass-card p-6 hover:translate-y-0">
          <div className="flex items-center gap-3 mb-3">
            <div className="p-3 rounded-xl bg-gradient-to-br from-amber-500 to-orange-500 shadow-lg shadow-amber-500/20 text-white">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <p className="text-sm text-neutral-500 dark:text-neutral-400 font-medium">Tickets Sold</p>
              <p className="text-2xl font-bold text-neutral-900 dark:text-white">
                {loading ? <span className="inline-block w-20 h-6 rounded bg-neutral-200 dark:bg-neutral-800 animate-pulse" /> : totalVendorTickets}
              </p>
            </div>
          </div>
          <p className="text-xs text-neutral-400 dark:text-neutral-500">Valid tickets sold across every vendor network.</p>
        </div>
      </div>

      <div className="glass-card p-6 hover:translate-y-0">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-xl font-bold text-neutral-900 dark:text-white">Vendor Performance</h2>
            <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-1">Income, bookings, and theatre footprint by vendor.</p>
          </div>
          <span className="text-xs font-bold uppercase tracking-widest px-3 py-1 rounded-full bg-primary-500/10 text-primary-600 dark:text-primary-400 border border-primary-500/20">
            {vendorSummaries.length} vendors
          </span>
        </div>

        {loading ? (
          <div className="space-y-4">
            {[1, 2, 3].map((item) => (
              <div key={item} className="h-20 rounded-xl bg-neutral-100 dark:bg-neutral-800/50 animate-pulse" />
            ))}
          </div>
        ) : vendorSummaries.length === 0 ? (
          <div className="py-12 text-center">
            <Users className="w-12 h-12 mx-auto text-neutral-300 dark:text-neutral-600 mb-3" />
            <p className="text-neutral-500 dark:text-neutral-400 font-medium">No vendors found</p>
            <p className="text-sm text-neutral-400 dark:text-neutral-500 mt-1">Vendor accounts will appear here once they are registered.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {vendorSummaries.map((vendor, index) => (
              <motion.div
                key={vendor.id}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.04 }}
                className="p-4 rounded-xl bg-neutral-50 dark:bg-neutral-900/40 border border-neutral-200 dark:border-neutral-800"
              >
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                  <div>
                    <p className="font-semibold text-neutral-900 dark:text-white">{vendor.name}</p>
                    <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-1">{vendor.email}</p>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 lg:min-w-[520px]">
                    <div>
                      <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Net Income</p>
                      <p className="text-sm font-semibold text-neutral-900 dark:text-white mt-1">{formatCurrency(vendor.total_income)}</p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Theatres</p>
                      <p className="text-sm font-semibold text-neutral-900 dark:text-white mt-1">{vendor.theatres_count}</p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Bookings</p>
                      <p className="text-sm font-semibold text-neutral-900 dark:text-white mt-1">{vendor.completed_bookings_count}</p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-wide text-neutral-400 dark:text-neutral-500">Tickets</p>
                      <p className="text-sm font-semibold text-neutral-900 dark:text-white mt-1">{vendor.tickets_sold_count}</p>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
