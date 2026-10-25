import { useEffect } from 'react'
import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router'
import '../styles.css'
import { Header } from '../components/header'

export const Route = createRootRoute({
  head: () => ({
    meta: [{ charSet: 'utf-8' }, { name: 'viewport', content: 'width=device-width, initial-scale=1' }, { title: 'Shop' }],
  }),
  component: RootComponent,
})

function RootComponent() {
  useEffect(() => {
    if (localStorage.getItem('theme') === 'dark') document.documentElement.classList.add('dark')
  }, [])

  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body className="bg-background text-foreground">
        <Header />
        <Outlet />
        <Scripts />
      </body>
    </html>
  )
}
