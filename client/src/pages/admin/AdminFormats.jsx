import { MonitorPlay } from 'lucide-react'
import AdminRefCrud from '../../components/AdminRefCrud'

const fields = [
  { key: 'name', label: 'Name', placeholder: 'IMAX' },
  { key: 'code', label: 'Code', placeholder: 'imax' },
]

export default function AdminFormats() {
  return <AdminRefCrud entityName="Formats" apiPath="formats" icon={MonitorPlay} fields={fields} color="amber" />
}
