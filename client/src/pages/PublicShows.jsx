import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useSelector } from 'react-redux'
import { Loader, Calendar, MapPin } from 'lucide-react'
import { useGetCitiesQuery, useGetMovieQuery, useGetShowsQuery } from '../store/apiSlice'
import { selectSelectedCity } from '../store/citySlice'
import { Skeleton } from '../components/ui/Skeleton'
import { BookingStepper } from '../components/ui/BookingStepper'

export default function PublicShows() {
  const { id: movieId } = useParams()
  const navigate = useNavigate()
  const selectedCity = useSelector(selectSelectedCity)
  
  const [dates, setDates] = useState([])
  const [selectedDate, setSelectedDate] = useState('')
  const { data: cities = [] } = useGetCitiesQuery()
  const { data: movie } = useGetMovieQuery(movieId, { skip: !movieId })
  const {
    data: shows = [],
    isLoading: showsLoading,
    isFetching: showsFetching,
  } = useGetShowsQuery(
    {
      movie_id: movieId,
      city_id: selectedCity || undefined,
      date: selectedDate,
      per_page: 50,
    },
    { skip: !selectedDate }
  )

  // Generate next 7 days starting from today
  useEffect(() => {
    const nextDates = []
    const today = new Date()
    for (let i = 0; i < 7; i++) {
      const d = new Date(today)
      d.setDate(today.getDate() + i)
      nextDates.push({
        dateStr: d.toISOString().split('T')[0],
        dayName: d.toLocaleDateString('en-US', { weekday: 'short' }),
        dayMonth: d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' })
      })
    }
    setDates(nextDates)
    setSelectedDate(nextDates[0].dateStr)
  }, [])

  const loading = showsLoading || showsFetching

  // Group by Theatre
  const theatresMap = {}
  shows.forEach(show => {
    if (!show.screen || !show.screen.theatre) return
    const tId = show.screen.theatre.id
    if (!theatresMap[tId]) {
      theatresMap[tId] = { 
        id: tId, 
        name: show.screen.theatre.name, 
        building_name: show.screen.theatre.building_name,
        street_address: show.screen.theatre.street_address,
        shows: [] 
      }
    }
    theatresMap[tId].shows.push(show)
  })
  const groupedTheatres = Object.values(theatresMap).sort((a, b) => a.name.localeCompare(b.name))

  const formatTime = (timeStr) => {
    return new Date(timeStr).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  return (
    <div className="bg-neutral-50 dark:bg-[#0b090f] min-h-screen">
      <BookingStepper currentStep={1} />
      <div className="py-10 max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Movie Header */}
        <div className="mb-10 p-6 glass-card border border-neutral-200 dark:border-neutral-800/50 rounded-3xl flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-neutral-900 dark:text-white mb-2">{movie?.title || 'Loading...'}</h1>
            <div className="flex gap-4 text-xs font-bold uppercase tracking-wider text-neutral-500 dark:text-neutral-400">
               <span className="flex items-center gap-1"><MapPin className="w-4 h-4" /> {selectedCity ? (cities.find(c => c.id === selectedCity)?.name || 'Selected City') : 'All Cities'}</span>
               <span className="flex items-center gap-1 bg-primary-500/10 text-primary-500 px-2 py-0.5 rounded">{movie?.genre || '...'}</span>
            </div>
          </div>
        </div>

        {/* Date Picker Horizontal */}
        <div className="flex gap-4 overflow-x-auto px-1 sm:px-2 py-2 snap-x snap-mandatory mb-8 scrollbar-hide">
          {dates.map((d, i) => {
             const active = selectedDate === d.dateStr
             return (
               <button
                 key={i}
                 onClick={() => setSelectedDate(d.dateStr)}
                 className={`flex flex-col items-center justify-center min-w-[84px] sm:min-w-[92px] px-4 py-3 rounded-2xl border-2 transition-all duration-200 cursor-pointer snap-start shrink-0
                   ${active 
                      ? 'border-primary-500 bg-primary-500/14 text-primary-600 dark:text-primary-300 font-bold shadow-[0_10px_24px_rgba(139,92,246,0.22)] scale-105'
                      : 'border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900/50 text-neutral-500 hover:border-primary-500/50 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                   }`}
               >
                 <span className={`text-[11px] uppercase tracking-[0.24em] ${active ? 'text-primary-500 dark:text-primary-300' : ''}`}>{d.dayName}</span>
                 <span className={`text-lg mt-1 ${active ? 'text-primary-600 dark:text-primary-300' : 'text-neutral-700 dark:text-neutral-300'}`}>{d.dayMonth}</span>
               </button>
             )
          })}
        </div>

        {loading ? (
          <div className="space-y-6">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="glass-card bg-white dark:bg-neutral-900/40 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-6">
                <div className="flex items-center gap-3 mb-6">
                  <Skeleton className="w-10 h-10 rounded-lg" />
                  <div className="space-y-2">
                    <Skeleton className="h-6 w-48" />
                    <Skeleton className="h-4 w-64" />
                  </div>
                </div>
                <div className="flex flex-wrap gap-4">
                  {[...Array(4)].map((_, j) => (
                    <Skeleton key={j} className="h-[68px] w-[120px] rounded-xl" />
                  ))}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-6">
            {groupedTheatres.length === 0 ? (
              <div className="text-center py-20 bg-white dark:bg-neutral-900/40 rounded-3xl border border-dashed border-neutral-300 dark:border-neutral-800">
                 <Calendar className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-700 mb-4" />
                 <p className="text-xl font-medium text-neutral-500">No showtimes are available for that day in the selected city.</p>
                 <p className="text-sm text-neutral-400 dark:text-neutral-500 mt-2">Try another date or switch to a different city.</p>
              </div>
            ) : (
              groupedTheatres.map(theatre => (
                <div key={theatre.id} className="glass-card bg-white dark:bg-neutral-900/40 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-6 hover:border-primary-500/30 transition-colors">
                  <div className="flex items-center gap-3 mb-6">
                    <div className="p-2 bg-neutral-100 dark:bg-neutral-800 rounded-lg text-neutral-500">
                       <MapPin className="w-6 h-6" />
                    </div>
                    <div>
                      <h3 className="text-xl font-bold text-neutral-900 dark:text-white">{theatre.name}</h3>
                      { (theatre.building_name || theatre.street_address) && (
                        <p className="text-sm text-neutral-500 mt-1">{[theatre.building_name, theatre.street_address].filter(Boolean).join(', ')}</p>
                      )}
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-4">
                    {theatre.shows.map(show => (
                      <button
                         key={show.id}
                         onClick={() => navigate(`/shows/${show.id}/seats`)}
                         className="group relative border border-neutral-300 dark:border-neutral-700 rounded-xl px-5 py-3 hover:border-primary-500 hover:shadow-lg transition-all text-center flex flex-col items-center min-w-[120px] bg-white dark:bg-neutral-900 cursor-pointer"
                      >
                         <span className="text-sm font-bold text-emerald-600 dark:text-emerald-400 mb-1">{formatTime(show.start_time)}</span>
                         <span className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest">{show.format?.code} {show.language?.code}</span>
                      </button>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

      </div>
    </div>
  )
}
