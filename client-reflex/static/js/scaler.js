const init = () => {
  const ro = new ResizeObserver((entries) => {
    for (const entry of entries) {
      const container = entry.target;
      const content = container.querySelector(".scaler-target");
      if (!content) continue;
      const nativeW = parseFloat(container.dataset.nativeW);
      const currentW = entry.contentRect.width;
      if (nativeW && currentW) {
        const scale = currentW / (nativeW * 3.7795275591);
        content.style.transform = `scale(${scale})`;
      }
    }
  });

  const mo = new MutationObserver((mutations) => {
    for (const m of mutations) {
      for (const node of m.addedNodes) {
        if (node.nodeType === 1) {
          if (node.classList.contains("scaler-container")) ro.observe(node);
          node
            .querySelectorAll(".scaler-container")
            .forEach((c) => ro.observe(c));
        }
      }
    }
  });
  mo.observe(document.body, { childList: true, subtree: true });

  // Find existing ones
  document.querySelectorAll(".scaler-container").forEach((c) => ro.observe(c));
};

if (document.readyState === "loading") {
  window.addEventListener("DOMContentLoaded", init);
} else {
  init();
}
