import { cn } from '@/lib/utils'
import { cardVariants, type CardVariants } from './card.variants'

export function Card({ className, padding, ...props }: React.ComponentProps<'div'> & CardVariants) {
  return <div className={cn(cardVariants({ padding }), className)} {...props} />
}
