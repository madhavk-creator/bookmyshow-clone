import { useEffect, useState } from 'react'
import { useParams, useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronLeft, Save, Loader, AlertTriangle, Calendar, Layers, Popcorn, Languages, Video, FileText } from 'lucide-react'
import DateFieldPanel from '../../components/DateFieldPanel'
import { useCreateShowMutation, useGetMoviesQuery, useGetScreenQuery, useGetSeatLayoutQuery, useGetSeatLayoutsQuery, useGetShowQuery, useUpdateShowMutation } from '../../store/apiSlice'
import { extractApiError } from '../../utils/api'
import { isBeforeLocalDateTime, toLocalDateTimeValue } from '../../utils/dateInput'
import { showErrorToast, showSuccessToast, showWarningToast } from '../../utils/toast'

export default function VendorShowEditor() {
  const { theatreId, screenId, showId } = useParams()
  const isEditing = Boolean(showId)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const preselectedMovieId = searchParams.get('movieId') || ''
  const [createShow] = useCreateShowMutation()
  const [updateShow] = useUpdateShowMutation()

  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const [languages, setLanguages] = useState([])
  const [formats, setFormats] = useState([])

  const [formData, setFormData] = useState({
    movie_id: '',
    movie_language_id: '',
    movie_format_id: '',
    seat_layout_id: '',
    start_time: '',
    recurrence_end_date: '',
    section_prices: [] // { seat_section_id, base_price }
  })
  const { data: movies = [], isLoading: moviesLoading } = useGetMoviesQuery()
  const { data: screen } = useGetScreenQuery(
    { theatreId, screenId },
    { skip: !theatreId || !screenId }
  )
  const { data: allLayouts = [], isLoading: layoutsLoading } = useGetSeatLayoutsQuery(
    { theatreId, screenId },
    { skip: !theatreId || !screenId }
  )
  const layouts = allLayouts.filter((layout) => layout.status === 'published')
  const { data: showData, isLoading: showLoading } = useGetShowQuery(
    { theatreId, screenId, showId },
    { skip: !isEditing }
  )
  const selectedLayoutId = formData.seat_layout_id || showData?.seat_layout_id || ''
  const { data: selectedLayoutDetail, isLoading: layoutDetailLoading } = useGetSeatLayoutQuery(
    { theatreId, screenId, layoutId: selectedLayoutId },
    { skip: !selectedLayoutId }
  )
  const selectedLayoutSections = selectedLayoutDetail?.sections || []
  const loading = moviesLoading || layoutsLoading || (isEditing && showLoading) || layoutDetailLoading
  const minimumStartTime = toLocalDateTimeValue()
  const supportedFormatIds = new Set((screen?.formats || []).map((format) => format.id))
  const compatibleFormats = formats.filter((format) => supportedFormatIds.has(format.id))

  useEffect(() => {
    if (!isEditing || !showData || movies.length === 0) return

    const loadedMovie = movies.find((movie) => movie.id === showData.movie?.id)
    if (loadedMovie) {
      setLanguages(loadedMovie.languages || [])
      setFormats(loadedMovie.formats || [])
    }
    
    setFormData({
      movie_id: showData.movie?.id || '',
      movie_language_id: showData.language?.id || '',
      movie_format_id: showData.format?.id || '',
      seat_layout_id: showData.seat_layout_id || '',
      start_time: new Date(new Date(showData.start_time).getTime() - new Date(showData.start_time).getTimezoneOffset() * 60000).toISOString().slice(0, 16),
      recurrence_end_date: '',
      section_prices: showData.section_prices || []
    })
  }, [isEditing, movies, showData])

  useEffect(() => {
    if (!selectedLayoutSections.length) return
    if (isEditing) return

    setFormData((prev) => ({
      ...prev,
      section_prices: selectedLayoutSections.map((section) => ({
        seat_section_id: section.id,
        base_price: '',
      })),
    }))
  }, [isEditing, selectedLayoutSections])

  useEffect(() => {
    if (isEditing || !preselectedMovieId || movies.length === 0) return
    if (formData.movie_id) return

    const selectedMovie = movies.find((movie) => movie.id === preselectedMovieId)
    if (!selectedMovie) return

    const compatibleFormats = (selectedMovie.formats || []).filter((format) => supportedFormatIds.has(format.id))

    setLanguages(selectedMovie.languages || [])
    setFormats(selectedMovie.formats || [])
    setFormData((prev) => ({
      ...prev,
      movie_id: preselectedMovieId,
      movie_language_id: selectedMovie.languages?.length === 1 ? selectedMovie.languages[0].movie_language_id || '' : '',
      movie_format_id: compatibleFormats.length === 1 ? compatibleFormats[0].movie_format_id || '' : '',
    }))
  }, [formData.movie_id, isEditing, movies, preselectedMovieId, screen?.formats])

  const handleLayoutChange = (e) => {
    const layoutId = e.target.value
    setFormData(prev => ({
      ...prev,
      seat_layout_id: layoutId,
      section_prices: [],
    }))
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))

    if (name === 'movie_id') {
      const selectedMovie = movies.find(m => m.id === value)
      if (selectedMovie) {
        const movieCompatibleFormats = (selectedMovie.formats || []).filter((format) => supportedFormatIds.has(format.id))
        setLanguages(selectedMovie.languages || [])
        setFormats(selectedMovie.formats || [])
        
        setFormData(prev => ({
          ...prev,
          movie_id: value,
          movie_language_id: selectedMovie.languages?.length === 1 ? selectedMovie.languages[0].movie_language_id || '' : '',
          movie_format_id: movieCompatibleFormats.length === 1 ? movieCompatibleFormats[0].movie_format_id || '' : ''
        }))
      } else {
        setLanguages([])
        setFormats([])
        setFormData(prev => ({
          ...prev,
          movie_id: value,
          movie_language_id: '',
          movie_format_id: ''
        }))
      }
    }
  }

  const handlePriceChange = (sectionId, value) => {
    setFormData(prev => ({
      ...prev,
      section_prices: prev.section_prices.map(sp => 
        sp.seat_section_id === sectionId ? { ...sp, base_price: value } : sp
      )
    }))
  }

  const getShowSaveErrorMessage = (err) => {
    const message = extractApiError(err, 'Failed to save show')

    if (message.includes('This screen already has a show scheduled')) {
      return 'You have another show running in the same screen for one or more selected dates. Please pick a different time or shorten the repeat range.'
    }

    return message
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    
    // Basic validation
    if (!formData.movie_id || !formData.start_time || !formData.seat_layout_id || !formData.movie_language_id || !formData.movie_format_id) {
      setError('Please fill in all required show details.')
      showWarningToast('Please fill in all required show details.')
      setSubmitting(false)
      return
    }

    if (isBeforeLocalDateTime(formData.start_time, minimumStartTime)) {
      setError('Show time cannot be in the past.')
      showWarningToast('Show time cannot be in the past.')
      setSubmitting(false)
      return
    }

    if (
      !isEditing &&
      formData.recurrence_end_date &&
      formData.recurrence_end_date < formData.start_time.slice(0, 10)
    ) {
      setError('Repeat end date must be on or after the show date.')
      showWarningToast('Repeat end date must be on or after the show date.')
      setSubmitting(false)
      return
    }
    
    for (const sp of formData.section_prices) {
      const basePrice = Number(sp.base_price)
      if (sp.base_price === '' || !Number.isFinite(basePrice) || basePrice < 0) {
        setError('Please enter a valid positive base price for all sections.')
        showWarningToast('Please enter a valid positive base price for all sections.')
        setSubmitting(false)
        return
      }
    }

    try {
      const payload = {
        show: {
          start_time: new Date(formData.start_time).toISOString(),
          section_prices: formData.section_prices.map(sp => ({
            seat_section_id: sp.seat_section_id,
            base_price: Number(sp.base_price)
          }))
        }
      }
      
      if (!isEditing) {
        payload.show.movie_id = formData.movie_id
        payload.show.movie_language_id = formData.movie_language_id
        payload.show.movie_format_id = formData.movie_format_id
        payload.show.seat_layout_id = formData.seat_layout_id
        if (formData.recurrence_end_date) {
          payload.show.recurrence_end_date = formData.recurrence_end_date
        }
      }
      
      if (isEditing) {
        await updateShow({ theatreId, screenId, showId, show: payload.show }).unwrap()
      } else {
        await createShow({ theatreId, screenId, show: payload.show }).unwrap()
      }
      if (isEditing) {
        showSuccessToast('Show updated successfully.')
      } else if (formData.recurrence_end_date) {
        showSuccessToast('Shows scheduled successfully for the selected date range.')
      } else {
        showSuccessToast('Show scheduled successfully.')
      }
      navigate(`/vendor/shows/${theatreId}/${screenId}`)
    } catch (err) {
      const errorMessage = getShowSaveErrorMessage(err)
      setError(errorMessage)
      showErrorToast(errorMessage)
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader className="w-12 h-12 text-purple-500 animate-spin mb-4" />
        <p className="text-neutral-500">Loading editor...</p>
      </div>
    )
  }

  return (
    <div className="p-6 lg:p-8 max-w-4xl mx-auto">
      <button 
        onClick={() => navigate(`/vendor/shows/${theatreId}/${screenId}`)}
        className="flex items-center text-sm text-neutral-500 hover:text-purple-500 transition-colors mb-6"
      >
        <ChevronLeft className="w-4 h-4 mr-1" /> Back to Shows
      </button>

      <div className="glass-card p-8">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-2">
          {isEditing ? 'Edit Show & Pricing' : 'Schedule New Show'}
        </h1>
        <p className="text-neutral-500 dark:text-neutral-400 mb-8 border-b border-neutral-200 dark:border-neutral-800 pb-6">
          {isEditing 
            ? 'Update the show time or adjust section prices. Other properties cannot be changed once scheduled.'
            : 'Configure movie, time, layout and tiered pricing for this screen.'}
        </p>
        
        {error && (
          <div className="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/50 flex items-start text-red-500">
            <AlertTriangle className="w-5 h-5 flex-shrink-0 mr-3 mt-0.5" />
            <p className="text-sm font-medium">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="flex items-center text-sm font-medium text-neutral-700 dark:text-neutral-300">
                <Popcorn className="w-4 h-4 mr-2 text-purple-500" /> Movie *
              </label>
              <select 
                name="movie_id" 
                value={formData.movie_id} 
                onChange={handleChange}
                disabled={isEditing}
                className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700 rounded-xl px-4 py-3 focus:ring-2 focus:ring-purple-500/50 disabled:opacity-50 disabled:bg-neutral-100 dark:disabled:bg-neutral-800"
              >
                <option value="">Select a movie</option>
                {movies.map(m => <option key={m.id} value={m.id}>{m.title}</option>)}
              </select>
            </div>
            
            <div className="space-y-2">
              <DateFieldPanel
                icon={Calendar}
                label="Date & Time"
                type="datetime-local"
                name="start_time" 
                value={formData.start_time} 
                onChange={handleChange}
                min={minimumStartTime}
                required
                hint="Only future showtimes are allowed. The selected time uses the browser's local timezone."
                error={error === 'Show time cannot be in the past.' ? error : undefined}
              />
            </div>

            {!isEditing && (
              <div className="space-y-2">
                <DateFieldPanel
                  icon={Calendar}
                  label="Repeat Daily Until"
                  type="date"
                  name="recurrence_end_date"
                  value={formData.recurrence_end_date}
                  onChange={handleChange}
                  min={formData.start_time ? formData.start_time.slice(0, 10) : minimumStartTime.slice(0, 10)}
                  hint="Optional. Leave empty for a single show, or choose an end date to repeat this show daily at the same time."
                  error={error === 'Repeat end date must be on or after the show date.' ? error : undefined}
                />
              </div>
            )}

            <div className="space-y-2">
              <label className="flex items-center text-sm font-medium text-neutral-700 dark:text-neutral-300">
                <Languages className="w-4 h-4 mr-2 text-purple-500" /> Language *
              </label>
              <select 
                name="movie_language_id" 
                value={formData.movie_language_id} 
                onChange={handleChange}
                disabled={isEditing}
                className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700 rounded-xl px-4 py-3 focus:ring-2 focus:ring-purple-500/50 disabled:opacity-50"
              >
                <option value="">Select language</option>
                {languages.map(l => <option key={l.movie_language_id || l.id} value={l.movie_language_id || ''}>{l.name} ({l.code})</option>)}
              </select>
            </div>

            <div className="space-y-2">
              <label className="flex items-center text-sm font-medium text-neutral-700 dark:text-neutral-300">
                <Video className="w-4 h-4 mr-2 text-purple-500" /> Format *
              </label>
              <select 
                name="movie_format_id" 
                value={formData.movie_format_id} 
                onChange={handleChange}
                disabled={isEditing}
                className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700 rounded-xl px-4 py-3 focus:ring-2 focus:ring-purple-500/50 disabled:opacity-50"
              >
                <option value="">Select format</option>
                {compatibleFormats.map(f => <option key={f.movie_format_id || f.id} value={f.movie_format_id || ''}>{f.name} ({f.code})</option>)}
              </select>
            </div>

            <div className="space-y-2 md:col-span-2">
              <label className="flex items-center text-sm font-medium text-neutral-700 dark:text-neutral-300">
                <Layers className="w-4 h-4 mr-2 text-purple-500" /> Seat Layout *
              </label>
              <select 
                name="seat_layout_id" 
                value={formData.seat_layout_id} 
                onChange={handleLayoutChange}
                disabled={isEditing}
                className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700 rounded-xl px-4 py-3 focus:ring-2 focus:ring-purple-500/50 disabled:opacity-50"
              >
                <option value="">Select a published layout</option>
                {layouts.map(l => <option key={l.id} value={l.id}>{l.name} (Capacity: {l.total_seats})</option>)}
              </select>
              {layouts.length === 0 && !isEditing && (
                <p className="text-xs text-amber-500 mt-1">No published layouts found for this screen.</p>
              )}
            </div>
          </div>

          {/* Section Pricing */}
          {selectedLayoutSections.length > 0 && (
            <div className="pt-6 border-t border-neutral-200 dark:border-neutral-800">
              <h3 className="text-lg font-bold text-neutral-900 dark:text-white flex items-center mb-4">
                <FileText className="w-5 h-5 mr-2 text-purple-500" /> Section Pricing
              </h3>
              
              <div className="bg-neutral-50 dark:bg-neutral-900/30 rounded-xl border border-neutral-200 dark:border-neutral-700 overflow-hidden">
                <table className="w-full text-sm text-left">
                  <thead className="bg-neutral-100 dark:bg-neutral-800/80 text-neutral-700 dark:text-neutral-300 font-semibold border-b border-neutral-200 dark:border-neutral-700">
                    <tr>
                      <th className="px-4 py-3">Section Code</th>
                      <th className="px-4 py-3">Name</th>
                      <th className="px-4 py-3">Capacity</th>
                      <th className="px-4 py-3">Base Price (₹)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedLayoutSections.map(section => {
                      const sp = formData.section_prices.find(p => p.seat_section_id === section.id)
                      return (
                        <tr key={section.id} className="border-b border-neutral-200 dark:border-neutral-800 last:border-0 hover:bg-white dark:hover:bg-neutral-800/30 transition-colors">
                          <td className="px-4 py-3 font-medium text-neutral-900 dark:text-white text-xs">
                            <span className="px-2 py-1 rounded bg-neutral-200 dark:bg-neutral-700">{section.code}</span>
                          </td>
                          <td className="px-4 py-3 text-neutral-600 dark:text-neutral-400">{section.name || '-'}</td>
                          <td className="px-4 py-3 text-neutral-600 dark:text-neutral-400">{section.capacity || '-'}</td>
                          <td className="px-4 py-3">
                            <input
                              type="number"
                              min="0"
                              step="0.01"
                              placeholder="e.g. 150"
                              value={sp?.base_price || ''}
                              onChange={(e) => handlePriceChange(section.id, e.target.value)}
                              className="w-full bg-white dark:bg-neutral-900 border border-neutral-300 dark:border-neutral-600 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-purple-500/50"
                              required
                            />
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          <div className="flex justify-end gap-3 pt-6 border-t border-neutral-200 dark:border-neutral-800">
            <button
              type="button"
              onClick={() => navigate(`/vendor/shows/${theatreId}/${screenId}`)}
              className="px-6 py-2.5 rounded-xl font-medium bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 transition-all hover:scale-105 active:scale-95"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-6 py-2.5 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-medium rounded-xl shadow-lg shadow-purple-500/30 transition-all hover:shadow-purple-500/50 hover:scale-105 active:scale-95 flex flex-row items-center cursor-pointer disabled:opacity-50 disabled:pointer-events-none"
            >
              {submitting ? (
                <Loader className="w-5 h-5 animate-spin mx-auto" />
              ) : (
                <>
                  <Save className="w-5 h-5 mr-2" />
                  {isEditing ? 'Save Changes' : 'Schedule Show'}
                </>
              )}
            </button>
          </div>
          
          
        </form>
      </div>
    </div>
  )
}
