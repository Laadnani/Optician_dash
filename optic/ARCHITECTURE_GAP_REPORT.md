# CRM Architecture Gap Report

Comparing the target architecture in `final CRM adjustment.txt` (27 modules, reorganized into 8 top-level areas) against what's actually built in the app today. No code changed for this report — this is purely the audit you asked for.

## Headline finding

The app today is a **clinical practice tool**: patient intake, appointment scheduling, medical record-keeping (history, allergies, vitals, SOAP notes, diagnoses, lab/imaging orders, DICOM files), and a basic billing layer. The new architecture describes a **full optical retail operation**: frame and lens inventory, prescriptions as versioned optical entities, a multi-stage order-to-delivery workflow, an external lab pipeline, quality control, warranty, suppliers/purchasing, and a staff audit trail.

The overlap between the two is real but narrow — patients, appointments, documents, and billing exist in both worlds and just need extending. Almost everything else in the new spec (frames, lenses, contact lenses, orders, lab production, QC, mounting, fitting, delivery, after-sales, repairs, warranty, suppliers, purchasing, accessories, quotes, communication, staff audit trail) has **no current equivalent at all** — not a partial version, nothing. Of the 27 numbered modules, 4 are solidly or mostly built, 5 are partially built, and 18 need to be built from nothing.

There are also two direct **naming collisions** worth flagging now, before any renaming happens by accident: the app already has a `Prescription` model, but it means a medication prescription (drug list + instructions) — not the optical Rx (SPH/CYL/AXIS/ADD/PD) the new spec means by "Prescription." Same for `LabOrder`: today it means a clinical test (bloodwork), not sending a job to an external lens-grinding lab.

## Quick-scan status

| # | Module | Status | Note |
|---|--------|--------|------|
| 1 | Patient / Customer Management | ⚠️ Partial | Core identity fields solid; no address, profession, emergency contact, customer status, LTV, or purchase history |
| 2 | Optical Prescription Management | ❌ Missing | No versioned Rx entity; `EyeExam` covers a fraction of the fields |
| 3 | Visual / Optical Measurements | ❌ Missing | No PD, frame/lens measurements, or fitting parameters anywhere |
| 4 | Frame Management / Inventory | ❌ Missing | No Frame model, no variants, no stock transactions |
| 5 | Lens Product Management | ❌ Missing | No lens catalog at all |
| 6 | Contact Lens Management | ❌ Missing | No contact lens Rx or product model |
| 7 | Frame Selection / Virtual Sale | ❌ Missing | Nothing to select from yet (depends on #4) |
| 8 | Lens Recommendation / Consultation | ❌ Missing | No structured consultation entity |
| 9 | Eyewear Order Management | ❌ Missing | No Order entity or workflow state machine at all — this is the biggest single gap |
| 10 | Laboratory / Lens Production | ❌ Missing | `LabOrder` exists but means something else entirely |
| 11 | Quality Control | ❌ Missing | — |
| 12 | Mounting / Assembly | ❌ Missing | — |
| 13 | Final Fitting / Adjustment | ❌ Missing | — |
| 14 | Delivery | ❌ Missing | — |
| 15 | After-Sales / Follow-Up | ❌ Missing | No scheduled follow-ups or complaint tracking |
| 16 | Repairs & Maintenance | ❌ Missing | — |
| 17 | Warranty Management | ❌ Missing | — |
| 18 | Supplier Management | ❌ Missing | No B2B side exists |
| 19 | Purchasing | ❌ Missing | Low-stock alert exists but dead-ends with no action |
| 20 | Accessories Inventory | ❌ Missing | — |
| 21 | Pricing / Quotes | ❌ Missing | — |
| 22 | Payments / Invoicing | ⚠️ Partial | Two unlinked billing systems already exist (see below); missing methods/statuses/order link |
| 23 | Appointments | ✅ Mostly done | Best-covered module — needs field additions, not a rebuild |
| 24 | Documents | ⚠️ Partial | Basic upload+type vault exists; no versioning or order/prescription linking |
| 25 | Communication | ❌ Missing | No comms log, no automated notifications to patients |
| 26 | Staff / Employee Tasks (audit trail) | ❌ Missing | No staff/employee model at all — nothing records *who* did an action |
| 27 | Dashboard / KPIs | ⚠️ Partial | Appointment + revenue KPIs exist; Sales/Inventory/Production/Optical-performance KPIs have no data source yet |

## Detail, grouped by the target 8-module architecture

### 1. Patients
**Patient profile — ⚠️ Partial.** `Patient` has id, file number, national ID, name, DOB, sex, blood group, phone, email, and a single free-text insurance string. Missing entirely: multiple phone numbers, address, profession, emergency contact, preferred communication method, active/inactive status, first/last visit, total purchases, lifetime value — none of these exist as fields or as computed values.

**Medical/optical history — ⚠️ Partial, but pointed the wrong direction.** The app has rich *clinical* history (medical history, allergies, vital signs, SOAP notes, diagnoses) but none of the *retail* history the spec wants: previous glasses, previous contact lenses, previous purchases, repairs, complaints, returns/exchanges, warranty claims. Previous appointments and uploaded documents are covered.

**Prescriptions — ❌ Missing** (see naming collision above). **Measurements — ❌ Missing.** **Documents — ⚠️ Partial** (see module 24 below). **Communication — ❌ Missing.**

### 2. Optical Consultation
Nothing here exists as a structured entity. Visual needs, frame selection, lens recommendation are described nowhere in the data model — the closest thing is a free-text `reason` field on `Appointment` or `notes` on `EyeExam`/`SoapNote`. Measurements and prescription are covered under modules 1–3 above (i.e., not covered).

### 3. Products & Inventory
Frames, lenses, contact lenses, accessories, spare parts, stock movements — **all missing.** The one inventory-adjacent thing that exists, `InventoryItem` (name/quantity/unit/last-updated), is a flat generic stock counter used only to trigger a "running low" notification. It has no SKU, no variants (color/size), no transaction history (purchase/sale/reservation/return/damage/etc.), and isn't specific to frames, lenses, contacts, or accessories — it would need to be replaced, not extended.

### 4. Sales
Quotes, Orders, Invoices, Payments, Discounts. **Orders and Quotes don't exist in any form.** Invoicing/Payments exist but are thin: `Invoice` (id, patient, date, amount, status: paid/pending/cancelled) and `Payment` (id, invoice, date, amount, method: cash/card/transfer) — no discount field, no employee/reference tracking, no "partially paid"/"refunded" status, no link to an order (since orders don't exist). Separately, the Billing screen you had me build last session added a *second*, appointment-level price/paid-status system that isn't reconciled with the Invoice system at all. Both would likely get superseded by a proper Order entity per the new architecture.

### 5. Production
Laboratory, Lens Edging, Mounting, Quality Control, Remakes — **all missing**, aside from the `LabOrder` naming collision noted above (means a clinical test today, not a lens lab job).

### 6. Patient Delivery
Fitting, Delivery, Warranty, Repairs, Follow-up — **all missing.** There's no fitting record, no delivery record, no warranty entity, no repair ticket, and no automated follow-up scheduling (7-day/30-day/3-month/annual). The dashboard's "pending tasks" panel is the only thing in the ballpark, and it's derived from existing clinical order statuses, not a scheduled follow-up system.

### 7. Procurement
Suppliers, Purchase Orders, Receiving, Supplier Returns — **all missing.** There is no B2B/supplier concept anywhere in the current data model.

### 8. Management
**Staff — ❌ Missing**, and this is worth calling out as foundational: there's no Employee/Staff entity, no login/identity, and nothing in `DataProvider` records who performed an action (`Appointment.doctor` is just a free-text name string, not a linked staff record). Almost every other module's "audit trail" requirement depends on this existing first. **Tasks** — the sidebar already has a "Tasks" nav item, but it's an empty placeholder screen; it's a natural fit for this module's staff-task/audit-log concept rather than the generic to-do list it might currently suggest. **Reports/KPIs** — partial, see module 27 in the table above.

## Two things to decide before we touch code

1. **Naming collisions.** `Prescription` (medication Rx) and `LabOrder` (clinical test) already exist and mean something different from what the new spec calls by the same names. I'd rename the existing ones (e.g. `MedicationPrescription`, `ClinicalLabOrder`) and give the new optical/lens-lab concepts the clean names, rather than overload either.

2. **Is this now a hybrid clinical + retail practice, or a pivot to pure optical retail?** The new spec never mentions medical history, allergies, vitals, SOAP notes, diagnoses, imaging/DICOM, referrals, or telemedicine — all of which exist in the app today. If the doctor still does clinical exams *and* the practice sells eyewear, those stay as a parallel module alongside the 8 new ones. If the business is repositioning as pure optical retail, several of those become real deletion candidates (along with three already-orphaned widgets I flagged in the how-to-use audit — `TelemedicineCard`, `ReportCard`, and the current flat `InventoryCard` — none of which are referenced by any screen today). I don't want to guess on this one; it changes the delete list substantially.

Once you've had a look and we've settled those two points, I can turn this into a prioritized build plan.
