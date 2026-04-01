import { Globe } from 'lucide-react'
import AdminRefCrud from '../../components/AdminRefCrud'

const fields = [
  { key: 'name', label: 'Name', placeholder: 'Hindi' },
  { key: 'code', label: 'Code', placeholder: 'hi' },
]

export default function AdminLanguages() {
  return <AdminRefCrud entityName="Languages" apiPath="languages" icon={Globe} fields={fields} color="emerald" />
}
