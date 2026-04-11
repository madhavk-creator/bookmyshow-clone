import { useState, useEffect, useCallback } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { Clock, Star, ChevronLeft, ChevronRight, MapPin, Ticket } from 'lucide-react'

// Unique cinematic Unsplash images seeded per-movie
const BACKDROP_IMAGES = [
  'photo-1489599849927-2ee91cede3ba',
  'photo-1536440136628-849c177e76a1',
  'photo-1440404653325-ab127d49abc1',
  'photo-1517604931442-7e0c8ed2963c',
  'photo-1485846234645-a62644f84728',
  'photo-1478720568477-152d9b164e26',
  'photo-1524712245354-2c4e5e7121c0',
  'photo-1595769816263-9b910be24d5f',
]

function getBackdropUrl(movieId, index) {
  const img = BACKDROP_IMAGES[index % BACKDROP_IMAGES.length]
  return `https://images.unsplash.com/${img}?q=80&w=1920&auto=format&fit=crop&sig=${movieId}`
}

const slideVariants = {
  enter: { opacity: 0, scale: 1.08 },
  center: { opacity: 1, scale: 1 },
  exit: { opacity: 0, scale: 0.96 },
}

export default function HeroCarousel({ movies = [], cities = [], selectedCity, onCityChange }) {
  const navigate = useNavigate()
  const [current, setCurrent] = useState(0)
  const [isPaused, setIsPaused] = useState(false)
  const heroMovies = movies.slice(0, 6) // max 6 slides
  const currentIndex = heroMovies.length > 0 ? current % heroMovies.length : 0

  const next = useCallback(() => {
    if (heroMovies.length <= 1) return
    setCurrent(prev => (prev + 1) % heroMovies.length)
  }, [heroMovies.length])

  const prev = useCallback(() => {
    if (heroMovies.length <= 1) return
    setCurrent(prev => (prev - 1 + heroMovies.length) % heroMovies.length)
  }, [heroMovies.length])

  // Auto-advance timer
  useEffect(() => {
    if (isPaused || heroMovies.length <= 1) return
    const timer = setInterval(next, 5000)
    return () => clearInterval(timer)
  }, [isPaused, next, heroMovies.length])

  // Reset slide when movie list changes
  

  if (!heroMovies.length) {
    // Fallback static hero when no movies
    return (
      <section className="relative w-full h-[60vh] min-h-[500px] flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-neutral-900 to-[#0b090f]" />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b090f] via-transparent to-transparent z-10" />
        <div className="relative z-20 text-center px-4 max-w-3xl mx-auto">
          <h1 className="text-5xl md:text-7xl font-bold text-white tracking-tight leading-tight">
            Discover The Best <br/> <span className="text-primary-400">Cinematic Experiences</span>
          </h1>
          <p className="mt-6 text-lg text-neutral-400">Select your city to find nearby theaters and showtimes</p>
          <CitySelector cities={cities} selectedCity={selectedCity} onCityChange={onCityChange} />
        </div>
      </section>
    )
  }

  const movie = heroMovies[currentIndex]

  const formatLanguages = (m) => {
    const labels = Array.isArray(m?.languages)
      ? m.languages.map(l => l?.name || l?.code).filter(Boolean)
      : []
    return labels.length > 0 ? labels.join(' · ') : ''
  }

  return (
    <section
      className="relative w-full h-[65vh] min-h-[520px] overflow-hidden select-none"
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
    >
      {/* Backdrop images */}
      <AnimatePresence mode="sync">
        <motion.div
          key={movie.id}
          variants={slideVariants}
          initial="enter"
          animate="center"
          exit="exit"
          transition={{ duration: 0.8, ease: [0.4, 0, 0.2, 1] }}
          className="absolute inset-0 z-0"
        >
          <div
            className="absolute inset-0 bg-cover bg-center"
            style={{ backgroundImage: `url(${getBackdropUrl(movie.id, currentIndex)})` }}
          />
          {/* Overlays for readability */}
          <div className="absolute inset-0 bg-gradient-to-r from-black/85 via-black/50 to-transparent" />
          <div className="absolute inset-0 bg-gradient-to-t from-[#0b090f] via-transparent to-black/30" />
        </motion.div>
      </AnimatePresence>

      {/* Content */}
      <div className="relative z-20 h-full flex flex-col justify-end pb-16 md:pb-20 px-6 md:px-16 lg:px-24 max-w-7xl mx-auto">
        <AnimatePresence mode="wait">
          <motion.div
            key={movie.id}
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
            className="max-w-2xl"
          >
            {/* Genre badge */}
            <div className="flex items-center gap-3 mb-4">
              <span className="bg-primary-500/80 backdrop-blur-md text-white text-[10px] font-bold px-3 py-1.5 rounded-full uppercase tracking-[0.2em]">
                {movie.genre || 'Drama'}
              </span>
              {movie.rating && (
                <span className="flex items-center gap-1 text-amber-400 text-xs font-bold">
                  <Star className="w-3.5 h-3.5 fill-amber-400" />
                  {movie.rating.toUpperCase()}
                </span>
              )}
            </div>

            {/* Title */}
            <h2 className="text-4xl md:text-6xl font-black text-white leading-[1.1] tracking-tight mb-4 drop-shadow-[0_4px_12px_rgba(0,0,0,0.5)]">
              {movie.title}
            </h2>

            {/* Meta row */}
            <div className="flex flex-wrap items-center gap-4 text-sm text-neutral-300 font-medium mb-6">
              {movie.running_time && (
                <span className="flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-neutral-400" />
                  {movie.running_time} min
                </span>
              )}
              {formatLanguages(movie) && (
                <span className="text-neutral-400">{formatLanguages(movie)}</span>
              )}
            </div>

            {/* CTA buttons */}
            <div className="flex items-center gap-3">
              <button
                onClick={() => navigate(`/movies/${movie.id}/shows`)}
                className="group flex items-center gap-2 px-7 py-3.5 bg-gradient-to-r from-primary-600 to-primary-500 hover:from-primary-500 hover:to-primary-400 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary-500/30 hover:shadow-primary-500/50 transition-all hover:scale-105 active:scale-95 cursor-pointer"
              >
                <Ticket className="w-5 h-5 group-hover:rotate-12 transition-transform" />
                Book Tickets
              </button>
              <button
                onClick={() => navigate(`/movies/${movie.id}`)}
                className="px-7 py-3.5 border-2 border-white/20 text-white rounded-xl font-bold text-sm hover:bg-white/10 hover:border-white/40 transition-all backdrop-blur-sm cursor-pointer"
              >
                View Details
              </button>
            </div>
          </motion.div>
        </AnimatePresence>

        {/* City selector */}
        <div className="mt-8">
          <CitySelector cities={cities} selectedCity={selectedCity} onCityChange={onCityChange} />
        </div>
      </div>

      {/* Navigation arrows */}
      {heroMovies.length > 1 && (
        <>
          <button
            onClick={prev}
            className="absolute left-4 top-1/2 -translate-y-1/2 z-30 p-2.5 rounded-full bg-black/30 hover:bg-black/60 backdrop-blur-md text-white/70 hover:text-white border border-white/10 transition-all cursor-pointer"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={next}
            className="absolute right-4 top-1/2 -translate-y-1/2 z-30 p-2.5 rounded-full bg-black/30 hover:bg-black/60 backdrop-blur-md text-white/70 hover:text-white border border-white/10 transition-all cursor-pointer"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </>
      )}

      {/* Dot indicators */}
      {heroMovies.length > 1 && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-30 flex items-center gap-2">
          {heroMovies.map((m, i) => (
            <button
              key={m.id}
              onClick={() => setCurrent(i)}
              className={`transition-all rounded-full cursor-pointer ${
                i === currentIndex
                  ? 'w-8 h-2 bg-primary-500 shadow-md shadow-primary-500/40'
                  : 'w-2 h-2 bg-white/30 hover:bg-white/60'
              }`}
            />
          ))}
        </div>
      )}

      {/* Progress bar */}
      {heroMovies.length > 1 && !isPaused && (
        <div className="absolute bottom-0 left-0 right-0 z-30 h-[2px] bg-white/5">
          <motion.div
            key={currentIndex}
            className="h-full bg-primary-500/60"
            initial={{ width: '0%' }}
            animate={{ width: '100%' }}
            transition={{ duration: 5, ease: 'linear' }}
          />
        </div>
      )}
    </section>
  )
}

function CitySelector({ cities, selectedCity, onCityChange }) {
  if (!cities.length) return null
  return (
    <div className="inline-flex items-center gap-2 glass-card px-3 py-2 rounded-2xl backdrop-blur-xl bg-black/40 border-white/10">
      <MapPin className="text-primary-400 w-5 h-5 shrink-0" />
      <select
        title="Select City"
        aria-label="Select City"
        className="bg-transparent border-none text-white text-sm font-medium focus:ring-0 outline-none cursor-pointer appearance-none pr-6"
        value={selectedCity || ''}
        onChange={(e) => onCityChange(e.target.value)}
      >
        <option value="" disabled className="text-black">Choose your city</option>
        {cities.map(city => (
          <option key={city.id} value={city.id} className="text-black">{city.name}, {city.state}</option>
        ))}
      </select>
    </div>
  )
}
