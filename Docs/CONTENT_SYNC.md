# Content Sync — Website Pages

The user-facing pages linked from the app live in a separate website repo.

**Website repo**: `/Users/mo/Developer/Kleingewerbe/Website`
**Section**: `projects/cost-tracker/`

| URL | File | Linked from |
|---|---|---|
| `mo-geb.com/projects/cost-tracker/` | `index.html` | Settings → Website |
| `.../terms` | `terms.html` | Settings → Terms of Service |
| `.../guide` | `guide.html` | Settings → User Guide |
| `.../patches` | `patches.html` | Settings → Patch Notes (added in 2.0.0) |
| `mo-geb.com/privacy/` | `privacy.html` | App Store Connect metadata only |

Marketing name in copy: **"ClutterFree Expenses"** (not "Kostentracker").

## Release checklist

For every public release that ships to the App Store:

1. **`patches.html`** — add a new `<div class="patch-item">` for the version with the changes.
2. **`guide.html`** — update if any user-visible feature changed (new screen, new button, new flow). Check screenshots are still accurate.
3. **`terms.html`** — only update if monetization model, data handling, or legal language actually changes.
4. **`privacy.html`** — only update if the data we collect/share changes. Apple requires this URL in App Store Connect.

Two git pushes per release: one app repo, one website repo.

## When linking *to* a new page from the app

If a feature needs a new page (or a new URL on an existing page), keep all URL strings in one place — currently scattered across [SettingsView.swift](../Kostentracker/View/Settings/SettingsView.swift). Worth centralizing into a `WebURLs` enum if this grows.
