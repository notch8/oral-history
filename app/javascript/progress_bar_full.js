document.addEventListener('turbo:load', function () {
  console.log('✅ progress_bar_full.js loaded');

  const runFullImportForm = document.getElementById('run-full-import-form');
  const importNotice = document.getElementById('import-notice');
  const well = document.querySelector('.well');
  const progressStatus = document.querySelector('.progress-status');
  const progressBar = document.querySelector('.progress-bar');
  const flashes = document.getElementById('flashes');
  let currentJobId = null;

  if (!runFullImportForm) {
    console.log('🟡 No run-full-import-form found.');
    return;
  }

  runFullImportForm.addEventListener('submit', function (event) {
    event.preventDefault();
    console.log('🟢 Full Import form submitted.');

    fetch('/admin/run_full_import', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => {
        if (!response.ok) throw new Error('Failed to start full import');
        return response.json();
      })
      .then(data => {
        console.log('🟢 Import started, job ID:', data.job_id);
        showNotice('info', 'Starting full import... please wait.');
        if (well) well.style.display = 'block';
        currentJobId = data.job_id;
        startFullProgressPolling();
      })
      .catch(error => {
        console.error('Import start failed:', error);
        showNotice('danger', 'Failed to start full import.');
      });
  });

  checkIfImportAlreadyRunning();

  function checkIfImportAlreadyRunning() {
    fetch('/admin/importer_running')
      .then(response => response.json())
      .then(data => {
        if (data.running) {
          console.log('Ongoing import detected, resuming polling...');

          // Fetch most recent ImportFullRecordsJob from server
          fetch('/admin/full_import_progress') // Add a route that finds latest job
            .then(res => res.json())
            .then(progressData => {
              currentJobId = progressData.job_id;
              if (well) well.style.display = 'block';
              startFullProgressPolling();
            });
        } else {
          console.log('No full import running yet.');
        }
      })
      .catch(() => {
        console.log('Failed to check for running job.');
      });
  }

  let pollingComplete = false;

function startFullProgressPolling() {
  console.log('Starting full import progress polling...');
  let pollingInterval = setInterval(() => {
    if (pollingComplete) return; // prevent updates after done

    fetch(`/admin/full_import_progress/${currentJobId}`)
      .then(response => response.json())
      .then(data => {
        const progress = data.progress || 0;
        const stage = data.stage || '';

        if (well) well.style.display = 'block';

        if (progressBar) {
          progressBar.style.width = `${progress}%`;
          progressBar.innerText = `${progress}%`;
        }

        if (progressStatus) {
          progressStatus.innerText = `Progress: ${progress}% - ${stage}`;
        }

        if (progress >= 100) {
          pollingComplete = true; // block further updates
          clearInterval(pollingInterval);

          progressStatus.innerText = 'Full import complete!';
          if (importNotice) importNotice.style.display = 'none';

          showNotice('success', 'Full import completed successfully!');
          if (well) {
            setTimeout(() => {
              well.style.opacity = '0';
              setTimeout(() => {
                well.style.display = 'none';
                well.style.opacity = '1';
              }, 500);
            }, 3000);
          }
        }
      })
      .catch(error => {
        console.error('❌ Error polling full import progress:', error);
        clearInterval(pollingInterval);
      });
  }, 1000);
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
