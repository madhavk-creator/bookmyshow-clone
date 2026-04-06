import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../utils/api'
import { showApiErrorToast, showSuccessToast } from '../utils/toast'
import { useConfirm } from '../components/ConfirmProvider'
import { Loader, Ticket, Clock, CheckCircle, XCircle, MapPin, Film, Star, X } from 'lucide-react'
import { useCancelBookingMutation, useGetBookingsQuery } from '../store/apiSlice'

export default function UserBookings() {
  const confirm = useConfirm()
  const navigate = useNavigate()
  const [cancellingBookingId, setCancellingBookingId] = useState(null)
  const [cancelBooking] = useCancelBookingMutation()
  
  const [reviewModal, setReviewModal] = useState({ isOpen: false, movieId: null, movieTitle: '' })
  const [reviewForm, setReviewForm] = useState({ rating: 5, description: '' })
  const [submittingReview, setSubmittingReview] = useState(false)
  const { data: bookingsData, isLoading, isFetching } = useGetBookingsQuery()
  const bookings = bookingsData?.bookings || []
  const loading = isLoading || isFetching

  const handleReviewSubmit = async (e) => {
    e.preventDefault()
    setSubmittingReview(true)
    try {
      await api.post(`/api/v1/movies/${reviewModal.movieId}/reviews`, {
        review: reviewForm
      })
      showSuccessToast('Review submitted successfully!')
      setReviewModal({ isOpen: false, movieId: null, movieTitle: '' })
      setReviewForm({ rating: 5, description: '' })
    } catch (err) {
      showApiErrorToast(err, 'Failed to submit review')
    } finally {
      setSubmittingReview(false)
    }
  }

  const formatDateTime = (t) => {
    const d = new Date(t)
    return d.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) + ' at ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  const canCancelBooking = (booking) => (
    (booking.status === 'pending' || booking.status === 'confirmed') &&
    new Date(booking.show?.start_time).getTime() > Date.now()
  )

  const handleCancelBooking = async (booking) => {
    const confirmed = await confirm({
      title: 'Cancel Booking?',
      message: `Cancel your booking for ${booking.show?.movie?.title}? Seats will be released if the show has not started yet.`,
      confirmText: 'Cancel Booking',
      cancelText: 'Keep Booking',
      tone: 'danger',
    })
    if (!confirmed) return

    setCancellingBookingId(booking.id)
    try {
      await cancelBooking(booking.id).unwrap()
      showSuccessToast('Booking cancelled.')
    } catch (err) {
      showApiErrorToast(err, 'Failed to cancel booking')
    } finally {
      setCancellingBookingId(null)
    }
  }

  const openBookingSummary = (bookingId) => {
    navigate(`/checkout/${bookingId}`)
  }

  if (loading) return <div className="flex justify-center items-center min-h-[60vh]"><Loader className="w-10 h-10 animate-spin text-primary-500" /></div>

  return (
    <div className="bg-neutral-50 dark:bg-[#0b090f] min-h-screen py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-neutral-900 dark:text-white mb-8 flex items-center gap-3">
          <Ticket className="w-8 h-8 text-primary-500" /> My Bookings
        </h1>

        {bookings.length === 0 ? (
          <div className="glass-card py-20 text-center rounded-3xl border border-dashed border-neutral-300 dark:border-neutral-700">
             <Ticket className="w-16 h-16 mx-auto text-neutral-300 dark:text-neutral-700 mb-4" />
             <p className="text-xl font-medium text-neutral-500">You haven't booked any tickets yet.</p>
          </div>
        ) : (
          <div className="space-y-6">
            {bookings.map(booking => {
               const StatusIcon = booking.status === 'confirmed' ? CheckCircle : booking.status === 'cancelled' ? XCircle : Clock
               const statusColor = booking.status === 'confirmed' ? 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20' : booking.status === 'cancelled' ? 'text-red-500 bg-red-500/10 border-red-500/20' : 'text-amber-500 bg-amber-500/10 border-amber-500/20'

               return (
                 <div
                   key={booking.id}
                   onClick={() => openBookingSummary(booking.id)}
                   className="glass-card bg-white dark:bg-neutral-900/40 rounded-2xl p-6 border border-neutral-200 dark:border-neutral-800 flex flex-col md:flex-row gap-6 items-start md:items-center hover:border-primary-500/20 transition-colors cursor-pointer"
                 >
                   <div className="flex-1 space-y-4 w-full">
                     <div className="flex justify-between items-start">
                       <div>
                         <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-widest border mb-3 ${statusColor}`}>
                           <StatusIcon className="w-3.5 h-3.5" /> {booking.status}
                         </span>
                         <h3 className="text-xl font-bold text-neutral-900 dark:text-white flex items-center gap-2">
                           <Film className="w-5 h-5 text-neutral-400" /> {booking.show?.movie?.title}
                         </h3>
                       </div>
                       <div className="text-right">
                         <p className="text-xs text-neutral-500 font-bold uppercase tracking-wider mb-1">Amount</p>
                         <p className="text-lg font-black text-neutral-900 dark:text-white">₹{parseFloat(booking.total_amount).toFixed(2)}</p>
                       </div>
                     </div>
                     
                     <div className="grid grid-cols-2 gap-4 text-sm font-medium text-neutral-600 dark:text-neutral-400 bg-neutral-50 dark:bg-neutral-800/50 p-4 rounded-xl border border-neutral-200 dark:border-neutral-700">
                       <div className="flex items-start gap-2">
                         <Clock className="w-4 h-4 mt-0.5" />
                         <div><p className="text-[10px] uppercase font-bold text-neutral-500 tracking-wider">Showtime</p>{formatDateTime(booking.show?.start_time)}</div>
                       </div>
                       <div className="flex items-start gap-2">
                         <MapPin className="w-4 h-4 mt-0.5" />
                         <div><p className="text-[10px] uppercase font-bold text-neutral-500 tracking-wider">Theatre</p>{booking.show?.screen?.theatre?.name}</div>
                       </div>
                     </div>
                   </div>

                   <div className="flex w-full md:w-auto flex-col gap-2 shrink-0 border-t md:border-t-0 md:border-l border-neutral-200 dark:border-neutral-800 pt-4 md:pt-0 md:pl-6">
                     <p className="text-sm text-neutral-500 font-bold mb-1 text-center md:text-left">{booking.tickets_count} Tickets</p>
                     
                     {booking.status === 'confirmed' && (
                       <button
                         onClick={(event) => {
                           event.stopPropagation()
                           setReviewModal({ isOpen: true, movieId: booking.show.movie.id, movieTitle: booking.show.movie.title })
                         }}
                         className="px-6 py-2.5 bg-neutral-100 dark:bg-neutral-800 hover:bg-primary-500/10 text-neutral-900 dark:text-primary-400 rounded-xl font-bold transition-all border border-transparent hover:border-primary-500/20 text-sm whitespace-nowrap flex items-center justify-center gap-2"
                       >
                         <Star className="w-4 h-4" /> Write Review
                       </button>
                     )}
                     {canCancelBooking(booking) && (
                       <button
                         onClick={(event) => {
                           event.stopPropagation()
                           handleCancelBooking(booking)
                         }}
                         disabled={cancellingBookingId === booking.id}
                         className="px-6 py-2.5 bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 rounded-xl font-bold transition-all border border-transparent hover:border-red-500/20 text-sm whitespace-nowrap flex items-center justify-center gap-2 disabled:opacity-50"
                       >
                         {cancellingBookingId === booking.id ? <Loader className="w-4 h-4 animate-spin" /> : 'Cancel Booking'}
                       </button>
                     )}
                   </div>
                 </div>
               )
            })}
          </div>
        )}
      </div>

      {/* Review Modal */}
      {reviewModal.isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm shadow-2xl animate-fade-in">
          <div className="w-full max-w-md glass-card bg-white dark:bg-neutral-900 p-8 rounded-3xl animate-slide-up relative">
             <button onClick={() => setReviewModal({ isOpen: false, movieId: null, movieTitle: '' })} className="absolute top-6 right-6 p-2 rounded-full bg-neutral-100 dark:bg-neutral-800 text-neutral-500 hover:text-neutral-900 dark:hover:text-white transition-all"><X className="w-4 h-4" /></button>
             
             <h2 className="text-2xl font-bold text-neutral-900 dark:text-white mb-2">Write a Review</h2>
             <p className="text-neutral-500 dark:text-neutral-400 mb-6 text-sm">How was your experience watching <span className="font-bold text-neutral-700 dark:text-neutral-300">"{reviewModal.movieTitle}"</span>?</p>
             
             <form onSubmit={handleReviewSubmit} className="space-y-6">
               <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-3">Rating</label>
                  <div className="flex gap-2">
                    {[1, 2, 3, 4, 5].map(star => (
                      <button 
                        key={star} 
                        type="button" 
                        onClick={() => setReviewForm(prev => ({ ...prev, rating: star }))}
                        className="p-1 cursor-pointer transition-transform hover:scale-110 focus:outline-none"
                      >
                         <Star className={`w-8 h-8 ${star <= reviewForm.rating ? 'fill-amber-400 text-amber-400' : 'text-neutral-300 dark:text-neutral-700'}`} />
                      </button>
                    ))}
                  </div>
               </div>

               <div>
                 <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-2">Review (optional)</label>
                 <textarea 
                   rows="4" 
                   value={reviewForm.description}
                   onChange={e => setReviewForm(prev => ({ ...prev, description: e.target.value }))}
                   className="w-full bg-neutral-50 dark:bg-neutral-800/50 border border-neutral-200 dark:border-neutral-700 rounded-xl px-4 py-3 text-neutral-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500/50 resize-none transition-all"
                   placeholder="What did you think of the movie?"
                 />
               </div>

               <button 
                 type="submit" 
                 disabled={submittingReview}
                 className="w-full py-3 bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white rounded-xl font-bold shadow-lg shadow-primary-500/30 transition-all hover:scale-105 active:scale-95 disabled:opacity-50 flex justify-center"
               >
                 {submittingReview ? <Loader className="w-5 h-5 animate-spin" /> : 'Submit Review'}
               </button>
             </form>
          </div>
        </div>
      )}
    </div>
  )
}
