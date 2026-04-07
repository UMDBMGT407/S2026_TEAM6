/* ===== Staff Material Forms ===== */
/* Section Guide: bootstrapping, shared utilities, material requests, used material log */
(function () {
  'use strict';

  /* Bootstrapping */
  document.addEventListener('DOMContentLoaded', function () {
    initMaterialRequestsPage();
    initUsedMaterialLogPage();
  });

  /* Shared Utility */
  function isValidNumber(value) {
    return value.trim() !== '' && Number.isFinite(Number(value));
  }

  function saveMaterialRequest(entry) {
    var requests = JSON.parse(localStorage.getItem('staffMaterialRequests') || '[]');
    requests.push(entry);
    localStorage.setItem('staffMaterialRequests', JSON.stringify(requests));
  }

  function saveUsedMaterialLog(rows) {
    var logs = JSON.parse(localStorage.getItem('staffUsedMaterialLogs') || '[]');
    logs.push({
      rows: rows,
      submittedAt: new Date().toISOString()
    });
    localStorage.setItem('staffUsedMaterialLogs', JSON.stringify(logs));
  }

  function collectUsedLogRows(itemInputs, quantityInputs) {
    var hasInvalidEntry = false;
    var validEntries = [];

    for (var i = 0; i < itemInputs.length; i += 1) {
      var itemValue = itemInputs[i].value.trim();
      var quantityValue = quantityInputs[i].value.trim();

      /* Ignore fully empty rows */
      if (itemValue === '' && quantityValue === '') {
        continue;
      }

      /* Reject partially filled or non-numeric rows */
      if (itemValue === '' || !isValidNumber(quantityValue)) {
        hasInvalidEntry = true;
        continue;
      }

      validEntries.push({
        item: itemValue,
        quantity: Number(quantityValue)
      });
    }

    return {
      hasInvalidEntry: hasInvalidEntry,
      validEntries: validEntries
    };
  }

  /* ===== Material Requests ===== */
  function bindMaterialRequestForm(config) {
    var itemInput = document.getElementById(config.itemId);
    var quantityInput = document.getElementById(config.quantityId);
    var noteInput = document.getElementById(config.noteId);
    var submitButton = document.getElementById(config.submitId);

    if (!itemInput || !quantityInput || !noteInput || !submitButton) {
      return;
    }

    submitButton.addEventListener('click', function () {
      var itemValue = itemInput.value.trim();
      var quantityValue = quantityInput.value.trim();

      /* Validation Rules */
      if (itemValue === '' || !isValidNumber(quantityValue)) {
        alert('Invalid Entry: Please Review Request');
        return;
      }

      /* localStorage Persistence */
      saveMaterialRequest({
        item: itemValue,
        quantity: Number(quantityValue),
        note: noteInput.value.trim(),
        submittedAt: new Date().toISOString()
      });

      alert('Material Request Submitted Successfully.');
    });
  }

  function initMaterialRequestsPage() {
    var hasDesktopView = Boolean(document.querySelector('.material-requests'));
    var hasMobileView = Boolean(document.querySelector('.material-requests-mobile'));

    if (!hasDesktopView && !hasMobileView) {
      return;
    }

    bindMaterialRequestForm({
      itemId: 'request-item-input',
      quantityId: 'request-quantity-input',
      noteId: 'request-note-input',
      submitId: 'submit-material-request'
    });

    bindMaterialRequestForm({
      itemId: 'request-item-input-mobile',
      quantityId: 'request-quantity-input-mobile',
      noteId: 'request-note-input-mobile',
      submitId: 'submit-material-request-mobile'
    });
  }

  /* ===== Used Material Log ===== */
  function initUsedMaterialLogPage() {
    var desktopPage = document.querySelector('.used-material-log');
    if (desktopPage) {
      initDesktopUsedMaterialLog(desktopPage);
    }

    var mobilePage = document.querySelector('.used-material-log-mobile');
    if (mobilePage) {
      initMobileUsedMaterialLog(mobilePage);
    }
  }

  function initDesktopUsedMaterialLog(page) {
    /* Element Bindings */
    var addRowButton = document.getElementById('add-used-log-row-btn');
    var removeRowButton = document.getElementById('remove-used-log-row-btn');
    var submitButton = document.getElementById('submit-used-log-btn');
    var dynamicRowsContainer = document.getElementById('dynamic-used-log-rows');
    var formCard = page.querySelector('.used-log-form-card');
    var submitText = page.querySelector('.submit-log-text');
    var addIcon = page.querySelector('.add-row-icon');
    var removeIcon = page.querySelector('.remove-row-icon');

    /* Safety Guard */
    if (!addRowButton || !removeRowButton || !submitButton || !dynamicRowsContainer || !formCard) {
      return;
    }

    /* Dynamic Row State */
    var initialRows = page.querySelectorAll('.used-log-item-input').length;
    var currentRowCount = initialRows;
    var dynamicRows = [];

    /* Layout Constants */
    var rowStartTop = 379;
    var rowGap = 51;

    /* Baseline Layout Measurements */
    var baseFormCardHeight = parseInt(getComputedStyle(formCard).height, 10);
    var baseSubmitTop = parseInt(getComputedStyle(submitButton).top, 10);
    var baseSubmitTextTop = submitText ? parseInt(getComputedStyle(submitText).top, 10) : 0;
    var baseAddTop = parseInt(getComputedStyle(addRowButton).top, 10);
    var baseAddIconTop = addIcon ? parseInt(getComputedStyle(addIcon).top, 10) : 0;
    var baseRemoveTop = parseInt(getComputedStyle(removeRowButton).top, 10);
    var baseRemoveIconTop = removeIcon ? parseInt(getComputedStyle(removeIcon).top, 10) : 0;
    var basePageHeight = parseInt(getComputedStyle(page).height, 10);

    /* Layout Updater */
    function updateDynamicLayout() {
      var extraRows = Math.max(0, currentRowCount - initialRows);
      var offset = extraRows * rowGap;

      formCard.style.height = String(baseFormCardHeight + offset) + 'px';
      submitButton.style.top = String(baseSubmitTop + offset) + 'px';
      addRowButton.style.top = String(baseAddTop + offset) + 'px';
      removeRowButton.style.top = String(baseRemoveTop + offset) + 'px';
      page.style.height = String(basePageHeight + offset) + 'px';

      if (submitText) {
        submitText.style.top = String(baseSubmitTextTop + offset) + 'px';
      }

      if (addIcon) {
        addIcon.style.top = String(baseAddIconTop + offset) + 'px';
      }

      if (removeIcon) {
        removeIcon.style.top = String(baseRemoveIconTop + offset) + 'px';
      }
    }

    /* Row Factory */
    function createDynamicRow(rowNumber) {
      var rowTop = rowStartTop + (rowNumber - 1) * rowGap;
      var itemLabelTop = rowTop - 3;
      var quantityLabelTop = rowTop - 2;

      var itemLabel = document.createElement('div');
      itemLabel.className = 'dynamic-log-item-label';
      itemLabel.textContent = 'Item:';
      itemLabel.style.top = String(itemLabelTop) + 'px';

      var quantityLabel = document.createElement('div');
      quantityLabel.className = 'dynamic-log-quantity-label';
      quantityLabel.textContent = 'Quantity:';
      quantityLabel.style.top = String(quantityLabelTop) + 'px';

      var itemBg = document.createElement('div');
      itemBg.className = 'dynamic-log-row-item-bg';
      itemBg.style.top = String(rowTop) + 'px';

      var quantityBg = document.createElement('div');
      quantityBg.className = 'dynamic-log-row-qty-bg';
      quantityBg.style.top = String(rowTop) + 'px';

      var itemInput = document.createElement('input');
      itemInput.type = 'text';
      itemInput.id = 'used-log-item-' + String(rowNumber);
      itemInput.className = 'used-log-item-input dynamic-row';
      itemInput.placeholder = 'Search';
      itemInput.style.top = String(rowTop + 3) + 'px';

      var quantityInput = document.createElement('input');
      quantityInput.type = 'number';
      quantityInput.min = '0';
      quantityInput.step = 'any';
      quantityInput.id = 'used-log-quantity-' + String(rowNumber);
      quantityInput.className = 'used-log-quantity-input dynamic-row';
      quantityInput.placeholder = 'Enter Amount';
      quantityInput.style.top = String(rowTop + 3) + 'px';

      dynamicRowsContainer.appendChild(itemLabel);
      dynamicRowsContainer.appendChild(quantityLabel);
      dynamicRowsContainer.appendChild(itemBg);
      dynamicRowsContainer.appendChild(quantityBg);
      dynamicRowsContainer.appendChild(itemInput);
      dynamicRowsContainer.appendChild(quantityInput);

      dynamicRows.push({
        elements: [itemLabel, quantityLabel, itemBg, quantityBg, itemInput, quantityInput]
      });
    }

    /* Row Removal */
    function removeDynamicRow() {
      if (dynamicRows.length === 0) {
        return;
      }

      var lastRow = dynamicRows.pop();
      for (var i = 0; i < lastRow.elements.length; i += 1) {
        lastRow.elements[i].remove();
      }
    }

    /* Row Controls */
    addRowButton.addEventListener('click', function () {
      currentRowCount += 1;
      createDynamicRow(currentRowCount);
      updateDynamicLayout();
    });

    removeRowButton.addEventListener('click', function () {
      if (currentRowCount <= initialRows) {
        return;
      }

      removeDynamicRow();
      currentRowCount -= 1;
      updateDynamicLayout();
    });

    /* Submit Flow: validate -> persist -> notify */
    submitButton.addEventListener('click', function () {
      var itemInputs = page.querySelectorAll('.used-log-item-input');
      var quantityInputs = page.querySelectorAll('.used-log-quantity-input');
      var rowData = collectUsedLogRows(itemInputs, quantityInputs);

      /* Final validation gate */
      if (rowData.hasInvalidEntry || rowData.validEntries.length === 0) {
        alert('Please Make a Valid Seclection to Submit');
        return;
      }

      /* localStorage Persistence */
      saveUsedMaterialLog(rowData.validEntries);

      alert('Used Material Log Successfully Submitted');
    });
  }

  function initMobileUsedMaterialLog(page) {
    /* Element Bindings */
    var addRowButton = document.getElementById('add-used-log-row-btn-mobile');
    var removeRowButton = document.getElementById('remove-used-log-row-btn-mobile');
    var submitButton = document.getElementById('submit-used-log-btn-mobile');
    var rowsContainer = document.getElementById('dynamic-used-log-rows-mobile');

    /* Safety Guard */
    if (!addRowButton || !removeRowButton || !submitButton || !rowsContainer) {
      return;
    }

    /* Dynamic Row State */
    var dynamicRows = [];
    var nextRowNumber = page.querySelectorAll('.used-log-item-input-mobile').length + 1;

    /* Row Factory */
    function createMobileRow(rowNumber) {
      var row = document.createElement('div');
      row.className = 'staff-mobile-used-row';

      var itemField = document.createElement('label');
      itemField.className = 'staff-mobile-field';
      itemField.setAttribute('for', 'used-log-item-mobile-' + String(rowNumber));

      var itemLabel = document.createElement('span');
      itemLabel.className = 'staff-mobile-label';
      itemLabel.textContent = 'Item';

      var itemInput = document.createElement('input');
      itemInput.type = 'text';
      itemInput.id = 'used-log-item-mobile-' + String(rowNumber);
      itemInput.className = 'staff-mobile-input used-log-item-input-mobile';
      itemInput.placeholder = 'Search';

      var quantityField = document.createElement('label');
      quantityField.className = 'staff-mobile-field';
      quantityField.setAttribute('for', 'used-log-quantity-mobile-' + String(rowNumber));

      var quantityLabel = document.createElement('span');
      quantityLabel.className = 'staff-mobile-label';
      quantityLabel.textContent = 'Quantity';

      var quantityInput = document.createElement('input');
      quantityInput.type = 'number';
      quantityInput.min = '0';
      quantityInput.step = 'any';
      quantityInput.id = 'used-log-quantity-mobile-' + String(rowNumber);
      quantityInput.className = 'staff-mobile-input used-log-quantity-input-mobile';
      quantityInput.placeholder = 'Enter Amount';

      itemField.appendChild(itemLabel);
      itemField.appendChild(itemInput);
      quantityField.appendChild(quantityLabel);
      quantityField.appendChild(quantityInput);
      row.appendChild(itemField);
      row.appendChild(quantityField);

      rowsContainer.appendChild(row);
      dynamicRows.push(row);
    }

    /* Row Controls */
    addRowButton.addEventListener('click', function () {
      createMobileRow(nextRowNumber);
      nextRowNumber += 1;
    });

    removeRowButton.addEventListener('click', function () {
      if (dynamicRows.length === 0) {
        return;
      }

      var lastRow = dynamicRows.pop();
      lastRow.remove();
    });

    /* Submit Flow: validate -> persist -> notify */
    submitButton.addEventListener('click', function () {
      var itemInputs = page.querySelectorAll('.used-log-item-input-mobile');
      var quantityInputs = page.querySelectorAll('.used-log-quantity-input-mobile');
      var rowData = collectUsedLogRows(itemInputs, quantityInputs);

      /* Final validation gate */
      if (rowData.hasInvalidEntry || rowData.validEntries.length === 0) {
        alert('Please Make a Valid Seclection to Submit');
        return;
      }

      /* localStorage Persistence */
      saveUsedMaterialLog(rowData.validEntries);

      alert('Used Material Log Successfully Submitted');
    });
  }
})();
