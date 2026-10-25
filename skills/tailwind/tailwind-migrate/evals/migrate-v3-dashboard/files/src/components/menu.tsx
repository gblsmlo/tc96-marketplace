export function Menu() {
  return (
    <div className="group relative">
      <button className="rounded px-3 py-2 hover:bg-gray-100">Account</button>
      <ul className="absolute hidden rounded border bg-white shadow group-hover:block">
        <li><a className="block px-3 py-2" href="/settings">Settings</a></li>
        <li><a className="block px-3 py-2" href="/logout">Log out</a></li>
      </ul>
    </div>
  )
}
