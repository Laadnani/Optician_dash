# Doc CRM — design export (for redesign handoff)

Static HTML/CSS replica of the current Flutter app, generated directly from the app's own source (routes, nav labels, KPI cards, form fields). Open `index.html` to browse every screen.

## What's in here

```
index.html              ← start here — links to all 29 pages, grouped like the sidebar
pages/*.html             ← one file per screen
assets/css/style.css     ← the entire design system (colors, type, components) — edit this to re-skin everything at once
assets/js/app.js         ← tiny bit of JS: mobile nav toggle, tab clicks, view-toggle clicks
```

No build step. No framework. Open any `.html` file straight in a browser, or serve the folder with any static file server.

## Coverage

All 29 screens the app routes to: Dashboard, Calendar, Patients (+ Add patient, + Patient file detail/tabs), and the 22 operational modules (Prescriptions, Measurements, Communication, Frame Selection, Lens Recommendation, Frame Inventory, Lens Catalog, Contact Lenses, Accessories, Quotes, Orders, Billing, Laboratory, Mounting, Quality Control, Final Fitting, Delivery, After-Sales, Repairs, Warranty, Suppliers, Purchasing), plus Tasks and Settings.

Exact and pulled straight from the app's source:
- Every page title, sidebar label, and section grouping
- Every KPI card's label, icon, and color role (primary / secondary / success / warning / destructive / teal / purple)
- Which pages have the month filter bar (18 of the 22 modules — inventory/catalog pages like Frame Inventory, Lens Catalog, Contact Lenses, Accessories, and Suppliers don't, since stock doesn't belong to a calendar month)
- Every form field label on Add Patient, and the field layout on Insurance/Eye Exam/Prescription/Billing/Document forms
- The 8 Patient File tabs, the 4 Settings tabs, the Patients screen's search/filter/table columns

Representative, not live data:
- Every record card's sample content (patient names, dates, amounts) is placeholder — there's no backend here, so this shows the card *shape* (which fields, what a status badge looks like) rather than real records.
- The Billing weekly chart and Calendar month grid are simplified static mockups of the real `fl_chart` bar chart / month grid, not pixel-identical.

## Colors — the one real assumption

The app's actual color values live inside the `shadcn_flutter` package, which isn't inspectable from this environment. What *is* known from the source: the app defaults to shadcn_flutter's neutral **"Default"** color family (light mode), with `colorScheme.chart2` used as a secondary accent on most KPI grids, plus Material's standard `orange.shade700` / `green.shade700` / `teal.shade600` / `purple.shade400` / destructive-red for status colors — all of which **are** exact (Material named colors have fixed hex values).

The neutral chrome (background/surface/border/primary/muted) is approximated with the standard shadcn "zinc" palette, which is what shadcn_flutter's "Default" family is modeled on. If you want to confirm the exact values, open the app → Settings → Appearance and read them off the live color swatches, then update the `:root` variables at the top of `assets/css/style.css` — every page updates instantly since they all share one stylesheet.

The app also has 7 other selectable color families (Blue, Green, Orange, Red, Rose, Violet, Yellow) and a dark mode — this export includes a `.dark` class on `<html>` as a starting point for a dark variant, but only light/Default is fully designed here.

## Typography

Inter, loaded from Google Fonts, as a stand-in for the app's default typography. The app also has an in-app toggle for "Geist typography" (Settings → Appearance) — Geist isn't on Google Fonts, so if the redesign should target Geist specifically, swap the `<link>` tags and `--font-sans` variable for a self-hosted Geist build.

## Icons

Google's **Material Symbols Outlined** (loaded from Google Fonts) — the same icon set Flutter's `Icons.*_outlined` constants are drawn from, so icon names map 1:1 to what's actually used in the app (e.g. `Icons.calendar_month_outlined` → `calendar_month`).
