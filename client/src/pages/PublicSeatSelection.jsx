import { useEffect, useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { showApiErrorToast, showWarningToast } from '../utils/toast'
import { TransformWrapper, TransformComponent, useControls } from 'react-zoom-pan-pinch'
import { Tooltip } from 'react-tooltip'
import 'react-tooltip/dist/react-tooltip.css'
import { Loader, MapPin, Calendar, Clock, Ticket, ZoomIn, ZoomOut, Maximize, X } from 'lucide-react'
import { useSelector } from 'react-redux'
import { selectCurrentUser } from '../store/authSlice'
import { useCreateBookingMutation, useGetShowQuery, useGetShowSeatsQuery } from '../store/apiSlice'
import { Skeleton } from '../components/ui/Skeleton'
import { BookingStepper } from '../components/ui/BookingStepper'

export default function PublicSeatSelection() {
  const { showId } = useParams()
  const navigate = useNavigate()
  const user = useSelector(selectCurrentUser)
  const [createBooking] = useCreateBookingMutation()
  const [selectedSeats, setSelectedSeats] = useState([])
  const [booking, setBooking] = useState(false)
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    const mq = window.matchMedia('(max-width: 768px)')
    setIsMobile(mq.matches)
    const handler = (e) => setIsMobile(e.matches)
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [])
  const { data: show, isLoading: showLoading } = useGetShowQuery({ showId }, { skip: !showId })
  const { data: seatData, isLoading: seatsLoading, refetch } = useGetShowSeatsQuery(showId, { skip: !showId })
  const loading = showLoading || seatsLoading
  const sections = seatData?.sections || []
  const seats = useMemo(
    () => sections.flatMap((section) => section.seats.map((seat) => ({ ...seat, section }))),
    [sections]
  )

  useEffect(() => {
    setSelectedSeats([])
    setBooking(false)
  }, [showId])

  useEffect(() => {
    if (!seats.length) return

    const seatById = new Map(seats.map((seat) => [seat.id, seat]))
    const heldSeats = seats.filter((seat) => seat.status === 'held_by_you')

    setSelectedSeats((prev) => {
      const preservedAvailableSeats = prev
        .map((seat) => seatById.get(seat.id))
        .filter((seat) => seat?.status === 'available')

      return [ ...heldSeats, ...preservedAvailableSeats ]
    })
  }, [seats])

  let totalRows = 0, totalColumns = 0
  seats.forEach(s => {
    if (s.grid_row > totalRows) totalRows = s.grid_row
    if (s.grid_column > totalColumns) totalColumns = s.grid_column
  })
  totalRows += 1
  totalColumns += 1

  const seatMap = {}
  seats.forEach(s => { seatMap[`${s.grid_row},${s.grid_column}`] = s })

  const handleSeatClick = (seat) => {
    if (seat.status === 'held_by_you') return
    if (seat.status !== 'available') return

    const isSelected = selectedSeats.find(s => s.id === seat.id)
    if (isSelected) {
      setSelectedSeats(prev => prev.filter(s => s.id !== seat.id))
    } else {
      if (selectedSeats.length >= 10) {
        showWarningToast('You can select a maximum of 10 seats.')
        return
      }
      setSelectedSeats(prev => [...prev, seat])
    }
  }

  const handleBook = async () => {
    if (!user) {
      navigate('/login?redirect=' + encodeURIComponent(window.location.pathname))
      return
    }

    setBooking(true)
    try {
      const data = await createBooking({
        show_id: showId,
        seat_ids: selectedSeats.map(s => s.id)
      }).unwrap()
      navigate(`/checkout/${data.id}`)
    } catch (err) {
       showApiErrorToast(err, 'Failed to hold seats. They might have just been booked!')
       await refetch()
       setSelectedSeats([])
    } finally {
      setBooking(false)
    }
  }

  const formatTime = (t) => new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const formatDate = (d) => new Date(d).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
  
  const totalPrice = selectedSeats.reduce((acc, seat) => acc + parseFloat(seat.section.base_price || 0), 0)

  if (loading) return (
    <div className="flex flex-col min-h-screen bg-neutral-50 dark:bg-[#0b090f]">
      <div className="sticky top-0 z-30 bg-white dark:bg-neutral-900 border-b border-neutral-200 dark:border-neutral-800 p-4 shadow-sm">
        <div className="max-w-7xl mx-auto flex flex-col gap-2">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-6 w-96 max-w-full" />
        </div>
      </div>
      <div className="flex-1 p-4 md:p-8 flex justify-center pb-32 mt-10">
        <div className="glass-card p-6 inline-flex flex-col items-center w-full max-w-4xl">
          <div className="flex justify-center mb-12 w-full"><Skeleton className="h-2 w-1/2 rounded-full" /></div>
          <div className="flex flex-col items-center gap-2">
            {[...Array(6)].map((_, r) => (
              <div key={r} className="flex items-center gap-2">
                {[...Array(12)].map((_, c) => (
                   <Skeleton key={c} className="w-8 h-8 rounded" />
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
  if (!show) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-neutral-50 dark:bg-[#0b090f] px-4 text-center">
        <div className="max-w-md">
          <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-3">This show is no longer available</h1>
          <p className="text-neutral-500 dark:text-neutral-400">Please go back and choose another showtime.</p>
        </div>
      </div>
    )
  }

   const Controls = () => {
    const { zoomIn, zoomOut, resetTransform } = useControls();
    return (
      <div className="absolute top-4 right-4 z-40 flex flex-col gap-2 bg-white/80 dark:bg-neutral-900/80 backdrop-blur border border-neutral-200 dark:border-neutral-700 p-1.5 rounded-xl shadow-lg">
        <button onClick={() => zoomIn()} className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors"><ZoomIn className="w-5 h-5 text-neutral-600 dark:text-neutral-300" /></button>
        <button onClick={() => resetTransform()} className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors"><Maximize className="w-5 h-5 text-neutral-600 dark:text-neutral-300" /></button>
        <button onClick={() => zoomOut()} className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors"><ZoomOut className="w-5 h-5 text-neutral-600 dark:text-neutral-300" /></button>
      </div>
    );
  };

  const SeatGrid = () => (
    <div className="flex flex-col items-center justify-center min-w-max min-h-max p-16 md:p-32">
      {/* Screen indicator */}
      <div className="flex justify-center mb-16 w-[600px] max-w-[80vw]">
        <div className="relative w-full">
          <div className="h-4 bg-gradient-to-r from-transparent via-cyan-400/40 dark:via-cyan-600/40 to-transparent rounded-[100%] blur-[3px]" />
          <div className="h-1.5 bg-gradient-to-r from-transparent via-cyan-300 dark:via-cyan-500 to-transparent rounded-full mt-1 shadow-[0_0_20px_rgba(34,211,238,0.5)]" />
          <p className="text-center text-xs font-black uppercase tracking-[0.6em] text-neutral-400 dark:text-cyan-600/60 mt-6 [text-shadow:0_0_10px_rgba(0,0,0,0.5)]">
            Screen
          </p>
        </div>
      </div>

      {/* Grid */}
      <div className="flex flex-col items-center gap-2 select-none">
        {Array.from({ length: totalRows }, (_, row) => (
          <div key={row} className="flex items-center gap-2">
            <div className="w-8 text-right text-xs font-bold text-neutral-400 shrink-0 mr-4 uppercase">
              {String.fromCharCode(65 + row)}
            </div>
            {Array.from({ length: totalColumns }, (_, col) => {
              const seat = seatMap[`${row},${col}`]
              const islounge = seat?.seat_kind === 'lounge'

              if (!seat) {
                return <div key={col} style={{ width: 32, height: 32 }} className="shrink-0" />
              }

              const isHeldByYou = seat.status === 'held_by_you'
              const isAvailable = seat.status === 'available'
              const isSelectable = isAvailable || isHeldByYou
              const isSelected = selectedSeats.some(s => s.id === seat.id)
              const baseColor = seat.section.color_hex || '#8B5CF6'

              return (
                <button
                  key={col}
                  disabled={!isSelectable}
                  onClick={() => handleSeatClick(seat)}
                  className={`relative flex items-center justify-center text-[10px] font-bold transition-all rounded shrink-0 ring-offset-2 dark:ring-offset-[#0b090f]
                    ${!isSelectable
                       ? 'bg-neutral-200 dark:bg-neutral-800 border border-neutral-300 dark:border-neutral-700 cursor-not-allowed opacity-40 hover:opacity-70' 
                       : isSelected
                         ? 'text-white shadow-[0_0_15px_rgba(0,0,0,0.2)] scale-110 z-10 ring-2 ring-primary-500 cursor-pointer'
                         : 'text-white cursor-pointer hover:scale-110 hover:shadow-lg z-10 ring-0 hover:ring-2 hover:ring-white/30'
                    }`}
                  style={{
                    width: islounge ? 74 : 34,
                    height: 34,
                    background: isSelectable
                      ? `linear-gradient(135deg, ${baseColor}90, ${baseColor}30)` 
                      : undefined,
                    border: isSelectable
                      ? `1px solid ${baseColor}` 
                      : undefined,
                    backgroundColor: isSelected ? baseColor : undefined,
                    textShadow: isSelectable || isSelected ? '0 1px 3px rgba(0,0,0,0.8)' : undefined,
                  }}
                  data-tooltip-id="seat-tooltip"
                  data-tooltip-content={`${seat.row_label}${seat.seat_number}||${seat.section.base_price}||${seat.section.name}`}
                >
                  {!isSelectable ? <X className="w-3 h-3 text-neutral-400 opacity-50" /> : seat.seat_number}
                </button>
              )
            })}
            <div className="w-8 text-left text-xs font-bold text-neutral-400 shrink-0 ml-4 uppercase">
              {String.fromCharCode(65 + row)}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <div className="flex flex-col min-h-screen bg-neutral-50 dark:bg-[#0b090f]">
       <BookingStepper currentStep={2} />
       {/* Header */}
       <div className="sticky top-0 z-30 bg-white dark:bg-neutral-900 border-b border-neutral-200 dark:border-neutral-800 p-4 shadow-sm">
         <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-1">{show.movie.title}</h1>
              <div className="flex flex-wrap items-center gap-3 text-sm text-neutral-500 dark:text-neutral-400 font-medium">
                <span className="flex items-center gap-1.5"><Calendar className="w-4 h-4" /> {formatDate(show.start_time)}</span>
                <span className="flex items-center gap-1.5"><Clock className="w-4 h-4" /> {formatTime(show.start_time)}</span>
                <span className="bg-neutral-100 dark:bg-neutral-800 px-2 py-0.5 rounded uppercase">{show.format.code}</span>
                <span className="bg-neutral-100 dark:bg-neutral-800 px-2 py-0.5 rounded uppercase">{show.language.code}</span>
              </div>
            </div>
         </div>
       </div>

       <div className="flex-1 p-4 md:p-8 flex justify-center pb-32 relative">
         <div className="glass-card w-full max-w-6xl h-[65vh] flex flex-col items-center relative overflow-hidden border border-neutral-200 dark:border-neutral-800/50 shadow-2xl">
            {isMobile ? (
              <TransformWrapper initialScale={1} minScale={0.4} maxScale={3.5} wheel={{ step: 0.1 }}>
                <Controls />
                <TransformComponent wrapperStyle={{ width: '100%', height: '100%' }}>
                  <SeatGrid />
                </TransformComponent>
              </TransformWrapper>
            ) : (
              <div className="w-full h-full overflow-auto">
                <SeatGrid />
              </div>
            )}

            {/* Legend */}
            <div className="mt-8 flex flex-wrap justify-center items-center gap-x-6 gap-y-3 text-xs text-neutral-500 font-medium px-6 py-4 glass-card bg-white/50 dark:bg-neutral-900/50 backdrop-blur-md rounded-2xl w-full max-w-4xl mx-auto border border-neutral-200 dark:border-neutral-800">
               <div className="flex items-center gap-2">
                 <div className="w-5 h-5 rounded border-2 border-primary-500 bg-primary-500 shadow-sm" /> Selected
               </div>
               <div className="flex items-center gap-2">
                 <div className="w-5 h-5 rounded border border-primary-500 bg-primary-500/20" /> Available
               </div>
               <div className="flex items-center gap-2">
                 <div className="w-5 h-5 rounded border border-neutral-300 dark:border-neutral-700 bg-neutral-200 dark:bg-neutral-800 flex items-center justify-center"><X className="w-3 h-3 text-neutral-400" /></div> Sold/Blocked
               </div>
               <div className="w-px h-6 bg-neutral-300 dark:bg-neutral-700 hidden sm:block mx-2" />
               {sections.map(sec => (
                 <div key={sec.id} className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full shadow-sm" style={{ backgroundColor: sec.color_hex }} />
                    {sec.name} (₹{sec.base_price || 0})
                 </div>
               ))}
            </div>
         </div>
       </div>

       {/* Tooltip Overlay */}
       <Tooltip id="seat-tooltip" 
          className="z-[60] !bg-neutral-900/95 !backdrop-blur-xl border border-white/10 !rounded-2xl !shadow-[0_20px_40px_rgba(0,0,0,0.3)] !px-4 !py-3"
          render={({ content }) => {
            if (!content) return null
            const [label, price, tier] = content.split('||')
            return (
              <div className="flex flex-col gap-1 items-center min-w-[80px]">
                <span className="text-white font-black text-xl tracking-tight">{label}</span>
                <div className="w-full h-px bg-white/10 my-0.5" />
                <span className="text-primary-400 font-black text-[10px] tracking-widest uppercase">{tier}</span>
                <span className="text-neutral-300 text-sm font-bold mt-0.5">₹ {price}</span>
              </div>
            )
          }}
        />

       {/* Bottom Floating Bar */}
       {selectedSeats.length > 0 && (
         <div className="fixed bottom-0 left-0 right-0 bg-white dark:bg-neutral-900 border-t border-neutral-200 dark:border-neutral-800 p-4 shadow-[0_-10px_40px_rgba(0,0,0,0.1)] z-40 animate-slide-up">
           <div className="max-w-7xl mx-auto flex items-center justify-between">
              <div>
                <p className="text-xs text-neutral-500 uppercase tracking-widest font-bold mb-1">{selectedSeats.length} Tickets Selected</p>
                <div className="flex gap-1 flex-wrap mb-1 max-w-sm">
                  {selectedSeats.map(s => (
                    <span key={s.id} className="text-sm font-bold text-neutral-900 dark:text-white after:content-[','] last:after:content-['']">{s.row_label}{s.seat_number}</span>
                  ))}
                </div>
              </div>
              <div className="flex items-center gap-6">
                <div className="text-right">
                  <p className="text-xs text-neutral-500 uppercase font-bold mb-1">Total</p>
                  <p className="text-2xl font-black text-neutral-900 dark:text-white">₹{totalPrice.toFixed(2)}</p>
                </div>
                <button 
                  onClick={handleBook}
                  disabled={booking}
                  className="px-8 py-3 bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 text-white rounded-xl font-bold text-lg shadow-lg shadow-primary-500/30 transition-all hover:scale-105 active:scale-95 disabled:opacity-50 disabled:scale-100 flex items-center gap-2"
                >
                  {booking ? <Loader className="w-5 h-5 animate-spin" /> : 'Pay Now'}
                </button>
              </div>
           </div>
         </div>
       )}
    </div>
  )
}
