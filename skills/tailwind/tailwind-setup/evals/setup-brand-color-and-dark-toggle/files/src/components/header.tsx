export function Header() {
  function toggle() {
    const dark = document.documentElement.classList.toggle('dark')
    localStorage.setItem('theme', dark ? 'dark' : 'light')
  }

  return (
    <header className="flex items-center justify-between border-b px-6 py-4">
      <span className="text-brand text-xl font-semibold">Shop</span>
      <span className="rounded bg-warning px-2 text-xs">beta</span>
      <button type="button" onClick={toggle} className="rounded-md px-3 py-1 text-sm hover:bg-muted dark:hover:bg-muted">
        Toggle theme
      </button>
    </header>
  )
}
