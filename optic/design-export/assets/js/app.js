// Doc CRM design export — tiny bit of JS so the static pages feel alive
// enough to click through during a redesign review. No framework, no
// build step: open any .html file directly in a browser.

document.addEventListener("DOMContentLoaded", () => {
  const toggle = document.getElementById("mobileNavToggle");
  const sidebar = document.getElementById("sidebar");
  if (toggle && sidebar) {
    toggle.addEventListener("click", () => sidebar.classList.toggle("open"));
  }

  // Tab strips: clicking a tab just toggles the active class (no routing —
  // each Flutter tab's content isn't reproduced per-tab here, only the
  // "Overview" tab's content is shown, matching how this export prioritizes
  // structure over full interactivity).
  document.querySelectorAll(".tab-strip").forEach((strip) => {
    strip.querySelectorAll(".tab-item").forEach((tab) => {
      tab.addEventListener("click", () => {
        strip.querySelectorAll(".tab-item").forEach((t) => t.classList.remove("active"));
        tab.classList.add("active");
      });
    });
  });

  // View toggle (Table view / Card view, Day / Week / Month, etc.)
  document.querySelectorAll(".view-toggle").forEach((group) => {
    group.querySelectorAll("button").forEach((btn) => {
      btn.addEventListener("click", () => {
        group.querySelectorAll("button").forEach((b) => b.classList.remove("active"));
        btn.classList.add("active");
      });
    });
  });

  // Dark-mode preview toggle, if a page adds a [data-toggle-dark] button.
  document.querySelectorAll("[data-toggle-dark]").forEach((btn) => {
    btn.addEventListener("click", () => document.documentElement.classList.toggle("dark"));
  });
});
