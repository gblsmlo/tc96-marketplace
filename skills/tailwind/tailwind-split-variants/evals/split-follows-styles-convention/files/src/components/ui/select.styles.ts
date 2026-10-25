import { cva, type VariantProps } from 'class-variance-authority'

export const selectStyles = cva('h-9 w-full rounded-md border border-input bg-background px-3 text-sm', {
  variants: { invalid: { true: 'border-destructive', false: '' } },
})

export type SelectStyles = VariantProps<typeof selectStyles>
