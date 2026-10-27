import { expect, test } from "@playwright/test"

test("a seller sees each quote's status on the quotes page", async ({ page }) => {
  await page.goto("/quotes")
  await expect(page.getByText("approved")).toBeVisible()
})
