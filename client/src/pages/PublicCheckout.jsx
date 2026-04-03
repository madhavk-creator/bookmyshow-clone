import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { api } from '../utils/api'
import { showApiErrorToast, showSuccessToast } from '../utils/toast'
import { Loader, CheckCircle, CreditCard, Film, Calendar, MapPin, X } from 'lucide-react'

export default function PublicCheckout() {
  const { bookingId } = useParams()
  const navigate = useNavigate()
  
  const [booking, setBooking] = useState(null)
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)

  useEffect(() => {
    async function fetchBooking() {
      try {
        const { data } = await api.get(`/api/v1/bookings/${bookingId}`)
        setBooking(data)
      } catch (err) {
        showApiErrorToast(err, 'Failed to fetch booking details')
      } finally {
        setLoading(false)
      }
    }
    fetchBooking()
  }, [bookingId])

  const handleConfirmPayment = async () => {
    setProcessing(true)
    try {
      const { data } = await api.post(`/api/v1/bookings/${bookingId}/confirm_payment`)
      setBooking(data)
      showSuccessToast('Payment successful! Your tickets are confirmed.')
    } catch (err) {
      showApiErrorToast(err, 'Payment failed')
    } finally {
      setProcessing(false)
    }
  }

  const handleCancel = async () => {
    if (!window.confirm("Are you sure you want to cancel this booking?")) return
    setProcessing(true)
    try {
      const { data } = await api.post(`/api/v1/bookings/${bookingId}/cancel`)
      setBooking(data)
      showSuccessToast('Booking cancelled.')
    } catch (err) {
      showApiErrorToast(err, 'Failed to cancel')
    } finally {
      setProcessing(false)
    }
  }

  const formatTime = (t) => new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const formatDate = (d) => new Date(d).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })

  if (loading) return <div className="flex justify-center items-center h-[70vh]"><Loader className="w-10 h-10 animate-spin text-primary-500" /></div>
  if (!booking) return <div className="text-center py-20 text-neutral-500">Booking not found</div>

  const isConfirmed = booking.status === 'confirmed'
  const isCancelled = booking.status === 'cancelled'

  return (
    <div className="bg-neutral-50 dark:bg-[#0b090f] min-h-screen py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto space-y-8">
        
        {/* Status Banner */}
        {isConfirmed && (
          <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-2xl p-6 flex flex-col items-center text-center animate-slide-up">
            <CheckCircle className="w-16 h-16 text-emerald-500 mb-4" />
            <h2 className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">Booking Confirmed!</h2>
            <p className="text-neutral-600 dark:text-neutral-300 mt-2">Your tickets have been sent to your email. See you at the movies!</p>
          </div>
        )}

        {isCancelled && (
          <div className="bg-red-500/10 border border-red-500/30 rounded-2xl p-6 flex flex-col items-center text-center">
            <X className="w-16 h-16 text-red-500 mb-4" />
            <h2 className="text-2xl font-bold text-red-600 dark:text-red-400">Booking Cancelled</h2>
            <p className="text-neutral-600 dark:text-neutral-300 mt-2">This booking was cancelled. Any held seats have been released.</p>
          </div>
        )}

        <div className="glass-card bg-white dark:bg-neutral-900/40 rounded-3xl overflow-hidden shadow-xl border border-neutral-200 dark:border-neutral-800">
          <div className="p-8">
            <h1 className="text-3xl font-bold text-neutral-900 dark:text-white mb-8 border-b border-neutral-200 dark:border-neutral-800 pb-4">Booking Summary</h1>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
              <div className="space-y-6">
                <div className="flex items-start gap-4">
                  <div className="p-3 bg-primary-500/10 text-primary-600 dark:text-primary-400 rounded-xl">
                    <Film className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-sm text-neutral-500 font-bold uppercase tracking-wider mb-1">Movie</p>
                    <h3 className="text-xl font-bold text-neutral-900 dark:text-white">{booking.show?.movie?.title}</h3>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="p-3 bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400 rounded-xl">
                    <Calendar className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-sm text-neutral-500 font-bold uppercase tracking-wider mb-1">Date & Time</p>
                    <p className="text-lg font-bold text-neutral-900 dark:text-white">{formatDate(booking.show?.start_time)}</p>
                    <p className="text-neutral-600 dark:text-neutral-400">{formatTime(booking.show?.start_time)}</p>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="p-3 bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400 rounded-xl">
                    <MapPin className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-sm text-neutral-500 font-bold uppercase tracking-wider mb-1">Theatre</p>
                    <p className="text-lg font-bold text-neutral-900 dark:text-white">{booking.show?.screen?.theatre?.name}</p>
                    <p className="text-neutral-600 dark:text-neutral-400">{booking.show?.screen?.name}</p>
                  </div>
                </div>
              </div>

              <div className="bg-neutral-50 dark:bg-neutral-800/50 p-6 rounded-2xl border border-neutral-200 dark:border-neutral-700">
                <h4 className="text-sm text-neutral-500 font-bold uppercase tracking-wider mb-4 border-b border-neutral-200 dark:border-neutral-700 pb-2">Tickets ({booking.tickets?.length})</h4>
                <div className="space-y-3 mb-6">
                  {booking.tickets?.map(t => (
                    <div key={t.id} className="flex justify-between items-center text-sm font-medium text-neutral-700 dark:text-neutral-300">
                      <span>{t.seat_label} ({t.section_name})</span>
                      <span>₹{parseFloat(t.price).toFixed(2)}</span>
                    </div>
                  ))}
                </div>
                <div className="border-t border-neutral-300 dark:border-neutral-600 pt-4 flex justify-between items-center relative">
                   <span className="text-lg font-bold text-neutral-900 dark:text-white">Total Amount</span>
                   <span className="text-2xl font-black text-primary-600 dark:text-primary-400 relative">
                     {isConfirmed && <div className="absolute -inset-2 bg-primary-500/20 blur-xl rounded-full z-0" />}
                     <span className="relative z-10">₹{parseFloat(booking.total_amount).toFixed(2)}</span>
                   </span>
                </div>
              </div>
            </div>

            {booking.status === 'pending' && (
              <div className="flex flex-col sm:flex-row gap-4 pt-6 border-t border-neutral-200 dark:border-neutral-800">
                <button 
                  onClick={handleCancel}
                  disabled={processing}
                  className="flex-1 px-6 py-4 bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 rounded-xl font-bold transition-all disabled:opacity-50"
                >
                  Cancel Booking
                </button>
                <button 
                  onClick={handleConfirmPayment}
                  disabled={processing}
                  className="flex-[2] px-6 py-4 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-white rounded-xl font-bold shadow-lg shadow-emerald-500/30 transition-all hover:scale-105 active:scale-95 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {processing ? <Loader className="w-6 h-6 animate-spin" /> : <><CreditCard className="w-6 h-6" /> Confirm Payment</>}
                </button>
              </div>
            )}
            
            {isConfirmed && (
               <div className="mt-8 flex justify-center">
                 <button onClick={() => navigate('/user/bookings')} className="px-8 py-3 bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 text-neutral-900 dark:text-white font-bold rounded-xl transition-all">
                   View My Bookings
                 </button>
               </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
