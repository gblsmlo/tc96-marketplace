import { cva, type VariantProps } from 'class-variance-authority'

export const cardVariants = cva('rounded-lg border bg-background text-foreground', {
  variants: {
    padding: { none: 'p-0', md: 'p-4', lg: 'p-6' },
  },
  defaultVariants: { padding: 'md' },
})

export type CardVariants = VariantProps<typeof cardVariants>
