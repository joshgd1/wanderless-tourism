import { defineConfig, devices } from "@playwright/test";

/**
 * Flutter Web initialization stubs injected before any page JavaScript runs.
 *
 * Covers two failure modes in headless environments:
 * 1. navigator.language/languages returning undefined → Flutter's dart:Intl
 *    crashes with "invalid language tag: undefined".
 * 2. Missing accessibility APIs → Flutter shows the "Enable accessibility"
 *    overlay instead of rendering the app.
 */
const flutterWebStub = `
(function() {
  // Locale — must be valid BCP 47 or Flutter's dart:Intl crashes
  Object.defineProperty(navigator, 'language', {
    value: 'en-US', writable: true, configurable: true,
  });
  Object.defineProperty(navigator, 'languages', {
    value: ['en-US', 'en'], writable: true, configurable: true,
  });
  // Accessibility — prevent Flutter's accessibility overlay
  Object.defineProperty(window, 'accessibilityFeatures', {
    value: { exhaustive: true, spokenSurprise: true, animations: true },
    writable: true, configurable: true,
  });
  Object.defineProperty(window, 'axActivator', {
    value: { activate: function(){}, deactivate: function(){} },
    writable: true, configurable: true,
  });
  Object.defineProperty(window, 'axo', {
    value: true, writable: true, configurable: true,
  });
  Object.defineProperty(navigator, 'accessibilityControls', {
    value: { enabled: true }, writable: true, configurable: true,
  });
})();
`;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  timeout: 30000,
  use: {
    baseURL: "https://joshgd1.github.io/wanderless-tourism",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        // Stub browser APIs before Flutter loads to prevent crashes and overlays
        addInitScript: flutterWebStub,
      },
    },
    {
      name: "firefox",
      use: {
        ...devices["Desktop Firefox"],
        addInitScript: flutterWebStub,
        launchOptions: {
          firefoxUserPrefs: {
            "privacy.accessibility.enabled": false,
          },
        },
      },
    },
    {
      name: "mobile",
      use: {
        ...devices["iPhone 15 Pro"],
        addInitScript: flutterWebStub,
      },
    },
  ],
});
