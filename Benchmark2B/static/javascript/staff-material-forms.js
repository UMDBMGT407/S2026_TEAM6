/* ===== Staff Material Forms ===== */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    initInventoryForms();
  });

  function setStatusMessage(element, type, text) {
    if (!element) {
      return;
    }

    element.textContent = text || '';
    element.classList.remove('is-error', 'is-success');
    if (type) {
      element.classList.add(type === 'error' ? 'is-error' : 'is-success');
    }
  }

  function normalizeText(value) {
    return (value || '').replace(/\s+/g, ' ').trim();
  }

  function parsePositiveNumber(value) {
    var parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  async function fetchTaskOptions() {
    var response = await fetch('/staff/tasks/options');
    var payload = await response.json();

    if (!response.ok) {
      throw new Error(payload.error || 'Unable to load tasks.');
    }

    return payload.tasks || [];
  }

  function populateTaskSelect(selectElement, tasks, emptyLabel) {
    if (!selectElement) {
      return;
    }

    var previousValue = selectElement.value;
    selectElement.innerHTML = '';

    var firstOption = document.createElement('option');
    firstOption.value = '';
    firstOption.textContent = emptyLabel;
    selectElement.appendChild(firstOption);

    tasks.forEach(function (task) {
      var option = document.createElement('option');
      option.value = String(task.id);
      option.textContent = task.label || task.name || ('Task #' + String(task.id));
      selectElement.appendChild(option);
    });

    if (previousValue && Array.from(selectElement.options).some(function (opt) { return opt.value === previousValue; })) {
      selectElement.value = previousValue;
    }
  }

  function createUsageRow(index) {
    var row = document.createElement('div');
    row.className = 'used-log-row staff-table-row';

    var itemInput = document.createElement('input');
    itemInput.type = 'text';
    itemInput.id = 'used-log-item-' + String(index);
    itemInput.className = 'used-log-item-input staff-input';
    itemInput.placeholder = 'Search';

    var qtyInput = document.createElement('input');
    qtyInput.type = 'number';
    qtyInput.min = '0';
    qtyInput.step = 'any';
    qtyInput.id = 'used-log-quantity-' + String(index);
    qtyInput.className = 'used-log-quantity-input staff-input';
    qtyInput.placeholder = 'Enter amount';

    row.appendChild(itemInput);
    row.appendChild(qtyInput);
    return row;
  }

  function collectUsageEntries(rowsContainer) {
    var rows = Array.from(rowsContainer.querySelectorAll('.used-log-row'));
    var entries = [];

    for (var i = 0; i < rows.length; i += 1) {
      var itemInput = rows[i].querySelector('.used-log-item-input');
      var qtyInput = rows[i].querySelector('.used-log-quantity-input');

      var itemName = normalizeText(itemInput ? itemInput.value : '');
      var quantityText = normalizeText(qtyInput ? qtyInput.value : '');

      if (!itemName && !quantityText) {
        continue;
      }

      var quantity = parsePositiveNumber(quantityText);
      if (!itemName || quantity === null) {
        return {
          error: 'Each used-material row needs both an item and a quantity greater than zero.'
        };
      }

      entries.push({
        item: itemName,
        quantity: quantity
      });
    }

    if (!entries.length) {
      return {
        error: 'Add at least one used material entry before submitting.'
      };
    }

    return {
      entries: entries
    };
  }

  function resetUsageRows(rowsContainer, baseRowCount) {
    var rows = Array.from(rowsContainer.querySelectorAll('.used-log-row'));
    rows.forEach(function (row, index) {
      var itemInput = row.querySelector('.used-log-item-input');
      var qtyInput = row.querySelector('.used-log-quantity-input');

      if (index < baseRowCount) {
        if (itemInput) itemInput.value = '';
        if (qtyInput) qtyInput.value = '';
      } else {
        row.remove();
      }
    });
  }

  function initInventoryForms() {
    var requestItemInput = document.getElementById('request-item-input');
    var requestQuantityInput = document.getElementById('request-quantity-input');
    var requestNoteInput = document.getElementById('request-note-input');
    var requestTaskSelect = document.getElementById('request-task-select');
    var requestSubmitButton = document.getElementById('submit-material-request');
    var requestStatus = document.getElementById('material-request-status');

    var usageTaskSelect = document.getElementById('used-log-task-select');
    var usageRowsContainer = document.getElementById('dynamic-used-log-rows');
    var usageAddRowButton = document.getElementById('add-used-log-row-btn');
    var usageRemoveRowButton = document.getElementById('remove-used-log-row-btn');
    var usageSubmitButton = document.getElementById('submit-used-log-btn');
    var usageStatus = document.getElementById('used-log-status');

    if (!requestSubmitButton || !usageSubmitButton || !usageRowsContainer) {
      return;
    }

    var baseUsageRowCount = usageRowsContainer.querySelectorAll('.used-log-row').length;

    async function loadTaskSelectors() {
      try {
        var tasks = await fetchTaskOptions();
        populateTaskSelect(requestTaskSelect, tasks, 'General Inventory Need');
        populateTaskSelect(usageTaskSelect, tasks, 'Select Task');
      } catch (error) {
        setStatusMessage(requestStatus, 'error', error.message || 'Unable to load task options.');
        setStatusMessage(usageStatus, 'error', error.message || 'Unable to load task options.');
      }
    }

    loadTaskSelectors();

    requestSubmitButton.addEventListener('click', async function () {
      var itemValue = normalizeText(requestItemInput ? requestItemInput.value : '');
      var quantityValue = parsePositiveNumber(requestQuantityInput ? requestQuantityInput.value : '');
      var noteValue = normalizeText(requestNoteInput ? requestNoteInput.value : '');
      var selectedTask = requestTaskSelect ? normalizeText(requestTaskSelect.value) : '';

      if (!itemValue) {
        setStatusMessage(requestStatus, 'error', 'Enter an item name before submitting.');
        return;
      }

      if (quantityValue === null) {
        setStatusMessage(requestStatus, 'error', 'Quantity must be greater than zero.');
        return;
      }

      requestSubmitButton.disabled = true;
      setStatusMessage(requestStatus, '', 'Submitting request...');

      try {
        var response = await fetch('/staff/material-requests', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            task_id: selectedTask || null,
            item: itemValue,
            quantity: quantityValue,
            note: noteValue
          })
        });

        var payload = await response.json();
        if (!response.ok) {
          throw new Error(payload.error || 'Unable to submit request.');
        }

        setStatusMessage(
          requestStatus,
          'success',
          payload.request_code
            ? 'Request submitted (' + payload.request_code + ').'
            : 'Request submitted successfully.'
        );

        if (requestItemInput) requestItemInput.value = '';
        if (requestQuantityInput) requestQuantityInput.value = '';
        if (requestNoteInput) requestNoteInput.value = '';
        if (requestTaskSelect) requestTaskSelect.value = '';
      } catch (error) {
        setStatusMessage(requestStatus, 'error', error.message || 'Unable to submit request.');
      } finally {
        requestSubmitButton.disabled = false;
      }
    });

    usageAddRowButton.addEventListener('click', function () {
      var nextIndex = usageRowsContainer.querySelectorAll('.used-log-row').length + 1;
      usageRowsContainer.appendChild(createUsageRow(nextIndex));
      setStatusMessage(usageStatus, '', '');
    });

    usageRemoveRowButton.addEventListener('click', function () {
      var rows = Array.from(usageRowsContainer.querySelectorAll('.used-log-row'));
      if (rows.length <= baseUsageRowCount) {
        return;
      }

      var lastRow = rows[rows.length - 1];
      lastRow.remove();
      setStatusMessage(usageStatus, '', '');
    });

    usageSubmitButton.addEventListener('click', async function () {
      var selectedTask = usageTaskSelect ? normalizeText(usageTaskSelect.value) : '';
      if (!selectedTask) {
        setStatusMessage(usageStatus, 'error', 'Select a task before submitting used materials.');
        return;
      }

      var collection = collectUsageEntries(usageRowsContainer);
      if (collection.error) {
        setStatusMessage(usageStatus, 'error', collection.error);
        return;
      }

      usageSubmitButton.disabled = true;
      setStatusMessage(usageStatus, '', 'Submitting used material log...');

      try {
        var response = await fetch('/staff/material-usage', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            task_id: Number(selectedTask),
            items: collection.entries
          })
        });

        var payload = await response.json();
        if (!response.ok) {
          throw new Error(payload.error || 'Unable to submit used material log.');
        }

        setStatusMessage(usageStatus, 'success', 'Used material log submitted successfully.');
        if (usageTaskSelect) usageTaskSelect.value = '';
        resetUsageRows(usageRowsContainer, baseUsageRowCount);
      } catch (error) {
        setStatusMessage(usageStatus, 'error', error.message || 'Unable to submit used material log.');
      } finally {
        usageSubmitButton.disabled = false;
      }
    });
  }
})();
