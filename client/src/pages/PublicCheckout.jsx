import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { showApiErrorToast, showSuccessToast } from '../utils/toast'
import { useConfirm } from '../components/ConfirmProvider'
import { Loader, CheckCircle, CreditCard, Film, Calendar, MapPin, X } from 'lucide-react'
import { useApplyBookingCouponMutation, useCancelBookingMutation, useConfirmBookingPaymentMutation, useGetBookingQuery, useGetCouponsQuery } from '../store/apiSlice'

export default function PublicCheckout() {
  const { bookingId } = useParams()
  const navigate = useNavigate()
  const confirm = useConfirm()
  const [confirmBookingPayment] = useConfirmBookingPaymentMutation()
  const [cancelBooking] = useCancelBookingMutation()
  const [applyBookingCoupon] = useApplyBookingCouponMutation()
  const [processing, setProcessing] = useState(false)
  const [manualCode, setManualCode] = useState('')
  const [applyingCoupon, setApplyingCoupon] = useState(false)
  const { data: booking, isLoading: bookingLoading } = useGetBookingQuery(bookingId, { skip: !bookingId })
  const { data: coupons = [], isLoading: couponsLoading } = useGetCouponsQuery()
  const loading = bookingLoading || couponsLoading

  const handleConfirmPayment = async () => {
    setProcessing(true)
    try {
      await confirmBookingPayment(bookingId).unwrap()
      showSuccessToast('Payment successful! Your tickets are confirmed.')
    } catch (err) {
      showApiErrorToast(err, 'Payment failed')
    } finally {
      setProcessing(false)
    }
  }

  const handleCancel = async () => {
    const confirmed = await confirm({
      title: 'Cancel Booking?',
      message: 'This will cancel the booking and release the seats back into inventory if the show has not started yet.',
      confirmText: 'Cancel Booking',
      cancelText: 'Keep Booking',
      tone: 'danger',
    })
    if (!confirmed) return

    setProcessing(true)
    try {
      await cancelBooking(bookingId).unwrap()
      showSuccessToast('Booking cancelled.')
    } catch (err) {
      showApiErrorToast(err, 'Failed to cancel')
    } finally {
      setProcessing(false)
    }
  }

  const handleApplyCoupon = async (codeToApply) => {
    const code = codeToApply || manualCode
    if (!code.trim()) return
    setApplyingCoupon(true)
    try {
      await applyBookingCoupon({ bookingId, couponCode: code.trim() }).unwrap()
      setManualCode('')
      if (code.trim()) {
        showSuccessToast('Coupon applied successfully!')
      } else {
        showSuccessToast('Coupon removed.')
      }
    } catch (err) {
      showApiErrorToast(err, 'Invalid or inapplicable coupon')
    } finally {
      setApplyingCoupon(false)
    }
  }

  const formatTime = (t) => new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const formatDate = (d) => new Date(d).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })

  if (loading) return <div className="flex justify-center items-center h-[70vh]"><Loader className="w-10 h-10 animate-spin text-primary-500" /></div>
  if (!booking) return <div className="text-center py-20 text-neutral-500">Booking not found</div>

  const isConfirmed = booking.status === 'confirmed'
  const isCancelled = booking.status === 'cancelled'
  const isExpired = booking.status === 'expired'
  const canCancel = (booking.status === 'pending' || booking.status === 'confirmed') &&
    new Date(booking.show?.start_time).getTime() > Date.now()

  return (
    <div className="bg-neutral-50 dark:bg-[#0b090f] min-h-screen py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto space-y-8">
        
        {/* Status Banner */}
        {isConfirmed && (
          <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-2xl p-6 flex flex-col items-center text-center animate-slide-up">
            <CheckCircle className="w-16 h-16 text-emerald-500 mb-4" />
            <h2 className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">Booking Confirmed!</h2>
            <p className="text-neutral-600 dark:text-neutral-300 mt-2">Your tickets have been sent to your email. Have a great time at the movies!</p>
          </div>
        )}

        {isCancelled && (
          <div className="bg-red-500/10 border border-red-500/30 rounded-2xl p-6 flex flex-col items-center text-center">
            <X className="w-16 h-16 text-red-500 mb-4" />
            <h2 className="text-2xl font-bold text-red-600 dark:text-red-400">Booking Cancelled</h2>
            <p className="text-neutral-600 dark:text-neutral-300 mt-2">This booking was cancelled. Your refund will be processed within 5-7 business days.</p>
          </div>
        )}

        {isExpired && (
          <div className="bg-amber-500/10 border border-amber-500/30 rounded-2xl p-6 flex flex-col items-center text-center">
            <X className="w-16 h-16 text-amber-500 mb-4" />
            <h2 className="text-2xl font-bold text-amber-600 dark:text-amber-400">Booking Expired</h2>
            <p className="text-neutral-600 dark:text-neutral-300 mt-2">Payment confirmation was not received within the booking window.</p>
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
                   <div className="text-right">
                     {booking.coupon && (
                       <span className="text-sm font-bold text-neutral-400 line-through mr-2">
                         ₹{booking.tickets?.reduce((acc, t) => acc + parseFloat(t.price), 0).toFixed(2)}
                       </span>
                     )}
                     <span className="text-2xl font-black text-primary-600 dark:text-primary-400 relative">
                       {isConfirmed && <div className="absolute -inset-2 bg-primary-500/20 blur-xl rounded-full z-0" />}
                       <span className="relative z-10">₹{parseFloat(booking.total_amount).toFixed(2)}</span>
                     </span>
                   </div>
                </div>
              </div>
            </div>

            {/* Coupons Section */}
            {booking.status === 'pending' && (
              <div className="mb-8 p-6 bg-neutral-50 dark:bg-neutral-800/20 rounded-2xl border border-neutral-200 dark:border-neutral-800">
                <h4 className="text-lg font-bold text-neutral-900 dark:text-white mb-4">Promotional Offers</h4>
                <div className="flex flex-col sm:flex-row gap-4 mb-6">
                  <input type="text" placeholder="Got a Promocode?" value={manualCode} onChange={e=>setManualCode(e.target.value.toUpperCase())}
                    className="flex-1 px-4 py-3 bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700 rounded-xl outline-none uppercase font-mono font-bold tracking-[0.16em] [font-feature-settings:'zero'_1] text-sm focus:border-primary-500 transition-colors" />
                  <button onClick={() => handleApplyCoupon()} disabled={applyingCoupon || !manualCode.trim()} 
                    className="px-6 py-3 bg-neutral-900 dark:bg-white text-white dark:text-neutral-900 rounded-xl font-bold disabled:opacity-50 transition-all flex items-center justify-center gap-2">
                    {applyingCoupon ? <Loader className="w-5 h-5 animate-spin" /> : 'Apply'}
                  </button>
                </div>
                
                {booking.coupon && (
                  <div className="bg-emerald-500/10 border border-emerald-500/20 p-4 rounded-xl flex justify-between items-center mb-6">
                     <div>
                       <span className="text-sm font-bold text-emerald-600 dark:text-emerald-400">Coupon Applied!</span>
                       <p className="text-lg font-black text-emerald-700 dark:text-emerald-300 uppercase tracking-[0.18em] font-mono [font-feature-settings:'zero'_1]">
                         {booking.coupon.code}
                       </p>
                     </div>
                     <button onClick={() => handleApplyCoupon('')} disabled={applyingCoupon} className="text-sm font-bold text-red-500 hover:text-red-600 transition-colors">
                       Remove
                     </button>
                  </div>
                )}

                {coupons.length > 0 && !booking.coupon && (
                  <div className="space-y-3">
                    <p className="text-sm font-bold text-neutral-500 uppercase tracking-wider">Available Coupons</p>
                    {coupons.map(coupon => {
                      const isApplicable = !coupon.minimum_booking_amount || parseFloat(booking.total_amount) >= parseFloat(coupon.minimum_booking_amount)
                      return (
                        <div key={coupon.id} className={`p-4 rounded-xl border flex items-center justify-between transition-all ${isApplicable ? 'bg-white dark:bg-neutral-900 border-primary-500/20 hover:border-primary-500/50' : 'bg-neutral-100 dark:bg-neutral-800/50 border-neutral-200 dark:border-neutral-700 opacity-50'}`}>
                          <div>
                             <div className="flex items-center gap-2 mb-1">
                               <span className="px-2 py-0.5 bg-primary-500/10 text-primary-600 dark:text-primary-400 border border-primary-500/20 text-xs font-black uppercase tracking-[0.16em] font-mono [font-feature-settings:'zero'_1] rounded">
                                 {coupon.code}
                               </span>
                               <span className="font-bold text-neutral-900 dark:text-white">
                                 {coupon.coupon_type === 'percentage' ? `${parseFloat(coupon.discount_percentage)}% OFF` : `₹${parseFloat(coupon.discount_amount)} OFF`}
                               </span>
                             </div>
                             {coupon.minimum_booking_amount && <p className="text-xs text-neutral-500 font-medium">Valid on orders above ₹{parseFloat(coupon.minimum_booking_amount)}</p>}
                          </div>
                          {isApplicable ? (
                            <button onClick={() => handleApplyCoupon(coupon.code)} disabled={applyingCoupon} className="text-sm font-bold text-primary-600 dark:text-primary-400 hover:text-primary-500 transition-colors">
                              Apply
                            </button>
                          ) : (
                            <span className="text-xs font-bold text-neutral-400">Not Applicable</span>
                          )}
                        </div>
                      )
                    })}
                  </div>
                )}
              </div>
            )}

            {booking.status === 'pending' && (
              <div className="flex flex-col sm:flex-row gap-4 pt-6 border-t border-neutral-200 dark:border-neutral-800">
                <button 
                  onClick={handleCancel}
                  disabled={processing || !canCancel}
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
               <div className="mt-8 flex flex-col sm:flex-row justify-center gap-4">
                 {canCancel && (
                   <button
                     onClick={handleCancel}
                     disabled={processing}
                     className="px-8 py-3 bg-red-500/10 hover:bg-red-500/20 text-red-600 dark:text-red-400 font-bold rounded-xl transition-all disabled:opacity-50"
                   >
                     {processing ? 'Cancelling...' : 'Cancel Booking'}
                   </button>
                 )}
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
