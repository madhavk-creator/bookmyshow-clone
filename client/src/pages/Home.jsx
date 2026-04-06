import { useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Clock, MapPin, PlayCircle, Loader, Film } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux'
import { useGetCitiesQuery, useGetMoviesQuery } from '../store/apiSlice'
import { selectSelectedCity, setSelectedCity } from '../store/citySlice'

export default function Home() {
  const navigate = useNavigate()
  const dispatch = useDispatch()
  const selectedCity = useSelector(selectSelectedCity)
  const { data: cities = [], isLoading: citiesLoading } = useGetCitiesQuery()
  const {
    data: movies = [],
    isLoading: moviesLoading,
    isFetching: moviesFetching,
  } = useGetMoviesQuery(
    { city_id: selectedCity },
    { skip: !selectedCity }
  )

  useEffect(() => {
    if (cities.length > 0 && !selectedCity) {
      dispatch(setSelectedCity(cities[0].id))
    }
  }, [cities, dispatch, selectedCity])

  const loading = citiesLoading || (!selectedCity && cities.length > 0) || moviesLoading || moviesFetching

  const formatMovieLanguages = (movie) => {
    const labels = Array.isArray(movie?.languages)
      ? movie.languages.map((language) => language?.name || language?.code).filter(Boolean)
      : []

    return labels.length > 0 ? labels.join(', ') : 'Languages TBA'
  }

  return (
    <div className="flex-1 w-full bg-neutral-50 dark:bg-[#0b090f]">
      {/* HERO SECTION */}
      <section className="relative w-full h-[60vh] min-h-[500px] flex items-center justify-center overflow-hidden">
        {/* Placeholder Hero Background */}
        <div className="absolute inset-0 bg-gradient-to-br from-neutral-900 to-[#0b090f] z-0" />
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=2670&auto=format&fit=crop')] opacity-20 bg-cover bg-center filter mix-blend-overlay z-0" />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b090f] via-transparent to-transparent z-10" />
        
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="relative z-20 text-center px-4 max-w-4xl mx-auto space-y-6"
        >
          <h1 className="text-5xl md:text-7xl font-bold text-white tracking-tight glow-text leading-tight">
            Discover The Best <br/> <span className="text-primary-400">Cinematic Experiences</span>
          </h1>
          <p className="text-xl text-neutral-300 font-medium text-white tracking-tight glow-text leading-tight">Watch your favorite films on the big screen. Experience convenience like never before.</p>
          <p className="text-xl text-neutral-300 font-medium text-white tracking-tight glow-text leading-tight">Book tickets, choose seats, and enjoy exclusive offers all in one place.</p>
          <p className="text-sm text-neutral-500">Select your city to find nearby theaters and showtimes</p>
          
          <div className="mt-8 flex justify-center">
            <div className="glass-card p-2 inline-flex items-center space-x-2 rounded-2xl w-full max-w-md backdrop-blur-xl bg-black/40 border-white/10">
              <MapPin className="text-primary-400 ml-4 w-6 h-6" />
              <select 
                title="Select City"
                aria-label="Select City"
                className="bg-transparent border-none text-white text-lg font-medium focus:ring-0 w-full p-3 outline-none cursor-pointer appearance-none"
                value={selectedCity}
                onChange={(e) => dispatch(setSelectedCity(e.target.value))}
              >
                <option value="" disabled className="text-black">Choose your city</option>
                {cities.map(city => (
                  <option key={city.id} value={city.id} className="text-black">{city.name}, {city.state}</option>
                ))}
              </select>
            </div>
          </div>
        </motion.div>
      </section>

      {/* MOVIES GRID */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="flex justify-between items-end mb-10">
          <div>
            <h2 className="text-3xl font-bold text-neutral-900 dark:text-white mb-2">Now Showing</h2>
            <p className="text-neutral-500 dark:text-neutral-400 font-medium">Trending movies tailored for you</p>
          </div>
          <button className="text-primary-600 dark:text-primary-400 font-semibold hover:underline hidden sm:block">
            View All Movies &rarr;
          </button>
        </div>

        {loading ? (
          <div className="flex justify-center items-center py-20">
            <Loader className="w-10 h-10 text-primary-500 animate-spin" />
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8">
            <AnimatePresence>
              {movies.map((movie, index) => (
                <motion.div
                  key={movie.id}
                  onClick={() => navigate(`/movies/${movie.id}`)}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="group relative flex flex-col glass-card bg-white dark:bg-neutral-900/40 rounded-3xl overflow-hidden hover:shadow-2xl hover:shadow-primary-500/10 cursor-pointer"
                >
                  <div className="relative aspect-[2/3] overflow-hidden">
                    <img 
                      src={`https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=800&auto=format&fit=crop&sig=${movie.id}`} 
                      alt={movie.title}
                      className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-in-out"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center">
                      <PlayCircle className="w-16 h-16 text-white drop-shadow-lg scale-50 group-hover:scale-100 transition-all duration-300" />
                    </div>
                    <div className="absolute bottom-4 left-4 right-4 flex gap-2">
                       <span className="bg-primary-500/80 backdrop-blur-md text-white text-xs font-bold px-3 py-1.5 rounded-full uppercase tracking-wider">{movie.genre || "Drama"}</span>
                    </div>
                  </div>
                  <div className="flex flex-1 flex-col p-6">
                    <h3 className="font-bold text-xl text-neutral-900 dark:text-white mb-3 line-clamp-1">{movie.title}</h3>
                    <div className="flex flex-wrap items-center text-sm text-neutral-500 dark:text-neutral-400 font-medium mb-2 gap-3">
                      <div className="flex items-center gap-1"><Clock className="w-4 h-4"/> {movie.running_time || 120}m</div>
                      <div className="flex items-center gap-1 text-primary-600 dark:text-primary-400 bg-primary-500/10 px-2 py-0.5 rounded text-xs">{movie.rating?.toUpperCase() || 'UA'}</div>
                    </div>
                    <p className="mb-4 min-h-[2.5rem] text-sm font-medium text-neutral-500 dark:text-neutral-400 line-clamp-2">
                      {formatMovieLanguages(movie)}
                    </p>
                    <div className="mt-auto flex gap-2">
                      <button onClick={(e) => { e.stopPropagation(); navigate(`/movies/${movie.id}`) }} className="flex-1 py-2.5 rounded-xl border-2 border-neutral-300 dark:border-neutral-700 text-neutral-700 dark:text-neutral-300 font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-all text-sm">
                        Read More
                      </button>
                      <button onClick={(e) => { e.stopPropagation(); navigate(`/movies/${movie.id}/shows`) }} className="flex-1 py-2.5 rounded-xl border-2 border-primary-500/50 text-primary-600 dark:text-primary-400 font-bold hover:bg-primary-500 hover:text-white hover:border-transparent transition-all text-sm">
                        Book Tickets
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>

            {!loading && movies.length === 0 && (
              <div className="col-span-full py-20 text-center text-neutral-500">
                <Film className="w-16 h-16 mx-auto mb-4 opacity-50" />
                <p className="text-xl font-medium">No movies with scheduled shows are available in this city right now.</p>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  )
}
