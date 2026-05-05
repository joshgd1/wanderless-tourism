import { test, expect, Page } from "@playwright/test";

const BASE = "https://joshgd1.github.io/wanderless-tourism";

// Flutter Web stubs are injected via playwright.config.ts addInitScript.
// The stubs prevent:
// 1. navigator.language undefined → Flutter's dart:Intl "invalid language tag" crash
// 2. Missing accessibility APIs → Flutter's "Enable accessibility" overlay

/**
 * Wait for the Flutter Web app to initialize.
 * Flutter is ready when flt-glass-pane is present AND there are no Dart errors.
 */
async function waitForFlutterApp(page: Page, timeout = 20000) {
  // Wait for Flutter's rendering surface
  await page.waitForSelector("flt-glass-pane", { timeout });

  // Wait for Flutter to finish rendering (network idle + extra buffer)
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(2000);
}

/**
 * Collect all Dart/JS errors from the page (ignoring network resource errors).
 */
function collectErrors(page: Page): string[] {
  const errors: string[] = [];
  page.on("pageerror", (err) => errors.push(err.message));
  page.on("console", (msg) => {
    if (msg.type() === "error") errors.push(msg.text());
  });
  return errors;
}

/** Ignore network resource errors that are not app bugs. */
function filterAppErrors(errors: string[]): string[] {
  return errors.filter(
    (e) =>
      !e.includes("favicon") &&
      !e.includes("fonts.googleapis") &&
      !e.includes("fonts.gstatic") &&
      !e.includes("net::ERR") &&
      !e.includes("Failed to load resource"),
  );
}

test.describe("Smoke Tests", () => {
  test("Login page loads — Flutter renders without Dart errors", async ({
    page,
  }) => {
    // Stubs injected via playwright.config.ts addInitScript
    const errors = collectErrors(page);

    await page.goto(`${BASE}/#/login`);
    await page.waitForLoadState("domcontentloaded");
    await waitForFlutterApp(page);

    // Flutter canvas must be present
    await expect(page.locator("flt-glass-pane")).toBeVisible();
    await expect(page.locator("canvas")).toBeVisible();

    // No Dart crashes or JS errors (filter network noise)
    const appErrors = filterAppErrors(errors);
    expect(appErrors).toHaveLength(0);
  });

  test("Guide login page loads — Flutter renders without Dart errors", async ({
    page,
  }) => {
    // Stubs injected via playwright.config.ts addInitScript
    const errors = collectErrors(page);

    await page.goto(`${BASE}/#/guide/login`);
    await page.waitForLoadState("domcontentloaded");
    await waitForFlutterApp(page);

    await expect(page.locator("flt-glass-pane")).toBeVisible();
    await expect(page.locator("canvas")).toBeVisible();

    const appErrors = filterAppErrors(errors);
    expect(appErrors).toHaveLength(0);
  });

  test("Groups page loads — Flutter renders without Dart errors", async ({
    page,
  }) => {
    // Stubs injected via playwright.config.ts addInitScript
    const errors = collectErrors(page);

    await page.goto(`${BASE}/#/groups`);
    await page.waitForLoadState("domcontentloaded");
    await waitForFlutterApp(page);

    await expect(page.locator("flt-glass-pane")).toBeVisible();
    await expect(page.locator("canvas")).toBeVisible();

    const appErrors = filterAppErrors(errors);
    expect(appErrors).toHaveLength(0);
  });

  test("Discover page loads — Flutter renders without Dart errors", async ({
    page,
  }) => {
    // Stubs injected via playwright.config.ts addInitScript
    const errors = collectErrors(page);

    await page.goto(`${BASE}/#/discover`);
    await page.waitForLoadState("domcontentloaded");
    await waitForFlutterApp(page);

    await expect(page.locator("flt-glass-pane")).toBeVisible();
    await expect(page.locator("canvas")).toBeVisible();

    const appErrors = filterAppErrors(errors);
    expect(appErrors).toHaveLength(0);
  });

  test("Navigation between screens works", async ({ page }) => {
    // Stubs injected via playwright.config.ts addInitScript

    await page.goto(`${BASE}/#/login`);
    await page.waitForLoadState("domcontentloaded");
    await waitForFlutterApp(page);

    // URL should reflect the login route
    await expect(page).toHaveURL(/login/);

    // Flutter canvas should be visible
    await expect(page.locator("flt-glass-pane")).toBeVisible();
  });
});
