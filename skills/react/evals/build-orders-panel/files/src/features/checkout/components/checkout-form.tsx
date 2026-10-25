import { useState } from 'react'
import { useForm } from 'react-hook-form'

export function CheckoutForm() {
  const { register, handleSubmit, watch, reset } = useForm()
  const [email, setEmail] = useState('')
  const all = watch()

  const onSubmit = async (data: unknown) => {
    await fetch('/api/checkout', { method: 'POST', body: JSON.stringify(data) })
    reset()
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} onChange={(e) => setEmail(e.target.value)} />
      <input {...register('address')} />
      {all.address?.length > 0 && <input {...register('notes')} />}
      <button type="submit">Pay</button>
    </form>
  )
}
