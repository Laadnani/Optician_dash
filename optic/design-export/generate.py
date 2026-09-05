# -*- coding: utf-8 -*-
import os, html

OUT = os.path.dirname(os.path.abspath(__file__))
PAGES_DIR = os.path.join(OUT, "pages")

def icon(name):
    """Flutter Icons.xxx_outlined -> Material Symbols Outlined ligature."""
    n = name.replace("Icons.", "")
    for suf in ("_outlined", "_outline"):
        if n.endswith(suf):
            n = n[: -len(suf)]
            break
    return n

def esc(s):
    return html.escape(str(s), quote=True)

# ---------------------------------------------------------------------------
# Navigation model (mirrors lib/helpers/nav_items.dart exactly)
# ---------------------------------------------------------------------------
NAV = [
    {"top": True, "id": "dashboard", "label": "Dashboard", "icon": "dashboard", "href": "dashboard.html"},
    {"top": True, "id": "calendar", "label": "Calendar", "icon": "calendar_month", "href": "calendar.html"},
    {"section": "Patients", "items": [
        {"id": "patients", "label": "Patients", "icon": "people", "href": "patients.html"},
        {"id": "prescriptions", "label": "Optical Prescription Management", "icon": "assignment", "href": "prescriptions.html"},
        {"id": "measurements", "label": "Visual / Optical Measurements", "icon": "straighten", "href": "measurements.html"},
        {"id": "communication", "label": "Communication", "icon": "forum", "href": "communication.html"},
    ]},
    {"section": "Optical Consultation", "items": [
        {"id": "frame-selection", "label": "Frame Selection / Virtual Sale", "icon": "camera_alt", "href": "frame-selection.html"},
        {"id": "lens-recommendation", "label": "Lens Recommendation / Optical Consultation", "icon": "medical_services", "href": "lens-recommendation.html"},
    ]},
    {"section": "Products & Inventory", "items": [
        {"id": "frame-inventory", "label": "Frame Management / Frame Inventory", "icon": "inventory_2", "href": "frame-inventory.html"},
        {"id": "lens-catalog", "label": "Lens Product Management", "icon": "blur_on", "href": "lens-catalog.html"},
        {"id": "contact-lenses", "label": "Contact Lens Management", "icon": "visibility", "href": "contact-lenses.html"},
        {"id": "accessories", "label": "Accessories Inventory", "icon": "shopping_bag", "href": "accessories.html"},
    ]},
    {"section": "Sales", "items": [
        {"id": "quotes", "label": "Pricing / Quotes", "icon": "request_quote", "href": "quotes.html"},
        {"id": "orders", "label": "Eyewear Order Management", "icon": "shopping_cart", "href": "orders.html"},
        {"id": "billing", "label": "Billing", "icon": "receipt_long", "href": "billing.html"},
    ]},
    {"section": "Production", "items": [
        {"id": "laboratory", "label": "Laboratory / Lens Production Management", "icon": "science", "href": "laboratory.html"},
        {"id": "mounting", "label": "Mounting / Assembly", "icon": "build", "href": "mounting.html"},
        {"id": "quality-control", "label": "Quality Control", "icon": "verified", "href": "quality-control.html"},
    ]},
    {"section": "Patient Delivery", "items": [
        {"id": "final-fitting", "label": "Final Fitting / Adjustment", "icon": "tune", "href": "final-fitting.html"},
        {"id": "delivery", "label": "Delivery", "icon": "local_shipping", "href": "delivery.html"},
        {"id": "after-sales", "label": "After-Sales / Follow-Up", "icon": "support_agent", "href": "after-sales.html"},
        {"id": "repairs", "label": "Repairs & Maintenance", "icon": "build_circle", "href": "repairs.html"},
        {"id": "warranty", "label": "Warranty Management", "icon": "verified_user", "href": "warranty.html"},
    ]},
    {"section": "Procurement", "items": [
        {"id": "suppliers", "label": "Supplier Management", "icon": "storefront", "href": "suppliers.html"},
        {"id": "purchasing", "label": "Purchasing", "icon": "shopping_cart_checkout", "href": "purchasing.html"},
    ]},
    {"section": "Management", "items": [
        {"id": "tasks", "label": "Staff / Employee Tasks", "icon": "badge", "href": "tasks.html"},
        {"id": "settings", "label": "Settings", "icon": "settings", "href": "settings.html"},
    ]},
]

def sidebar_html(active_id):
    parts = []
    parts.append('<aside class="sidebar" id="sidebar">')
    parts.append('  <div class="sidebar-brand">'
                  '<div class="logo-mark">DC</div>'
                  '<div><div class="brand-name">Doc CRM</div>'
                  '<div class="brand-sub">Optical retail operations</div></div></div>')
    parts.append('  <nav class="sidebar-scroll">')
    for entry in NAV:
        if entry.get("top"):
            cls = "nav-item active" if entry["id"] == active_id else "nav-item"
            parts.append(f'<a class="{cls}" href="{entry["href"]}">'
                         f'<span class="material-symbols-outlined">{entry["icon"]}</span>'
                         f'<span class="label">{esc(entry["label"])}</span></a>')
        else:
            parts.append(f'<div class="nav-section-label">{esc(entry["section"])}</div>')
            for it in entry["items"]:
                cls = "nav-item active" if it["id"] == active_id else "nav-item"
                parts.append(f'<a class="{cls}" href="{it["href"]}">'
                             f'<span class="material-symbols-outlined">{it["icon"]}</span>'
                             f'<span class="label">{esc(it["label"])}</span></a>')
    parts.append('  </nav>')
    parts.append('  <div class="sidebar-footer">'
                  '<a class="nav-item" href="#"><span class="material-symbols-outlined">logout</span>'
                  '<span class="label">Sign out</span></a></div>')
    parts.append('</aside>')
    return "\n".join(parts)

PAGE_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title} — Doc CRM design export</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
<link rel="stylesheet" href="../assets/css/style.css">
</head>
<body>
<button class="btn btn-outline btn-icon" id="mobileNavToggle" style="position:fixed;top:14px;left:14px;z-index:30;display:none;">
  <span class="material-symbols-outlined">menu</span>
</button>
<div class="app-shell">
{sidebar}
<main class="content">
<div class="page">
{body}
</div>
</main>
</div>
<script src="../assets/js/app.js"></script>
</body>
</html>
"""

def page_header(title, subtitle=None, actions=""):
    sub = f'<div class="page-subtitle">{esc(subtitle)}</div>' if subtitle else ""
    return f"""<div class="page-header-row">
  <div><h1 class="page-title">{esc(title)}</h1>{sub}</div>
  <div class="page-header-actions">{actions}</div>
</div>"""

def month_filter_bar():
    return """<div class="month-filter-bar">
  <span class="material-symbols-outlined">calendar_month</span>
  <span class="nav-arrow material-symbols-outlined">chevron_left</span>
  <span class="month-label">August 2026</span>
  <span class="nav-arrow material-symbols-outlined">chevron_right</span>
</div>"""

TINT = {
    "primary": "tint-primary", "chart2": "tint-chart2", "success": "tint-success",
    "warning": "tint-warning", "destructive": "tint-destructive", "teal": "tint-teal", "purple": "tint-purple",
}

def kpi_grid(kpis, cols=None):
    cols_cls = f" cols-{cols}" if cols else ""
    cards = []
    for label, value, ic, tone in kpis:
        cards.append(f"""  <div class="kpi-card">
    <div class="kpi-icon {TINT[tone]}"><span class="material-symbols-outlined">{icon(ic)}</span></div>
    <div><div class="kpi-value">{esc(value)}</div><div class="kpi-label">{esc(label)}</div></div>
  </div>""")
    return f'<div class="kpi-grid{cols_cls}">\n' + "\n".join(cards) + "\n</div>"

def chip(label, tone="neutral"):
    return f'<span class="chip chip-{tone}">{esc(label)}</span>'

def record_card(title, subtitle, fields, patient=None, status=None, status_tone="neutral"):
    rows = "".join(
        f'<div class="record-field-row"><span class="record-field-label">{esc(k)}</span>'
        f'<span class="record-field-value">{esc(v)}</span></div>'
        for k, v in fields
    )
    tag = f'<div class="patient-tag">{esc(patient)}</div>' if patient else ""
    st = chip(status, status_tone) if status else ""
    return f"""<div class="card record-card">
  {tag}
  <div class="record-card-top">
    <div><div class="record-card-title">{esc(title)}</div><div class="record-card-subtitle">{esc(subtitle)}</div></div>
    {st}
  </div>
  {rows}
</div>"""

def card_grid(cards_html, cols=3):
    cls = f" cols-{cols}" if cols != 3 else ""
    return f'<div class="card-grid{cls}">\n' + "\n".join(cards_html) + "\n</div>"

def write_page(slug, title, active_id, body_html):
    html_out = PAGE_TEMPLATE.format(title=esc(title), sidebar=sidebar_html(active_id), body=body_html)
    with open(os.path.join(PAGES_DIR, f"{slug}.html"), "w", encoding="utf-8") as f:
        f.write(html_out)


# ---------------------------------------------------------------------------
# Generic "module" page renderer — used by the 21 operational-module screens
# that share the same KPI-grid + record-card-grid shape.
# ---------------------------------------------------------------------------
def module_page(slug, active_id, title, add_label, kpis, cols, month_filter, records, empty_icon):
    actions = f'<button class="btn btn-primary"><span class="material-symbols-outlined">add</span>{esc(add_label)}</button>'
    body = [page_header(title, actions=actions)]
    if month_filter:
        body.append(month_filter_bar())
    body.append(kpi_grid(kpis, cols=cols))
    body.append(card_grid(records, cols=3))
    write_page(slug, title, active_id, "\n".join(body))

MODULES = [
    dict(slug="accessories", active="accessories", title="Accessories Inventory", add="Add accessory",
         cols=3, month=False, empty_icon="shopping_bag",
         kpis=[("Total items", "12", "Icons.shopping_bag_outlined", "primary"),
               ("Stock value", "18,400 MAD", "Icons.payments_outlined", "chart2"),
               ("Low stock", "3", "Icons.warning_amber_outlined", "warning")],
         records=[
             record_card("Cleaning kit — Premium", "SKU: ACC-0182", [("Category","Care"),("Price","95 MAD"),("Stock","24")]),
             record_card("Chain — Metal beaded", "SKU: ACC-0091", [("Category","Chains"),("Price","140 MAD"),("Stock","6")], status="Low stock", status_tone="warning"),
             record_card("Case — Hard shell navy", "SKU: ACC-0033", [("Category","Cases"),("Price","60 MAD"),("Stock","41")]),
         ]),
    dict(slug="after-sales", active="after-sales", title="After-Sales / Follow-Up", add="Add ticket",
         cols=3, month=True, empty_icon="support_agent",
         kpis=[("Total tickets", "9", "Icons.support_agent_outlined", "primary"),
               ("Open", "4", "Icons.flag_outlined", "warning"),
               ("Resolved", "5", "Icons.check_circle_outline", "success")],
         records=[
             record_card("Comfort issue", "ORD-2291", [("Date","Aug 12, 2026"),("Staff","Youssef B.")], patient="Nadia El Amrani", status="Open", status_tone="warning"),
             record_card("Vision issue", "ORD-2277", [("Date","Aug 9, 2026"),("Staff","Salma T.")], patient="Karim Idrissi", status="In progress", status_tone="info"),
             record_card("Breakage", "ORD-2260", [("Date","Aug 3, 2026"),("Staff","Youssef B.")], patient="Hicham Alaoui", status="Resolved", status_tone="success"),
         ]),
    dict(slug="communication", active="communication", title="Communication", add="Log communication",
         cols=3, month=True, empty_icon="forum",
         kpis=[("Total logged", "34", "Icons.forum_outlined", "primary"),
               ("This month", "12", "Icons.calendar_today_outlined", "chart2"),
               ("Needs follow-up", "3", "Icons.flag_outlined", "warning")],
         records=[
             record_card("Order ready reminder", "Phone · Outbound", [("Date","Aug 14, 2026"),("Staff","Salma T.")], patient="Amine Rachidi"),
             record_card("Prescription question", "WhatsApp · Inbound", [("Date","Aug 13, 2026"),("Staff","Youssef B.")], patient="Fatima Ezzahra"),
             record_card("Appointment confirmation", "SMS · Outbound", [("Date","Aug 11, 2026"),("Staff","Salma T.")], patient="Omar Benjelloun"),
         ]),
    dict(slug="contact-lenses", active="contact-lenses", title="Contact Lens Management", add="Add product",
         cols=4, month=False, empty_icon="visibility",
         kpis=[("Products carried", "16", "Icons.visibility_outlined", "primary"),
               ("Stock value", "9,200 MAD", "Icons.payments_outlined", "chart2"),
               ("Low stock", "2", "Icons.warning_amber_outlined", "warning"),
               ("Patients fitted", "23", "Icons.people_outline", "teal")],
         records=[
             record_card("Acuvue Oasys — Daily", "Supplier: Johnson & Johnson", [("Price","320 MAD"),("Stock","18")]),
             record_card("Biofinity — Monthly", "Supplier: CooperVision", [("Price","410 MAD"),("Stock","5")], status="Low stock", status_tone="warning"),
             record_card("Dailies Total 1", "Supplier: Alcon", [("Price","390 MAD"),("Stock","27")]),
         ]),
    dict(slug="delivery", active="delivery", title="Delivery", add="Add delivery",
         cols=3, month=True, empty_icon="local_shipping",
         kpis=[("This month", "7", "Icons.calendar_today_outlined", "primary"),
               ("Scheduled", "3", "Icons.schedule_outlined", "warning"),
               ("Delivered", "12", "Icons.local_shipping_outlined", "success")],
         records=[
             record_card("In-store pickup", "ORD-2291", [("Date","Aug 15, 2026"),("Staff","Youssef B.")], patient="Nadia El Amrani", status="Scheduled", status_tone="warning"),
             record_card("Home delivery", "ORD-2286", [("Date","Aug 13, 2026"),("Staff","Salma T.")], patient="Karim Idrissi", status="Delivered", status_tone="success"),
             record_card("Courier", "ORD-2279", [("Date","Aug 10, 2026"),("Staff","Youssef B.")], patient="Hicham Alaoui", status="Delivered", status_tone="success"),
         ]),
    dict(slug="final-fitting", active="final-fitting", title="Final Fitting / Adjustment", add="Add fitting",
         cols=3, month=True, empty_icon="tune",
         kpis=[("Total fittings", "15", "Icons.tune_outlined", "primary"),
               ("This month", "5", "Icons.calendar_today_outlined", "chart2"),
               ("Avg. comfort", "4.6/5", "Icons.sentiment_satisfied_outlined", "success")],
         records=[
             record_card("Nose pads", "ORD-2291", [("Date","Aug 14, 2026"),("Comfort","5/5"),("Staff","Youssef B.")], patient="Nadia El Amrani"),
             record_card("Temple length", "ORD-2284", [("Date","Aug 12, 2026"),("Comfort","4/5"),("Staff","Salma T.")], patient="Omar Benjelloun"),
             record_card("Frame alignment", "ORD-2275", [("Date","Aug 8, 2026"),("Comfort","5/5"),("Staff","Youssef B.")], patient="Fatima Ezzahra"),
         ]),
    dict(slug="frame-inventory", active="frame-inventory", title="Frame Management / Frame Inventory", add="Add frame",
         cols=4, month=False, empty_icon="inventory_2",
         kpis=[("Frame variants", "48", "Icons.inventory_2_outlined", "primary"),
               ("Stock value", "62,000 MAD", "Icons.payments_outlined", "chart2"),
               ("Low stock", "5", "Icons.warning_amber_outlined", "warning"),
               ("Out of stock", "2", "Icons.remove_shopping_cart_outlined", "destructive")],
         records=[
             record_card("Ray-Ban Aviator", "Brand: Ray-Ban", [("Color","Gold"),("Price","1,450 MAD"),("Stock","9")]),
             record_card("Gucci GG0027O", "Brand: Gucci", [("Color","Black"),("Price","2,900 MAD"),("Stock","2")], status="Low stock", status_tone="warning"),
             record_card("Oakley Holbrook", "Brand: Oakley", [("Color","Matte grey"),("Price","1,650 MAD"),("Stock","0")], status="Out of stock", status_tone="destructive"),
         ]),
    dict(slug="frame-selection", active="frame-selection", title="Frame Selection / Virtual Sale", add="Log session",
         cols=4, month=True, empty_icon="camera_alt",
         kpis=[("Total sessions", "21", "Icons.camera_alt_outlined", "primary"),
               ("This month", "8", "Icons.calendar_today_outlined", "chart2"),
               ("Virtual try-ons", "6", "Icons.smartphone_outlined", "purple"),
               ("Conversion rate", "62%", "Icons.check_circle_outline", "success")],
         records=[
             record_card("In-store", "Selected: Ray-Ban Aviator", [("Date","Aug 14, 2026"),("Staff","Salma T.")], patient="Nadia El Amrani"),
             record_card("Virtual try-on", "Selected: undecided", [("Date","Aug 12, 2026"),("Staff","Youssef B.")], patient="Karim Idrissi"),
             record_card("In-store", "Selected: Gucci GG0027O", [("Date","Aug 9, 2026"),("Staff","Salma T.")], patient="Amine Rachidi"),
         ]),
    dict(slug="laboratory", active="laboratory", title="Laboratory / Lens Production Management", add="Add work order",
         cols=4, month=True, empty_icon="science",
         kpis=[("Total jobs", "27", "Icons.science_outlined", "primary"),
               ("In progress", "6", "Icons.precision_manufacturing_outlined", "chart2"),
               ("Overdue", "2", "Icons.warning_amber_outlined", "destructive"),
               ("Completed this month", "9", "Icons.check_circle_outline", "success")],
         records=[
             record_card("Lens grinding", "ORD-2291", [("Date","Aug 12, 2026"),("Due","Aug 16, 2026")], status="In progress", status_tone="info"),
             record_card("Lens grinding", "ORD-2270", [("Date","Aug 5, 2026"),("Due","Aug 10, 2026")], status="Overdue", status_tone="destructive"),
             record_card("Lens grinding", "ORD-2255", [("Date","Jul 29, 2026"),("Due","Aug 2, 2026")], status="Completed", status_tone="success"),
         ]),
    dict(slug="lens-catalog", active="lens-catalog", title="Lens Product Management", add="Add lens",
         cols=3, month=False, empty_icon="blur_on",
         kpis=[("Lens products", "34", "Icons.blur_on_outlined", "primary"),
               ("Average price", "620 MAD", "Icons.payments_outlined", "chart2"),
               ("Premium coatings", "11", "Icons.stars_outlined", "purple")],
         records=[
             record_card("Varilux Progressive", "Supplier: Essilor", [("Type","Progressive"),("Price","1,200 MAD")]),
             record_card("Crizal Anti-Glare", "Supplier: Essilor", [("Type","Single vision"),("Price","480 MAD")]),
             record_card("Transitions Signature", "Supplier: Transitions", [("Type","Photochromic"),("Price","950 MAD")]),
         ]),
    dict(slug="lens-recommendation", active="lens-recommendation", title="Lens Recommendation / Optical Consultation", add="Log recommendation",
         cols=3, month=True, empty_icon="medical_services",
         kpis=[("Total recommendations", "19", "Icons.medical_services_outlined", "primary"),
               ("This month", "6", "Icons.calendar_today_outlined", "chart2"),
               ("Acceptance rate", "74%", "Icons.check_circle_outline", "success")],
         records=[
             record_card("Progressive", "Reason: presbyopia", [("Date","Aug 13, 2026"),("Staff","Youssef B.")], patient="Hicham Alaoui", status="Accepted", status_tone="success"),
             record_card("Myopia control", "Reason: pediatric myopia", [("Date","Aug 10, 2026"),("Staff","Salma T.")], patient="Fatima Ezzahra", status="Pending", status_tone="warning"),
             record_card("Computer lens", "Reason: screen strain", [("Date","Aug 6, 2026"),("Staff","Youssef B.")], patient="Omar Benjelloun", status="Accepted", status_tone="success"),
         ]),
    dict(slug="measurements", active="measurements", title="Visual / Optical Measurements", add="Add measurement",
         cols=3, month=True, empty_icon="straighten",
         kpis=[("Total measurements", "41", "Icons.straighten_outlined", "primary"),
               ("This month", "9", "Icons.calendar_today_outlined", "chart2"),
               ("Digital equipment", "28", "Icons.precision_manufacturing_outlined", "teal")],
         records=[
             record_card("PD 63mm", "Method: Pupillometer", [("Date","Aug 12, 2026"),("Operator","Salma T.")], patient="Nadia El Amrani"),
             record_card("PD 61mm", "Method: Digital centration", [("Date","Aug 9, 2026"),("Operator","Youssef B.")], patient="Karim Idrissi"),
             record_card("PD 64mm", "Method: Manual", [("Date","Aug 4, 2026"),("Operator","Salma T.")], patient="Amine Rachidi"),
         ]),
    dict(slug="mounting", active="mounting", title="Mounting / Assembly", add="Add job",
         cols=4, month=True, empty_icon="build",
         kpis=[("Total jobs", "24", "Icons.build_outlined", "primary"),
               ("In progress", "5", "Icons.precision_manufacturing_outlined", "chart2"),
               ("Completed this month", "8", "Icons.check_circle_outline", "success"),
               ("Rework", "1", "Icons.warning_amber_outlined", "destructive")],
         records=[
             record_card("Ray-Ban Aviator + Varilux", "ORD-2291", [("Date","Aug 13, 2026"),("Technician","Youssef B.")], status="In progress", status_tone="info"),
             record_card("Gucci GG0027O + Crizal", "ORD-2280", [("Date","Aug 9, 2026"),("Technician","Salma T.")], status="Completed", status_tone="success"),
             record_card("Oakley Holbrook + Transitions", "ORD-2266", [("Date","Aug 2, 2026"),("Technician","Youssef B.")], status="Rework", status_tone="destructive"),
         ]),
    dict(slug="orders", active="orders", title="Eyewear Order Management", add="Add order",
         cols=4, month=True, empty_icon="shopping_cart",
         kpis=[("Total orders", "38", "Icons.shopping_cart_outlined", "primary"),
               ("This month", "10", "Icons.calendar_today_outlined", "chart2"),
               ("In production", "6", "Icons.precision_manufacturing_outlined", "teal"),
               ("This month's revenue", "54,200 MAD", "Icons.payments_outlined", "success")],
         records=[
             record_card("Ray-Ban Aviator + Varilux", "2,650 MAD", [("Date","Aug 13, 2026"),("Pipeline","Lab")], patient="Nadia El Amrani", status="In production", status_tone="info"),
             record_card("Gucci GG0027O + Crizal", "3,380 MAD", [("Date","Aug 9, 2026"),("Pipeline","Delivered")], patient="Karim Idrissi", status="Completed", status_tone="success"),
             record_card("Oakley Holbrook + Transitions", "2,600 MAD", [("Date","Aug 5, 2026"),("Pipeline","Mounting")], patient="Amine Rachidi", status="In production", status_tone="info"),
         ]),
    dict(slug="prescriptions", active="prescriptions", title="Optical Prescription Management", add="Add prescription",
         cols=4, month=True, empty_icon="assignment",
         kpis=[("Total prescriptions", "56", "Icons.assignment_outlined", "primary"),
               ("This month", "11", "Icons.calendar_today_outlined", "chart2"),
               ("Expiring soon", "4", "Icons.warning_amber_outlined", "warning"),
               ("Expired", "2", "Icons.event_busy_outlined", "destructive")],
         records=[
             record_card("Distance", "Dr. Amine Fassi", [("Date","Aug 12, 2026"),("Expires","Aug 12, 2027")], patient="Nadia El Amrani"),
             record_card("Progressive", "Dr. Amine Fassi", [("Date","Jul 20, 2026"),("Expires","Sep 2, 2026")], patient="Hicham Alaoui", status="Expiring soon", status_tone="warning"),
             record_card("Reading", "Dr. Leila Bennis", [("Date","Feb 2, 2025"),("Expires","Feb 2, 2026")], patient="Omar Benjelloun", status="Expired", status_tone="destructive"),
         ]),
    dict(slug="purchasing", active="purchasing", title="Purchasing", add="Add purchase order",
         cols=3, month=True, empty_icon="shopping_cart_checkout",
         kpis=[("Total orders", "17", "Icons.shopping_cart_checkout_outlined", "primary"),
               ("Pending value", "28,500 MAD", "Icons.payments_outlined", "warning"),
               ("Received", "12", "Icons.check_circle_outline", "success")],
         records=[
             record_card("2,400 MAD", "Essilor Maroc", [("Date","Aug 11, 2026"),("Expected","Aug 20, 2026")], status="Sent", status_tone="info"),
             record_card("6,100 MAD", "Ray-Ban Distribution", [("Date","Aug 6, 2026"),("Expected","Aug 18, 2026")], status="Confirmed", status_tone="info"),
             record_card("3,900 MAD", "CooperVision", [("Date","Jul 28, 2026"),("Received","Aug 4, 2026")], status="Received", status_tone="success"),
         ]),
    dict(slug="quality-control", active="quality-control", title="Quality Control", add="Add check",
         cols=3, month=True, empty_icon="verified",
         kpis=[("Total checks", "33", "Icons.verified_outlined", "primary"),
               ("Pass rate", "91%", "Icons.check_circle_outline", "success"),
               ("Failed", "3", "Icons.error_outline", "destructive")],
         records=[
             record_card("Frame fit", "ORD-2291", [("Date","Aug 13, 2026"),("Inspector","Salma T.")], status="Pass", status_tone="success"),
             record_card("Lens quality", "ORD-2280", [("Date","Aug 9, 2026"),("Inspector","Youssef B.")], status="Conditional pass", status_tone="warning"),
             record_card("Prescription accuracy", "ORD-2266", [("Date","Aug 2, 2026"),("Inspector","Salma T.")], status="Fail", status_tone="destructive"),
         ]),
    dict(slug="quotes", active="quotes", title="Pricing / Quotes", add="Add quote",
         cols=4, month=True, empty_icon="request_quote",
         kpis=[("Total quotes", "29", "Icons.request_quote_outlined", "primary"),
               ("This month", "7", "Icons.calendar_today_outlined", "chart2"),
               ("Accepted", "14", "Icons.check_circle_outline", "success"),
               ("Pending value", "32,100 MAD", "Icons.payments_outlined", "warning")],
         records=[
             record_card("2,650 MAD", "Valid until Sep 12, 2026", [("Date","Aug 12, 2026")], patient="Nadia El Amrani", status="Accepted", status_tone="success"),
             record_card("1,890 MAD", "Valid until Sep 1, 2026", [("Date","Aug 1, 2026")], patient="Karim Idrissi", status="Sent", status_tone="info"),
             record_card("3,200 MAD", "Valid until Aug 20, 2026", [("Date","Jul 21, 2026")], patient="Amine Rachidi", status="Draft", status_tone="neutral"),
         ]),
    dict(slug="repairs", active="repairs", title="Repairs & Maintenance", add="Add repair",
         cols=3, month=True, empty_icon="build_circle",
         kpis=[("Total repairs", "13", "Icons.build_circle_outlined", "primary"),
               ("In progress", "3", "Icons.precision_manufacturing_outlined", "chart2"),
               ("Repair revenue", "6,400 MAD", "Icons.payments_outlined", "success")],
         records=[
             record_card("Frame — bent temple", "150 MAD", [("Date","Aug 12, 2026"),("Technician","Youssef B.")], patient="Hicham Alaoui", status="In progress", status_tone="info"),
             record_card("Lens — scratched", "0 MAD (warranty)", [("Date","Aug 8, 2026"),("Technician","Salma T.")], patient="Fatima Ezzahra", status="Completed", status_tone="success"),
             record_card("Frame — broken hinge", "220 MAD", [("Date","Aug 3, 2026"),("Technician","Youssef B.")], patient="Omar Benjelloun", status="Received", status_tone="neutral"),
         ]),
    dict(slug="suppliers", active="suppliers", title="Supplier Management", add="Add supplier",
         cols=2, month=False, empty_icon="storefront",
         kpis=[("Total suppliers", "9", "Icons.storefront_outlined", "primary"),
               ("Avg. rating", "4.3/5", "Icons.star_outline", "warning")],
         records=[
             record_card("Essilor Maroc", "Lenses", [("Contact","Rachid M."),("Phone","0522 45 12 34"),("Rating","4.6/5")]),
             record_card("Ray-Ban Distribution", "Frames", [("Contact","Sara L."),("Phone","0522 78 90 12"),("Rating","4.2/5")]),
             record_card("CooperVision", "Contact lenses", [("Contact","Nabil K."),("Phone","0522 33 44 55"),("Rating","4.0/5")]),
         ]),
    dict(slug="warranty", active="warranty", title="Warranty Management", add="Add claim",
         cols=3, month=True, empty_icon="verified_user",
         kpis=[("Total claims", "11", "Icons.verified_user_outlined", "primary"),
               ("Pending", "3", "Icons.pending_outlined", "warning"),
               ("Approved / replaced", "6", "Icons.check_circle_outline", "success")],
         records=[
             record_card("Frame defect", "ORD-2260", [("Date","Aug 11, 2026"),("Staff","Salma T.")], patient="Hicham Alaoui", status="Submitted", status_tone="neutral"),
             record_card("Lens coating peeling", "ORD-2241", [("Date","Aug 2, 2026"),("Staff","Youssef B.")], patient="Fatima Ezzahra", status="Approved", status_tone="success"),
             record_card("Frame defect", "ORD-2198", [("Date","Jul 22, 2026"),("Staff","Salma T.")], patient="Omar Benjelloun", status="Replaced", status_tone="success"),
         ]),
]

for m in MODULES:
    module_page(m["slug"], m["active"], m["title"], m["add"], m["kpis"], m["cols"], m["month"], m["records"], m["empty_icon"])

print(f"Generated {len(MODULES)} module pages")

# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------
def dashboard_page():
    header = """<div class="card" style="background:linear-gradient(135deg, #eff6ff, #ffffff); margin-bottom:20px;">
  <div class="row" style="justify-content:space-between; align-items:flex-start;">
    <div>
      <div style="font-size:18px; font-weight:700;">Good morning, Youssef</div>
      <div class="muted" style="margin-top:4px;">Wednesday, August 12, 2026 &middot; 6 appointments today</div>
    </div>
    <div class="avatar" style="width:44px;height:44px;">YB</div>
  </div>
</div>"""
    monthly_revenue = """<div class="card" style="margin-bottom:20px;">
  <div class="row" style="justify-content:space-between;">
    <div>
      <div class="muted" style="font-size:12px;">Monthly revenue</div>
      <div style="font-size:26px; font-weight:700; margin-top:2px;">148,600 MAD</div>
      <div class="chip chip-success" style="margin-top:6px;">+12% vs. last month</div>
    </div>
    <span class="material-symbols-outlined" style="font-size:34px; color:var(--chart-2);">trending_up</span>
  </div>
</div>"""
    quick_actions = """<div class="row" style="gap:10px; margin-bottom:20px;">
  <button class="btn btn-outline"><span class="material-symbols-outlined">event_available</span>New appointment</button>
  <button class="btn btn-outline"><span class="material-symbols-outlined">person_add</span>New patient</button>
</div>"""
    snapshot = kpi_grid([
        ("Today's appointments", "6", "Icons.event_outlined", "primary"),
        ("Completed", "2", "Icons.check_circle_outline", "success"),
        ("Scheduled", "3", "Icons.schedule_outlined", "chart2"),
        ("Cancelled", "1", "Icons.cancel_outlined", "destructive"),
    ], cols=4)
    main_section = """<div class="two-col" style="margin:20px 0;">
  <div class="card">
    <div class="row" style="justify-content:space-between; margin-bottom:12px;">
      <div style="font-weight:600;">Today's appointments</div>
      <span class="muted" style="font-size:12px;">Aug 12, 2026</span>
    </div>
    <div class="stack">
      <div class="row" style="justify-content:space-between; padding:8px 0; border-bottom:1px solid var(--border);">
        <div class="row"><div class="avatar">NA</div><div><div style="font-weight:500;">Nadia El Amrani</div><div class="muted" style="font-size:12px;">09:00 &middot; Routine eye exam</div></div></div>
        <span class="chip chip-success">Completed</span>
      </div>
      <div class="row" style="justify-content:space-between; padding:8px 0; border-bottom:1px solid var(--border);">
        <div class="row"><div class="avatar">KI</div><div><div style="font-weight:500;">Karim Idrissi</div><div class="muted" style="font-size:12px;">10:30 &middot; Follow-up</div></div></div>
        <span class="chip chip-info">Scheduled</span>
      </div>
      <div class="row" style="justify-content:space-between; padding:8px 0;">
        <div class="row"><div class="avatar">AR</div><div><div style="font-weight:500;">Amine Rachidi</div><div class="muted" style="font-size:12px;">14:00 &middot; Contact lens fitting</div></div></div>
        <span class="chip chip-info">Scheduled</span>
      </div>
    </div>
  </div>
  <div class="card">
    <div style="font-weight:600; margin-bottom:12px;">Needs your attention</div>
    <div class="stack">
      <div class="row" style="justify-content:space-between;">
        <div class="row"><span class="material-symbols-outlined" style="color:var(--warning);">draw</span>
        <div><div style="font-weight:500; font-size:13px;">Consent form needs signature</div><div class="muted" style="font-size:12px;">Hicham Alaoui</div></div></div>
        <span class="material-symbols-outlined muted">chevron_right</span>
      </div>
      <div class="row" style="justify-content:space-between;">
        <div class="row"><span class="material-symbols-outlined" style="color:var(--warning);">draw</span>
        <div><div style="font-weight:500; font-size:13px;">Consent form needs signature</div><div class="muted" style="font-size:12px;">Fatima Ezzahra</div></div></div>
        <span class="material-symbols-outlined muted">chevron_right</span>
      </div>
    </div>
    <button class="btn btn-ghost btn-sm" style="margin-top:10px;">See all</button>
  </div>
</div>"""
    overview_cards = """<div class="card-grid cols-2">
  <div class="card">
    <div class="row" style="justify-content:space-between; margin-bottom:8px;"><span style="font-weight:600;">Patients overview</span><span class="material-symbols-outlined muted">people</span></div>
    <div class="row" style="gap:20px;">
      <div><div style="font-size:20px;font-weight:700;">312</div><div class="muted" style="font-size:11.5px;">Total patients</div></div>
      <div><div style="font-size:20px;font-weight:700;">18</div><div class="muted" style="font-size:11.5px;">New this month</div></div>
    </div>
  </div>
  <div class="card">
    <div class="row" style="justify-content:space-between; margin-bottom:8px;"><span style="font-weight:600;">Inventory alerts</span><span class="material-symbols-outlined muted">inventory_2</span></div>
    <div class="row" style="gap:20px;">
      <div><div style="font-size:20px;font-weight:700; color:var(--warning);">5</div><div class="muted" style="font-size:11.5px;">Low stock frames</div></div>
      <div><div style="font-size:20px;font-weight:700; color:var(--destructive);">2</div><div class="muted" style="font-size:11.5px;">Out of stock</div></div>
    </div>
  </div>
  <div class="card">
    <div class="row" style="justify-content:space-between; margin-bottom:8px;"><span style="font-weight:600;">Orders pipeline</span><span class="material-symbols-outlined muted">shopping_cart</span></div>
    <div class="row" style="gap:20px;">
      <div><div style="font-size:20px;font-weight:700;">38</div><div class="muted" style="font-size:11.5px;">Total orders</div></div>
      <div><div style="font-size:20px;font-weight:700;">6</div><div class="muted" style="font-size:11.5px;">In production</div></div>
    </div>
  </div>
  <div class="card">
    <div class="row" style="justify-content:space-between; margin-bottom:8px;"><span style="font-weight:600;">Quality overview</span><span class="material-symbols-outlined muted">verified</span></div>
    <div class="row" style="gap:20px;">
      <div><div style="font-size:20px;font-weight:700; color:var(--success);">91%</div><div class="muted" style="font-size:11.5px;">Pass rate</div></div>
      <div><div style="font-size:20px;font-weight:700; color:var(--destructive);">3</div><div class="muted" style="font-size:11.5px;">Failed checks</div></div>
    </div>
  </div>
</div>"""
    body = "\n".join([header, monthly_revenue, quick_actions, snapshot, main_section, overview_cards])
    write_page("dashboard", "Dashboard", "dashboard", body)

# ---------------------------------------------------------------------------
# Calendar
# ---------------------------------------------------------------------------
def calendar_page():
    actions = ('<button class="btn btn-primary"><span class="material-symbols-outlined">add</span>Add appointment</button>')
    header = page_header("Calendar", actions=actions)
    view_bar = """<div class="row" style="justify-content:space-between; margin-bottom:16px; flex-wrap:wrap; gap:10px;">
  <div class="month-filter-bar" style="margin-bottom:0;">
    <span class="nav-arrow material-symbols-outlined">chevron_left</span>
    <span class="month-label">August 2026</span>
    <span class="nav-arrow material-symbols-outlined">chevron_right</span>
  </div>
  <div class="view-toggle">
    <button>Day</button><button>Week</button><button class="active">Month</button>
  </div>
</div>"""
    weekdays = "".join(f'<div class="weekday">{d}</div>' for d in ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"])
    cells = []
    import calendar as _cal
    cal = _cal.Calendar(firstweekday=0)
    days = list(cal.itermonthdays(2026, 8))
    events = {
        3: ["09:00 Nadia El Amrani"],
        3: ["09:00 Nadia El Amrani", "14:00 Amine Rachidi"],
        12: ["09:00 Nadia El Amrani", "10:30 Karim Idrissi", "14:00 Amine Rachidi"],
        18: ["11:00 Hicham Alaoui"],
        21: ["15:30 Fatima Ezzahra"],
        27: ["09:30 Omar Benjelloun"],
    }
    for d in days:
        if d == 0:
            cells.append('<div class="calendar-cell muted"></div>')
        else:
            today_cls = " today" if d == 12 else ""
            evs = "".join(f'<span class="event-dot">{e}</span>' for e in events.get(d, []))
            cells.append(f'<div class="calendar-cell{today_cls}"><span class="day-num">{d}</span>{evs}</div>')
    grid = f'<div class="calendar-grid">{weekdays}{"".join(cells)}</div>'
    write_page("calendar", "Calendar", "calendar", "\n".join([header, view_bar, grid]))

# ---------------------------------------------------------------------------
# Patients
# ---------------------------------------------------------------------------
def patients_page():
    actions = '<button class="btn btn-primary"><span class="material-symbols-outlined">add</span>Add patient</button>'
    header = page_header("Patients", subtitle="312 patients", actions=actions)
    toolbar = """<div class="toolbar">
  <div class="search-input"><span class="material-symbols-outlined">search</span><input placeholder="Search by name, file #, or phone..."></div>
  <select class="select-filter"><option>All genders</option><option>Male</option><option>Female</option></select>
  <select class="select-filter"><option>All patients</option><option>Has insurance</option><option>No insurance</option></select>
  <select class="select-filter"><option>All statuses</option><option>Active</option><option>Inactive</option></select>
  <div class="view-toggle"><button class="active">Table view</button><button>Card view</button></div>
</div>"""
    rows = [
        ("Nadia El Amrani", "P-0142", 34, "0661 22 33 44", "Yes", "Active"),
        ("Karim Idrissi", "P-0138", 29, "0662 55 66 77", "No", "Active"),
        ("Amine Rachidi", "P-0135", 41, "0663 88 99 00", "Yes", "Active"),
        ("Hicham Alaoui", "P-0129", 52, "0664 11 22 33", "No", "Inactive"),
        ("Fatima Ezzahra", "P-0121", 27, "0665 44 55 66", "Yes", "Active"),
    ]
    trs = ""
    for name, fid, age, phone, ins, status in rows:
        ins_chip = chip(ins, "success" if ins == "Yes" else "neutral")
        st_chip = chip(status, "success" if status == "Active" else "neutral")
        trs += f"<tr><td>{esc(name)}</td><td>{esc(fid)}</td><td>{age}</td><td>{esc(phone)}</td><td>{ins_chip}</td><td>{st_chip}</td></tr>\n"
    table = f"""<div class="data-table-wrap">
<table class="data-table">
<thead><tr><th>Name</th><th>File #</th><th>Age</th><th>Phone</th><th>Insurance</th><th>Status</th></tr></thead>
<tbody>
{trs}</tbody>
</table>
</div>"""
    write_page("patients", "Patients", "patients", "\n".join([header, toolbar, table]))

# ---------------------------------------------------------------------------
# Add patient
# ---------------------------------------------------------------------------
def add_patient_page():
    header = page_header("Add patient", subtitle="Create a new patient file to get started.")
    def field(label, hint=None, kind="text", options=None):
        h = f'<span class="hint">{esc(hint)}</span>' if hint else ""
        if kind == "select":
            opts = "".join(f"<option>{esc(o)}</option>" for o in options)
            return f'<div class="field"><label>{esc(label)}</label><select>{opts}</select>{h}</div>'
        if kind == "textarea":
            return f'<div class="field"><label>{esc(label)}</label><textarea></textarea>{h}</div>'
        return f'<div class="field"><label>{esc(label)}</label><input type="text">{h}</div>'
    form = f"""<div class="card" style="max-width:720px;">
  <div class="field-grid">
    {field("First name")}
    {field("Last name")}
    {field("Date of birth", hint="YYYY-MM-DD")}
    {field("Gender", kind="select", options=["Male","Female","Other"])}
    {field("Blood group")}
    {field("Phone")}
    {field("Email")}
    {field("National ID")}
    {field("Insurance (optional)")}
    {field("Profession")}
    {field("Contact name")}
    {field("Contact phone")}
  </div>
  <div style="margin-top:14px;">{field("Address", kind="textarea")}</div>
  <div class="row" style="justify-content:flex-end; gap:8px; margin-top:18px;">
    <button class="btn btn-outline">Cancel</button>
    <button class="btn btn-primary">Add patient</button>
  </div>
</div>"""
    write_page("add-patient", "Add patient", "patients", "\n".join([header, form]))

# ---------------------------------------------------------------------------
# Patient file (detail)
# ---------------------------------------------------------------------------
def patient_file_page():
    header = """<div class="card" style="margin-bottom:18px;">
  <div class="row" style="justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:14px;">
    <div class="row" style="gap:14px;">
      <div class="avatar" style="width:56px;height:56px;font-size:16px;">NA</div>
      <div>
        <div style="font-size:17px; font-weight:700;">Nadia El Amrani</div>
        <div class="muted" style="font-size:12.5px;">File #P-0142 &middot; 34 y/o &middot; Female &middot; 0661 22 33 44</div>
        <div class="row" style="gap:16px; margin-top:8px;">
          <div><div class="muted" style="font-size:11px;">First visit</div><div style="font-weight:600; font-size:13px;">Jan 14, 2024</div></div>
          <div><div class="muted" style="font-size:11px;">Last visit</div><div style="font-weight:600; font-size:13px;">Aug 3, 2026</div></div>
          <div><div class="muted" style="font-size:11px;">Total purchases</div><div style="font-weight:600; font-size:13px;">14,650 MAD</div></div>
          <div><div class="muted" style="font-size:11px;">Lifetime value</div><div style="font-weight:600; font-size:13px; color:var(--success);">18,200 MAD</div></div>
        </div>
      </div>
    </div>
    <div class="row" style="gap:8px; flex-wrap:wrap;">
      <button class="btn btn-outline btn-sm">New Quote</button>
      <button class="btn btn-outline btn-sm">New Order</button>
      <button class="btn btn-outline btn-icon"><span class="material-symbols-outlined">shield</span></button>
    </div>
  </div>
</div>"""
    tabs = """<div class="tab-strip">
  <div class="tab-item active">Overview</div>
  <div class="tab-item">Appointments</div>
  <div class="tab-item">Exams &amp; notes</div>
  <div class="tab-item">Prescriptions</div>
  <div class="tab-item">Measurements</div>
  <div class="tab-item">Contact Lens</div>
  <div class="tab-item">Billing</div>
  <div class="tab-item">Documents</div>
</div>"""
    overview = """<div class="card-grid cols-2">
  <div class="card">
    <div style="font-weight:600; margin-bottom:8px;">Insurance</div>
    <div class="record-field-row"><span class="record-field-label">Provider</span><span class="record-field-value">CNOPS</span></div>
    <div class="record-field-row"><span class="record-field-label">Policy number</span><span class="record-field-value">CN-88213</span></div>
    <div class="record-field-row"><span class="record-field-label">Valid until</span><span class="record-field-value">Dec 31, 2026</span></div>
  </div>
  <div class="card">
    <div style="font-weight:600; margin-bottom:8px;">Recent activity</div>
    <div class="record-field-row"><span class="record-field-label">Eye exam</span><span class="record-field-value">Aug 3, 2026</span></div>
    <div class="record-field-row"><span class="record-field-label">Prescription</span><span class="record-field-value">Aug 3, 2026</span></div>
    <div class="record-field-row"><span class="record-field-label">Order placed</span><span class="record-field-value">Aug 5, 2026</span></div>
  </div>
</div>"""
    write_page("patient-file", "Patient file — Nadia El Amrani", "patients", "\n".join([header, tabs, overview]))

# ---------------------------------------------------------------------------
# Billing
# ---------------------------------------------------------------------------
def billing_page():
    header = page_header("Billing")
    month = month_filter_bar()
    kpis = kpi_grid([
        ("Total this month", "148,600 MAD", "Icons.payments_outlined", "primary"),
        ("Vs. last month", "+12%", "Icons.trending_up", "success"),
    ], cols=2)
    chart = """<div class="card">
  <div style="font-weight:600; margin-bottom:16px;">Weekly revenue</div>
  <div class="row" style="align-items:flex-end; gap:14px; height:220px; padding:0 6px;">
    <div style="display:flex;flex-direction:column;align-items:center;gap:6px;"><div style="width:28px;height:120px;background:var(--primary);border-radius:4px 4px 0 0;"></div><span class="muted" style="font-size:10.5px;">Jul 14</span></div>
    <div style="display:flex;flex-direction:column;align-items:center;gap:6px;"><div style="width:28px;height:160px;background:var(--primary);border-radius:4px 4px 0 0;"></div><span class="muted" style="font-size:10.5px;">Jul 21</span></div>
    <div style="display:flex;flex-direction:column;align-items:center;gap:6px;"><div style="width:28px;height:90px;background:var(--primary);border-radius:4px 4px 0 0;"></div><span class="muted" style="font-size:10.5px;">Jul 28</span></div>
    <div style="display:flex;flex-direction:column;align-items:center;gap:6px;"><div style="width:28px;height:200px;background:var(--primary);border-radius:4px 4px 0 0;"></div><span class="muted" style="font-size:10.5px;">Aug 4</span></div>
    <div style="display:flex;flex-direction:column;align-items:center;gap:6px;"><div style="width:28px;height:140px;background:var(--primary);border-radius:4px 4px 0 0;"></div><span class="muted" style="font-size:10.5px;">Aug 11</span></div>
  </div>
  <div class="row" style="gap:20px; margin-top:14px;">
    <div class="row" style="gap:6px;"><span style="width:10px;height:10px;border-radius:999px;background:var(--primary); display:inline-block;"></span><span class="muted" style="font-size:12px;">New appointment</span></div>
    <div class="row" style="gap:6px;"><span style="width:10px;height:10px;border-radius:999px;background:var(--chart-2); display:inline-block;"></span><span class="muted" style="font-size:12px;">Reschedule</span></div>
  </div>
</div>"""
    write_page("billing", "Billing", "billing", "\n".join([header, month, kpis, chart]))

# ---------------------------------------------------------------------------
# Tasks
# ---------------------------------------------------------------------------
def tasks_page():
    header = page_header("Staff / Employee Tasks", subtitle="Everything that needs your attention across the app.")
    month = month_filter_bar()
    kpis = kpi_grid([
        ("Total tasks", "5", "Icons.checklist_outlined", "primary"),
        ("Linked to a patient", "5", "Icons.person_outline", "chart2"),
    ], cols=2)
    rows = [
        ("Consent form needs signature", "Hicham Alaoui"),
        ("Consent form needs signature", "Fatima Ezzahra"),
        ("Consent form needs signature", "Omar Benjelloun"),
    ]
    items = "".join(f"""<div class="row" style="justify-content:space-between; padding:12px 16px; border-bottom:1px solid var(--border);">
    <div class="row" style="gap:12px;"><div class="kpi-icon tint-warning" style="width:32px;height:32px;"><span class="material-symbols-outlined" style="font-size:16px;">draw</span></div>
    <div><div style="font-weight:500; font-size:13px;">{esc(t)}</div><div class="muted" style="font-size:12px;">{esc(p)}</div></div></div>
    <span class="material-symbols-outlined muted">chevron_right</span>
  </div>""" for t, p in rows)
    list_card = f'<div class="card" style="padding:0;">{items}</div>'
    write_page("tasks", "Staff / Employee Tasks", "tasks", "\n".join([header, month, kpis, list_card]))

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
def settings_page():
    header = page_header("Settings")
    tabs = """<div class="tab-strip">
  <div class="tab-item active">Appearance</div>
  <div class="tab-item">Dashboard</div>
  <div class="tab-item">Account</div>
  <div class="tab-item">Notifications</div>
</div>"""
    def slider_row(label, value):
        return f"""<div class="setting-row"><div><div class="setting-label">{esc(label)}</div></div><div class="row"><input type="range"><span class="muted" style="width:36px;text-align:right;">{esc(value)}</span></div></div>"""
    def toggle_row(label, on=True):
        cls = "toggle on" if on else "toggle"
        return f'<div class="setting-row"><div class="setting-label">{esc(label)}</div><div class="{cls}"></div></div>'
    left = f"""<div class="card">
  <div class="setting-row"><div class="setting-label">Dark mode</div><div class="toggle"></div></div>
  <div class="setting-row"><div><div class="setting-label">Color scheme</div></div>
    <div class="row" style="gap:6px;">
      <span style="width:20px;height:20px;border-radius:999px;background:#18181B;border:2px solid var(--foreground);display:inline-block;"></span>
      <span style="width:20px;height:20px;border-radius:999px;background:#2563EB;display:inline-block;"></span>
      <span style="width:20px;height:20px;border-radius:999px;background:#16A34A;display:inline-block;"></span>
      <span style="width:20px;height:20px;border-radius:999px;background:#EA580C;display:inline-block;"></span>
      <span style="width:20px;height:20px;border-radius:999px;background:#DC2626;display:inline-block;"></span>
    </div>
  </div>
  <div class="setting-row"><div><div class="setting-label">Language</div></div><select class="select-filter"><option>English</option><option>Fran&ccedil;ais</option><option>&#1575;&#1604;&#1593;&#1585;&#1576;&#1610;&#1577;</option></select></div>
  {slider_row("Corner radius", "0.5")}
  {slider_row("Widget scaling", "1.0")}
  {slider_row("Text scaling", "1.0")}
  {slider_row("Icon scaling", "1.0")}
  {slider_row("Surface opacity", "1.0")}
  {slider_row("Surface blur", "0")}
  {slider_row("Card border", "1")}
  {slider_row("Card shadow", "0.5")}
  {toggle_row("Use Geist typography", on=False)}
</div>"""
    right = """<div class="card">
  <div style="font-weight:600; margin-bottom:2px;">Preview</div>
  <div class="card" style="margin-top:12px; box-shadow:none;">
    <div style="font-weight:600;">Sample card</div>
    <div class="muted" style="font-size:12.5px; margin:6px 0 12px;">This is how cards, text, and buttons look with the settings above.</div>
    <div class="row" style="gap:8px;">
      <button class="btn btn-primary">Primary</button>
      <button class="btn btn-outline">Outline</button>
    </div>
  </div>
</div>"""
    grid = f'<div class="two-col">{left}{right}</div>'
    footer = """<div class="row" style="justify-content:flex-end; gap:8px; margin-top:16px;">
  <button class="btn btn-outline">Reset</button>
  <button class="btn btn-primary">Save changes</button>
</div>"""
    write_page("settings", "Settings", "settings", "\n".join([header, tabs, grid, footer]))

dashboard_page()
calendar_page()
patients_page()
add_patient_page()
patient_file_page()
billing_page()
tasks_page()
settings_page()
print("Generated 8 custom pages")

# ---------------------------------------------------------------------------
# Index / landing page — links every generated page, grouped like the sidebar
# ---------------------------------------------------------------------------
def index_page():
    groups = []
    top_items = "".join(
        f'<a class="idx-link" href="pages/{e["href"]}"><span class="material-symbols-outlined">{e["icon"]}</span>{esc(e["label"])}</a>'
        for e in NAV if e.get("top")
    )
    groups.append(f'<div class="idx-group"><div class="idx-group-title">Top level</div><div class="idx-grid">{top_items}</div></div>')
    for entry in NAV:
        if entry.get("top"):
            continue
        items = "".join(
            f'<a class="idx-link" href="pages/{it["href"]}"><span class="material-symbols-outlined">{it["icon"]}</span>{esc(it["label"])}</a>'
            for it in entry["items"]
        )
        groups.append(f'<div class="idx-group"><div class="idx-group-title">{esc(entry["section"])}</div><div class="idx-grid">{items}</div></div>')
    extra = """<div class="idx-group"><div class="idx-group-title">Other views</div><div class="idx-grid">
    <a class="idx-link" href="pages/add-patient.html"><span class="material-symbols-outlined">person_add</span>Add patient (form)</a>
    <a class="idx-link" href="pages/patient-file.html"><span class="material-symbols-outlined">folder_open</span>Patient file (detail/tabs)</a>
  </div></div>"""
    groups.append(extra)

    html_out = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Doc CRM — design export index</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
<link rel="stylesheet" href="assets/css/style.css">
<style>
  body {{ background: var(--background); }}
  .idx-wrap {{ max-width: 980px; margin: 0 auto; padding: 48px 24px 80px; }}
  .idx-hero {{ margin-bottom: 32px; }}
  .idx-hero h1 {{ font-size: 26px; margin: 0 0 8px; }}
  .idx-hero p {{ color: var(--muted-foreground); max-width: 640px; }}
  .idx-group {{ margin-bottom: 28px; }}
  .idx-group-title {{ font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; color: var(--muted-foreground); margin-bottom: 10px; }}
  .idx-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 10px; }}
  .idx-link {{ display:flex; align-items:center; gap:10px; padding:12px 14px; background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); font-size:13px; font-weight:500; box-shadow:var(--shadow-card); }}
  .idx-link:hover {{ border-color: var(--border-strong); background: var(--surface-2); }}
  .idx-link .material-symbols-outlined {{ color: var(--muted-foreground); font-size:19px; }}
</style>
</head>
<body>
<div class="idx-wrap">
  <div class="idx-hero">
    <div class="logo-mark" style="margin-bottom:14px;">DC</div>
    <h1>Doc CRM — design export</h1>
    <p>Static HTML/CSS replica of the current Flutter app (29 screens), built for a redesign handoff. Every page uses the shared stylesheet at <code>assets/css/style.css</code> — swap the CSS variables at the top of that file to re-skin every screen at once. See <code>README.md</code> for what's exact vs. approximated.</p>
  </div>
  {''.join(groups)}
</div>
</body>
</html>"""
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(html_out)

index_page()
print("Generated index.html")
