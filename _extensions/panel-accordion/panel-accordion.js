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
})();
