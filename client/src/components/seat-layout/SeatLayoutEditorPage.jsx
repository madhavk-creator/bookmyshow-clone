import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ArrowLeft, Save, Loader, Plus, Trash2, X, Palette,
  Armchair, Accessibility, Sofa, MousePointer, Eraser
} from 'lucide-react'
import { useGetSeatLayoutQuery, useSyncSeatLayoutSectionsMutation, useSyncSeatLayoutSeatsMutation } from '../../store/apiSlice'
import { useConfirm } from '../ConfirmProvider'
import { extractApiError } from '../../utils/api'
import { showApiErrorToast, showSuccessToast, showWarningToast } from '../../utils/toast'

const SEAT_KINDS = [
  { value: 'standard', label: 'Standard', icon: Armchair },
  { value: 'recliner', label: 'Recliner', icon: Armchair },
  { value: 'wheelchair', label: 'Wheelchair', icon: Accessibility },
  { value: 'companion', label: 'Companion', icon: Armchair },
  { value: 'lounge', label: 'lounge', icon: Sofa },
]

const DEFAULT_SECTION_COLORS = ['#CEBFF1', '#EF4444', '#3B82F6', '#10B981', '#F59E0B', '#EC4899', '#6366F1', '#14B8A6']

const THEMES = {
  vendor: {
    loader: 'text-amber-500',
    backPath: ({ theatreId, screenId }) => `/vendor/layouts/${theatreId}/${screenId}`,
    readOnly: 'text-amber-500',
    primaryButton: 'bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 shadow-amber-500/30',
    saveButton: 'bg-primary-500/10 text-primary-600 dark:text-primary-400 hover:bg-primary-500/20 border-primary-500/20',
    paintTool: 'bg-amber-500/20 text-amber-600 dark:text-amber-400 border-amber-500/40',
    seatKindActive: 'bg-amber-500/20 text-amber-600 dark:text-amber-400 border-amber-500/40',
    seatKindHover: 'hover:border-amber-500/30',
    sectionAdd: 'text-amber-500 hover:text-amber-400',
    sectionSelected: 'border-amber-500/40 bg-amber-500/10',
    sectionHover: 'hover:border-amber-500/20',
    gridHover: 'hover:border-amber-500/50 hover:bg-amber-500/5',
    dragRing: 'ring-amber-400',
    dragFill: 'bg-amber-500/15',
    inputFocus: 'focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500',
  },
  admin: {
    loader: 'text-primary-500',
    backPath: ({ theatreId, screenId }) => `/admin/layouts/${theatreId}/${screenId}`,
    readOnly: 'text-primary-500',
    primaryButton: 'bg-gradient-to-r from-primary-600 to-blue-600 hover:from-primary-500 hover:to-blue-500 shadow-primary-500/30',
    saveButton: 'bg-primary-500/10 text-primary-600 dark:text-primary-400 hover:bg-primary-500/20 border-primary-500/20',
    paintTool: 'bg-primary-500/20 text-primary-600 dark:text-primary-400 border-primary-500/40',
    seatKindActive: 'bg-primary-500/20 text-primary-600 dark:text-primary-400 border-primary-500/40',
    seatKindHover: 'hover:border-primary-500/30',
    sectionAdd: 'text-primary-500 hover:text-primary-400',
    sectionSelected: 'border-primary-500/40 bg-primary-500/10',
    sectionHover: 'hover:border-primary-500/20',
    gridHover: 'hover:border-primary-500/50 hover:bg-primary-500/5',
    dragRing: 'ring-primary-400',
    dragFill: 'bg-primary-500/15',
    inputFocus: 'focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500',
  },
}

export default function SeatLayoutEditorPage({ mode = 'vendor' }) {
  const theme = THEMES[mode] || THEMES.vendor
  const { theatreId, screenId, layoutId } = useParams()
  const navigate = useNavigate()
  const confirm = useConfirm()
  const { data: layoutData, isLoading, isFetching, refetch, error: queryError } = useGetSeatLayoutQuery(
    { theatreId, screenId, layoutId },
    { skip: !theatreId || !screenId || !layoutId }
  )
  const [syncSections] = useSyncSeatLayoutSectionsMutation()
  const [syncSeats] = useSyncSeatLayoutSeatsMutation()

  const [layout, setLayout] = useState(null)
  const [sections, setSections] = useState([])
  const [seats, setSeats] = useState([])
  const [saving, setSaving] = useState(false)
  const [selectedSection, setSelectedSection] = useState(null)
  const [tool, setTool] = useState('paint')
  const [seatKind, setSeatKind] = useState('standard')
  const [showSectionModal, setShowSectionModal] = useState(false)
  const [editingSection, setEditingSection] = useState(null)
  const [sectionForm, setSectionForm] = useState({ code: '', name: '', color_hex: '#8B5CF6', rank: 0 })
  const [error, setError] = useState(null)
  const [dragStart, setDragStart] = useState(null)
  const [dragEnd, setDragEnd] = useState(null)
  const [isDragging, setIsDragging] = useState(false)

  const loading = isLoading || isFetching

  useEffect(() => {
    if (!layoutData) return
    setLayout(layoutData)
    setSections(layoutData.sections || [])
    const allSeats = (layoutData.sections || []).flatMap((section) =>
      (section.seats || []).map((seat) => ({ ...seat, seat_section_id: section.id }))
    )
    setSeats(allSeats)
    setSelectedSection((prev) => prev || layoutData.sections?.[0]?.id || null)
    setError(null)
  }, [layoutData])

  useEffect(() => {
    if (!queryError) return
    setError(extractApiError(queryError, 'Failed to load seat layout'))
  }, [queryError])

  const seatMap = {}
  seats.forEach((seat) => { seatMap[`${seat.grid_row},${seat.grid_column}`] = seat })

  const sectionMap = {}
  sections.forEach((section) => { sectionMap[section.id] = section })

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

  const getCoverageSummary = () => {
    const totalCells = (layout?.total_rows || 0) * (layout?.total_columns || 0)
    const occupiedCells = new Set()

    seats.forEach((seat) => {
      const xSpan = seat.x_span || 1
      const ySpan = seat.y_span || 1

      for (let rowOffset = 0; rowOffset < ySpan; rowOffset += 1) {
        for (let colOffset = 0; colOffset < xSpan; colOffset += 1) {
          occupiedCells.add(`${seat.grid_row + rowOffset},${seat.grid_column + colOffset}`)
        }
      }
    })

    const assignedCells = occupiedCells.size
    const unassignedCells = Math.max(totalCells - assignedCells, 0)

    return {
      totalCells,
      assignedCells,
      unassignedCells,
      unassignedRatio: totalCells > 0 ? unassignedCells / totalCells : 0,
    }
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

    applyToolToRect({
      minRow: Math.min(dragStart.row, dragEnd.row),
      maxRow: Math.max(dragStart.row, dragEnd.row),
      minCol: Math.min(dragStart.col, dragEnd.col),
      maxCol: Math.max(dragStart.col, dragEnd.col),
    })

    setIsDragging(false)
    setDragStart(null)
    setDragEnd(null)
  }

  const applyToolToRect = (rect) => {
    if (tool === 'erase') {
      setSeats((prev) => prev.filter((seat) =>
        !(seat.grid_row >= rect.minRow && seat.grid_row <= rect.maxRow && seat.grid_column >= rect.minCol && seat.grid_column <= rect.maxCol)
      ))
      return
    }

    if (!selectedSection) {
      showWarningToast('Select a section first.')
      return
    }

    setSeats((prev) => {
      const updated = [...prev]
      for (let row = rect.minRow; row <= rect.maxRow; row += 1) {
        for (let col = rect.minCol; col <= rect.maxCol; col += 1) {
          const index = updated.findIndex((seat) => seat.grid_row === row && seat.grid_column === col)
          if (index !== -1) {
            updated[index] = { ...updated[index], seat_section_id: selectedSection, seat_kind: seatKind }
          } else {
            const rowLabel = String.fromCharCode(65 + row)
            const rowSeats = updated.filter((seat) => seat.grid_row === row)
            updated.push({
              row_label: rowLabel,
              seat_number: rowSeats.length + 1,
              grid_row: row,
              grid_column: col,
              seat_section_id: selectedSection,
              seat_kind: seatKind,
              x_span: seatKind === 'lounge' ? 2 : 1,
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
      const data = await syncSections({ theatreId, screenId, layoutId, sections: payload }).unwrap()
      const serverSections = data.sections || []

      setSections(serverSections)
      setSeats((prevSeats) => prevSeats.map((seat) => {
        const oldSection = sections.find((section) => section.id === seat.seat_section_id)
        if (!oldSection) return seat
        const newSection = serverSections.find((section) => section.code === oldSection.code)
        return newSection ? { ...seat, seat_section_id: newSection.id } : seat
      }))

      if (selectedSection) {
        const oldSection = sections.find((section) => section.id === selectedSection)
        if (oldSection) {
          const newSection = serverSections.find((section) => section.code === oldSection.code)
          if (newSection) setSelectedSection(newSection.id)
          else if (serverSections.length > 0) setSelectedSection(serverSections[0].id)
        }
      } else if (serverSections.length > 0) {
        setSelectedSection(serverSections[0].id)
      }

      showSuccessToast('Sections saved successfully.')
    } catch (err) {
      showApiErrorToast(err, 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const handleSaveSeats = async () => {
    const coverage = getCoverageSummary()
    if (coverage.totalCells > 0 && coverage.unassignedRatio >= 0.5) {
      const confirmed = await confirm({
        title: 'Large Unassigned Area',
        message: `${coverage.unassignedCells} of ${coverage.totalCells} seat positions are still unassigned in this layout. You can continue if this is intentional, or go back and finish assigning seats first.`,
        confirmText: 'Save Anyway',
        cancelText: 'Review Layout',
        tone: 'warning',
      })

      if (!confirmed) return
    }

    setSaving(true)
    try {
      const sortedSeats = [...seats].sort((a, b) => a.grid_row - b.grid_row || a.grid_column - b.grid_column)
      const rowCounts = {}
      const labeled = sortedSeats.map((seat) => {
        const rowLabel = String.fromCharCode(65 + seat.grid_row)
        rowCounts[seat.grid_row] = (rowCounts[seat.grid_row] || 0) + 1
        return { ...seat, row_label: rowLabel, seat_number: rowCounts[seat.grid_row] }
      })

      const payload = labeled.map(({ id, label, ...rest }) => rest)
      await syncSeats({ theatreId, screenId, layoutId, seats: payload }).unwrap()
      await refetch()
      showSuccessToast('Seat map saved successfully.')
    } catch (err) {
      showApiErrorToast(err, 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const openSectionCreate = () => {
    setEditingSection(null)
    const nextRank = sections.length
    const nextColor = DEFAULT_SECTION_COLORS[nextRank % DEFAULT_SECTION_COLORS.length]
    setSectionForm({ code: '', name: '', color_hex: nextColor, rank: nextRank })
    setShowSectionModal(true)
  }

  const openSectionEdit = (section) => {
    setEditingSection(section)
    setSectionForm({ code: section.code, name: section.name, color_hex: section.color_hex || '#8B5CF6', rank: section.rank })
    setShowSectionModal(true)
  }

  const handleSectionSubmit = (event) => {
    event.preventDefault()
    if (editingSection) {
      setSections((prev) => prev.map((section) => section.id === editingSection.id ? { ...section, ...sectionForm } : section))
    } else {
      setSections((prev) => [...prev, { id: `temp-${Date.now()}`, ...sectionForm }])
    }
    setShowSectionModal(false)
  }

  const removeSection = (sectionId) => {
    setSections((prev) => prev.filter((section) => section.id !== sectionId))
    setSeats((prev) => prev.filter((seat) => seat.seat_section_id !== sectionId))
    if (selectedSection === sectionId) setSelectedSection(sections[0]?.id || null)
  }

  const isDraft = layout?.status === 'draft'

  if (loading) {
    return <div className="flex justify-center items-center h-[60vh]"><Loader className={`w-10 h-10 animate-spin ${theme.loader}`} /></div>
  }

  if (error) {
    return <div className="p-8 text-center text-red-500">{error}</div>
  }

  if (!layout) return null

  return (
    <div className="p-4 lg:p-6 max-w-[1600px] mx-auto">
      <div className="flex items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(theme.backPath({ theatreId, screenId }))} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 transition-colors cursor-pointer">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">{layout.name}</h1>
            <p className="text-sm text-neutral-500 dark:text-neutral-400">
              v{layout.version_number} · {layout.total_rows}×{layout.total_columns} · {seats.length} seats
              {!isDraft && <span className={`ml-2 font-medium ${theme.readOnly}`}>(Read-only - {layout.status})</span>}
            </p>
          </div>
        </div>
        {isDraft && (
          <div className="flex gap-2">
            <button onClick={handleSaveSections} disabled={saving} className={`px-4 py-2 rounded-xl text-sm font-medium border transition-colors cursor-pointer flex items-center gap-1.5 disabled:opacity-50 ${theme.saveButton}`}>
              <Save className="w-4 h-4" /> Save Sections
            </button>
            <button onClick={handleSaveSeats} disabled={saving} className={`${theme.primaryButton} text-white font-medium py-2 px-5 rounded-xl shadow-lg transition-all hover:scale-105 active:scale-95 flex items-center gap-2 cursor-pointer disabled:opacity-50`}>
              {saving ? <Loader className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />} Save Seats
            </button>
          </div>
        )}
      </div>

      <div className="flex flex-col xl:flex-row gap-6">
        <div className="w-full xl:w-72 shrink-0 space-y-4">
          {isDraft && (
            <div className="glass-card p-4 hover:translate-y-0">
              <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 mb-3">Tool</h3>
              <div className="flex gap-2">
                <button onClick={() => setTool('paint')} className={`flex-1 px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer flex items-center justify-center gap-1.5 ${tool === 'paint' ? theme.paintTool : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700'}`}>
                  <MousePointer className="w-4 h-4" /> Paint
                </button>
                <button onClick={() => setTool('erase')} className={`flex-1 px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer flex items-center justify-center gap-1.5 ${tool === 'erase' ? 'bg-red-500/20 text-red-600 dark:text-red-400 border-red-500/40' : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700'}`}>
                  <Eraser className="w-4 h-4" /> Erase
                </button>
              </div>
            </div>
          )}

          {isDraft && (
            <div className="glass-card p-4 hover:translate-y-0">
              <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 mb-3">Seat Type</h3>
              <div className="space-y-1.5">
                {SEAT_KINDS.map((kind) => (
                  <button key={kind.value} onClick={() => setSeatKind(kind.value)} className={`w-full px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer flex items-center gap-2 ${seatKind === kind.value ? theme.seatKindActive : `bg-neutral-100 dark:bg-neutral-800 text-neutral-500 border-neutral-200 dark:border-neutral-700 ${theme.seatKindHover}`}`}>
                    <kind.icon className="w-4 h-4" /> {kind.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className="glass-card p-4 hover:translate-y-0">
            <div className="flex justify-between items-center mb-3">
              <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400">Sections</h3>
              {isDraft && (
                <button onClick={openSectionCreate} className={`cursor-pointer ${theme.sectionAdd}`}><Plus className="w-4 h-4" /></button>
              )}
            </div>
            <div className="space-y-1.5">
              {sections.length === 0 && (
                <p className="text-xs text-neutral-400 text-center py-4">Add a section to start</p>
              )}
              {sections.map((section) => (
                <div
                  key={section.id}
                  onClick={() => { setSelectedSection(section.id); setTool('paint') }}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium border transition-all cursor-pointer ${selectedSection === section.id ? theme.sectionSelected : `border-neutral-200 dark:border-neutral-700 ${theme.sectionHover} bg-neutral-100 dark:bg-neutral-800`}`}
                >
                  <div className="w-4 h-4 rounded shrink-0" style={{ background: `linear-gradient(135deg, ${section.color_hex || '#8B5CF6'}50, ${section.color_hex || '#8B5CF6'}10)`, border: `1px solid ${section.color_hex || '#8B5CF6'}` }} />
                  <span className="flex-1 text-neutral-700 dark:text-neutral-300 truncate">{section.name}</span>
                  <span className="text-[10px] text-neutral-400">{seats.filter((seat) => seat.seat_section_id === section.id).length}</span>
                  {isDraft && (
                    <div className="flex gap-0.5">
                      <button onClick={(event) => { event.stopPropagation(); openSectionEdit(section) }} className="p-1 rounded hover:bg-neutral-200 dark:hover:bg-neutral-700 text-neutral-400 cursor-pointer"><Palette className="w-3 h-3" /></button>
                      <button onClick={(event) => { event.stopPropagation(); removeSection(section.id) }} className="p-1 rounded hover:bg-red-100 dark:hover:bg-red-500/10 text-neutral-400 hover:text-red-500 cursor-pointer"><Trash2 className="w-3 h-3" /></button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="glass-card p-4 hover:translate-y-0">
            <h3 className="text-xs font-bold uppercase tracking-widest text-neutral-500 dark:text-neutral-400 mb-3">Legend</h3>
            <div className="space-y-2 text-xs text-neutral-500 dark:text-neutral-400">
              <div className="flex items-center gap-2"><div className="w-6 h-6 rounded bg-neutral-200 dark:bg-neutral-700 border-2 border-dashed border-neutral-300 dark:border-neutral-600" /><span>Empty cell</span></div>
              {sections.map((section) => (
                <div key={section.id} className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded" style={{ background: `linear-gradient(135deg, ${section.color_hex || '#8B5CF6'}50, ${section.color_hex || '#8B5CF6'}10)`, border: `1.5px solid ${section.color_hex || '#8B5CF6'}` }} />
                  <span>{section.name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="flex-1 overflow-auto">
          <div className="glass-card p-6 hover:translate-y-0">
            <div className="flex justify-center mb-8">
              <div className="relative w-3/4 max-w-lg">
                <div className="h-2 bg-gradient-to-r from-transparent via-neutral-400 dark:via-neutral-500 to-transparent rounded-full" />
                <p className="text-center text-[10px] font-bold uppercase tracking-[0.3em] text-neutral-400 dark:text-neutral-500 mt-2">
                  {layout.screen_label || 'SCREEN'}
                </p>
              </div>
            </div>

            <div className="flex flex-col items-center gap-1 select-none" style={{ minWidth: layout.total_columns * 34 }} onMouseLeave={() => { if (isDragging) handleMouseUp() }}>
              {Array.from({ length: layout.total_rows }, (_, row) => (
                <div key={row} className="flex items-center gap-1">
                  <div className="w-6 text-right text-[10px] font-bold text-neutral-400 dark:text-neutral-500 shrink-0 mr-1">
                    {String.fromCharCode(65 + row)}
                  </div>
                  {Array.from({ length: layout.total_columns }, (_, col) => {
                    const seat = seatMap[`${row},${col}`]
                    const section = seat ? sectionMap[seat.seat_section_id] : null
                    const islounge = seat?.seat_kind === 'lounge'
                    const inDrag = isCellInDrag(row, col)

                    return (
                      <div
                        key={col}
                        onMouseDown={(event) => { event.preventDefault(); handleMouseDown(row, col) }}
                        onMouseEnter={() => handleMouseEnter(row, col)}
                        onMouseUp={handleMouseUp}
                        className={`relative flex items-center justify-center text-[9px] font-bold transition-all duration-100 rounded
                          ${seat
                            ? 'text-white shadow-sm cursor-pointer'
                            : isDraft
                              ? `border-2 border-dashed border-neutral-300 dark:border-neutral-700 text-neutral-300 dark:text-neutral-700 cursor-crosshair ${theme.gridHover}`
                              : 'border border-neutral-200 dark:border-neutral-800 text-transparent'
                          }
                          ${inDrag && !seat ? `ring-2 ${theme.dragRing} ring-offset-1 ring-offset-transparent ${theme.dragFill}` : ''}
                          ${inDrag && seat ? `ring-2 ${theme.dragRing} brightness-125` : ''}`}
                        style={{
                          width: islounge ? 62 : 28,
                          height: 28,
                          background: seat ? `linear-gradient(135deg, ${section?.color_hex || '#8B5CF6'}50, ${section?.color_hex || '#8B5CF6'}10)` : 'transparent',
                          border: seat ? `1.5px solid ${section?.color_hex || '#8B5CF6'}` : undefined,
                          textShadow: seat ? '0 1px 2px rgba(0,0,0,0.8)' : undefined,
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
                  <div className="w-6 text-left text-[10px] font-bold text-neutral-400 dark:text-neutral-500 shrink-0 ml-1">
                    {String.fromCharCode(65 + row)}
                  </div>
                </div>
              ))}

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

      <AnimatePresence>
        {showSectionModal && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setShowSectionModal(false)}>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="w-full max-w-md glass-card p-8 hover:translate-y-0" onClick={(event) => event.stopPropagation()}>
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-neutral-900 dark:text-white">{editingSection ? 'Edit' : 'New'} Section</h2>
                <button onClick={() => setShowSectionModal(false)} className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400 cursor-pointer"><X className="w-5 h-5" /></button>
              </div>
              <form onSubmit={handleSectionSubmit} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Name *</label>
                    <input type="text" required value={sectionForm.name} onChange={(event) => setSectionForm((prev) => ({ ...prev, name: event.target.value }))} className={`w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 transition-all ${theme.inputFocus}`} placeholder="Premium" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Code *</label>
                    <input type="text" required value={sectionForm.code} onChange={(event) => setSectionForm((prev) => ({ ...prev, code: event.target.value }))} className={`w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 transition-all ${theme.inputFocus}`} placeholder="premium" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Color</label>
                    <div className="flex items-center gap-3">
                      <input type="color" value={sectionForm.color_hex} onChange={(event) => setSectionForm((prev) => ({ ...prev, color_hex: event.target.value }))} className="w-12 h-12 rounded-lg border-2 border-neutral-300 dark:border-neutral-700 cursor-pointer" />
                      <div className="flex flex-wrap gap-1.5">
                        {DEFAULT_SECTION_COLORS.map((color) => (
                          <button key={color} type="button" onClick={() => setSectionForm((prev) => ({ ...prev, color_hex: color }))} className={`w-6 h-6 rounded cursor-pointer border-2 transition-all ${sectionForm.color_hex === color ? 'border-white scale-110 shadow-lg' : 'border-transparent'}`} style={{ backgroundColor: color }} />
                        ))}
                      </div>
                    </div>
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 ml-1">Rank</label>
                    <input type="number" min="0" value={sectionForm.rank} onChange={(event) => setSectionForm((prev) => ({ ...prev, rank: parseInt(event.target.value, 10) || 0 }))} className={`w-full bg-white dark:bg-neutral-900/50 border border-neutral-300 dark:border-neutral-700/50 text-neutral-900 dark:text-neutral-100 rounded-xl px-4 py-3 transition-all ${theme.inputFocus}`} placeholder="0" />
                  </div>
                </div>
                <button type="submit" className={`w-full mt-2 text-white font-medium py-3 px-6 rounded-xl shadow-lg transition-all hover:scale-105 active:scale-95 cursor-pointer ${theme.primaryButton}`}>
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
