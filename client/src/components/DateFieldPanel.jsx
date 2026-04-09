import { useEffect, useMemo, useRef, useState } from 'react'
import { CalendarDays, ChevronLeft, ChevronRight, Clock3 } from 'lucide-react'

const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
]

const WEEKDAY_NAMES = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']

function pad(value) {
  return String(value).padStart(2, '0')
}

function parseLocalValue(value, type) {
  if (!value) return null

  if (type === 'date') {
    const [year, month, day] = value.split('-').map(Number)
    if (!year || !month || !day) return null
    return new Date(year, month - 1, day, 12, 0, 0, 0)
  }

  const [datePart, timePart = '00:00'] = value.split('T')
  const [year, month, day] = datePart.split('-').map(Number)
  const [hour = 0, minute = 0] = timePart.split(':').map(Number)

  if (!year || !month || !day) return null
  return new Date(year, month - 1, day, hour, minute, 0, 0)
}

function formatDateValue(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

function formatDateTimeValue(date, time = {}) {
  const hours = time.hours ?? date.getHours()
  const minutes = time.minutes ?? date.getMinutes()
  return `${formatDateValue(date)}T${pad(hours)}:${pad(minutes)}`
}

function formatDisplayValue(value, type) {
  const parsed = parseLocalValue(value, type)
  if (!parsed) return ''

  if (type === 'date') {
    return parsed.toLocaleDateString([], {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    })
  }

  return parsed.toLocaleString([], {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function startOfDay(date) {
  const next = new Date(date)
  next.setHours(0, 0, 0, 0)
  return next
}

function sameDay(a, b) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

function buildCalendarDays(monthDate) {
  const firstOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1)
  const firstWeekday = (firstOfMonth.getDay() + 6) % 7
  const calendarStart = new Date(firstOfMonth)
  calendarStart.setDate(firstOfMonth.getDate() - firstWeekday)

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(calendarStart)
    date.setDate(calendarStart.getDate() + index)
    return date
  })
}

export default function DateFieldPanel({
  icon: Icon,
  label,
  type = 'datetime-local',
  value,
  onChange,
  min,
  name,
  required = false,
  disabled = false,
  hint,
  error,
}) {
  const inputId = `${name || label}-${type}`.toLowerCase().replace(/[^a-z0-9]+/g, '-')
  const wrapperRef = useRef(null)
  const committedDate = useMemo(() => parseLocalValue(value, type), [value, type])
  const minDate = useMemo(() => parseLocalValue(min, type), [min, type])
  const baseDate = committedDate || minDate || new Date()

  const [isOpen, setIsOpen] = useState(false)
  const [visibleMonth, setVisibleMonth] = useState(
    new Date(baseDate.getFullYear(), baseDate.getMonth(), 1)
  )
  const [draftDate, setDraftDate] = useState(baseDate)
  const [draftHours, setDraftHours] = useState(baseDate.getHours())
  const [draftMinutes, setDraftMinutes] = useState(baseDate.getMinutes())

  useEffect(() => {
    const nextBase = committedDate || minDate || new Date()
    setVisibleMonth(new Date(nextBase.getFullYear(), nextBase.getMonth(), 1))
    setDraftDate(nextBase)
    setDraftHours(nextBase.getHours())
    setDraftMinutes(nextBase.getMinutes())
  }, [committedDate, minDate])

  useEffect(() => {
    if (!isOpen) return undefined

    function handleClickOutside(event) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setIsOpen(false)
      }
    }

    function handleEscape(event) {
      if (event.key === 'Escape') {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    document.addEventListener('keydown', handleEscape)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
      document.removeEventListener('keydown', handleEscape)
    }
  }, [isOpen])

  const calendarDays = useMemo(() => buildCalendarDays(visibleMonth), [visibleMonth])
  const availableYears = useMemo(() => {
    const currentYear = new Date().getFullYear()
    const startYear = minDate ? minDate.getFullYear() : currentYear - 5
    return Array.from({ length: 12 }, (_, index) => startYear + index)
  }, [minDate])

  const displayValue = formatDisplayValue(value, type)

  function emitChange(nextValue) {
    onChange?.({ target: { name, value: nextValue } })
  }

  function isBeforeMin(candidate) {
    if (!minDate) return false
    if (type === 'date') return startOfDay(candidate) < startOfDay(minDate)
    return candidate < minDate
  }

  function handleDaySelect(day) {
    if (isBeforeMin(day)) return

    setDraftDate(day)
    setVisibleMonth(new Date(day.getFullYear(), day.getMonth(), 1))

    if (type === 'date') {
      emitChange(formatDateValue(day))
      setIsOpen(false)
    }
  }

  function handleApply() {
    const nextValue =
      type === 'date'
        ? formatDateValue(draftDate)
        : formatDateTimeValue(draftDate, { hours: draftHours, minutes: draftMinutes })

    const nextDate = parseLocalValue(nextValue, type)
    if (nextDate && isBeforeMin(nextDate)) return

    emitChange(nextValue)
    setIsOpen(false)
  }

  function handleCancel() {
    const nextBase = committedDate || minDate || new Date()
    setDraftDate(nextBase)
    setDraftHours(nextBase.getHours())
    setDraftMinutes(nextBase.getMinutes())
    setVisibleMonth(new Date(nextBase.getFullYear(), nextBase.getMonth(), 1))
    setIsOpen(false)
  }

  const selectedDate = draftDate
  const selectedDateTime =
    type === 'datetime-local'
      ? new Date(
          draftDate.getFullYear(),
          draftDate.getMonth(),
          draftDate.getDate(),
          draftHours,
          draftMinutes,
          0,
          0
        )
      : draftDate

  return (
    <div ref={wrapperRef} className="space-y-2">
      <label htmlFor={inputId} className="flex items-center justify-between gap-3">
        <span className="flex items-center text-sm font-medium text-neutral-700 dark:text-neutral-300">
          {Icon ? (
            <span className="mr-2 flex h-8 w-8 items-center justify-center rounded-xl bg-primary-500/10 text-primary-500">
              <Icon className="w-4 h-4" />
            </span>
          ) : null}
          {label}
          {required ? ' *' : ''}
        </span>
        {type === 'datetime-local' ? (
          <span className="rounded-full bg-neutral-100 px-2.5 py-1 text-[10px] font-bold uppercase tracking-[0.2em] text-neutral-500 dark:bg-neutral-800 dark:text-neutral-400">
            Local Time
          </span>
        ) : null}
      </label>

      <input id={inputId} name={name} type="hidden" value={value} required={required} />

      <button
        type="button"
        disabled={disabled}
        onClick={() => setIsOpen((open) => !open)}
        className={`relative flex w-full items-center justify-between rounded-2xl border px-4 py-3 text-left transition-all ${
          error
            ? 'border-red-400 bg-red-50/60 dark:border-red-500/60 dark:bg-red-500/10'
            : 'border-neutral-200 bg-white/90 dark:border-neutral-800 dark:bg-neutral-900/70'
        } disabled:cursor-not-allowed disabled:opacity-50`}
      >
        <div>
          <p className="text-[10px] font-bold uppercase tracking-[0.24em] text-neutral-400 dark:text-neutral-500">
            {type === 'date' ? 'Pick a date' : 'Pick a date & time'}
          </p>
          <p className="mt-1 text-sm font-medium text-neutral-900 dark:text-neutral-100">
            {displayValue || (type === 'date' ? 'Select a release date' : 'Select a future date and time')}
          </p>
        </div>
        <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-neutral-100 text-neutral-500 dark:bg-neutral-800 dark:text-neutral-300">
          {type === 'date' ? <CalendarDays className="h-4 w-4" /> : <Clock3 className="h-4 w-4" />}
        </span>
      </button>

      {isOpen ? (
        <div className="relative z-40 overflow-hidden rounded-[1.5rem] border border-neutral-200 bg-white shadow-2xl dark:border-neutral-800 dark:bg-neutral-950">
          <div className="p-4">
            <div className="grid grid-cols-5 items-center gap-x-3 pb-4">
              <div className="col-span-1">
                <button
                  type="button"
                  onClick={() =>
                    setVisibleMonth(
                      new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() - 1, 1)
                    )
                  }
                  className="flex h-9 w-9 items-center justify-center rounded-full text-neutral-800 hover:bg-neutral-100 dark:text-neutral-200 dark:hover:bg-neutral-800"
                  aria-label="Previous"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
              </div>

              <div className="col-span-3 flex items-center justify-center gap-2">
                <select
                  value={visibleMonth.getMonth()}
                  onChange={(event) =>
                    setVisibleMonth(
                      new Date(visibleMonth.getFullYear(), Number(event.target.value), 1)
                    )
                  }
                  className="rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm font-semibold text-neutral-800 outline-none dark:border-neutral-700 dark:bg-neutral-900 dark:text-neutral-200"
                >
                  {MONTH_NAMES.map((monthName, index) => (
                    <option key={monthName} value={index}>
                      {monthName}
                    </option>
                  ))}
                </select>

                <select
                  value={visibleMonth.getFullYear()}
                  onChange={(event) =>
                    setVisibleMonth(
                      new Date(Number(event.target.value), visibleMonth.getMonth(), 1)
                    )
                  }
                  className="rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm font-semibold text-neutral-800 outline-none dark:border-neutral-700 dark:bg-neutral-900 dark:text-neutral-200"
                >
                  {availableYears.map((year) => (
                    <option key={year} value={year}>
                      {year}
                    </option>
                  ))}
                </select>
              </div>

              <div className="col-span-1 flex justify-end">
                <button
                  type="button"
                  onClick={() =>
                    setVisibleMonth(
                      new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() + 1, 1)
                    )
                  }
                  className="flex h-9 w-9 items-center justify-center rounded-full text-neutral-800 hover:bg-neutral-100 dark:text-neutral-200 dark:hover:bg-neutral-800"
                  aria-label="Next"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-7 gap-1 pb-2">
              {WEEKDAY_NAMES.map((weekday) => (
                <span
                  key={weekday}
                  className="block text-center text-xs font-medium text-neutral-500 dark:text-neutral-400"
                >
                  {weekday}
                </span>
              ))}
            </div>

            <div className="grid grid-cols-7 gap-1">
              {calendarDays.map((day) => {
                const inCurrentMonth = day.getMonth() === visibleMonth.getMonth()
                const disabledDay = !inCurrentMonth || isBeforeMin(day)
                const isSelected = sameDay(day, selectedDate)

                return (
                  <button
                    key={day.toISOString()}
                    type="button"
                    disabled={disabledDay}
                    onClick={() => handleDaySelect(day)}
                    className={`h-10 w-10 rounded-full border text-sm transition-all ${
                      isSelected
                        ? 'border-transparent bg-blue-600 font-semibold text-white dark:bg-blue-500'
                        : 'border-transparent text-neutral-800 hover:border-blue-600 hover:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-400'
                    } ${disabledDay ? 'cursor-not-allowed opacity-35' : ''}`}
                  >
                    {day.getDate()}
                  </button>
                )
              })}
            </div>

            {type === 'datetime-local' ? (
              <div className="mt-4 flex items-center justify-center gap-2 border-t border-neutral-200 pt-4 dark:border-neutral-800">
                <select
                  value={draftHours}
                  onChange={(event) => setDraftHours(Number(event.target.value))}
                  className="rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm font-medium text-neutral-800 outline-none dark:border-neutral-700 dark:bg-neutral-900 dark:text-neutral-200"
                >
                  {Array.from({ length: 24 }, (_, hour) => (
                    <option key={hour} value={hour}>
                      {pad(hour)}
                    </option>
                  ))}
                </select>
                <span className="text-neutral-500 dark:text-neutral-400">:</span>
                <select
                  value={draftMinutes}
                  onChange={(event) => setDraftMinutes(Number(event.target.value))}
                  className="rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm font-medium text-neutral-800 outline-none dark:border-neutral-700 dark:bg-neutral-900 dark:text-neutral-200"
                >
                  {Array.from({ length: 12 }, (_, step) => step * 5).map((minute) => (
                    <option key={minute} value={minute}>
                      {pad(minute)}
                    </option>
                  ))}
                </select>
              </div>
            ) : null}
          </div>

          <div className="flex items-center justify-end gap-2 border-t border-neutral-200 px-4 py-3 dark:border-neutral-800">
            <button
              type="button"
              onClick={handleCancel}
              className="rounded-xl border border-neutral-200 bg-white px-3 py-2 text-xs font-bold text-neutral-800 transition-all hover:bg-neutral-50 dark:border-neutral-700 dark:bg-neutral-800 dark:text-neutral-200 dark:hover:bg-neutral-700"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleApply}
              disabled={Boolean(selectedDateTime && isBeforeMin(selectedDateTime))}
              className="rounded-xl bg-blue-600 px-3 py-2 text-xs font-bold text-white transition-all hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-blue-500 dark:hover:bg-blue-600"
            >
              Apply
            </button>
          </div>
        </div>
      ) : null}

      {error ? (
        <p className="text-xs font-medium text-red-500">{error}</p>
      ) : hint ? (
        <p className="text-xs font-medium text-neutral-500 dark:text-neutral-400">{hint}</p>
      ) : null}
    </div>
  )
}
