import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const pill = 'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium'
const dot = 'size-1.5 rounded-full bg-current'

export const badgeVariants = cva(pill, {
  variants: {
    tone: {
      neutral: 'bg-muted text-muted-foreground',
      success: 'bg-success text-success-foreground',
      danger: 'bg-destructive text-destructive-foreground',
    },
  },
  defaultVariants: { tone: 'neutral' },
})

export type BadgeProps = React.ComponentProps<'span'> & VariantProps<typeof badgeVariants> & { withDot?: boolean }

export function Badge({ className, tone, withDot, children, ...props }: BadgeProps) {
  return (
    <span className={cn(badgeVariants({ tone }), className)} {...props}>
      {withDot && <span aria-hidden="true" className={dot} />}
      {children}
    </span>
  )
}
