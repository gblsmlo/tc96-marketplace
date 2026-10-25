import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const inputStyles = cva(
  'h-9 w-full rounded-md border border-input bg-background px-3 text-sm outline-hidden focus-visible:ring-2 focus-visible:ring-ring',
  {
    variants: {
      size: { sm: 'h-8 text-xs', md: 'h-9' },
      invalid: { true: 'border-destructive', false: '' },
    },
    defaultVariants: { size: 'md', invalid: false },
  },
)

export function Input({ className, size, invalid, ...props }: Omit<React.ComponentProps<'input'>, 'size'> & VariantProps<typeof inputStyles>) {
  return <input className={cn(inputStyles({ size, invalid }), className)} {...props} />
}
