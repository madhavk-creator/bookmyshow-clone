import { useState, useEffect } from 'react'
import { Ticket, Plus, Trash2, Calendar, Loader, Tag, AlertCircle } from 'lucide-react'
import { api, extractApiError } from '../../utils/api'
import { showSuccessToast, showApiErrorToast } from '../../utils/toast'

export default function AdminCoupons() {
  const [coupons, setCoupons] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  
  const [formData, setFormData] = useState({
    code: '',
    coupon_type: 'percentage',
    discount_percentage: '',
    discount_amount: '',
    valid_from: '',
    valid_until: '',
    minimum_booking_amount: '',
    max_uses_per_user: '',
    max_total_uses: ''
  })

  const fetchCoupons = async () => {
    setLoading(true)
    try {
      const { data } = await api.get('/api/v1/admin/coupons')
      setCoupons(data.coupons || [])
    } catch (err) {
      showApiErrorToast(err, 'Failed to fetch coupons')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchCoupons()
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)

    // Clean up empty strings to nil
    const payload = { ...formData }
    if (payload.coupon_type === 'percentage') delete payload.discount_amount
    if (payload.coupon_type === 'amount') delete payload.discount_percentage
    
    Object.keys(payload).forEach(k => {
      if (payload[k] === '') payload[k] = null
    })

    try {
      const { data } = await api.post('/api/v1/admin/coupons', { coupon: payload })
      setCoupons([data, ...coupons])
      showSuccessToast('Coupon created successfully')
      setIsModalOpen(false)
      setFormData({
        code: '', coupon_type: 'percentage', discount_percentage: '', discount_amount: '',
        valid_from: '', valid_until: '', minimum_booking_amount: '', max_uses_per_user: '', max_total_uses: ''
      })
    } catch (err) {
      showApiErrorToast(err, 'Failed to create coupon')
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this coupon?')) return
    try {
      await api.delete(`/api/v1/admin/coupons/${id}`)
      setCoupons(coupons.filter(c => c.id !== id))
      showSuccessToast('Coupon deleted')
    } catch (err) {
      showApiErrorToast(err, 'Failed to delete coupon')
    }
  }

  return (
    <div className="p-6 lg:p-8 max-w-7xl mx-auto animate-fade-in">
      <div className="flex justify-between items-center mb-8 bg-white/50 dark:bg-[#0b090f]/50 p-6 rounded-3xl border border-neutral-200 dark:border-neutral-800 backdrop-blur-xl">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-primary-500/10 flex items-center justify-center">
            <Ticket className="w-6 h-6 text-primary-500" />
          </div>
          <div>
            <h1 className="text-2xl font-black text-neutral-900 dark:text-white">Coupons</h1>
            <p className="text-neutral-500 dark:text-neutral-400 font-medium">Manage promotional codes</p>
          </div>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="px-6 py-3 bg-primary-600 hover:bg-primary-500 text-white rounded-xl font-bold transition-all shadow-lg shadow-primary-500/25 flex items-center gap-2"
        >
          <Plus className="w-5 h-5" /> New Coupon
        </button>
      </div>

      {loading ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1,2,3].map(i => <div key={i} className="h-40 rounded-2xl bg-neutral-100 dark:bg-neutral-800/50 animate-pulse" />)}
        </div>
      ) : coupons.length === 0 ? (
        <div className="text-center py-20 bg-white/50 dark:bg-neutral-900/20 rounded-3xl border border-neutral-200 dark:border-neutral-800">
           <Tag className="w-16 h-16 text-neutral-300 dark:text-neutral-700 mx-auto mb-4" />
           <h3 className="text-xl font-bold text-neutral-900 dark:text-white">No Coupons Found</h3>
           <p className="text-neutral-500 dark:text-neutral-400">Create your first discount code to get started.</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {coupons.map(coupon => (
            <div key={coupon.id} className="glass-card p-6 rounded-2xl relative overflow-hidden group">
              {/* Status Indicator */}
              <div className={`absolute top-0 right-0 w-16 h-16 -mr-8 -mt-8 rotate-45 ${coupon.is_active ? 'bg-emerald-500/20' : 'bg-red-500/20'}`} />
              
              <div className="flex justify-between items-start mb-4">
                <div className="inline-flex px-3 py-1 bg-primary-500/10 border border-primary-500/20 rounded-lg">
                  <span className="font-mono font-black text-xl text-primary-600 dark:text-primary-400 tracking-wider uppercase">{coupon.code}</span>
                </div>
                <button onClick={() => handleDelete(coupon.id)} className="text-neutral-400 hover:text-red-500 transition-colors p-2 rounded-lg hover:bg-red-500/10">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>

              <div className="mb-4">
                <span className="text-3xl font-black text-neutral-900 dark:text-white drop-shadow-sm">
                  {coupon.coupon_type === 'percentage' ? `${parseFloat(coupon.discount_percentage)}%` : `₹${parseFloat(coupon.discount_amount)}`}
                </span>
                <span className="text-neutral-500 dark:text-neutral-400 font-bold ml-2">OFF</span>
              </div>

              <div className="space-y-2 text-sm">
                <div className="flex items-center gap-2 text-neutral-600 dark:text-neutral-400">
                  <Calendar className="w-4 h-4" />
                  <span>{new Date(coupon.valid_from).toLocaleDateString()} &rarr; {new Date(coupon.valid_until).toLocaleDateString()}</span>
                </div>
                {coupon.minimum_booking_amount && (
                  <div className="text-neutral-500">Min spend: <span className="font-bold text-neutral-700 dark:text-neutral-300">₹{parseFloat(coupon.minimum_booking_amount)}</span></div>
                )}
                <div className="flex gap-4 mt-2">
                  <span className="text-xs font-bold px-2 py-1 bg-neutral-100 dark:bg-neutral-800 rounded">
                    Global limit: {coupon.max_total_uses || '∞'}
                  </span>
                  <span className="text-xs font-bold px-2 py-1 bg-neutral-100 dark:bg-neutral-800 rounded">
                    Per user: {coupon.max_uses_per_user || '∞'}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setIsModalOpen(false)} />
          <div className="relative bg-white dark:bg-neutral-950 rounded-3xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto border border-neutral-200 dark:border-neutral-800 p-6 md:p-8 animate-slide-up">
            <h2 className="text-2xl font-black text-neutral-900 dark:text-white mb-6">Create New Coupon</h2>
            
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Coupon Code</label>
                  <input type="text" required value={formData.code} onChange={e => setFormData({...formData, code: e.target.value.toUpperCase()})}
                    placeholder="e.g. SUMMER20" className="w-full font-mono font-bold tracking-widest uppercase p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                </div>
                
                <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Discount Type</label>
                  <select value={formData.coupon_type} onChange={e => setFormData({...formData, coupon_type: e.target.value})}
                    className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white font-medium">
                    <option value="percentage">Percentage (%)</option>
                    <option value="amount">Fixed Amount (₹)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Value</label>
                  {formData.coupon_type === 'percentage' ? (
                    <input type="number" required min="1" max="100" value={formData.discount_percentage} onChange={e => setFormData({...formData, discount_percentage: e.target.value})}
                      placeholder="%" className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                  ) : (
                    <input type="number" required min="1" value={formData.discount_amount} onChange={e => setFormData({...formData, discount_amount: e.target.value})}
                      placeholder="₹" className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                  )}
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Valid From</label>
                  <input type="datetime-local" required value={formData.valid_from} onChange={e => setFormData({...formData, valid_from: e.target.value})}
                    className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Valid Until</label>
                  <input type="datetime-local" required value={formData.valid_until} onChange={e => setFormData({...formData, valid_until: e.target.value})}
                    className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                </div>

                <div className="col-span-2">
                  <div className="h-px bg-neutral-200 dark:bg-neutral-800 my-2" />
                </div>
                
                <div className="col-span-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">
                    Minimum Booking Amount <span className="text-neutral-400 font-normal">(Optional)</span>
                  </label>
                  <input type="number" min="0" value={formData.minimum_booking_amount} onChange={e => setFormData({...formData, minimum_booking_amount: e.target.value})}
                    placeholder="₹ 0.00" className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Max Uses Per User <span className="text-neutral-400 font-normal">(Optional)</span></label>
                  <input type="number" min="1" value={formData.max_uses_per_user} onChange={e => setFormData({...formData, max_uses_per_user: e.target.value})}
                    placeholder="∞" className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                </div>

                <div>
                  <label className="block text-sm font-bold text-neutral-700 dark:text-neutral-300 mb-1">Total Global Uses <span className="text-neutral-400 font-normal">(Optional)</span></label>
                  <input type="number" min="1" value={formData.max_total_uses} onChange={e => setFormData({...formData, max_total_uses: e.target.value})}
                    placeholder="∞" className="w-full p-3 rounded-xl bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 focus:ring-2 focus:ring-primary-500 outline-none dark:text-white" />
                </div>
              </div>

              <div className="flex gap-4 pt-4">
                <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 py-3 px-4 bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 text-neutral-900 dark:text-white rounded-xl font-bold transition-all">
                  Cancel
                </button>
                <button type="submit" disabled={submitting} className="flex-1 py-3 px-4 bg-primary-600 hover:bg-primary-500 text-white rounded-xl font-bold transition-all disabled:opacity-50 flex items-center justify-center gap-2">
                  {submitting ? <Loader className="w-5 h-5 animate-spin"/> : 'Create Coupon'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
