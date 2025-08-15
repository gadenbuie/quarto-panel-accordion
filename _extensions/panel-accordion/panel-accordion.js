(function () {
  function openAccordionFromHash() {
    if (!window.bootstrap) return;

    const hash = window.location.hash;
    if (!hash) return;

    const target = document.querySelector(hash);
    if (!target) return;

    if (!target.classList.contains("accordion-header")) return;

    const triggerBtn = target.querySelector(
      ".accordion-button[data-bs-target]"
    );
    if (!triggerBtn) return;

    const panelSelector = triggerBtn.getAttribute("data-bs-target");
    if (!panelSelector) return;

    const panel = document.querySelector(panelSelector);
    if (!panel) return;

    const collapse = bootstrap.Collapse.getOrCreateInstance(panel, {
      toggle: false,
    });
    collapse.show();
  }

  function handleAnchorClick(event) {
    const link = event.currentTarget;

    const hrefHash = link.getAttribute("href") || "";
    if (hrefHash.startsWith("#")) {
      window.location.hash = hrefHash;
    }
  }

  function moveAccordionAnchorLinks() {
    if (!document.querySelector(".accordion-header")) return;
    if (!document.querySelector(".anchored .anchorjs-link")) {
      setTimeout(moveAccordionAnchorLinks, 10);
    }

    document
      .querySelectorAll(".accordion-header .anchorjs-link")
      .forEach(function (link) {
        const header = link.closest(".accordion-header");
        const headerContent = header.querySelector(".accordion-header-content");
        if (headerContent) {
          headerContent.appendChild(link);
          link.addEventListener("click", handleAnchorClick);
        }
      });
  }

  document.addEventListener("DOMContentLoaded", openAccordionFromHash);
  window.addEventListener("hashchange", openAccordionFromHash);
  document.addEventListener("DOMContentLoaded", moveAccordionAnchorLinks);
})();
