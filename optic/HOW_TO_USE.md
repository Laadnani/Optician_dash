# Doc CRM — How To Use

*A feature-by-feature guide to the app as it exists today, written to double as a gap-check: every section below is marked ✅ (working), ⚠️ (partially working / placeholder), or ❌ (not implemented — button or nav item exists but does nothing yet).*

## Overview

Doc CRM is a single-doctor eye-clinic practice manager built in Flutter, running as a desktop-style web/desktop app (it also adapts down to tablet and mobile widths). It's organized around six sections reachable from the left sidebar: **Dashboard**, **Billing**, **Patients**, **Calendar**, **Tasks**, and **Settings**. Underneath, everything reads from and writes to one in-memory mock data store (`DataProvider`) that stands in for a future real backend — every screen already talks to it through the same repository pattern a real API would use, so swapping in a backend later shouldn't require touching the UI.

The app supports three languages (English, French, Arabic, with right-to-left layout for Arabic), a fully custom theme (dark/light, 8 color families, adjustable corner radius, and independent text/icon/widget scaling), and a global notification bell that surfaces clinically-relevant alerts from anywhere in the app. The sections below walk through what each part of the app actually does today.

## Dashboard ⚠️

The landing screen: a greeting header with a patient search bar, four quick-action buttons, a KPI row (today's appointments/completed/scheduled/cancelled), a mini calendar next to that day's appointment list, and a pending-tasks panel. Clicking a date on the mini calendar updates the appointment list beside it.

Not everything here is wired up yet: the search bar in the header is decorative (typing into it does nothing), and of the four quick actions only "New appointment" and "New patient" actually work — "Start Telemedicine" and "Write Prescription" are buttons that do nothing when tapped. The pending-tasks panel's "See all" link is also a no-op.

## Calendar ✅

A full Day/Week/Month calendar over the same appointment data the dashboard uses, so there's one source of truth rather than two. Switch views with the tabs at the top, jump back to today with the Today button, and step forward/backward a day/week/month at a time with the arrow buttons. An "Add appointment" button opens the same booking form used everywhere else in the app (see Appointments, below).

## Patients ✅

The patient list, with a toggle between a card view and a dense table view (File #, Name, DOB/Age, Phone, Insurance), filters for gender and insurance status, and pagination once the list gets long. An "Add patient" button opens a full intake form (name, DOB, gender, blood group, contact info, national ID, insurance). Tapping any patient opens their file.

## Patient File ✅

Everything about one patient lives here, across seven tabs:

- **Overview** — medical history, allergies, vital signs, insurance
- **Appointments** — this patient's visit history, each with an editable price and a tap-to-cycle paid/unpaid/not-billable status (see Billing, below, for how this feeds the revenue chart)
- **Exams** — eye exams (with visual acuity/IOP trend panels), SOAP notes, diagnoses
- **Prescriptions** — prescriptions with medication lists and instructions
- **Orders** — lab orders, imaging orders, DICOM files, referrals
- **Billing** — this patient's invoices and payments (a separate, older record-keeping list — see the note under Billing below)
- **Documents** — uploaded documents and digital signatures

Every tab has floating "add" buttons for its record types, each opening a themed form dialog. Status values (scheduled/completed/paid/pending/cancelled, etc.) render as consistent colored badges everywhere they appear.

## Billing ✅

The main Billing screen answers "how much did the doctor actually make": a card for this month's total paid revenue, a card comparing it to last month (up/down, color-coded), and a weekly bar chart of the last 8 weeks split into first-time appointments vs. reschedules (a reschedule is any visit booked for a patient who already has an earlier one on file). This is driven entirely by the price and paid/unpaid/not-billable status set on each appointment.

One thing worth knowing: a patient's file also has its own **Invoices** and **Payments** sections (under the Billing tab), which are an older, separate record-keeping list — an invoice isn't linked to a specific appointment, and its numbers aren't reflected in the main Billing screen's chart. The two systems currently coexist rather than being reconciled into one.

## Tasks ❌

The sidebar has a "Tasks" entry, but it opens a "coming soon" placeholder screen — there's no task-management feature behind it. (Don't confuse this with the dashboard's "pending tasks" panel, which is a different, already-working thing — see below.)

## Notifications ✅

The bell icon in the top bar (visible on every screen) surfaces the same "things needing attention" list as the dashboard's pending-tasks panel: pending lab/imaging results, open referrals, low inventory, and consent forms missing a signature — all derived automatically from existing records, not a separately-maintained list. Clicking an item marks it read and, where it's tied to a specific patient, jumps to that patient's file. Read/unread state persists as you navigate around the app.

## Settings ⚠️

Three tabs: **Appearance** is fully built — dark/light mode, 8 color families, language (English/French/Arabic), corner radius, three independent scaling sliders (text, icons, and general widget/spacing size), surface opacity/blur, card border/shadow, and a typography toggle, all with a live preview and an explicit Save/Reset. **Account** and **Notifications** are both "coming soon" placeholders with no real settings behind them yet.

## Known gaps (the checklist this doc was meant to produce)

Beyond what's flagged above, three widgets exist in the codebase but are never actually shown anywhere in the app — there's no screen that renders them, so they're effectively dead ends right now:

- **Telemedicine** — a `TelemedicineCard` component exists (doctor ID, platform, status, scheduled time) but there's no telemedicine section on the patient file and no session list anywhere; it pairs with the dashboard's non-functional "Start Telemedicine" button.
- **Reports** — a `ReportCard` component exists but isn't shown on any tab.
- **Inventory** — inventory items only ever surface indirectly, through the "running low" pending-task/notification; there's no screen to actually view or manage stock.

And one smaller, more mechanical gap: the "Add X" record forms (Add Allergy, Add Vital Signs, Add Insurance, etc. — about 55 individual field labels and hint texts across all the patient-file dialogs) are still hardcoded in English even though the rest of the app's text is fully translated into French and Arabic.
