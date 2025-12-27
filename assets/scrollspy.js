const navItems = document.querySelectorAll("body > nav ul li > a:first-child");
const sectionVisibilities = {};

const observer = new IntersectionObserver(
  (entries, observer) => {
    for (const entry of entries)
      sectionVisibilities[entry.target.id] = entry.isIntersecting;

    let currentSectionId;
    for (const [id, visible] of Object.entries(sectionVisibilities))
      if (visible) {
        currentSectionId = id;
        break;
      }

    for (const navItem of navItems)
      navItem.className =
        navItem.getAttribute("href") === `#${currentSectionId}`
          ? "active"
          : "";
  },
  {
    root: null,
    rootMargin: "0px",
    threshold: 0,
  },
);

for (const section of document.querySelectorAll("main > * > section")) {
  if ("id" in section) observer.observe(section);
}
