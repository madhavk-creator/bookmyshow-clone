import { MapPin } from 'lucide-react'
import AdminRefCrud from '../../components/AdminRefCrud'

const fields = [
  { key: 'name', label: 'Name', placeholder: 'Mumbai' },
  { key: 'state', label: 'State', placeholder: 'Maharashtra' },
]

export default function AdminCities() {
  return <AdminRefCrud entityName="Cities" apiPath="cities" paramKey="city" icon={MapPin} fields={fields} color="blue" />
}
