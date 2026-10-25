import { cva } from 'class-variance-authority'
import { cn } from '@/lib/utils'

type AlertProps = React.ComponentProps<'div'> & { intent?: 'info' | 'warning' | 'error' }

export function Alert({ className, intent = 'info', ...props }: AlertProps) {
  const alertStyles = cva('relative w-full rounded-lg border p-4 text-sm', {
    variants: {
      intent: {
        info: 'border-border bg-background text-foreground',
        warning: 'border-warning/50 bg-warning/10 text-warning-foreground',
        error: 'border-destructive/50 bg-destructive/10 text-destructive',
      },
    },
  })
  return <div role="alert" className={cn(alertStyles({ intent }), className)} {...props} />
}
