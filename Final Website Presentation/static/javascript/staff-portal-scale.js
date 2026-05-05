// Shared desktop scaling for fixed-canvas staff pages.
(function () {
  var desktopMinWidth = 992;
  var maxScale = 3;
  var canvasSelectors = [
    ".staff-scheduling-dashboard",
    ".task-management-dashboard",
    ".inventory-dashboard",
    ".material-requests",
    ".used-material-log",
    ".availability-entry-page",
    ".contact-client-modal",
    ".job-materials-modal",
  ];

  function clamp(value, minValue, maxValue) {
    return Math.max(minValue, Math.min(maxValue, value));
  }

  function getViewportWidth() {
    return window.innerWidth || document.documentElement.clientWidth || 0;
  }

  function getCanvasParent(canvasElement) {
    return canvasElement.parentElement || null;
  }

  function resetScale(canvasElement) {
    var parentElement = getCanvasParent(canvasElement);
    canvasElement.style.transform = "";
    canvasElement.style.transformOrigin = "";
    canvasElement.style.marginBottom = "";
    if (parentElement) {
      parentElement.style.minWidth = "";
      parentElement.style.minHeight = "";
    }
  }

  function rememberBaseSize(canvasElement) {
    if (canvasElement.dataset.baseWidth && canvasElement.dataset.baseHeight) {
      return;
    }

    var previousTransform = canvasElement.style.transform;
    var previousTransformOrigin = canvasElement.style.transformOrigin;
    var previousMarginBottom = canvasElement.style.marginBottom;

    canvasElement.style.transform = "";
    canvasElement.style.transformOrigin = "";
    canvasElement.style.marginBottom = "";

    var measuredWidth = parseFloat(window.getComputedStyle(canvasElement).width) || canvasElement.offsetWidth || 1440;
    var measuredHeight = canvasElement.offsetHeight || 1024;

    canvasElement.dataset.baseWidth = String(Math.round(measuredWidth));
    canvasElement.dataset.baseHeight = String(Math.round(measuredHeight));

    canvasElement.style.transform = previousTransform;
    canvasElement.style.transformOrigin = previousTransformOrigin;
    canvasElement.style.marginBottom = previousMarginBottom;
  }

  function applyScale(canvasElement, scaleFactor) {
    var parentElement = getCanvasParent(canvasElement);
    var baseWidth = parseFloat(canvasElement.dataset.baseWidth || "1440");
    var baseHeight = parseFloat(canvasElement.dataset.baseHeight || "1024");

    canvasElement.style.transformOrigin = "top left";
    canvasElement.style.transform = "scale(" + scaleFactor + ")";
    canvasElement.style.marginBottom = Math.max(0, baseHeight * (scaleFactor - 1)) + "px";

    if (parentElement) {
      parentElement.style.minWidth = Math.ceil(baseWidth * scaleFactor) + "px";
      parentElement.style.minHeight = Math.ceil(baseHeight * scaleFactor) + "px";
    }
  }

  function applyDesktopScaling() {
    var viewportWidth = getViewportWidth();
    var shouldScaleDesktop = viewportWidth >= desktopMinWidth;

    canvasSelectors.forEach(function (selector) {
      document.querySelectorAll(selector).forEach(function (canvasElement) {
        if (!shouldScaleDesktop || window.getComputedStyle(canvasElement).display === "none") {
          resetScale(canvasElement);
          return;
        }

        rememberBaseSize(canvasElement);

        var baseWidth = parseFloat(canvasElement.dataset.baseWidth || "1440");
        if (!baseWidth || baseWidth <= 0) {
          return;
        }

        var scaleFactor = clamp(viewportWidth / baseWidth, 1, maxScale);
        applyScale(canvasElement, scaleFactor);
      });
    });
  }

  var resizeTimer = null;
  function onResize() {
    if (resizeTimer) {
      clearTimeout(resizeTimer);
    }

    resizeTimer = setTimeout(function () {
      applyDesktopScaling();
    }, 80);
  }

  window.addEventListener("resize", onResize);
  window.addEventListener("load", applyDesktopScaling);
  applyDesktopScaling();
})();
