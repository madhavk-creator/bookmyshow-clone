import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { api, extractApiError } from '../utils/api'
import { showApiErrorToast, showWarningToast } from '../utils/toast'
import { Loader, MapPin, Calendar, Clock, Ticket } from 'lucide-react'
import { useSelector } from 'react-redux'
import { selectCurrentUser } from '../store/authSlice'

export default function PublicSeatSelection() {
  const { showId } = useParams()
  const navigate = useNavigate()
  const user = useSelector(selectCurrentUser)
  
  const [show, setShow] = useState(null)
  const [sections, setSections] = useState([])
  const [seats, setSeats] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedSeats, setSelectedSeats] = useState([])
  const [booking, setBooking] = useState(false)

  useEffect(() => {
    async function fetchShowData() {
      try {
        const [showRes, seatsRes] = await Promise.all([
          api.get(`/api/v1/shows/${showId}`),
          api.get(`/api/v1/shows/${showId}/seats`)
        ])
        setShow(showRes.data)
        
        const fetchedSections = seatsRes.data.sections || []
        setSections(fetchedSections)
        
        const allSeats = fetchedSections.flatMap(sec => 
          sec.seats.map(s => ({ ...s, section: sec }))
        )
        setSeats(allSeats)
      } catch (err) {
        console.error(err)
        showApiErrorToast(err, 'Failed to load seats')
      } finally {
        setLoading(false)
      }
    }
    fetchShowData()
  }, [showId])

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
      const { data } = await api.post('/api/v1/bookings', {
        booking: {
          show_id: showId,
          seat_ids: selectedSeats.map(s => s.id)
        }
      })
      navigate(`/checkout/${data.id}`)
    } catch (err) {
       showApiErrorToast(err, 'Failed to hold seats. They might have just been booked!')
       // Refresh seats silently
       api.get(`/api/v1/shows/${showId}/seats`).then(res => {
         const fetchedSections = res.data.sections || []
         setSections(fetchedSections)
         const allSeats = fetchedSections.flatMap(sec => sec.seats.map(s => ({ ...s, section: sec })))
         setSeats(allSeats)
         setSelectedSeats([])
       })
    } finally {
      setBooking(false)
    }
  }

  const formatTime = (t) => new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const formatDate = (d) => new Date(d).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
  
  const totalPrice = selectedSeats.reduce((acc, seat) => acc + parseFloat(seat.section.base_price || 0), 0)

  if (loading) return <div className="flex justify-center items-center h-[70vh]"><Loader className="w-10 h-10 animate-spin text-primary-500" /></div>
  if (!show) return <div className="text-center py-20">Show not found</div>

  return (
    <div className="flex flex-col min-h-screen bg-neutral-50 dark:bg-[#0b090f]">
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

       <div className="flex-1 overflow-auto p-4 md:p-8 flex justify-center pb-32">
         <div className="glass-card p-6 inline-flex flex-col items-center">
            {/* Screen indicator */}
            <div className="flex justify-center mb-12 w-full">
              <div className="relative w-full max-w-2xl">
                <div className="h-3 bg-gradient-to-r from-transparent via-cyan-400/50 dark:via-cyan-600/50 to-transparent rounded-[100%] blur-[2px]" />
                <div className="h-1 bg-gradient-to-r from-transparent via-cyan-300 dark:via-cyan-500 to-transparent rounded-full mt-1" />
                <p className="text-center text-xs font-bold uppercase tracking-[0.4em] text-neutral-400 dark:text-neutral-500 mt-4">
                  All eyes this way
                </p>
              </div>
            </div>

            {/* Grid */}
            <div className="flex flex-col items-center gap-1.5 select-none transition-all pb-12">
              {Array.from({ length: totalRows }, (_, row) => (
                <div key={row} className="flex items-center gap-1.5">
                  <div className="w-6 text-right text-xs font-bold text-neutral-400 shrink-0 mr-2 uppercase">
                    {String.fromCharCode(65 + row)}
                  </div>
                  {Array.from({ length: totalColumns }, (_, col) => {
                    const seat = seatMap[`${row},${col}`]
                    const isCouple = seat?.seat_kind === 'couple'
                    
                    if (!seat) {
                      return <div key={col} style={{ width: 32, height: 32 }} className="shrink-0" />
                    }

                    const isAvailable = seat.status === 'available'
                    const isSelected = selectedSeats.some(s => s.id === seat.id)
                    const baseColor = seat.section.color_hex || '#8B5CF6'

                    return (
                      <button
                        key={col}
                        disabled={!isAvailable}
                        onClick={() => handleSeatClick(seat)}
                        className={`relative flex items-center justify-center text-[10px] font-bold transition-all rounded shrink-0
                          ${!isAvailable 
                             ? 'bg-neutral-200 dark:bg-neutral-800 text-transparent border border-neutral-300 dark:border-neutral-700 cursor-not-allowed opacity-50' 
                             : isSelected
                               ? 'text-white shadow-lg scale-110 z-10 ring-2 ring-white cursor-pointer'
                               : 'text-white cursor-pointer hover:scale-105 hover:shadow-md'
                          }`}
                        style={{
                          width: isCouple ? 68 : 32,
                          height: 32,
                          background: isAvailable 
                            ? `linear-gradient(135deg, ${baseColor}80, ${baseColor}10)` 
                            : undefined,
                          border: isAvailable 
                            ? `1.5px solid ${baseColor}` 
                            : undefined,
                          backgroundColor: isSelected ? baseColor : undefined,
                          textShadow: isAvailable || isSelected ? '0 1px 2px rgba(0,0,0,0.8)' : undefined,
                        }}
                        title={`${seat.row_label}${seat.seat_number} - ₹${seat.section.base_price}`}
                      >
                        {seat.seat_number}
                      </button>
                    )
                  })}
                  <div className="w-6 text-left text-xs font-bold text-neutral-400 shrink-0 ml-2 uppercase">
                    {String.fromCharCode(65 + row)}
                  </div>
                </div>
              ))}
            </div>

            {/* Legend */}
            <div className="mt-8 flex flex-wrap justify-center gap-6 text-xs text-neutral-500 font-medium">
               <div className="flex items-center gap-2">
                 <div className="w-5 h-5 rounded border-2 border-primary-500 bg-primary-500" /> Selected
               </div>
               <div className="flex items-center gap-2">
                 <div className="w-5 h-5 rounded border border-primary-500 bg-primary-500/20" /> Available
               </div>
               <div className="flex items-center gap-2">
                 <div className="w-5 h-5 rounded border border-neutral-300 dark:border-neutral-700 bg-neutral-200 dark:bg-neutral-800" /> Sold/Blocked
               </div>
               {sections.map(sec => (
                 <div key={sec.id} className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: sec.color_hex }} />
                    {sec.name} (₹{sec.base_price || 0})
                 </div>
               ))}
            </div>
         </div>
       </div>

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
