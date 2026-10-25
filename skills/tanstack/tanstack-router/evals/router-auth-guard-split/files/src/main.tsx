import { RouterProvider } from '@tanstack/react-router'
import { createRoot } from 'react-dom/client'
import { AuthProvider } from './auth'
import { router } from './router'

createRoot(document.getElementById('root')!).render(
  <AuthProvider>
    <RouterProvider router={router} />
  </AuthProvider>,
)
