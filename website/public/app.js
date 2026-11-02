const nav = document.querySelector(".nav");
const toggle = document.querySelector(".menu-toggle");
const menu = document.querySelector("#site-menu");

function closeMenu({ restoreFocus = false } = {}) {
  nav?.classList.remove("nav-open");
  toggle?.setAttribute("aria-expanded", "false");
  toggle?.querySelector(".sr-only")?.replaceChildren("Open navigation");
  if (restoreFocus) toggle?.focus();
}

function openMenu() {
  nav?.classList.add("nav-open");
  toggle?.setAttribute("aria-expanded", "true");
  toggle?.querySelector(".sr-only")?.replaceChildren("Close navigation");
  menu?.querySelector("a")?.focus();
}

toggle?.addEventListener("click", () => {
  if (nav.classList.contains("nav-open")) closeMenu();
  else openMenu();
});

menu?.addEventListener("click", (event) => {
  if (event.target instanceof HTMLAnchorElement) closeMenu();
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    closeMenu({ restoreFocus: true });
    return;
  }
  if (event.key !== "Tab" || !nav?.classList.contains("nav-open")) return;
  const items = [toggle, ...menu.querySelectorAll("a")].filter(Boolean);
  const first = items[0];
  const last = items.at(-1);
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last?.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first?.focus();
  }
});

const revealItems = document.querySelectorAll(".reveal");
if (!("IntersectionObserver" in window)) {
  revealItems.forEach((item) => item.classList.add("is-visible"));
} else {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.16, rootMargin: "0px 0px -6% 0px" },
  );
  revealItems.forEach((item) => observer.observe(item));
}
