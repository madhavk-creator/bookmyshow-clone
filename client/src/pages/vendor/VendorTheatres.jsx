import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useSelector } from 'react-redux'
import { Building2, Plus, Pencil, Trash2, X, Loader, MapPin } from 'lucide-react'
import { selectCurrentUser } from '../../store/authSlice'
import { api, extractApiError } from '../../utils/api'

export default function VendorTheatres() {
  const user = useSelector(selectCurrentUser)
  const [theatres, setTheatres] = useState([])
  const [cities, setCities] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingTheatre, setEditingTheatre] = useState(null)
  const [formData, setFormData] = useState({ name: '', building_name: '', street_address: '', pincode: '', city_id: '' })
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const fetchTheatres = async () => {
    try {
      const { data } = await api.get(`/api/v1/theatres?vendor_id=${user?.id}`)
      setTheatres(Array.isArray(data) ? data : (data.theatres || []))
    } catch (err) { console.error(err) }
    finally { setLoading(false) }
  }

  const fetchCities = async () => {
    try {
      const { data } = await api.get('/api/v1/cities')
      setCities(Array.isArray(data) ? data : [])
    } catch (err) { console.error(err) }
  }

  useEffect(() => {
    if (user?.id) {
      fetchTheatres()
      fetchCities()
    }
  }, [user?.id])

  const openCreate = () => {
    setEditingTheatre(null)
    setFormData({ name: '', building_name: '', street_address: '', pincode: '', city_id: '' })
    setError(null)
    setShowModal(true)
  }

  const openEdit = (theatre) => {
    setEditingTheatre(theatre)
    setFormData({
      name: theatre.name || '',
      building_name: theatre.building_name || '',
      street_address: theatre.street_address || '',
      pincode: theatre.pincode || '',
      city_id: theatre.city?.id || '',
    })
    setError(null)
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)

    try {
      if (editingTheatre) {
        await api.patch(`/api/v1/theatres/${editingTheatre.id}`, { theatre: formData })
      } else {
        await api.post('/api/v1/theatres', { theatre: formData })
      }

      setShowModal(false)
      fetchTheatres()
    } catch (err) {
      setError(extractApiError(err, 'Operation failed'))
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this theatre?')) return
    try {
      await api.delete(`/api/v1/theatres/${id}`)
      fetchTheatres()
    } catch (err) { console.error(err) }
  }

  const handleChange = (e) => setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }))

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Theatres</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">Manage your cinema locations</p>
        </div>
        <button onClick={openCreate} className="bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-2.5 px-5 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:shadow-amber-500/50 hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer">
          <Plus className="w-5 h-5" />
          Add Theatre
        </button>
      </div>

      {/* Theatre Cards */}
      {loading ? (
        <div className="flex justify-center py-20">
          <Loader className="w-10 h-10 text-amber-500 animate-spin" />
        </div>
      ) : theatres.length === 0 ? (
        <div className="glass-card p-16 text-center hover:translate-y-0">
          <Building2 className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
          <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No theatres yet</h3>
          <p className="text-neutral-500 dark:text-neutral-400 mb-6">Get started by adding your first cinema location.</p>
          <button onClick={openCreate} className="bg-gradient-to-r from-amber-600 to-orange-600 text-white font-medium py-2.5 px-6 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:scale-105 cursor-pointer inline-flex items-center gap-2">
            <Plus className="w-5 h-5" /> Create Theatre
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AnimatePresence>
            {theatres.map((theatre, i) => (
              <motion.div
                key={theatre.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ delay: i * 0.05, duration: 0.3 }}
                className="glass-card p-6 hover:translate-y-0 group relative"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="w-12 h-12 rounded-xl bg-amber-500/10 flex items-center justify-center">
                    <Building2 className="w-6 h-6 text-amber-500" />
                  </div>
                  <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button onClick={() => openEdit(theatre)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 hover:text-amber-500 transition-colors cursor-pointer" title="Edit">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button onClick={() => handleDelete(theatre.id)} className="p-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 transition-colors cursor-pointer" title="Delete">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
                <h3 className="font-bold text-lg text-neutral-900 dark:text-white mb-2">{theatre.name}</h3>
                <div className="flex items-center gap-1.5 text-sm text-neutral-500 dark:text-neutral-400 mb-1">
                  <MapPin className="w-3.5 h-3.5" />
                  <span>{theatre.city?.name}, {theatre.city?.state}</span>
                </div>
                {theatre.building_name && (
                  <p className="text-xs text-neutral-400 dark:text-neutral-500">{theatre.building_name}</p>
                )}
                {theatre.street_address && (
                  <p className="text-xs text-neutral-400 dark:text-neutral-500">{theatre.street_address}{theatre.pincode ? ` - ${theatre.pincode}` : ''}</p>
                )}
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Modal */}
      <AnimatePresence>
        {showModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowModal(false)}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-lg glass-card p-8 hover:translate-y-0"
              onClick={e => e.stopPropagation()}
            >
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white">
                  {editingTheatre ? 'Edit Theatre' : 'New Theatre'}
                </h2>
                <button onClick={() => setShowModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer">
                  <X className="w-5 h-5" />
                </button>
              </div>

              {error && (
                <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">
                  {error}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Theatre Name *</label>
                  <input type="text" name="name" required value={formData.name} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                    placeholder="PVR Phoenix" />
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">City *</label>
                  <select name="city_id" required value={formData.city_id} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all appearance-none cursor-pointer">
                    <option value="">Select a city</option>
                    {cities.map(c => <option key={c.id} value={c.id}>{c.name}, {c.state}</option>)}
                  </select>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Building Name</label>
                    <input type="text" name="building_name" value={formData.building_name} onChange={handleChange}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="Phoenix Marketcity" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Pincode</label>
                    <input type="text" name="pincode" value={formData.pincode} onChange={handleChange}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="400001" />
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Street Address</label>
                  <input type="text" name="street_address" value={formData.street_address} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                    placeholder="LBS Marg, Kurla West" />
                </div>

                <button type="submit" disabled={submitting}
                  className="w-full mt-2 bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:shadow-amber-500/50 hover:scale-105 active:scale-95 flex justify-center items-center cursor-pointer disabled:opacity-70 disabled:pointer-events-none">
                  {submitting ? <Loader className="w-5 h-5 animate-spin" /> : (editingTheatre ? 'Update Theatre' : 'Create Theatre')}
                </button>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
