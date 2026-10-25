import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const button = cva('inline-flex items-center rounded-md px-4 py-2 text-sm font-medium focus:outline-none', {
  variants: {
    intent: {
      primary: 'bg-zinc-900 text-white hover:bg-zinc-800',
      danger: 'bg-red-600 text-white hover:bg-red-700',
    },
  },
  defaultVariants: { intent: 'primary' },
})

type ButtonProps = React.ComponentProps<'button'> & VariantProps<typeof button>

export function Button({ className, intent, type = 'button', ...props }: ButtonProps) {
  return <button type={type} className={cn(className, button({ intent }))} {...props} />
}
