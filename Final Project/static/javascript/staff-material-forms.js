/* Staff Material Forms wired to backend APIs */
(function () {
  'use strict';

  var INVENTORY_DATALIST_ID = 'staff-inventory-items-list';
  var inventoryItems = [];
  var inventoryByName = {};
  var inventorySearchTerm = '';

  document.addEventListener('DOMContentLoaded', function () {
    initializeForms();
  });

  async function initializeForms() {
    bindRowControls();
    bindMaterialRequestSubmission();
    bindMaterialUsageSubmission();
    bindInventoryReferenceControls();

    await Promise.all([
      loadInventoryOptions(),
      loadTaskOptions()
    ]);
  }

  async function requestJson(url, options) {
    var response = await fetch(url, options || {});
    var payload = {};
    try {
      payload = await response.json();
    } catch (err) {
      payload = {};
    }

    if (!response.ok) {
      throw new Error(payload.error || payload.message || 'Request failed');
    }
    return payload;
  }

  function normalizeText(value) {
    return String(value || '').trim().toLowerCase();
  }

  function isPositiveNumber(value) {
    if (value === null || value === undefined || String(value).trim() === '') {
      return false;
    }
    var parsed = Number(value);
    return Number.isFinite(parsed) && parsed > 0;
  }

  function formatNumber(value) {
    if (value === null || value === undefined || value === '') {
      return '0';
    }
    var parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      return String(value);
    }
    return parsed.toLocaleString(undefined, { maximumFractionDigits: 2 });
  }

  function formatCurrency(value) {
    if (value === null || value === undefined || value === '') {
      return 'N/A';
    }
    var parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      return 'N/A';
    }
    return '$' + parsed.toFixed(2);
  }

  function ensureInventoryDatalist() {
    var datalist = document.getElementById(INVENTORY_DATALIST_ID);
    if (!datalist) {
      datalist = document.createElement('datalist');
      datalist.id = INVENTORY_DATALIST_ID;
      document.body.appendChild(datalist);
    }
    return datalist;
  }

  function applyInventoryListToInputs(root) {
    var scope = root || document;
    var selectors = [
      '#request-item-input',
      '#request-item-input-mobile',
      '.used-log-item-input',
      '.used-log-item-input-mobile'
    ];

    selectors.forEach(function (selector) {
      var inputs = scope.querySelectorAll(selector);
      inputs.forEach(function (input) {
        input.setAttribute('list', INVENTORY_DATALIST_ID);
      });
    });
  }

  function buildInventoryIndex(items) {
    inventoryByName = {};
    items.forEach(function (item) {
      var key = normalizeText(item.item_name);
      if (!key) {
        return;
      }
      if (!inventoryByName[key]) {
        inventoryByName[key] = item;
      }
    });
  }

  function findInventoryMatchByName(name) {
    var key = normalizeText(name);
    if (!key) {
      return null;
    }
    return inventoryByName[key] || null;
  }

  async function loadInventoryOptions() {
    try {
      var data = await requestJson('/staff/inventory/options');
      inventoryItems = data.items || [];
      buildInventoryIndex(inventoryItems);

      var datalist = ensureInventoryDatalist();
      datalist.innerHTML = '';
      inventoryItems.forEach(function (item) {
        var option = document.createElement('option');
        option.value = item.item_name;
        datalist.appendChild(option);
      });

      applyInventoryListToInputs(document);
      renderInventoryReferenceList();
    } catch (err) {
      console.error('Failed to load inventory options:', err);
      renderInventoryReferenceList(err.message || 'Failed to load inventory.');
    }
  }

  async function loadTaskOptions() {
    var requestTaskSelect = document.getElementById('request-task-select');
    var usageTaskSelect = document.getElementById('used-log-task-select');

    if (!requestTaskSelect && !usageTaskSelect) {
      return;
    }

    try {
      var data = await requestJson('/staff/tasks/options');
      var tasks = data.tasks || [];

      if (requestTaskSelect) {
        populateTaskSelect(requestTaskSelect, tasks, 'General Inventory Need');
      }
      if (usageTaskSelect) {
        populateTaskSelect(usageTaskSelect, tasks, 'Select Task');
      }
    } catch (err) {
      console.error('Failed to load task options:', err);
      if (requestTaskSelect) {
        populateTaskSelect(requestTaskSelect, [], 'General Inventory Need');
      }
      if (usageTaskSelect) {
        populateTaskSelect(usageTaskSelect, [], 'Select Task');
      }
    }
  }

  function populateTaskSelect(selectElement, tasks, defaultLabel) {
    if (!selectElement) {
      return;
    }

    var defaultOption = '<option value="">' + defaultLabel + '</option>';
    var options = tasks.map(function (task) {
      return '<option value="' + task.id + '">' + escapeHtml(task.label || ('Task #' + task.id)) + '</option>';
    });
    selectElement.innerHTML = defaultOption + options.join('');
  }

  function bindInventoryReferenceControls() {
    var searchInput = document.getElementById('inventory-reference-search');
    var refreshButton = document.getElementById('refresh-staff-inventory-btn');

    if (searchInput) {
      searchInput.addEventListener('input', function () {
        inventorySearchTerm = searchInput.value.trim().toLowerCase();
        renderInventoryReferenceList();
      });
    }

    if (refreshButton) {
      refreshButton.addEventListener('click', function () {
        loadInventoryOptions();
      });
    }
  }

  function renderInventoryReferenceList(errorMessage) {
    var container = document.getElementById('inventory-reference-list');
    if (!container) {
      return;
    }

    if (errorMessage) {
      container.innerHTML = '<p class="inventory-reference-empty text-danger">' + escapeHtml(errorMessage) + '</p>';
      return;
    }

    var filtered = inventoryItems.filter(function (item) {
      if (!inventorySearchTerm) {
        return true;
      }
      var haystack = [
        item.item_name,
        item.item_type,
        item.unit_label
      ].join(' ').toLowerCase();
      return haystack.indexOf(inventorySearchTerm) !== -1;
    });

    if (!filtered.length) {
      container.innerHTML = '<p class="inventory-reference-empty">No inventory items match your search.</p>';
      return;
    }

    container.innerHTML = filtered.map(function (item) {
      var lowStock = Number(item.quantity_on_hand || 0) <= Number(item.reorder_level || 0);
      var stockTone = lowStock ? 'text-warning' : '';

      return [
        '<article class="inventory-reference-item">',
          '<div>',
            '<span class="inventory-reference-label">Item</span>',
            '<span class="inventory-reference-value">' + escapeHtml(item.item_name || '') + '</span>',
          '</div>',
          '<div>',
            '<span class="inventory-reference-label">Type</span>',
            '<span class="inventory-reference-value">' + escapeHtml(item.item_type || 'General Supply') + '</span>',
          '</div>',
          '<div>',
            '<span class="inventory-reference-label">Unit Price</span>',
            '<span class="inventory-reference-value">' + escapeHtml(formatCurrency(item.unit_price)) + '</span>',
          '</div>',
          '<div>',
            '<span class="inventory-reference-label">On Hand</span>',
            '<span class="inventory-reference-value ' + stockTone + '">' +
              escapeHtml(formatNumber(item.quantity_on_hand)) + ' ' + escapeHtml(item.unit_label || 'units') +
            '</span>',
          '</div>',
        '</article>'
      ].join('');
    }).join('');
  }

  function bindRowControls() {
    bindDesktopRowControls();
    bindMobileRowControls();
  }

  function bindDesktopRowControls() {
    var addRowButton = document.getElementById('add-used-log-row-btn');
    var removeRowButton = document.getElementById('remove-used-log-row-btn');
    var dynamicRowsContainer = document.getElementById('dynamic-used-log-rows');

    if (!addRowButton || !removeRowButton || !dynamicRowsContainer) {
      return;
    }

    addRowButton.addEventListener('click', function () {
      var row = document.createElement('div');
      row.className = 'used-log-row staff-table-row';
      row.innerHTML = [
        '<input type="text" class="used-log-item-input staff-input" placeholder="Search" />',
        '<input type="number" class="used-log-quantity-input staff-input" placeholder="Enter amount" min="0" step="any" />'
      ].join('');

      dynamicRowsContainer.appendChild(row);
      applyInventoryListToInputs(row);
    });

    removeRowButton.addEventListener('click', function () {
      var rows = dynamicRowsContainer.querySelectorAll('.used-log-row');
      if (rows.length <= 1) {
        return;
      }
      rows[rows.length - 1].remove();
    });
  }

  function bindMobileRowControls() {
    var addRowButton = document.getElementById('add-used-log-row-btn-mobile');
    var removeRowButton = document.getElementById('remove-used-log-row-btn-mobile');
    var rowsContainer = document.getElementById('dynamic-used-log-rows-mobile');

    if (!addRowButton || !removeRowButton || !rowsContainer) {
      return;
    }

    addRowButton.addEventListener('click', function () {
      var row = document.createElement('div');
      row.className = 'staff-mobile-used-row';
      row.innerHTML = [
        '<label class="staff-mobile-field">',
          '<span class="staff-mobile-label">Item</span>',
          '<input type="text" class="staff-mobile-input used-log-item-input-mobile" placeholder="Search" />',
        '</label>',
        '<label class="staff-mobile-field">',
          '<span class="staff-mobile-label">Quantity</span>',
          '<input type="number" class="staff-mobile-input used-log-quantity-input-mobile" placeholder="Enter Amount" min="0" step="any" />',
        '</label>'
      ].join('');

      rowsContainer.appendChild(row);
      applyInventoryListToInputs(row);
    });

    removeRowButton.addEventListener('click', function () {
      var rows = rowsContainer.querySelectorAll('.staff-mobile-used-row');
      if (rows.length <= 1) {
        return;
      }
      rows[rows.length - 1].remove();
    });
  }

  function bindMaterialRequestSubmission() {
    bindSingleRequestForm({
      itemId: 'request-item-input',
      quantityId: 'request-quantity-input',
      noteId: 'request-note-input',
      taskId: 'request-task-select',
      submitId: 'submit-material-request',
      statusId: 'material-request-status'
    });

    bindSingleRequestForm({
      itemId: 'request-item-input-mobile',
      quantityId: 'request-quantity-input-mobile',
      noteId: 'request-note-input-mobile',
      taskId: 'request-task-select-mobile',
      submitId: 'submit-material-request-mobile',
      statusId: 'material-request-status-mobile'
    });
  }

  function bindSingleRequestForm(config) {
    var itemInput = document.getElementById(config.itemId);
    var quantityInput = document.getElementById(config.quantityId);
    var noteInput = document.getElementById(config.noteId);
    var submitButton = document.getElementById(config.submitId);
    var taskSelect = document.getElementById(config.taskId);
    var statusEl = document.getElementById(config.statusId);

    if (!itemInput || !quantityInput || !noteInput || !submitButton) {
      return;
    }

    submitButton.addEventListener('click', async function () {
      clearStatus(statusEl);

      var itemValue = itemInput.value.trim();
      var quantityValue = quantityInput.value.trim();
      var noteValue = noteInput.value.trim();
      var taskValue = taskSelect ? taskSelect.value : '';

      if (!itemValue) {
        showStatus(statusEl, 'Please enter an item.', true);
        return;
      }
      if (!isPositiveNumber(quantityValue)) {
        showStatus(statusEl, 'Quantity must be greater than zero.', true);
        return;
      }

      var matchedItem = findInventoryMatchByName(itemValue);
      var payload = {
        item: itemValue,
        quantity: Number(quantityValue),
        note: noteValue,
        task_id: taskValue || null
      };

      if (matchedItem) {
        payload.item_id = matchedItem.item_id;
      }

      submitButton.disabled = true;
      try {
        var result = await requestJson('/staff/material-requests', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });

        showStatus(statusEl, 'Submitted successfully: ' + (result.request_code || 'request created'), false);
        itemInput.value = '';
        quantityInput.value = '';
        noteInput.value = '';
        if (taskSelect) {
          taskSelect.value = '';
        }
      } catch (err) {
        showStatus(statusEl, err.message, true);
      } finally {
        submitButton.disabled = false;
      }
    });
  }

  function bindMaterialUsageSubmission() {
    bindSingleUsageForm({
      submitId: 'submit-used-log-btn',
      taskId: 'used-log-task-select',
      itemSelector: '.used-log-item-input',
      quantitySelector: '.used-log-quantity-input',
      statusId: 'used-log-status'
    });

    bindSingleUsageForm({
      submitId: 'submit-used-log-btn-mobile',
      taskId: 'used-log-task-select-mobile',
      fallbackTaskId: 'used-log-task-select',
      itemSelector: '.used-log-item-input-mobile',
      quantitySelector: '.used-log-quantity-input-mobile',
      statusId: 'used-log-status-mobile'
    });
  }

  function bindSingleUsageForm(config) {
    var submitButton = document.getElementById(config.submitId);
    var taskSelect = document.getElementById(config.taskId);
    if (!taskSelect && config.fallbackTaskId) {
      taskSelect = document.getElementById(config.fallbackTaskId);
    }
    var statusEl = document.getElementById(config.statusId);

    if (!submitButton) {
      return;
    }

    submitButton.addEventListener('click', async function () {
      clearStatus(statusEl);

      if (!taskSelect || !taskSelect.value) {
        showStatus(statusEl, 'Please select a task before submitting.', true);
        return;
      }

      var itemInputs = Array.prototype.slice.call(document.querySelectorAll(config.itemSelector));
      var quantityInputs = Array.prototype.slice.call(document.querySelectorAll(config.quantitySelector));
      var entryCount = Math.min(itemInputs.length, quantityInputs.length);
      var itemsPayload = [];
      var invalidMessage = '';

      for (var i = 0; i < entryCount; i += 1) {
        var itemValue = itemInputs[i].value.trim();
        var quantityValue = quantityInputs[i].value.trim();

        if (!itemValue && !quantityValue) {
          continue;
        }

        if (!itemValue || !isPositiveNumber(quantityValue)) {
          invalidMessage = 'Each used-material row must include an item and a positive quantity.';
          break;
        }

        var match = findInventoryMatchByName(itemValue);
        var rowPayload = {
          item: itemValue,
          quantity: Number(quantityValue)
        };
        if (match) {
          rowPayload.item_id = match.item_id;
        }
        itemsPayload.push(rowPayload);
      }

      if (invalidMessage) {
        showStatus(statusEl, invalidMessage, true);
        return;
      }

      if (itemsPayload.length === 0) {
        showStatus(statusEl, 'Add at least one material row.', true);
        return;
      }

      submitButton.disabled = true;
      try {
        var result = await requestJson('/staff/material-usage', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            task_id: Number(taskSelect.value),
            items: itemsPayload
          })
        });

        showStatus(statusEl, result.message || 'Usage log submitted successfully.', false);
        clearFormInputs(itemInputs, quantityInputs);
      } catch (err) {
        showStatus(statusEl, err.message, true);
      } finally {
        submitButton.disabled = false;
      }
    });
  }

  function clearFormInputs(itemInputs, quantityInputs) {
    itemInputs.forEach(function (input) {
      input.value = '';
    });
    quantityInputs.forEach(function (input) {
      input.value = '';
    });
  }

  function showStatus(element, message, isError) {
    if (!element) {
      if (isError) {
        alert(message);
      }
      return;
    }

    element.textContent = message || '';
    element.classList.remove('text-danger', 'text-success');
    element.classList.add(isError ? 'text-danger' : 'text-success');
  }

  function clearStatus(element) {
    if (!element) {
      return;
    }
    element.textContent = '';
    element.classList.remove('text-danger', 'text-success');
  }

  function escapeHtml(value) {
    return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
})();
