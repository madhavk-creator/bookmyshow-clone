import { useParams, useNavigate } from 'react-router-dom'
import { Loader, Star, Clock, Ticket } from 'lucide-react'
import { useGetMovieQuery, useGetMovieReviewsQuery } from '../store/apiSlice'

export default function PublicMovieDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { data: movie, isLoading: movieLoading, isFetching: movieFetching } = useGetMovieQuery(id, { skip: !id })
  const {
    data: reviewsData = { reviews: [], average_rating: 0, total_reviews: 0 },
    isLoading: reviewsLoading,
    isFetching: reviewsFetching,
  } = useGetMovieReviewsQuery({ movieId: id, perPage: 10 }, { skip: !id })
  const loading = movieLoading || movieFetching || reviewsLoading || reviewsFetching

  if (loading) return <div className="flex justify-center py-20"><Loader className="w-10 h-10 animate-spin text-primary-500" /></div>
  if (!movie) return <div className="text-center py-20 text-neutral-500">Movie not found</div>

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-[#0b090f] pb-20 fade-in">
      {/* Hero Banner with Movie Poster & Info */}
      <div className="relative w-full h-[50vh] min-h-[400px]">
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=2670&auto=format&fit=crop')] opacity-30 bg-cover bg-center" />
        <div className="absolute inset-0 bg-gradient-to-t from-neutral-50 dark:from-[#0b090f] via-neutral-900/50 dark:via-[#0b090f]/80 to-transparent" />

        <div className="absolute bottom-0 left-0 w-full px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto pb-10 flex flex-col md:flex-row items-end gap-8 z-10 text-neutral-900 dark:text-white">
          <img src={`https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=800&auto=format&fit=crop&sig=${movie.id}`} alt={movie.title} className="w-48 h-72 rounded-2xl shadow-2xl object-cover hidden md:block border-4 border-white/10" />
          <div className="flex-1 space-y-4">
            <div className="flex flex-wrap items-center gap-3 text-white">
              <span className="bg-primary-500 text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider">{movie.genre}</span>
              <span className="flex items-center gap-1 text-amber-400 bg-amber-500/20 px-2 py-1 rounded-lg text-sm font-bold"><Star className="w-4 h-4 fill-amber-400" /> {reviewsData.average_rating ? Number(reviewsData.average_rating).toFixed(1) : 'New'}</span>
            </div>
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight text-white glow-text">{movie.title}</h1>
            <div className="flex flex-wrap items-center gap-4 text-sm font-medium text-neutral-200">
              <span className="flex items-center gap-1"><Clock className="w-4 h-4" /> {movie.running_time} mins</span>
              <span className="bg-white/20 backdrop-blur-md px-2 py-1 rounded">{movie.rating?.toUpperCase()}</span>
              <span>{new Date(movie.release_date).toLocaleDateString()}</span>
              <span>{movie.languages?.map((language) => language?.name || language?.code).filter(Boolean).join(', ') || 'Languages TBA'}</span>
            </div>
          </div>
          <div className="w-full md:w-auto">
            <button onClick={() => navigate(`/movies/${movie.id}/shows`)} className="w-full md:w-auto px-8 py-4 bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white rounded-xl font-bold text-lg shadow-lg shadow-primary-500/30 transition-all hover:scale-105 active:scale-95 flex items-center justify-center gap-2 cursor-pointer">
              <Ticket className="w-6 h-6" /> Book Tickets
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 grid grid-cols-1 lg:grid-cols-3 gap-12">
        <div className="lg:col-span-2 space-y-12">
          {/* About */}
          <section>
            <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-4">About the Movie</h2>
            <p className="text-neutral-600 dark:text-neutral-300 leading-relaxed text-lg">{movie.description}</p>
          </section>

          {/* Cast */}
          {movie.cast_members?.length > 0 && (
            <section>
              <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">Cast & Crew</h2>
              <div className="flex gap-6 overflow-x-auto pb-4 snap-x">
                {movie.cast_members.map((member, i) => (
                  <div key={i} className="flex flex-col items-center gap-3 min-w-[100px] snap-start">
                    <div className="w-24 h-24 rounded-full bg-neutral-200 dark:bg-neutral-800 overflow-hidden flex items-center justify-center border-2 border-neutral-200 dark:border-neutral-700 shadow-sm">
                      <img src={`https://i.pravatar.cc/150?u=${member.name}`} alt={member.name} className="w-full h-full object-cover" />
                    </div>
                    <div className="text-center">
                      <p className="font-bold text-neutral-900 dark:text-white text-sm">{member.name}</p>
                      <p className="text-xs text-neutral-500 uppercase font-medium">{member.role === 'director' ? 'Director' : member.character_name || 'Actor'}</p>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Reviews */}
          <section>
            <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">Reviews</h2>
            <div className="space-y-4">
              {reviewsData.reviews?.length > 0 ? reviewsData.reviews.map(review => (
                <div key={review.id} className="glass-card p-6 border border-neutral-200 dark:border-neutral-800/50 rounded-2xl hover:border-primary-500/30 transition-colors">
                  <div className="flex items-center gap-4 mb-3">
                    <div className="flex gap-1 text-amber-500">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star key={i} className={`w-4 h-4 ${i < review.rating ? 'fill-amber-500' : 'text-neutral-300 dark:text-neutral-700'}`} />
                      ))}
                    </div>
                    <p className="text-sm font-bold text-neutral-900 dark:text-white">{review.user?.name || 'Anonymous'}</p>
                    <span className="text-sm font-bold text-neutral-900 dark:text-white">{review.rating}/5</span>
                  </div>
                  <p className="text-neutral-700 dark:text-neutral-300 italic">"{review.description}"</p>
                </div>
              )) : <p className="text-neutral-500 dark:text-neutral-400 font-medium bg-neutral-100 dark:bg-neutral-800/50 p-6 rounded-2xl text-center border border-dashed border-neutral-300 dark:border-neutral-700">No reviews yet. Be the first to review after watching!</p>}
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}
