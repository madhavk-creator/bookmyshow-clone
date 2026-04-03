import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Building2, MapPin, Plus, Pencil, Trash2, X, Loader, Layers } from 'lucide-react'
import { api, extractApiError, getVendors } from '../../utils/api'

export default function AdminTheatres() {
  const navigate = useNavigate()
  const [theatres, setTheatres] = useState([])
  const [cities, setCities] = useState([])
  const [vendors, setVendors] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingTheatre, setEditingTheatre] = useState(null)
  const [formData, setFormData] = useState({ name: '', building_name: '', street_address: '', pincode: '', city_id: '', vendor_id: '' })
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const fetchTheatres = async () => {
    try {
      const { data } = await api.get('/api/v1/theatres')
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

  const fetchVendors = async () => {
    try {
      const { data } = await getVendors()
      setVendors(Array.isArray(data) ? data : (data.vendors || []))
    } catch (err) { console.error(err) }
  }

  useEffect(() => {
    fetchTheatres()
    fetchCities()
    fetchVendors()
  }, [])

  const getVendorLabel = (vendorId) => {
    const vendor = vendors.find((item) => item.id === vendorId)
    if (!vendor) return vendorId ? `${vendorId.slice(0, 8)}...` : 'Unassigned'
    return vendor.name || vendor.email || `${vendor.id.slice(0, 8)}...`
  }

  const openCreate = () => {
    setEditingTheatre(null)
    setFormData({ name: '', building_name: '', street_address: '', pincode: '', city_id: '', vendor_id: '' })
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
      vendor_id: theatre.vendor_id || '',
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
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Theatres</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">Manage global theatre catalogue</p>
        </div>
        <button onClick={openCreate} className="bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white font-medium py-2.5 px-5 rounded-xl shadow-lg shadow-primary-500/30 transition-all hover:shadow-primary-500/50 hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer">
          <Plus className="w-5 h-5" />
          Add Theatre
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader className="w-10 h-10 text-primary-500 animate-spin" /></div>
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
                <th className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Vendor</th>
                <th className="text-right text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Actions</th>
              </tr>
            </thead>
            <tbody>
              <AnimatePresence>
                {theatres.map((t, i) => (
                  <motion.tr key={t.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.03 }}
                    className="border-b border-neutral-100 dark:border-neutral-800/50 hover:bg-neutral-50 dark:hover:bg-neutral-900/30 transition-colors group">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-lg bg-primary-500/10 flex items-center justify-center shrink-0">
                          <Building2 className="w-4 h-4 text-primary-500" />
                        </div>
                        <div>
                          <span className="text-sm font-semibold text-neutral-900 dark:text-white block">{t.name}</span>
                          <span className="text-xs text-neutral-500 mt-0.5 block truncate max-w-xs">
                            {[t.building_name, t.street_address, t.pincode].filter(Boolean).join(', ')}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5 text-sm text-neutral-600 dark:text-neutral-300">
                        <MapPin className="w-3.5 h-3.5 text-neutral-400" />
                        {t.city?.name}, {t.city?.state}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div>
                        <span className="text-sm font-medium text-neutral-800 dark:text-neutral-200">
                          {getVendorLabel(t.vendor_id)}
                        </span>
                        <p className="text-xs text-neutral-500 dark:text-neutral-400 font-mono mt-1" title={t.vendor_id}>
                          {t.vendor_id}
                        </p>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => navigate(`/admin/theatres/${t.id}/screens`)} className="px-3 py-1.5 rounded-lg text-sm font-medium bg-primary-500/10 text-primary-600 hover:bg-primary-500/20 text-neutral-400 hover:text-primary-500 transition-colors cursor-pointer flex items-center gap-1.5 mr-2">
                          <Layers className="w-3.5 h-3.5" /> Screens
                        </button>
                        <button onClick={() => openEdit(t)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 hover:text-primary-500 transition-colors cursor-pointer"><Pencil className="w-4 h-4" /></button>
                        <button onClick={() => handleDelete(t.id)} className="p-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 transition-colors cursor-pointer"><Trash2 className="w-4 h-4" /></button>
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </AnimatePresence>
            </tbody>
          </table>
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
              initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }}
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
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Vendor *</label>
                  <select
                    name="vendor_id"
                    required
                    value={formData.vendor_id}
                    onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all appearance-none cursor-pointer"
                  >
                    <option value="">Select a vendor</option>
                    {vendors.map((vendor) => (
                      <option key={vendor.id} value={vendor.id}>
                        {vendor.name} {vendor.email ? `(${vendor.email})` : ''}
                      </option>
                    ))}
                  </select>
                  {vendors.length === 0 && (
                    <p className="text-xs text-neutral-500 dark:text-neutral-400 ml-1">
                      No active vendors found. Create a vendor account first.
                    </p>
                  )}
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Theatre Name *</label>
                  <input type="text" name="name" required value={formData.name} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                    placeholder="PVR Phoenix" />
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">City *</label>
                  <select name="city_id" required value={formData.city_id} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all appearance-none cursor-pointer">
                    <option value="">Select a city</option>
                    {cities.map(c => <option key={c.id} value={c.id}>{c.name}, {c.state}</option>)}
                  </select>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Building Name</label>
                    <input type="text" name="building_name" value={formData.building_name} onChange={handleChange}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                      placeholder="Phoenix Marketcity" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Pincode</label>
                    <input type="text" name="pincode" value={formData.pincode} onChange={handleChange}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                      placeholder="400001" />
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Street Address</label>
                  <input type="text" name="street_address" value={formData.street_address} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                    placeholder="LBS Marg, Kurla West" />
                </div>

                <button type="submit" disabled={submitting}
                  className="w-full mt-4 bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-primary-500/30 transition-all hover:scale-105 active:scale-95 flex justify-center items-center cursor-pointer disabled:opacity-70 disabled:pointer-events-none">
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
