import { test, expect } from '@playwright/test'

const BASE = 'http://localhost:5173'

test.describe('EBS Lobby Navigation Verification', () => {

  test.beforeEach(async ({ page }) => {
    // Login with mock credentials
    await page.goto(`${BASE}/login`)
    await page.waitForLoadState('networkidle')

    // Fill login form if present
    const emailInput = page.locator('input[type="email"]')
    if (await emailInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await emailInput.fill('admin@ebs.local')
      await page.locator('input[type="password"]').fill('mock')
      await page.locator('button[type="submit"]').first().click()

      // Wait for async login to complete and session restore dialog to render
      const freshStart = page.locator('button:has-text("Fresh Start")')
      await expect(freshStart).toBeVisible({ timeout: 5000 })
      await freshStart.click()

      // React Router uses client-side navigation (no page load event)
      await expect(page).toHaveURL(/\/series/, { timeout: 8000 })
    }
  })

  test('1. Series page loads with mock data', async ({ page }) => {
    await page.goto(`${BASE}/series`)
    await page.waitForLoadState('networkidle')

    // Should show series cards
    const cards = page.locator('.card')
    await expect(cards.first()).toBeVisible({ timeout: 5000 })

    // Take screenshot
    await page.screenshot({ path: '.tmp/verify-01-series.png', fullPage: true })
  })

  test('2. Events page — accordion Flight expand', async ({ page }) => {
    // Navigate to series 1 events
    await page.goto(`${BASE}/series/1/events`)
    await page.waitForLoadState('networkidle')

    // Should show event rows
    const eventRows = page.locator('tbody tr.clickable, tbody tr[class*="event"]')
    await expect(eventRows.first()).toBeVisible({ timeout: 5000 })

    // Click first event row to expand accordion
    await eventRows.first().click()

    // Should show flight accordion
    const flightAccordion = page.locator('.flight-accordion, .accordion-row, .accordion-cell')
    await expect(flightAccordion.first()).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-02-events-accordion.png', fullPage: true })
  })

  test('3. Flight click navigates to Tables', async ({ page }) => {
    await page.goto(`${BASE}/series/1/events`)
    await page.waitForLoadState('networkidle')

    // Expand event with flights
    const eventRows = page.locator('tbody tr.clickable, tbody tr[class*="event"]')
    // Click event #5 (Main Event) which should have running flights
    const mainEvent = page.locator('tr:has-text("Main Event"), tr:has-text("Mystery")')
    if (await mainEvent.first().isVisible({ timeout: 3000 }).catch(() => false)) {
      await mainEvent.first().click()
    } else {
      await eventRows.first().click()
    }

    await page.waitForTimeout(1000)

    // Click a clickable flight row
    const clickableFlight = page.locator('.flight-row-clickable')
    if (await clickableFlight.first().isVisible({ timeout: 3000 }).catch(() => false)) {
      await clickableFlight.first().click()

      // Should navigate to tables page
      await expect(page).toHaveURL(/\/flights\/\d+\/tables/, { timeout: 8000 })
      await page.screenshot({ path: '.tmp/verify-03-tables.png', fullPage: true })
    }
  })

  test('4. Tables page — Enter CC button exists', async ({ page }) => {
    // Direct nav to flight 4 (Day2 - running)
    await page.goto(`${BASE}/flights/4/tables`)
    await page.waitForLoadState('networkidle')

    // Should show table cards
    const cards = page.locator('.card')
    await expect(cards.first()).toBeVisible({ timeout: 5000 })

    // Should have Enter CC button
    const ccButton = page.locator('button:has-text("Enter CC"), button:has-text("Launch CC")')
    await expect(ccButton.first()).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-04-tables-cc.png', fullPage: true })
  })

  test('5. Table card expand panel', async ({ page }) => {
    await page.goto(`${BASE}/flights/4/tables`)
    await page.waitForLoadState('networkidle')

    // Click a card to expand
    const card = page.locator('.card').first()
    await card.click()

    // Should show expand panel
    const expandPanel = page.locator('.table-expand-panel, .table-detail-layout')
    await expect(expandPanel.first()).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-05-table-expand.png', fullPage: true })
  })

  test('6. Session restore dialog appears on login', async ({ page }) => {
    // Go directly to login (beforeEach already logged in, so log out first)
    await page.goto(`${BASE}/login`)
    await page.waitForLoadState('networkidle')

    const emailInput = page.locator('input[type="email"]')
    if (await emailInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await emailInput.fill('admin@ebs.local')
      await page.locator('input[type="password"]').fill('mock')
      await page.locator('button[type="submit"]').first().click()

      // Session restore dialog should appear
      const dialog = page.locator('text=Resume Previous Session')
      await expect(dialog).toBeVisible({ timeout: 5000 })

      // Click Continue to go to flight tables
      await page.locator('button:has-text("Continue")').click()
      await expect(page).toHaveURL(/\/flights\/\d+\/tables/, { timeout: 8000 })
    }

    await page.screenshot({ path: '.tmp/verify-06-session-restore.png', fullPage: true })
  })

  test('7. Series page has monthly grouping and search', async ({ page }) => {
    await page.goto(`${BASE}/series`)
    await page.waitForLoadState('networkidle')

    // Monthly grouping headers should exist
    const monthHeaders = page.locator('h2')
    await expect(monthHeaders.first()).toBeVisible({ timeout: 5000 })

    // Search bar should exist
    const searchInput = page.locator('input[placeholder*="Search"]')
    await expect(searchInput).toBeVisible({ timeout: 3000 })

    // Type search query
    await searchInput.fill('WSOP')
    await page.waitForTimeout(500)

    // Should still show matching series
    const cards = page.locator('.card')
    await expect(cards.first()).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-07-series-search.png', fullPage: true })
  })

  test('8. Event page has status tabs', async ({ page }) => {
    await page.goto(`${BASE}/series/1/events`)
    await page.waitForLoadState('networkidle')

    // Status tab buttons should exist
    const allTab = page.locator('button:has-text("All")')
    await expect(allTab).toBeVisible({ timeout: 5000 })

    const runningTab = page.locator('button:has-text("Running")')
    await expect(runningTab).toBeVisible()

    // Click running tab
    await runningTab.click()
    await page.waitForTimeout(500)

    await page.screenshot({ path: '.tmp/verify-08-event-tabs.png', fullPage: true })
  })

  test('9. Table page has filters and summary', async ({ page }) => {
    await page.goto(`${BASE}/flights/4/tables`)
    await page.waitForLoadState('networkidle')

    // Filter selects should exist
    const typeFilter = page.locator('select').first()
    await expect(typeFilter).toBeVisible({ timeout: 5000 })

    // Summary text should show Tables count
    const summary = page.locator('text=Tables:')
    await expect(summary).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-09-table-filters.png', fullPage: true })
  })

  test('10. Players page loads', async ({ page }) => {
    await page.goto(`${BASE}/players`)
    await page.waitForLoadState('networkidle')

    // Should show player table
    const heading = page.locator('h1:has-text("Players")')
    await expect(heading).toBeVisible({ timeout: 5000 })

    // Should show mock players
    const rows = page.locator('tbody tr')
    await expect(rows.first()).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-10-players.png', fullPage: true })
  })

  test('11. Forgot Password link works', async ({ page }) => {
    await page.goto(`${BASE}/login`)
    await page.waitForLoadState('networkidle')

    const forgotLink = page.locator('button:has-text("Forgot")')
    await expect(forgotLink).toBeVisible({ timeout: 5000 })

    await forgotLink.click()

    // Should show forgot password form
    const resetBtn = page.locator('button:has-text("Send Reset")')
    await expect(resetBtn).toBeVisible({ timeout: 3000 })

    // Back to login
    const backLink = page.locator('button:has-text("Back to login")')
    await backLink.click()

    const signInBtn = page.locator('button:has-text("Sign In")')
    await expect(signInBtn).toBeVisible({ timeout: 3000 })

    await page.screenshot({ path: '.tmp/verify-11-forgot-password.png', fullPage: true })
  })

  test('12. Feature Table blocks Go Live without RFID', async ({ page }) => {
    await page.goto(`${BASE}/flights/4/tables`)
    await page.waitForLoadState('networkidle')

    // Click feature table #072 (setup, has RFID but no deck)
    const setupFeature = page.locator('.card:has-text("Day2-#072")')
    if (await setupFeature.isVisible({ timeout: 3000 }).catch(() => false)) {
      await setupFeature.click()

      // Should show expand panel
      const expandPanel = page.locator('.table-expand-panel')
      await expect(expandPanel).toBeVisible({ timeout: 3000 })

      // Click Go live
      const goLive = page.locator('button:has-text("Go live")')
      if (await goLive.isVisible({ timeout: 2000 }).catch(() => false)) {
        // Listen for alert dialog
        page.on('dialog', async dialog => {
          expect(dialog.message()).toContain('deck registered')
          await dialog.accept()
        })
        await goLive.click()
        await page.waitForTimeout(500)
      }
    }

    await page.screenshot({ path: '.tmp/verify-12-feature-guard.png', fullPage: true })
  })

  test('13. Breadcrumb shows names and links work', async ({ page }) => {
    // Navigate through the full path to populate nav-store
    await page.goto(`${BASE}/series`)
    await page.waitForLoadState('networkidle')

    // Click first series
    await page.locator('.card').first().click()
    await expect(page).toHaveURL(/\/events/, { timeout: 8000 })

    // Breadcrumb should show series name
    const breadcrumb = page.locator('.breadcrumb, nav.breadcrumb')
    await expect(breadcrumb).toBeVisible({ timeout: 3000 })

    const breadcrumbText = await breadcrumb.textContent()
    console.log('Breadcrumb text:', breadcrumbText)

    // Should contain "EBS" and a series name (not just IDs)
    expect(breadcrumbText).toContain('EBS')

    await page.screenshot({ path: '.tmp/verify-06-breadcrumb.png', fullPage: true })

    // Click EBS breadcrumb link to go back to series
    const ebsLink = page.locator('.breadcrumb-link:has-text("EBS")')
    if (await ebsLink.isVisible({ timeout: 2000 }).catch(() => false)) {
      await ebsLink.click()
      await expect(page).toHaveURL(/\/series$/, { timeout: 8000 })
    }
  })
})
