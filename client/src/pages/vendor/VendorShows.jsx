import { useMemo, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { CalendarDays, Plus, Calendar, Clock, ChevronLeft, Loader, Video, AlertTriangle, Sparkles } from 'lucide-react'
import { useCancelShowMutation, useGetMoviesQuery, useGetScreenQuery, useGetScreenShowsQuery } from '../../store/apiSlice'
import { extractApiError } from '../../utils/api'
import { showApiErrorToast, showSuccessToast } from '../../utils/toast'
import { useConfirm } from '../../components/ConfirmProvider'

export default function VendorShows() {
  const { theatreId, screenId } = useParams()
  const navigate = useNavigate()
  const [cancelShow] = useCancelShowMutation()
  
  const confirm = useConfirm()
  const { data: screen, error: screenError } = useGetScreenQuery({ theatreId, screenId }, { skip: !theatreId || !screenId })
  const { data: movies = [], isLoading: moviesLoading } = useGetMoviesQuery()
  const {
    data: shows = [],
    isLoading: showsLoading,
    isFetching: showsFetching,
    error: showsError,
  } = useGetScreenShowsQuery({ theatreId, screenId }, { skip: !theatreId || !screenId })
  const loading = showsLoading || showsFetching
  const error = screenError || showsError ? extractApiError(screenError || showsError, 'Failed to load shows') : null
  const supportedFormatIds = useMemo(
    () => new Set((screen?.formats || []).map((format) => format.id)),
    [screen?.formats]
  )
  const compatibleMovies = useMemo(
    () => movies.filter((movie) => movie.formats?.some((format) => supportedFormatIds.has(format.id))),
    [movies, supportedFormatIds]
  )
  
  const handleCancelShow = async (showId) => {
    const confirmed = await confirm({
      title: 'Cancel Show?',
      message: 'This show will be cancelled and can no longer accept bookings.',
      confirmText: 'Cancel Show',
      tone: 'warning',
    })
    if (!confirmed) return
    
    try {
      await cancelShow({ theatreId, screenId, showId }).unwrap()
      showSuccessToast('Show cancelled successfully.')
    } catch (err) {
      showApiErrorToast(err, 'Failed to cancel show')
    }
  }

  const formatTime = (timeString) => {
    if (!timeString) return ''
    const date = new Date(timeString)
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  const formatDate = (timeString) => {
    if (!timeString) return ''
    const date = new Date(timeString)
    return date.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })
  }

  const getCompatibleFormats = (movie) =>
    (movie.formats || []).filter((format) => supportedFormatIds.has(format.id))
  
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <Loader className="w-12 h-12 text-purple-500 animate-spin mb-4" />
        <p className="text-neutral-500">Loading schedules...</p>
      </div>
    )
  }
  
  if (error) {
    return (
      <div className="p-8 max-w-7xl mx-auto">
        <div className="bg-red-500/10 border border-red-500/20 rounded-2xl p-6 text-center">
          <AlertTriangle className="w-12 h-12 text-red-500 mx-auto mb-3" />
          <h2 className="text-xl font-bold text-red-500 mb-2">Error</h2>
          <p className="text-red-400">{error}</p>
          <button 
            onClick={() => navigate('/vendor/screens')}
            className="mt-4 px-4 py-2 bg-red-500/20 text-red-600 dark:text-red-400 rounded-lg hover:bg-red-500/30 transition"
          >
            Go Back
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
        <div>
          <button 
            onClick={() => navigate('/vendor/screens')}
            className="flex items-center text-sm text-neutral-500 hover:text-purple-500 transition-colors mb-2"
          >
            <ChevronLeft className="w-4 h-4 mr-1" /> Back to Screens
          </button>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white flex items-center gap-3">
            <CalendarDays className="w-8 h-8 text-purple-500" />
            Shows for {screen?.name || 'Screen'}
          </h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-1">
            Manage movie schedules and pricing
          </p>
        </div>
        <button
          onClick={() => navigate(`/vendor/shows/${theatreId}/${screenId}/new`)}
          className="bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-medium py-2.5 px-5 rounded-xl shadow-lg shadow-purple-500/30 transition-all hover:shadow-purple-500/50 hover:scale-105 active:scale-95 flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Add Show
        </button>
      </div>

      {/* Shows List */}
      {shows.length === 0 ? (
        <div className="space-y-6">
          <div className="glass-card p-16 text-center hover:translate-y-0">
            <CalendarDays className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-600 mb-4" />
            <h3 className="text-xl font-semibold text-neutral-700 dark:text-neutral-300 mb-2">No shows scheduled</h3>
            <p className="text-neutral-500 dark:text-neutral-400 mb-6">Create your first show for this screen to start selling tickets.</p>
            <button
              onClick={() => navigate(`/vendor/shows/${theatreId}/${screenId}/new`)}
              className="px-6 py-3 bg-purple-500/10 text-purple-600 dark:text-purple-400 font-medium rounded-xl hover:bg-purple-500/20 transition-colors inline-flex items-center gap-2"
            >
              <Plus className="w-5 h-5" /> Schedule a Show
            </button>
          </div>

          <div className="glass-card p-6 lg:p-8 hover:translate-y-0">
            <div className="flex items-start justify-between gap-4 mb-6">
              <div>
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-purple-500" />
                  Available Movies For This Screen
                </h2>
                <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-1">
                  Only movies with at least one format supported by {screen?.name || 'this screen'} are shown here.
                </p>
              </div>
            </div>

            {moviesLoading ? (
              <div className="flex justify-center py-10">
                <Loader className="w-8 h-8 text-purple-500 animate-spin" />
              </div>
            ) : compatibleMovies.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-neutral-300 dark:border-neutral-700 p-8 text-center">
                <p className="text-neutral-600 dark:text-neutral-300 font-medium">
                  No compatible movies are available for this screen right now.
                </p>
                <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-2">
                  Add a movie with one of this screen&apos;s supported formats, or update the screen capabilities.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {compatibleMovies.map((movie) => {
                  const compatibleFormats = getCompatibleFormats(movie)

                  return (
                    <div
                      key={movie.id}
                      className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white/50 dark:bg-neutral-900/30 p-5"
                    >
                      <div className="flex items-start justify-between gap-4">
                        <div>
                          <h3 className="text-lg font-bold text-neutral-900 dark:text-white">
                            {movie.title}
                          </h3>
                          <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-1">
                            {movie.genre || 'Movie'} {movie.running_time ? `· ${movie.running_time} mins` : ''}
                          </p>
                          {compatibleFormats.length > 0 && (
                            <div className="flex flex-wrap gap-1.5 mt-3">
                              {compatibleFormats.map((format) => (
                                <span
                                  key={format.id}
                                  className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20"
                                >
                                  {format.code}
                                </span>
                              ))}
                            </div>
                          )}
                        </div>

                        <button
                          onClick={() => navigate(`/vendor/shows/${theatreId}/${screenId}/new?movieId=${movie.id}`)}
                          className="shrink-0 px-4 py-2 rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 hover:bg-purple-500/20 transition-colors text-sm font-medium inline-flex items-center gap-2"
                        >
                          <Plus className="w-4 h-4" />
                          Schedule Show
                        </button>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          <AnimatePresence>
            {shows.map((show, i) => (
              <motion.div
                key={show.id}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.05 }}
                className="glass-card p-6 relative overflow-hidden group hover:-translate-y-1 transition-all"
              >
                <div className={`absolute top-0 left-0 w-1 h-full ${show.status === 'cancelled' ? 'bg-red-500' : 'bg-purple-500'}`} />
                
                <div className="flex justify-between items-start mb-4">
                  <div className="flex gap-3 items-center">
                    <div className={`p-3 rounded-xl ${show.status === 'cancelled' ? 'bg-red-500/10 text-red-500' : 'bg-purple-500/10 text-purple-500'}`}>
                      <Video className="w-6 h-6" />
                    </div>
                    <div>
                      <h3 className="font-bold text-lg text-neutral-900 dark:text-white line-clamp-1" title={show.movie?.title}>
                        {show.movie?.title}
                      </h3>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400 border border-neutral-200 dark:border-neutral-700">
                          {show.language?.code}
                        </span>
                        <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20">
                          {show.format?.code}
                        </span>
                      </div>
                    </div>
                  </div>
                  <span className={`text-[10px] font-bold uppercase tracking-widest px-2 py-1 rounded-full border ${
                    show.status === 'scheduled' ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20' :
                    show.status === 'cancelled' ? 'bg-red-500/10 text-red-500 border-red-500/20' :
                    'bg-neutral-500/10 text-neutral-500 border-neutral-500/20'
                  }`}>
                    {show.status}
                  </span>
                </div>

                <div className="space-y-3 mb-6">
                  <div className="flex items-center text-sm text-neutral-600 dark:text-neutral-400">
                    <Calendar className="w-4 h-4 mr-3 text-neutral-400" />
                    {formatDate(show.start_time)}
                  </div>
                  <div className="flex items-center text-sm text-neutral-600 dark:text-neutral-400">
                    <Clock className="w-4 h-4 mr-3 text-neutral-400" />
                    {formatTime(show.start_time)}
                  </div>
                </div>

                <div className="flex gap-2 border-t border-neutral-200 dark:border-neutral-800 pt-4">
                  <Link
                    to={`/vendor/shows/${theatreId}/${screenId}/${show.id}/edit`}
                    className="flex-1 text-center py-2 bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 text-neutral-700 dark:text-neutral-300 rounded-lg text-sm font-medium transition-colors"
                  >
                    Manage
                  </Link>
                  {show.status === 'scheduled' && (
                    <button
                      onClick={() => handleCancelShow(show.id)}
                      className="px-4 py-2 bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 rounded-lg text-sm font-medium transition-colors"
                    >
                      Cancel
                    </button>
                  )}
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}
    </div>
  )
}
