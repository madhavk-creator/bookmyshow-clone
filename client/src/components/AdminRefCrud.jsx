import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useSelector } from 'react-redux'
import { Plus, Pencil, Trash2, X, Loader } from 'lucide-react'
import { selectCurrentToken } from '../store/authSlice'

export default function AdminRefCrud({ entityName, apiPath, paramKey, icon: Icon, fields, color = 'rose' }) {
  const token = useSelector(selectCurrentToken)
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editing, setEditing] = useState(null)
  const [formData, setFormData] = useState({})
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }

  const fetchItems = async () => {
    try {
      const res = await fetch(`/api/v1/${apiPath}`)
      const data = await res.json()
      setItems(Array.isArray(data) ? data : [])
    } catch (err) { console.error(err) }
    finally { setLoading(false) }
  }

  useEffect(() => { fetchItems() }, [])

  const openCreate = () => {
    setEditing(null)
    const empty = {}
    fields.forEach(f => empty[f.key] = '')
    setFormData(empty)
    setError(null)
    setShowModal(true)
  }

  const openEdit = (item) => {
    setEditing(item)
    const data = {}
    fields.forEach(f => data[f.key] = item[f.key] || '')
    setFormData(data)
    setError(null)
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      const key = paramKey || apiPath.replace(/s$/, '')
      const url = editing ? `/api/v1/${apiPath}/${editing.id}` : `/api/v1/${apiPath}`
      const method = editing ? 'PATCH' : 'POST'
      const res = await fetch(url, { method, headers, body: JSON.stringify({ [key]: formData }) })
      const data = await res.json()
      if (!res.ok) throw new Error(data.errors?.join(', ') || data.error || 'Operation failed')
      setShowModal(false)
      fetchItems()
    } catch (err) { setError(err.message) }
    finally { setSubmitting(false) }
  }

  const handleDelete = async (id) => {
    if (!confirm(`Delete this ${entityName.toLowerCase().replace(/s$/, '')}?`)) return
    try {
      await fetch(`/api/v1/${apiPath}/${id}`, { method: 'DELETE', headers })
      fetchItems()
    } catch (err) { console.error(err) }
  }

  const handleChange = (e) => setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }))

  const colorMap = {
    rose: { btn: 'from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 shadow-rose-500/30 hover:shadow-rose-500/50', badge: 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20', icon: 'bg-rose-500/10 text-rose-500', ring: 'focus:ring-rose-500/50 focus:border-rose-500' },
    blue: { btn: 'from-blue-600 to-cyan-600 hover:from-blue-500 hover:to-cyan-500 shadow-blue-500/30 hover:shadow-blue-500/50', badge: 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20', icon: 'bg-blue-500/10 text-blue-500', ring: 'focus:ring-blue-500/50 focus:border-blue-500' },
    emerald: { btn: 'from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 shadow-emerald-500/30 hover:shadow-emerald-500/50', badge: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20', icon: 'bg-emerald-500/10 text-emerald-500', ring: 'focus:ring-emerald-500/50 focus:border-emerald-500' },
    amber: { btn: 'from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 shadow-amber-500/30 hover:shadow-amber-500/50', badge: 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20', icon: 'bg-amber-500/10 text-amber-500', ring: 'focus:ring-amber-500/50 focus:border-amber-500' },
  }
  const c = colorMap[color] || colorMap.rose

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">{entityName}</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">Manage {entityName.toLowerCase()} across the platform</p>
        </div>
        <button onClick={openCreate} className={`bg-gradient-to-r ${c.btn} text-white font-medium py-2.5 px-5 rounded-xl shadow-lg transition-all hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer`}>
          <Plus className="w-5 h-5" /> Add {entityName.replace(/ies$/, 'y').replace(/s$/, '')}
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader className="w-10 h-10 text-rose-500 animate-spin" /></div>
      ) : items.length === 0 ? (
        <div className="glass-card p-16 text-center hover:translate-y-0">
          <Icon className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
          <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No {entityName.toLowerCase()} yet</h3>
        </div>
      ) : (
        <div className="glass-card overflow-hidden hover:translate-y-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-neutral-200 dark:border-neutral-800">
                {fields.map(f => (
                  <th key={f.key} className="text-left text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">{f.label}</th>
                ))}
                <th className="text-right text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 px-6 py-4">Actions</th>
              </tr>
            </thead>
            <tbody>
              <AnimatePresence>
                {items.map((item, i) => (
                  <motion.tr key={item.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ delay: i * 0.03 }}
                    className="border-b border-neutral-100 dark:border-neutral-800/50 hover:bg-neutral-50 dark:hover:bg-neutral-900/30 transition-colors group">
                    {fields.map(f => (
                      <td key={f.key} className="px-6 py-4 text-sm text-neutral-700 dark:text-neutral-300 font-medium">{item[f.key]}</td>
                    ))}
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => openEdit(item)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 hover:text-rose-500 transition-colors cursor-pointer"><Pencil className="w-4 h-4" /></button>
                        <button onClick={() => handleDelete(item.id)} className="p-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 transition-colors cursor-pointer"><Trash2 className="w-4 h-4" /></button>
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </AnimatePresence>
            </tbody>
          </table>
        </div>
      )}

      <AnimatePresence>
        {showModal && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setShowModal(false)}>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="w-full max-w-md glass-card p-8 hover:translate-y-0" onClick={e => e.stopPropagation()}>
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white">{editing ? 'Edit' : 'New'} {entityName.replace(/ies$/, 'y').replace(/s$/, '')}</h2>
                <button onClick={() => setShowModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer"><X className="w-5 h-5" /></button>
              </div>
              {error && <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">{error}</div>}
              <form onSubmit={handleSubmit} className="space-y-4">
                {fields.map(f => (
                  <div key={f.key} className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">{f.label} *</label>
                    <input type="text" name={f.key} required value={formData[f.key] || ''} onChange={handleChange}
                      className={`w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 ${c.ring} transition-all`}
                      placeholder={f.placeholder || ''} />
                  </div>
                ))}
                <button type="submit" disabled={submitting} className={`w-full mt-2 bg-gradient-to-r ${c.btn} text-white font-medium py-3 px-6 rounded-xl shadow-lg transition-all hover:scale-105 active:scale-95 flex justify-center items-center cursor-pointer disabled:opacity-70 disabled:pointer-events-none`}>
                  {submitting ? <Loader className="w-5 h-5 animate-spin" /> : (editing ? 'Update' : 'Create')}
                </button>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
