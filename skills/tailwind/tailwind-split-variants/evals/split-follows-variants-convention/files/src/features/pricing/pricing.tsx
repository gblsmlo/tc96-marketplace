import { buttonVariants } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

export function Pricing() {
  return (
    <Card padding="lg">
      <h2 className="text-xl font-semibold">Pro</h2>
      <a href="/checkout" className={buttonVariants({ variant: 'outline', size: 'sm' })}>
        Choose plan
      </a>
    </Card>
  )
}
