import { useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Loader, Clock, MapPin, PlayCircle, Film } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux'
import { useGetCitiesQuery, useGetMoviesQuery } from '../store/apiSlice'
import { selectSelectedCity, setSelectedCity } from '../store/citySlice'
import { SkeletonCard } from '../components/ui/Skeleton'
import HeroCarousel from '../components/ui/HeroCarousel'


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
      {/* HERO CAROUSEL */}
      <HeroCarousel
        movies={movies}
        cities={cities}
        selectedCity={selectedCity}
        onCityChange={(id) => dispatch(setSelectedCity(id))}
      />

      {/* MOVIES GRID */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="flex justify-between items-end mb-10">
          <div>
            <h2 className="text-3xl font-bold text-neutral-900 dark:text-white mb-2">Now Showing</h2>
            <p className="text-neutral-500 dark:text-neutral-400 font-medium">Trending movies tailored for you</p>
          </div>
          {/* <button className="text-primary-600 dark:text-primary-400 font-semibold hover:underline hidden sm:block">
            View All Movies &rarr;
          </button> */}
        </div>

        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8">
            {[...Array(8)].map((_, i) => (
              <SkeletonCard key={i} className="" />
            ))}
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
