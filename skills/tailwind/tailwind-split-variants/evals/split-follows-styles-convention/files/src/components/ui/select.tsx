import { cn } from '@/lib/utils'
import { selectStyles, type SelectStyles } from './select.styles'

export function Select({ className, invalid, ...props }: React.ComponentProps<'select'> & SelectStyles) {
  return <select className={cn(selectStyles({ invalid }), className)} {...props} />
}
