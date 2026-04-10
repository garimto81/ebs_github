import { test } from '@playwright/test'

const BASE = 'http://localhost:5173'

test('debug login attempt', async ({ page }) => {
  const logs: string[] = []
  page.on('console', msg => logs.push(`[${msg.type()}] ${msg.text()}`))
  page.on('pageerror', err => logs.push(`[PAGE_ERROR] ${err.message}`))

  await page.goto(`${BASE}/login`)
  await page.waitForLoadState('networkidle')

  // Check initial state
  const url0 = page.url()
  console.log('Initial URL:', url0)
  await page.screenshot({ path: '.tmp/login-debug-01.png', fullPage: true })

  // Fill and submit
  await page.locator('input[type="email"]').fill('admin@ebs.local')
  await page.locator('input[type="password"]').fill('mock')
  await page.locator('button[type="submit"]').first().click()

  // Wait for response
  await page.waitForTimeout(3000)

  const url1 = page.url()
  console.log('URL after login:', url1)

  // Check for errors or dialog
  const bodyText = await page.locator('body').textContent()
  console.log('Body text (first 500):', bodyText?.substring(0, 500))

  // Check for error messages
  const formError = page.locator('.form-error')
  if (await formError.isVisible().catch(() => false)) {
    console.log('FORM ERROR:', await formError.textContent())
  }

  await page.screenshot({ path: '.tmp/login-debug-02.png', fullPage: true })

  // Print all console logs
  for (const log of logs) {
    console.log(log)
  }
})
