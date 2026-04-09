function pad(value) {
  return String(value).padStart(2, '0')
}

export function toLocalDateValue(dateInput = new Date()) {
  const date = new Date(dateInput)
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

export function toLocalDateTimeValue(dateInput = new Date()) {
  const date = new Date(dateInput)
  date.setSeconds(0, 0)

  return `${toLocalDateValue(date)}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function isBeforeLocalDate(value, minValue = toLocalDateValue()) {
  if (!value) return false
  return value < minValue
}

export function isBeforeLocalDateTime(value, minValue = toLocalDateTimeValue()) {
  if (!value) return false
  return value < minValue
}
