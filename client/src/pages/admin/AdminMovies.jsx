import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Clapperboard, Plus, Pencil, Trash2, X, Loader, Clock } from 'lucide-react'
import DateFieldPanel from '../../components/DateFieldPanel'
import { extractApiError } from '../../utils/api'
import { showApiErrorToast, showSuccessToast } from '../../utils/toast'
import { useConfirm } from '../../components/ConfirmProvider'
import { useCreateMovieMutation, useDeleteMovieMutation, useGetFormatsQuery, useGetLanguagesQuery, useGetMovieQuery, useGetMoviesQuery, useUpdateMovieMutation } from '../../store/apiSlice'

const EMPTY_MOVIE_FORM = {
  title: '',
  genre: '',
  rating: 'UA',
  description: '',
  director: '',
  running_time: '',
  release_date: '',
  format_ids: [],
  language_entries: [],
  cast_members: [],
}

export default function AdminMovies() {
  const [showModal, setShowModal] = useState(false)
  const [editing, setEditing] = useState(null)
  const [formData, setFormData] = useState(EMPTY_MOVIE_FORM)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const confirm = useConfirm()
  const [createMovie] = useCreateMovieMutation()
  const [updateMovie] = useUpdateMovieMutation()
  const [deleteMovie] = useDeleteMovieMutation()
  const { data: movies = [], isLoading: moviesLoading, isFetching: moviesFetching } = useGetMoviesQuery()
  const { data: editingMovie, isFetching: editingMovieFetching } = useGetMovieQuery(editing?.id, {
    skip: !editing?.id,
  })
  const { data: languages = [] } = useGetLanguagesQuery()
  const { data: formats = [] } = useGetFormatsQuery()
  const loading = moviesLoading || moviesFetching
  const modalLoading = editingMovieFetching && !!editing

  const openCreate = () => {
    setEditing(null)
    setFormData(EMPTY_MOVIE_FORM)
    setError(null)
    setShowModal(true)
  }

  const openEdit = (movie) => {
    setEditing(movie)
    setFormData(EMPTY_MOVIE_FORM)
    setError(null)
    setShowModal(true)
  }

  useEffect(() => {
    if (!editing || !editingMovie) return

    setFormData({
      title: editingMovie.title || '',
      genre: editingMovie.genre || '',
      rating: editingMovie.rating || 'UA',
      description: editingMovie.description || '',
      director: editingMovie.director || '',
      running_time: editingMovie.running_time || '',
      release_date: editingMovie.release_date || '',
      format_ids: editingMovie.formats?.map((format) => format.id) || [],
      language_entries: editingMovie.languages?.map((language) => ({
        language_id: language.id,
        type: language.type || 'original',
      })) || [],
      cast_members: editingMovie.cast_members || [],
    })
  }, [editing, editingMovie])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      const payload = { ...formData, running_time: parseInt(formData.running_time) || 0 }
      if (editing) {
        await updateMovie({ id: editing.id, movie: payload }).unwrap()
      } else {
        await createMovie(payload).unwrap()
      }
      showSuccessToast(`Movie ${editing ? 'updated' : 'created'} successfully.`)
      setShowModal(false)
    } catch (err) { setError(extractApiError(err, 'Operation failed')) }
    finally { setSubmitting(false) }
  }

  const handleDelete = async (id) => {
    const confirmed = await confirm({
      title: 'Delete Movie?',
      message: 'This movie will be removed from the catalogue.',
      confirmText: 'Delete Movie',
      tone: 'danger',
    })
    if (!confirmed) return
    try {
      await deleteMovie(id).unwrap()
      showSuccessToast('Movie deleted successfully.')
    } catch (err) {
      console.error(err)
      showApiErrorToast(err, 'Failed to delete movie')
    }
  }

  const handleChange = (e) => setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }))
  const toggleFormat = (fmtId) => setFormData(prev => ({ ...prev, format_ids: prev.format_ids.includes(fmtId) ? prev.format_ids.filter(id => id !== fmtId) : [...prev.format_ids, fmtId] }))
  const toggleLanguage = (langId) => {
    setFormData(prev => {
      const exists = prev.language_entries.find(e => e.language_id === langId)
      if (exists) return { ...prev, language_entries: prev.language_entries.filter(e => e.language_id !== langId) }
      return { ...prev, language_entries: [...prev.language_entries, { language_id: langId, type: 'original' }] }
    })
  }

  const addCastMember = () => setFormData(prev => ({ ...prev, cast_members: [...prev.cast_members, { name: '', role: 'actor', character_name: '' }] }))
  const updateCastMember = (i, field, value) => setFormData(prev => {
    const cast = [...prev.cast_members]
    cast[i] = { ...cast[i], [field]: value }
    return { ...prev, cast_members: cast }
  })
  const removeCastMember = (i) => setFormData(prev => ({ ...prev, cast_members: prev.cast_members.filter((_, idx) => idx !== i) }))

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">Movies</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">Manage the movie catalogue</p>
        </div>
        <button onClick={openCreate} className="bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 text-white font-medium py-2.5 px-5 rounded-xl shadow-lg shadow-rose-500/30 transition-all hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer">
          <Plus className="w-5 h-5" /> Add Movie
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader className="w-10 h-10 text-rose-500 animate-spin" /></div>
      ) : movies.length === 0 ? (
        <div className="glass-card p-16 text-center hover:translate-y-0">
          <Clapperboard className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
          <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No movies yet</h3>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AnimatePresence>
            {movies.map((movie, i) => (
              <motion.div key={movie.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95 }} transition={{ delay: i * 0.04, duration: 0.3 }} className="glass-card p-6 hover:translate-y-0 group relative">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-12 h-12 rounded-xl bg-rose-500/10 flex items-center justify-center">
                    <Clapperboard className="w-6 h-6 text-rose-500" />
                  </div>
                  <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button onClick={() => openEdit(movie)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 hover:text-rose-500 transition-colors cursor-pointer"><Pencil className="w-4 h-4" /></button>
                    <button onClick={() => handleDelete(movie.id)} className="p-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 transition-colors cursor-pointer"><Trash2 className="w-4 h-4" /></button>
                  </div>
                </div>
                <h3 className="font-bold text-lg text-neutral-900 dark:text-white mb-1">{movie.title}</h3>
                <p className="text-sm text-neutral-500 dark:text-neutral-400 mb-3">{movie.director}</p>
                <div className="flex flex-wrap gap-2 mb-3">
                  <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20">{movie.genre}</span>
                  <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-primary-500/10 text-primary-600 dark:text-primary-400 border border-primary-500/20">{movie.rating}</span>
                </div>
                <div className="flex items-center gap-3 text-xs text-neutral-400">
                  <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5" />{movie.running_time}m</span>
                  <span>{movie.release_date}</span>
                </div>
                {movie.formats?.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-3">{movie.formats.map(f => <span key={f.id} className="text-[9px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded bg-neutral-100 dark:bg-neutral-800 text-neutral-500">{f.code}</span>)}</div>
                )}
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}

      <AnimatePresence>
        {showModal && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setShowModal(false)}>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="w-full max-w-2xl glass-card p-8 hover:translate-y-0 max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white">{editing ? 'Edit' : 'New'} Movie</h2>
                <button onClick={() => setShowModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer"><X className="w-5 h-5" /></button>
              </div>
              {error && <div className="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/50 text-red-500 text-sm text-center font-medium">{error}</div>}
              {modalLoading ? (
                <div className="py-16 flex flex-col items-center justify-center text-neutral-500 dark:text-neutral-400">
                  <Loader className="w-8 h-8 animate-spin text-rose-500 mb-3" />
                  <p className="font-medium">Loading movie details...</p>
                </div>
              ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1 col-span-2">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Title *</label>
                    <input type="text" name="title" required value={formData.title} onChange={handleChange} className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all" placeholder="Dune Part Two" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Genre *</label>
                    <input type="text" name="genre" required value={formData.genre} onChange={handleChange} className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all" placeholder="Sci-Fi" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Rating</label>
                    <select name="rating" value={formData.rating} onChange={handleChange} className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all appearance-none cursor-pointer">
                      <option value="U">U</option><option value="UA">UA</option><option value="A">A</option><option value="S">S</option>
                    </select>
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Director</label>
                    <input type="text" name="director" value={formData.director} onChange={handleChange} className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all" placeholder="Denis Villeneuve" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Running Time (min)</label>
                    <input type="number" name="running_time" value={formData.running_time} onChange={handleChange} min="1" className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all" placeholder="166" />
                  </div>
                  <div className="space-y-1">
                    <DateFieldPanel
                      icon={Clock}
                      label="Release Date"
                      type="date"
                      name="release_date"
                      value={formData.release_date}
                      onChange={handleChange}
                      hint="Past and future release dates are both allowed."
                    />
                  </div>
                  <div className="space-y-1 col-span-2">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Description</label>
                    <textarea name="description" value={formData.description} onChange={handleChange} rows={3} className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all resize-none" placeholder="Movie description..." />
                  </div>
                </div>

                {/* Formats */}
                {formats.length > 0 && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Formats</label>
                    <div className="flex flex-wrap gap-2">
                      {formats.map(fmt => (
                        <button type="button" key={fmt.id} onClick={() => toggleFormat(fmt.id)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider border transition-all cursor-pointer ${formData.format_ids.includes(fmt.id) ? 'bg-rose-500/20 text-rose-600 dark:text-rose-400 border-rose-500/40' : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700 hover:border-rose-500/30'}`}>
                          {fmt.name}
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {/* Languages */}
                {languages.length > 0 && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Languages</label>
                    <div className="flex flex-wrap gap-2">
                      {languages.map(lang => (
                        <button type="button" key={lang.id} onClick={() => toggleLanguage(lang.id)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider border transition-all cursor-pointer ${formData.language_entries.find(e => e.language_id === lang.id) ? 'bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border-emerald-500/40' : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700 hover:border-emerald-500/30'}`}>
                          {lang.name} ({lang.code})
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {/* Cast Members */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Cast Members</label>
                    <button type="button" onClick={addCastMember} className="text-xs text-rose-500 hover:underline font-semibold cursor-pointer">+ Add</button>
                  </div>
                  {formData.cast_members.map((cm, i) => (
                    <div key={i} className="flex gap-2 items-center">
                      <input type="text" value={cm.name} onChange={e => updateCastMember(i, 'name', e.target.value)} placeholder="Name" className="flex-1 bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-rose-500/50 transition-all" />
                      <select value={cm.role} onChange={e => updateCastMember(i, 'role', e.target.value)} className="bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-lg px-3 py-2 text-sm focus:outline-none appearance-none cursor-pointer">
                        <option value="actor">Actor</option><option value="director">Director</option><option value="producer">Producer</option>
                      </select>
                      <input type="text" value={cm.character_name || ''} onChange={e => updateCastMember(i, 'character_name', e.target.value)} placeholder="Character" className="flex-1 bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-rose-500/50 transition-all" />
                      <button type="button" onClick={() => removeCastMember(i)} className="p-1.5 rounded-lg text-neutral-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors cursor-pointer"><X className="w-4 h-4" /></button>
                    </div>
                  ))}
                </div>

                <button type="submit" disabled={submitting} className="w-full mt-2 bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-rose-500/30 transition-all hover:scale-105 active:scale-95 flex justify-center items-center cursor-pointer disabled:opacity-70 disabled:pointer-events-none">
                  {submitting ? <Loader className="w-5 h-5 animate-spin" /> : (editing ? 'Update Movie' : 'Create Movie')}
                </button>
              </form>
              )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
