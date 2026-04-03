import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Layers, Plus, Pencil, Loader, X, CheckCircle, Archive, ArrowLeft, Eye } from 'lucide-react'
import { api, extractApiError } from '../../utils/api'
import { showApiErrorToast, showSuccessToast } from '../../utils/toast'
import { useConfirm } from '../../components/ConfirmProvider'

export default function SeatLayoutManager() {
  const { theatreId, screenId } = useParams()
  const navigate = useNavigate()
  const [layouts, setLayouts] = useState([])
  const [screen, setScreen] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [formData, setFormData] = useState({ name: '', total_rows: '', total_columns: '', screen_label: '' })
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const confirm = useConfirm()

  const base = `/api/v1/theatres/${theatreId}/screens/${screenId}`

  const fetchLayouts = async () => {
    try {
      const [{ data: layoutRes }, { data: screenRes }] = await Promise.all([
        api.get(`${base}/seat_layouts`),
        api.get(base),
      ])
      setLayouts(Array.isArray(layoutRes) ? layoutRes : [])
      setScreen(screenRes)
    } catch (err) { console.error(err) }
    finally { setLoading(false) }
  }

  useEffect(() => { fetchLayouts() }, [theatreId, screenId])

  const handleCreate = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      const { data } = await api.post(`${base}/seat_layouts`, {
        seat_layout: { ...formData, total_rows: parseInt(formData.total_rows), total_columns: parseInt(formData.total_columns) },
      })
      setShowModal(false)
      setFormData({ name: '', total_rows: '', total_columns: '', screen_label: '' })
      showSuccessToast('Seat layout created. Start mapping seats now.')
      // Navigate directly to the editor grid for seat mapping
      navigate(`/vendor/layouts/${theatreId}/${screenId}/${data.id}`)
    } catch (err) {
      setError(extractApiError(err, 'Create failed'))
      showApiErrorToast(err, 'Create failed')
    }
    finally { setSubmitting(false) }
  }

  const handlePublish = async (layoutId) => {
    const confirmed = await confirm({
      title: 'Publish Layout?',
      message: 'Any currently published layout for this screen will be archived.',
      confirmText: 'Publish Layout',
      tone: 'warning',
    })
    if (!confirmed) return
    try {
      await api.post(`${base}/seat_layouts/${layoutId}/publish`)
      showSuccessToast('Seat layout published successfully.')
      fetchLayouts()
    } catch (err) { showApiErrorToast(err, 'Publish failed') }
  }

  const handleArchive = async (layoutId) => {
    const confirmed = await confirm({
      title: 'Archive Layout?',
      message: 'This layout will remain available as a read-only archived version.',
      confirmText: 'Archive Layout',
      tone: 'warning',
    })
    if (!confirmed) return
    try {
      await api.post(`${base}/seat_layouts/${layoutId}/archive`)
      showSuccessToast('Seat layout archived successfully.')
      fetchLayouts()
    } catch (err) { showApiErrorToast(err, 'Archive failed') }
  }

  const statusConfig = {
    draft:     { bg: 'bg-amber-500/10', text: 'text-amber-600 dark:text-amber-400', border: 'border-amber-500/20' },
    published: { bg: 'bg-emerald-500/10', text: 'text-emerald-600 dark:text-emerald-400', border: 'border-emerald-500/20' },
    archived:  { bg: 'bg-neutral-500/10', text: 'text-neutral-500', border: 'border-neutral-500/20' },
  }

  if (loading) return <div className="flex justify-center items-center h-[60vh]"><Loader className="w-10 h-10 text-amber-500 animate-spin" /></div>

  return (
    <div className="p-6 lg:p-8 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3 mb-2">
        <button onClick={() => navigate('/vendor/screens')} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 transition-colors cursor-pointer">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Seat Layouts</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">
            {screen?.name || 'Screen'} — manage seating configurations
          </p>
        </div>
        <button onClick={() => { setError(null); setShowModal(true) }} className="bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-2.5 px-5 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer">
          <Plus className="w-5 h-5" /> New Layout
        </button>
      </div>

      {/* Layout List */}
      <div className="mt-8 space-y-4">
        {layouts.length === 0 ? (
          <div className="glass-card p-16 text-center hover:translate-y-0">
            <Layers className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
            <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No layouts yet</h3>
            <p className="text-neutral-500 dark:text-neutral-400">Create your first seat layout to get started.</p>
          </div>
        ) : (
          <AnimatePresence>
            {layouts.map((layout, i) => {
              const sc = statusConfig[layout.status] || statusConfig.draft
              return (
                <motion.div
                  key={layout.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.05 }}
                  className="glass-card p-6 hover:translate-y-0"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-xl bg-amber-500/10 flex items-center justify-center">
                        <Layers className="w-6 h-6 text-amber-500" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-bold text-lg text-neutral-900 dark:text-white">{layout.name}</h3>
                          <span className={`text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-full border ${sc.bg} ${sc.text} ${sc.border}`}>{layout.status}</span>
                          <span className="text-xs text-neutral-400">v{layout.version_number}</span>
                        </div>
                        <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-0.5">
                          {layout.total_rows}×{layout.total_columns} grid · {layout.total_seats} seats
                          {layout.published_at && ` · Published ${new Date(layout.published_at).toLocaleDateString()}`}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      {layout.status === 'draft' && (
                        <>
                          <button onClick={() => navigate(`/vendor/layouts/${theatreId}/${screenId}/${layout.id}`)} className="px-3 py-2 rounded-lg text-sm font-medium bg-amber-500/10 text-amber-600 dark:text-amber-400 hover:bg-amber-500/20 border border-amber-500/20 transition-colors cursor-pointer flex items-center gap-1.5">
                            <Pencil className="w-3.5 h-3.5" /> Edit
                          </button>
                          <button onClick={() => handlePublish(layout.id)} className="px-3 py-2 rounded-lg text-sm font-medium bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/20 border border-emerald-500/20 transition-colors cursor-pointer flex items-center gap-1.5">
                            <CheckCircle className="w-3.5 h-3.5" /> Publish
                          </button>
                        </>
                      )}
                      {layout.status === 'published' && (
                        <>
                          <button onClick={() => navigate(`/vendor/layouts/${theatreId}/${screenId}/${layout.id}`)} className="px-3 py-2 rounded-lg text-sm font-medium bg-blue-500/10 text-blue-600 dark:text-blue-400 hover:bg-blue-500/20 border border-blue-500/20 transition-colors cursor-pointer flex items-center gap-1.5">
                            <Eye className="w-3.5 h-3.5" /> View
                          </button>
                          <button onClick={() => handleArchive(layout.id)} className="px-3 py-2 rounded-lg text-sm font-medium bg-neutral-500/10 text-neutral-500 hover:bg-neutral-500/20 border border-neutral-500/20 transition-colors cursor-pointer flex items-center gap-1.5">
                            <Archive className="w-3.5 h-3.5" /> Archive
                          </button>
                        </>
                      )}
                      {layout.status === 'archived' && (
                        <button onClick={() => navigate(`/vendor/layouts/${theatreId}/${screenId}/${layout.id}`)} className="px-3 py-2 rounded-lg text-sm font-medium bg-neutral-500/10 text-neutral-500 hover:bg-neutral-500/20 border border-neutral-500/20 transition-colors cursor-pointer flex items-center gap-1.5">
                          <Eye className="w-3.5 h-3.5" /> View
                        </button>
                      )}
                    </div>
                  </div>
                </motion.div>
              )
            })}
          </AnimatePresence>
        )}
      </div>

      {/* Create Modal */}
      <AnimatePresence>
        {showModal && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setShowModal(false)}>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="w-full max-w-lg glass-card p-8 hover:translate-y-0" onClick={e => e.stopPropagation()}>
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white">New Seat Layout</h2>
                <button onClick={() => setShowModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer"><X className="w-5 h-5" /></button>
              </div>
              {error && <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">{error}</div>}
              <form onSubmit={handleCreate} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Layout Name *</label>
                  <input type="text" required value={formData.name} onChange={e => setFormData(p => ({ ...p, name: e.target.value }))}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                    placeholder="Standard Layout" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Rows *</label>
                    <input type="number" required min="1" value={formData.total_rows} onChange={e => setFormData(p => ({ ...p, total_rows: e.target.value }))}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="10" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Columns *</label>
                    <input type="number" required min="1" value={formData.total_columns} onChange={e => setFormData(p => ({ ...p, total_columns: e.target.value }))}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="20" />
                  </div>
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Screen Label</label>
                  <input type="text" value={formData.screen_label} onChange={e => setFormData(p => ({ ...p, screen_label: e.target.value }))}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                    placeholder="SCREEN" />
                </div>
                <button type="submit" disabled={submitting} className="w-full mt-2 bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:scale-105 active:scale-95 flex justify-center items-center cursor-pointer disabled:opacity-70 disabled:pointer-events-none">
                  {submitting ? <Loader className="w-5 h-5 animate-spin" /> : 'Create Layout'}
                </button>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
