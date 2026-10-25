import { z } from 'zod'

/** Shared with the web app: the sign-up form validates with the same schema. */
export const SignUp = z.object({
  name: z.string().min(2),
  email: z.email(),
  password: z.string().min(10),
  plan: z.enum(['free', 'pro']).default('free'),
})
export type SignUp = z.infer<typeof SignUp>
