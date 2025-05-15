document.addEventListener('turbo:load', function () {
  console.log('progress_bar_single.js loaded');

  const runSingleImportForm = document.getElementById('run-single-import-button');
  const well = document.querySelector('.well');
  const progressStatus = document.querySelector('.progress-status');
  const progressBar = document.querySelector('.progress-bar');
  const importNotice = document.getElementById('import-notice');
  const flashes = document.getElementById('flashes');

  let currentJobId = null;

  if (!runSingleImportForm) {
    console.log('No run-single-import-button form found.');
    return;
  }

  runSingleImportForm.addEventListener('submit', function (event) {
    event.preventDefault();
    console.log('Single Import form submitted.');

    const formData = new FormData(runSingleImportForm);

    fetch('/admin/run_single_import', {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => {
        if (!response.ok) throw new Error('Failed to start import');
        return response.json();
      })
      .then(data => {
        console.log('Import job started!', data);

        // Extract ID from the input field for polling
        const recordId = runSingleImportForm.querySelector('input[name="id"]').value;
        currentJobId = recordId;

        startProgressPolling();

        runSingleImportForm.querySelector('input[name="id"]').value = '';

        if (well) well.style.display = 'block';
        if (progressStatus) progressStatus.innerText = "Starting single import...";
        if (progressBar) {
          progressBar.style.width = '0%';
          progressBar.innerText = 'Starting...';
        }
        showNotice('info', 'Starting single import... please wait.');
      })
      .catch(error => {
        console.error('❌ Error import failed to start:', error);
        showNotice('danger', 'Failed to start single import.');
      });
  });

  function startProgressPolling() {
    const interval = setInterval(() => {
      fetch(`/admin/single_import_progress/${currentJobId}`)
        .then(response => response.json())
        .then(data => {
          const progress = data.progress || 0;
          const stage = data.stage || 'Starting';

          if (progressBar) {
            progressBar.style.width = `${progress}%`;
            progressBar.innerText = `${progress}%`;
          }
          if (progressStatus) {
            progressStatus.innerText = `Progress: ${progress}% - ${stage}`;
          }

          if (progress >= 100) {
            clearInterval(interval);
            progressStatus.innerText = "Import Complete!";
            showNotice('success', 'Single import completed successfully!');
            fadeOutWell();
          }
        })
        .catch(error => {
          console.error('❌ Error polling single import progress:', error);
          clearInterval(interval);
        });
    }, 1000);
  }

  function fadeOutWell() {
    if (!well) return;
    setTimeout(() => {
      well.style.opacity = '0';
      setTimeout(() => {
        well.style.display = 'none';
        well.style.opacity = '1';
      }, 500);
    }, 3000);
  }

  function showNotice(type, message) {
    if (!flashes) return;
    flashes.innerHTML = `
      <div class="alert alert-${type} alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    `;
    flashes.style.display = 'block';
  }
});
