import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Monitor, Plus, Pencil, Trash2, X, Loader, ArrowLeft, Layers } from 'lucide-react'
import { useCreateScreenMutation, useDeleteScreenMutation, useGetFormatsQuery, useGetScreensQuery, useGetTheatreQuery, useUpdateScreenMutation } from '../../store/apiSlice'
import { extractApiError } from '../../utils/api'
import { showApiErrorToast, showSuccessToast } from '../../utils/toast'
import { useConfirm } from '../../components/ConfirmProvider'

export default function AdminScreens() {
  const { theatreId } = useParams()
  const navigate = useNavigate()
  const [showModal, setShowModal] = useState(false)
  const [editingScreen, setEditingScreen] = useState(null)
  const [formData, setFormData] = useState({ name: '', total_rows: '', total_columns: '', status: 'active', format_ids: [] })
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const confirm = useConfirm()
  const [createScreen] = useCreateScreenMutation()
  const [updateScreen] = useUpdateScreenMutation()
  const [deleteScreen] = useDeleteScreenMutation()
  const { data: theatre, isLoading: theatreLoading } = useGetTheatreQuery(theatreId, { skip: !theatreId })
  const { data: formats = [] } = useGetFormatsQuery()
  const {
    data: screens = [],
    isLoading: screensLoading,
    isFetching: screensFetching,
  } = useGetScreensQuery({ theatreId }, { skip: !theatreId })

  const openCreate = () => {
    setEditingScreen(null)
    setFormData({ name: '', total_rows: '', total_columns: '', status: 'active', format_ids: [] })
    setError(null)
    setShowModal(true)
  }

  const openEdit = (screen) => {
    setEditingScreen(screen)
    setFormData({
      name: screen.name || '',
      total_rows: screen.total_rows || '',
      total_columns: screen.total_columns || '',
      status: screen.status || 'active',
      format_ids: screen.formats?.map(f => f.id) || [],
    })
    setError(null)
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)

    const totalRows = parseInt(formData.total_rows, 10)
    const totalColumns = parseInt(formData.total_columns, 10)

    if (totalRows >= 50 || totalColumns >= 50) {
      setError('Rows and columns must both be less than 50.')
      setSubmitting(false)
      return
    }

    try {
      const payload = {
        ...formData,
        total_rows: totalRows,
        total_columns: totalColumns,
      }

      if (editingScreen) {
        await updateScreen({ theatreId, screenId: editingScreen.id, screen: payload }).unwrap()
      } else {
        await createScreen({ theatreId, screen: payload }).unwrap()
      }

      setShowModal(false)
    } catch (err) {
      setError(extractApiError(err, 'Operation failed'))
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (id) => {
    const confirmed = await confirm({
      title: 'Delete Screen?',
      message: 'This screen and its related setup will be removed.',
      confirmText: 'Delete Screen',
      tone: 'danger',
    })
    if (!confirmed) return
    try {
      await deleteScreen({ theatreId, screenId: id }).unwrap()
      showSuccessToast('Screen deleted successfully.')
    } catch (err) {
      console.error(err)
      showApiErrorToast(err, 'Failed to delete screen')
    }
  }

  const handleChange = (e) => setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }))

  const toggleFormat = (fmtId) => {
    setFormData(prev => ({
      ...prev,
      format_ids: prev.format_ids.includes(fmtId)
        ? prev.format_ids.filter(id => id !== fmtId)
        : [...prev.format_ids, fmtId]
    }))
  }

  if (theatreLoading) {
    return (
      <div className="flex justify-center items-center h-[60vh]">
        <Loader className="w-10 h-10 text-primary-500 animate-spin" />
      </div>
    )
  }

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="flex items-center gap-3 mb-8">
        <button onClick={() => navigate('/admin/theatres')} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 transition-colors cursor-pointer">
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Screens</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">{theatre?.name || 'Theatre'} — manage screens</p>
        </div>
        <button onClick={openCreate}
          className="bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white font-medium py-2.5 px-5 rounded-xl shadow-lg shadow-primary-500/30 transition-all hover:shadow-primary-500/50 hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer disabled:opacity-50 disabled:pointer-events-none">
          <Plus className="w-5 h-5" />
          Add Screen
        </button>
      </div>

      {screensLoading || screensFetching ? (
        <div className="flex justify-center py-20">
          <Loader className="w-10 h-10 text-primary-500 animate-spin" />
        </div>
      ) : screens.length === 0 ? (
        <div className="glass-card p-16 text-center hover:translate-y-0">
          <Monitor className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
          <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No screens yet</h3>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AnimatePresence>
            {screens.map((screen, i) => (
              <motion.div
                key={screen.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ delay: i * 0.05, duration: 0.3 }}
                className="glass-card p-6 hover:translate-y-0 group relative"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="w-12 h-12 rounded-xl bg-blue-500/10 flex items-center justify-center">
                    <Monitor className="w-6 h-6 text-blue-500" />
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-full border ${
                      screen.status === 'active'
                        ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                        : 'bg-neutral-500/10 text-neutral-500 border-neutral-500/20'
                    }`}>
                      {screen.status}
                    </span>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button onClick={() => openEdit(screen)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 hover:text-primary-500 transition-colors cursor-pointer" title="Edit">
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button onClick={() => handleDelete(screen.id)} className="p-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 transition-colors cursor-pointer" title="Delete">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
                <h3 className="font-bold text-lg text-neutral-900 dark:text-white mb-3">{screen.name}</h3>
                <div className="flex gap-4 text-sm text-neutral-500 dark:text-neutral-400 mb-3">
                  <span>{screen.total_rows} rows</span>
                  <span>·</span>
                  <span>{screen.total_columns} cols</span>
                  {screen.total_seats != null && <><span>·</span><span>{screen.total_seats} seats</span></>}
                </div>
                {screen.formats?.length > 0 && (
                  <div className="flex flex-wrap gap-1.5">
                    {screen.formats.map(f => (
                      <span key={f.id} className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-primary-500/10 text-primary-600 dark:text-primary-400 border border-primary-500/20">
                        {f.code}
                      </span>
                    ))}
                  </div>
                )}
                <button
                  onClick={() => navigate(`/admin/layouts/${theatreId}/${screen.id}`)}
                  className="mt-4 w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm font-medium bg-primary-500/10 text-primary-600 dark:text-primary-400 hover:bg-primary-500/20 border border-primary-500/20 transition-colors cursor-pointer"
                >
                  <Layers className="w-4 h-4" /> Manage Layouts
                </button>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Modal */}
      <AnimatePresence>
        {showModal && (
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
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
                  {editingScreen ? 'Edit Screen' : 'New Screen'}
                </h2>
                <button onClick={() => setShowModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer">
                  <X className="w-5 h-5" />
                </button>
              </div>

              {error && (
                <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">{error}</div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Screen Name *</label>
                  <input type="text" name="name" required value={formData.name} onChange={handleChange}
                    className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                    placeholder="Screen 1" />
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Rows *</label>
                    <input type="number" name="total_rows" required value={formData.total_rows} onChange={handleChange} min="1" max="49"
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                      placeholder="10" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Columns *</label>
                    <input type="number" name="total_columns" required value={formData.total_columns} onChange={handleChange} min="1" max="49"
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all"
                      placeholder="20" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Status</label>
                    <select name="status" value={formData.status} onChange={handleChange}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500 transition-all appearance-none cursor-pointer">
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                    </select>
                  </div>
                </div>

                {formats.length > 0 && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Supported Formats</label>
                    <div className="flex flex-wrap gap-2">
                      {formats.map(fmt => (
                        <button type="button" key={fmt.id} onClick={() => toggleFormat(fmt.id)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider border transition-all cursor-pointer ${
                            formData.format_ids.includes(fmt.id)
                              ? 'bg-primary-500/20 text-primary-600 dark:text-primary-400 border-primary-500/40'
                              : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700 hover:border-primary-500/30'
                          }`}>
                          {fmt.name} ({fmt.code})
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                <button type="submit" disabled={submitting}
                  className="w-full mt-4 bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-primary-500/30 transition-all hover:shadow-primary-500/50 hover:scale-105 active:scale-95 flex justify-center items-center cursor-pointer disabled:opacity-70 disabled:pointer-events-none">
                  {submitting ? <Loader className="w-5 h-5 animate-spin" /> : (editingScreen ? 'Update Screen' : 'Create Screen')}
                </button>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
