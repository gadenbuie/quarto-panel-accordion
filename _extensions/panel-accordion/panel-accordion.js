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

  document.addEventListener("DOMContentLoaded", openAccordionFromHash);
  window.addEventListener("hashchange", openAccordionFromHash);

  function handleAnchorClick(event) {
    const link = event.currentTarget;

    const hrefHash = link.getAttribute("href") || "";
    if (hrefHash.startsWith("#")) {
      window.location.hash = hrefHash;
    }
  }

  window.onload = function () {
    const links = document.querySelectorAll(".accordion-header .anchorjs-link");
    links.forEach(function (link) {
      const header = link.closest(".accordion-header");
      const headerContent = header.querySelector(".accordion-header-content");
      if (headerContent) {
        headerContent.appendChild(link);
        link.addEventListener("click", handleAnchorClick);
      }
    });
  };
})();

