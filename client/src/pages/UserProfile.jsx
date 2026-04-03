import { useEffect, useState } from 'react'
import { useSelector } from 'react-redux'
import { selectCurrentUser } from '../store/authSlice'
import { api } from '../utils/api'
import { Calendar, Ticket, User, Clock, Film } from 'lucide-react'
import { Link } from 'react-router-dom'

export default function UserProfile() {
  const user = useSelector(selectCurrentUser)
  const [stats, setStats] = useState({ totalBookings: 0, upcomingShows: 0 })
  const [recentBookings, setRecentBookings] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchUserData() {
      try {
        const { data } = await api.get('/api/v1/bookings')
        const bookings = data.bookings || []
        
        const now = new Date()
        let upcoming = 0
        bookings.forEach(b => {
          if (b.status === 'confirmed' && new Date(b.show.start_time) > now) {
            upcoming++
          }
        })
        
        setStats({
          totalBookings: data.pagination?.total_records || bookings.length,
          upcomingShows: upcoming
        })
        
        // Grab top 3 recent confirmed bookings
        setRecentBookings(
          bookings.filter(b => b.status === 'confirmed').slice(0, 3)
        )
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }
    fetchUserData()
  }, [])

  const getInitials = (name) => {
    if (!name) return '?'
    return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString(undefined, {
      weekday: 'short', month: 'short', day: 'numeric', year: 'numeric'
    })
  }

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-[#0b090f] py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto space-y-8 animate-slide-up">
        
        {/* Profile Header */}
        <div className="glass-card rounded-3xl p-8 sm:p-12 relative overflow-hidden">
           <div className="absolute top-0 left-0 w-full h-32 bg-gradient-to-r from-primary-600/30 via-purple-600/30 to-blue-600/30 blur-2xl z-0" />
           <div className="relative z-10 flex flex-col sm:flex-row items-center gap-8">
             <div className="w-32 h-32 rounded-full bg-gradient-to-br from-primary-500 to-purple-600 flex items-center justify-center text-white text-5xl font-black shadow-2xl shadow-primary-500/40 ring-4 ring-white dark:ring-neutral-900">
               {getInitials(user?.name)}
             </div>
             <div className="text-center sm:text-left">
                <h1 className="text-4xl font-black text-neutral-900 dark:text-white mb-2 tracking-tight">{user?.name}</h1>
                <p className="text-lg text-neutral-500 dark:text-neutral-400 font-medium mb-4">{user?.email}</p>
                <div className="flex flex-wrap justify-center sm:justify-start gap-4">
                  <span className="px-4 py-1.5 rounded-full bg-primary-500/10 text-primary-600 dark:text-primary-400 text-sm font-bold uppercase tracking-widest border border-primary-500/20">
                    {user?.role === 'vendor' ? 'Partner/Vendor' : (user?.role === 'admin' ? 'Administrator' : 'User')}
                  </span>
                  <Link to="/user/settings" className="px-4 py-1.5 rounded-full bg-neutral-200 dark:bg-neutral-800 hover:bg-neutral-300 dark:hover:bg-neutral-700 text-neutral-700 dark:text-neutral-300 text-sm font-bold transition-colors">
                    Edit Settings
                  </Link>
                </div>
             </div>
           </div>
        </div>

        {/* Dashboard Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
          <div className="glass-card rounded-2xl p-6 flex items-center gap-6">
             <div className="w-14 h-14 rounded-2xl bg-blue-500/10 text-blue-500 flex items-center justify-center">
               <Ticket className="w-7 h-7" />
             </div>
             <div>
               <p className="text-sm font-bold uppercase tracking-wider text-neutral-500 dark:text-neutral-400">Total Bookings</p>
               <h3 className="text-3xl font-black text-neutral-900 dark:text-white">{loading ? '-' : stats.totalBookings}</h3>
             </div>
          </div>
          <div className="glass-card rounded-2xl p-6 flex items-center gap-6">
             <div className="w-14 h-14 rounded-2xl bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
               <Calendar className="w-7 h-7" />
             </div>
             <div>
               <p className="text-sm font-bold uppercase tracking-wider text-neutral-500 dark:text-neutral-400">Upcoming Shows</p>
               <h3 className="text-3xl font-black text-neutral-900 dark:text-white">{loading ? '-' : stats.upcomingShows}</h3>
             </div>
          </div>
        </div>

        {/* Activity Feed */}
        <div className="glass-card rounded-2xl p-8">
           <div className="flex items-center justify-between mb-6 pb-4 border-b border-neutral-200 dark:border-neutral-800">
             <h2 className="text-xl font-bold text-neutral-900 dark:text-white flex items-center gap-2"><Film className="w-5 h-5 text-primary-500" /> Recent Bookings</h2>
             <Link to="/user/bookings" className="text-sm font-bold text-primary-600 dark:text-primary-400 hover:underline">View All</Link>
           </div>
           
           <div className="space-y-4">
             {loading ? (
               <div className="text-center py-8 text-neutral-500 animate-pulse">Loading recent activity...</div>
             ) : recentBookings.length === 0 ? (
               <div className="text-center py-12">
                 <div className="inline-flex w-16 h-16 rounded-full bg-neutral-100 dark:bg-neutral-800 items-center justify-center mb-4">
                   <Ticket className="w-8 h-8 text-neutral-400" />
                 </div>
                 <p className="text-lg font-bold text-neutral-600 dark:text-neutral-300">No confirmed bookings yet</p>
                 <Link to="/" className="inline-block mt-4 text-primary-500 hover:underline font-medium">Explore Movies</Link>
               </div>
             ) : (
               recentBookings.map(booking => (
                 <Link key={booking.id} to={`/checkout/${booking.id}`} className="block glass-card rounded-xl p-4 hover:border-primary-500/50 hover:shadow-lg transition-all">
                   <div className="flex justify-between items-center sm:items-start flex-col sm:flex-row gap-4">
                     <div>
                       <h4 className="font-bold text-neutral-900 dark:text-white mb-1">{booking.show.movie.title}</h4>
                       <div className="flex items-center gap-3 text-sm text-neutral-500">
                         <span className="flex items-center gap-1"><Calendar className="w-3 h-3" /> {formatDate(booking.show.start_time)}</span>
                       </div>
                     </div>
                     <div className="text-left sm:text-right w-full sm:w-auto flex flex-row sm:flex-col justify-between sm:justify-start items-center sm:items-end">
                       <span className="text-sm font-bold text-neutral-900 dark:text-white">{booking.tickets_count} Tickets</span>
                       <span className="text-xs font-bold text-emerald-500 bg-emerald-500/10 px-2 py-0.5 rounded mt-1 uppercase tracking-wider">Confirmed</span>
                     </div>
                   </div>
                 </Link>
               ))
             )}
           </div>
        </div>

      </div>
    </div>
  )
}
