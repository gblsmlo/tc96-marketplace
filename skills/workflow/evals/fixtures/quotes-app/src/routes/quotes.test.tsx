import { expect, test } from "bun:test"
import { render, screen } from "@testing-library/react"
import { QuotesTable } from "./quotes"

test("AC-06: each quote shows its status", () => {
  render(<QuotesTable data={[
    { id: "1", customerEmail: "a@x.com", listPrice: 100, status: "approved" },
    { id: "2", customerEmail: "b@x.com", listPrice: 200, status: "pending" },
    { id: "3", customerEmail: "c@x.com", listPrice: 300, status: "rejected" },
  ]} />)
  expect(screen.getByText("approved")).toBeTruthy()
  expect(screen.getByText("pending")).toBeTruthy()
  expect(screen.getByText("rejected")).toBeTruthy()
})
