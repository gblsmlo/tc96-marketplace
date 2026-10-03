// bench-harness v1 — example adapter. A tiny selectable list, defined inline, benchmarked through
// its public surface only: props in, DOM out, and a counter on the consumer's renderItem.
//
//   bun scripts/example/bench-example.ts --json /tmp/base.json
//   EXAMPLE_NO_MEMO=1 bun scripts/example/bench-example.ts --compare /tmp/base.json --gate   -> exits 1
//   bun scripts/example/bench-example.ts --compare /tmp/base.json --gate                     -> exits 0
//
// Needs react, react-dom and jsdom resolvable from this file (run it inside a project that has them).

import { countRenders, createBench, fire, type MountTools, seededRandom } from '../bench-harness'
import { type ChangeEvent, createElement, memo, type ReactNode, useCallback, useState } from 'react'

interface Item {
  id: string
  label: string
}

type RenderItem = (item: Item, selected: boolean) => ReactNode

interface RowProps {
  item: Item
  selected: boolean
  onSelect: (id: string) => void
  renderItem: RenderItem
}

function Row({ item, selected, onSelect, renderItem }: RowProps) {
  return createElement(
    'li',
    { 'aria-selected': selected, onClick: () => onSelect(item.id), role: 'option' },
    renderItem(item, selected),
  )
}

const MemoRow = memo(Row)
const RowComponent = process.env.EXAMPLE_NO_MEMO ? Row : MemoRow

function List({ items, renderItem }: { items: Item[]; renderItem: RenderItem }) {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [, setTick] = useState(0)
  const onSelect = useCallback((id: string) => setSelectedId(id), [])
  const visible = query ? items.filter((item) => item.label.includes(query)) : items
  return createElement(
    'div',
    null,
    createElement('input', {
      'aria-label': 'Filter',
      onChange: (event: ChangeEvent<HTMLInputElement>) => setQuery(event.target.value),
      value: query,
    }),
    createElement('button', { onClick: () => setTick((t) => t + 1), type: 'button' }, 'Refresh'),
    createElement(
      'ul',
      { 'aria-label': 'Items', role: 'listbox' },
      visible.map((item) =>
        createElement(RowComponent, {
          item,
          key: item.id,
          onSelect,
          renderItem,
          selected: item.id === selectedId,
        }),
      ),
    ),
  )
}

const SEED = 96

function buildItems(count: number): Item[] {
  const random = seededRandom(SEED)
  return Array.from({ length: count }, (_, index) => ({
    id: `item-${index}`,
    label: `Item ${index} ${Math.floor(random() * 1e6)}`,
  }))
}

const renderItem = countRenders<[Item, boolean], ReactNode>(
  (item, selected) => createElement('span', null, selected ? `> ${item.label}` : item.label),
  'renderItem',
)

interface Handle {
  container: HTMLElement
  size: number
}

const option = (handle: Handle, index: number) => {
  const element = handle.container.querySelectorAll('[role="option"]')[index]
  if (!element) throw new Error(`option ${index} not found`)
  return element
}

const listCase = (size: number) => ({
  id: `list ${size}`,
  mount(container: HTMLElement, tools: MountTools) {
    tools.render(createElement(List, { items: buildItems(size), renderItem }))
    return { container, size }
  },
})

const bench = createBench<Handle>({
  cases: [listCase(100), listCase(1000)],
  name: 'example list',
  scenarios: [
    {
      name: 'select click',
      setup: (handle) => fire.click(option(handle, 0)),
      run: (handle, { index }) => fire.click(option(handle, (index % (handle.size - 1)) + 1)),
    },
    {
      name: 'parent re-render',
      run: (handle) => {
        const button = handle.container.querySelector('button')
        if (!button) throw new Error('refresh button not found')
        fire.click(button)
      },
    },
  ],
  seed: SEED,
})

await bench.run()
