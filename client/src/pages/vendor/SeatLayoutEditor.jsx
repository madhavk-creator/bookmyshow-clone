import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ArrowLeft, Save, Loader, Plus, Trash2, X, Palette, GripVertical,
  Armchair, Accessibility, Heart, MousePointer, Eraser
} from 'lucide-react'
import { api, extractApiError } from '../../utils/api'

const SEAT_KINDS = [
  { value: 'standard',   label: 'Standard',   icon: Armchair },
  { value: 'recliner',   label: 'Recliner',   icon: Armchair },
  { value: 'wheelchair', label: 'Wheelchair',  icon: Accessibility },
  { value: 'companion',  label: 'Companion',  icon: Armchair },
  { value: 'couple',     label: 'Couple',     icon: Heart },
]

const DEFAULT_SECTION_COLORS = ['#8B5CF6', '#EF4444', '#3B82F6', '#10B981', '#F59E0B', '#EC4899', '#6366F1', '#14B8A6']

export default function SeatLayoutEditor() {
  const { theatreId, screenId, layoutId } = useParams()
  const navigate = useNavigate()

  const [layout, setLayout] = useState(null)
  const [sections, setSections] = useState([])
  const [seats, setSeats] = useState([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [selectedSection, setSelectedSection] = useState(null)
  const [tool, setTool] = useState('paint') // paint | erase
  const [seatKind, setSeatKind] = useState('standard')
  const [showSectionModal, setShowSectionModal] = useState(false)
  const [editingSection, setEditingSection] = useState(null)
  const [sectionForm, setSectionForm] = useState({ code: '', name: '', color_hex: '#8B5CF6', rank: 0 })
  const [error, setError] = useState(null)

  // Drag-to-select state
  const [dragStart, setDragStart] = useState(null)
  const [dragEnd, setDragEnd] = useState(null)
  const [isDragging, setIsDragging] = useState(false)

  const base = `/api/v1/theatres/${theatreId}/screens/${screenId}/seat_layouts/${layoutId}`

  const fetchLayout = useCallback(async () => {
    try {
      const { data } = await api.get(base)
      setLayout(data)
      setSections(data.sections || [])
      // Flatten seats from sections
      const allSeats = (data.sections || []).flatMap(sec =>
        (sec.seats || []).map(s => ({ ...s, seat_section_id: sec.id }))
      )
      setSeats(allSeats)
      setSelectedSection(prev => prev || data.sections?.[0]?.id || null)
    } catch (err) { console.error(err); setError(extractApiError(err, 'Failed to load layout')) }
    finally { setLoading(false) }
  }, [base])

  useEffect(() => { fetchLayout() }, [fetchLayout])

  // Build a lookup map: "row,col" -> seat
  const seatMap = {}
  seats.forEach(s => { seatMap[`${s.grid_row},${s.grid_column}`] = s })

  const sectionMap = {}
  sections.forEach(s => { sectionMap[s.id] = s })

  // Drag-to-select helpers
  const getDragRect = () => {
    if (!dragStart || !dragEnd) return null
    return {
      minRow: Math.min(dragStart.row, dragEnd.row),
      maxRow: Math.max(dragStart.row, dragEnd.row),
      minCol: Math.min(dragStart.col, dragEnd.col),
      maxCol: Math.max(dragStart.col, dragEnd.col),
    }
  }
  const dragRect = getDragRect()
  const isCellInDrag = (row, col) => {
    if (!dragRect) return false
    return row >= dragRect.minRow && row <= dragRect.maxRow && col >= dragRect.minCol && col <= dragRect.maxCol
  }

  const handleMouseDown = (row, col) => {
    if (layout?.status !== 'draft') return
    setDragStart({ row, col })
    setDragEnd({ row, col })
    setIsDragging(true)
  }

  const handleMouseEnter = (row, col) => {
    if (!isDragging) return
    setDragEnd({ row, col })
  }

  const handleMouseUp = () => {
    if (!isDragging || !dragStart || !dragEnd) {
      setIsDragging(false)
      return
    }
    const rect = {
      minRow: Math.min(dragStart.row, dragEnd.row),
      maxRow: Math.max(dragStart.row, dragEnd.row),
      minCol: Math.min(dragStart.col, dragEnd.col),
      maxCol: Math.max(dragStart.col, dragEnd.col),
    }
    applyToolToRect(rect)
    setIsDragging(false)
    setDragStart(null)
    setDragEnd(null)
  }

  const applyToolToRect = (rect) => {
    if (tool === 'erase') {
      setSeats(prev => prev.filter(s =>
        !(s.grid_row >= rect.minRow && s.grid_row <= rect.maxRow && s.grid_column >= rect.minCol && s.grid_column <= rect.maxCol)
      ))
      return
    }

    if (!selectedSection) { alert('Select a section first'); return }

    setSeats(prev => {
      let updated = [...prev]
      for (let r = rect.minRow; r <= rect.maxRow; r++) {
        for (let c = rect.minCol; c <= rect.maxCol; c++) {
          const idx = updated.findIndex(s => s.grid_row === r && s.grid_column === c)
          if (idx !== -1) {
            updated[idx] = { ...updated[idx], seat_section_id: selectedSection, seat_kind: seatKind }
          } else {
            const rowLabel = String.fromCharCode(65 + r)
            const rowSeats = updated.filter(s => s.grid_row === r)
            updated.push({
              row_label: rowLabel,
              seat_number: rowSeats.length + 1,
              grid_row: r,
              grid_column: c,
              seat_section_id: selectedSection,
              seat_kind: seatKind,
              x_span: seatKind === 'couple' ? 2 : 1,
              y_span: 1,
              is_accessible: seatKind === 'wheelchair',
              is_active: true,
            })
          }
        }
      }
      return updated
    })
  }

  const handleSaveSections = async () => {
    setSaving(true)
    try {
      const payload = sections.map(({ id, ...rest }) => rest)
      const { data } = await api.put(`${base}/sections`, { sections: payload })
      // Update with server response
      setSections(data.sections || [])
      if (data.sections?.length > 0) setSelectedSection(data.sections[0].id)
    } catch (err) { alert(extractApiError(err, 'Save failed')) }
    finally { setSaving(false) }
  }

  const handleSaveSeats = async () => {
    setSaving(true)
    try {
      // Recompute labels before saving
      const sortedSeats = [...seats].sort((a, b) => a.grid_row - b.grid_row || a.grid_column - b.grid_column)
      const rowCounts = {}
      const labeled = sortedSeats.map(s => {
        const rowLabel = String.fromCharCode(65 + s.grid_row)
        rowCounts[s.grid_row] = (rowCounts[s.grid_row] || 0) + 1
        return { ...s, row_label: rowLabel, seat_number: rowCounts[s.grid_row] }
      })

      const payload = labeled.map(({ id, label, ...rest }) => rest)
      await api.put(`${base}/seats`, { seats: payload })
      // Refresh
      await fetchLayout()
    } catch (err) { alert(extractApiError(err, 'Save failed')) }
    finally { setSaving(false) }
  }

  const openSectionCreate = () => {
    setEditingSection(null)
    const nextRank = sections.length
    const nextColor = DEFAULT_SECTION_COLORS[nextRank % DEFAULT_SECTION_COLORS.length]
    setSectionForm({ code: '', name: '', color_hex: nextColor, rank: nextRank })
    setShowSectionModal(true)
  }

  const openSectionEdit = (sec) => {
    setEditingSection(sec)
    setSectionForm({ code: sec.code, name: sec.name, color_hex: sec.color_hex || '#8B5CF6', rank: sec.rank })
    setShowSectionModal(true)
  }

  const handleSectionSubmit = (e) => {
    e.preventDefault()
    if (editingSection) {
      setSections(prev => prev.map(s => s.id === editingSection.id ? { ...s, ...sectionForm } : s))
    } else {
      setSections(prev => [...prev, { id: `temp-${Date.now()}`, ...sectionForm }])
    }
    setShowSectionModal(false)
  }

  const removeSection = (secId) => {
    setSections(prev => prev.filter(s => s.id !== secId))
    setSeats(prev => prev.filter(s => s.seat_section_id !== secId))
    if (selectedSection === secId) setSelectedSection(sections[0]?.id || null)
  }

  const isDraft = layout?.status === 'draft'

  if (loading) return <div className="flex justify-center items-center h-[60vh]"><Loader className="w-10 h-10 text-amber-500 animate-spin" /></div>
  if (error) return <div className="p-8 text-center text-red-500">{error}</div>
  if (!layout) return null

  return (
    <div className="p-4 lg:p-6 max-w-[1600px] mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(`/vendor/layouts/${theatreId}/${screenId}`)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 transition-colors cursor-pointer">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">{layout.name}</h1>
            <p className="text-sm text-neutral-500 dark:text-neutral-400">
              v{layout.version_number} · {layout.total_rows}×{layout.total_columns} · {seats.length} seats
              {!isDraft && <span className="ml-2 text-amber-500 font-medium">(Read-only — {layout.status})</span>}
            </p>
          </div>
        </div>
        {isDraft && (
          <div className="flex gap-2">
            <button onClick={handleSaveSections} disabled={saving} className="px-4 py-2 rounded-xl text-sm font-medium bg-primary-500/10 text-primary-600 dark:text-primary-400 hover:bg-primary-500/20 border border-primary-500/20 transition-colors cursor-pointer flex items-center gap-1.5 disabled:opacity-50">
              <Save className="w-4 h-4" /> Save Sections
            </button>
            <button onClick={handleSaveSeats} disabled={saving} className="bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-2 px-5 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer disabled:opacity-50">
              {saving ? <Loader className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />} Save Seats
            </button>
          </div>
        )}
      </div>

      <div className="flex flex-col xl:flex-row gap-6">
        {/* Left Panel — Sections + Tools */}
        <div className="w-full xl:w-72 shrink-0 space-y-4">
          {/* Tool Selection */}
          {isDraft && (
            <div className="glass-card p-4 hover:translate-y-0">
              <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 mb-3">Tool</h3>
              <div className="flex gap-2">
                <button onClick={() => setTool('paint')} className={`flex-1 px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer flex items-center justify-center gap-1.5 ${tool === 'paint' ? 'bg-amber-500/20 text-amber-600 dark:text-amber-400 border-amber-500/40' : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700'}`}>
                  <MousePointer className="w-4 h-4" /> Paint
                </button>
                <button onClick={() => setTool('erase')} className={`flex-1 px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer flex items-center justify-center gap-1.5 ${tool === 'erase' ? 'bg-red-500/20 text-red-600 dark:text-red-400 border-red-500/40' : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700'}`}>
                  <Eraser className="w-4 h-4" /> Erase
                </button>
              </div>
            </div>
          )}

          {/* Seat Kind */}
          {isDraft && (
            <div className="glass-card p-4 hover:translate-y-0">
              <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 mb-3">Seat Type</h3>
              <div className="space-y-1.5">
                {SEAT_KINDS.map(k => (
                  <button key={k.value} onClick={() => setSeatKind(k.value)} className={`w-full px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer flex items-center gap-2 ${seatKind === k.value ? 'bg-amber-500/20 text-amber-600 dark:text-amber-400 border-amber-500/40' : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700 hover:border-amber-500/30'}`}>
                    <k.icon className="w-4 h-4" /> {k.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Sections */}
          <div className="glass-card p-4 hover:translate-y-0">
            <div className="flex justify-between items-center mb-3">
              <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400">Sections</h3>
              {isDraft && (
                <button onClick={openSectionCreate} className="text-amber-500 hover:text-amber-400 cursor-pointer"><Plus className="w-4 h-4" /></button>
              )}
            </div>
            <div className="space-y-1.5">
              {sections.length === 0 && (
                <p className="text-xs text-neutral-400 text-center py-4">Add a section to start</p>
              )}
              {sections.map(sec => (
                <div
                  key={sec.id}
                  onClick={() => { setSelectedSection(sec.id); setTool('paint') }}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer ${selectedSection === sec.id ? 'border-amber-500/40 bg-amber-500/10' : 'border-neutral-200 dark:border-neutral-700 hover:border-amber-500/20 bg-neutral-100 dark:bg-neutral-800'}`}
                >
                  <div className="w-4 h-4 rounded shrink-0" style={{ backgroundColor: sec.color_hex || '#8B5CF6' }} />
                  <span className="flex-1 text-neutral-700 dark:text-neutral-300 truncate">{sec.name}</span>
                  <span className="text-[10px] text-neutral-400">{seats.filter(s => s.seat_section_id === sec.id).length}</span>
                  {isDraft && (
                    <div className="flex gap-0.5">
                      <button onClick={e => { e.stopPropagation(); openSectionEdit(sec) }} className="p-1 rounded hover:bg-neutral-200 dark:hover:bg-neutral-700 text-neutral-400 cursor-pointer"><Palette className="w-3 h-3" /></button>
                      <button onClick={e => { e.stopPropagation(); removeSection(sec.id) }} className="p-1 rounded hover:bg-red-100 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 cursor-pointer"><Trash2 className="w-3 h-3" /></button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Legend */}
          <div className="glass-card p-4 hover:translate-y-0">
            <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 mb-3">Legend</h3>
            <div className="space-y-2 text-xs text-neutral-500 dark:text-neutral-400">
              <div className="flex items-center gap-2"><div className="w-6 h-6 rounded bg-neutral-200 dark:bg-neutral-700 border-2 border-dashed border-neutral-300 dark:border-neutral-600" /><span>Empty cell</span></div>
              {sections.map(sec => (
                <div key={sec.id} className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded" style={{ backgroundColor: sec.color_hex || '#8B5CF6' }} />
                  <span>{sec.name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Panel — Grid */}
        <div className="flex-1 overflow-auto">
          <div className="glass-card p-6 hover:translate-y-0">
            {/* Screen indicator */}
            <div className="flex justify-center mb-8">
              <div className="relative w-3/4 max-w-lg">
                <div className="h-2 bg-gradient-to-r from-transparent via-neutral-400 dark:via-neutral-500 to-transparent rounded-full" />
                <p className="text-center text-[10px] font-bold uppercase tracking-[0.3em] text-neutral-400 dark:text-neutral-500 mt-2">
                  {layout.screen_label || 'SCREEN'}
                </p>
              </div>
            </div>

            {/* Grid */}
            <div className="flex flex-col items-center gap-1 select-none" style={{ minWidth: layout.total_columns * 34 }} onMouseLeave={() => { if (isDragging) handleMouseUp() }}>
              {Array.from({ length: layout.total_rows }, (_, row) => (
                <div key={row} className="flex items-center gap-1">
                  {/* Row label */}
                  <div className="w-6 text-right text-[10px] font-bold text-neutral-400 dark:text-neutral-500 shrink-0 mr-1">
                    {String.fromCharCode(65 + row)}
                  </div>
                  {/* Cells */}
                  {Array.from({ length: layout.total_columns }, (_, col) => {
                    const seat = seatMap[`${row},${col}`]
                    const section = seat ? sectionMap[seat.seat_section_id] : null
                    const isCouple = seat?.seat_kind === 'couple'
                    const inDrag = isCellInDrag(row, col)

                    return (
                      <div
                        key={col}
                        onMouseDown={(e) => { e.preventDefault(); handleMouseDown(row, col) }}
                        onMouseEnter={() => handleMouseEnter(row, col)}
                        onMouseUp={handleMouseUp}
                        className={`relative flex items-center justify-center text-[9px] font-bold transition-all duration-100 rounded
                          ${seat
                            ? 'text-white shadow-sm cursor-pointer'
                            : isDraft
                              ? 'border-2 border-dashed border-neutral-300 dark:border-neutral-700 text-neutral-300 dark:text-neutral-700 hover:border-amber-500/50 hover:bg-amber-500/5 cursor-crosshair'
                              : 'border border-neutral-200 dark:border-neutral-800 text-transparent'
                          }
                          ${inDrag && !seat ? 'ring-2 ring-amber-400 ring-offset-1 ring-offset-transparent bg-amber-500/15' : ''}
                          ${inDrag && seat ? 'ring-2 ring-amber-400 brightness-125' : ''}`}
                        style={{
                          width: isCouple ? 62 : 28,
                          height: 28,
                          backgroundColor: seat ? (section?.color_hex || '#8B5CF6') : 'transparent',
                          userSelect: 'none',
                        }}
                        title={seat ? `${seat.row_label || String.fromCharCode(65 + row)}${seat.seat_number || ''} (${seat.seat_kind})` : `${String.fromCharCode(65 + row)}${col + 1}`}
                      >
                        {seat ? (seat.label || `${String.fromCharCode(65 + row)}${seat.seat_number || ''}`) : ''}
                        {seat?.seat_kind === 'wheelchair' && <span className="absolute -top-1 -right-1 text-[7px]">♿</span>}
                        {seat?.seat_kind === 'recliner' && <span className="absolute -top-1 -right-1 text-[7px]">★</span>}
                      </div>
                    )
                  })}
                  {/* Row label (right) */}
                  <div className="w-6 text-left text-[10px] font-bold text-neutral-400 dark:text-neutral-500 shrink-0 ml-1">
                    {String.fromCharCode(65 + row)}
                  </div>
                </div>
              ))}

              {/* Column numbers */}
              <div className="flex items-center gap-1 mt-2">
                <div className="w-6 mr-1" />
                {Array.from({ length: layout.total_columns }, (_, col) => (
                  <div key={col} className="flex items-center justify-center text-[9px] font-bold text-neutral-400 dark:text-neutral-500" style={{ width: 28, height: 16 }}>
                    {col + 1}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Section Modal */}
      <AnimatePresence>
        {showSectionModal && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setShowSectionModal(false)}>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="w-full max-w-md glass-card p-8 hover:translate-y-0" onClick={e => e.stopPropagation()}>
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white">{editingSection ? 'Edit' : 'New'} Section</h2>
                <button onClick={() => setShowSectionModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer"><X className="w-5 h-5" /></button>
              </div>
              <form onSubmit={handleSectionSubmit} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Name *</label>
                    <input type="text" required value={sectionForm.name} onChange={e => setSectionForm(p => ({ ...p, name: e.target.value }))}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="Premium" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Code *</label>
                    <input type="text" required value={sectionForm.code} onChange={e => setSectionForm(p => ({ ...p, code: e.target.value }))}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="premium" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Color</label>
                    <div className="flex items-center gap-3">
                      <input type="color" value={sectionForm.color_hex} onChange={e => setSectionForm(p => ({ ...p, color_hex: e.target.value }))} className="w-12 h-12 rounded-lg border-2 border-neutral-300 dark:border-neutral-700 cursor-pointer" />
                      <div className="flex flex-wrap gap-1.5">
                        {DEFAULT_SECTION_COLORS.map(c => (
                          <button key={c} type="button" onClick={() => setSectionForm(p => ({ ...p, color_hex: c }))}
                            className={`w-6 h-6 rounded cursor-pointer border-2 transition-all ${sectionForm.color_hex === c ? 'border-white scale-110 shadow-lg' : 'border-transparent'}`}
                            style={{ backgroundColor: c }} />
                        ))}
                      </div>
                    </div>
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Rank</label>
                    <input type="number" min="0" value={sectionForm.rank} onChange={e => setSectionForm(p => ({ ...p, rank: parseInt(e.target.value) || 0 }))}
                      className="w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all"
                      placeholder="0" />
                  </div>
                </div>
                <button type="submit" className="w-full mt-2 bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white font-medium py-3 px-6 rounded-xl shadow-lg shadow-amber-500/30 transition-all hover:scale-105 active:scale-95 cursor-pointer">
                  {editingSection ? 'Update' : 'Add'} Section
                </button>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
