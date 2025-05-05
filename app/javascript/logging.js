document.addEventListener('turbo:load', function() {
  console.log('✅ logging.js loaded');

  const tabs = document.querySelectorAll('#logTabs .nav-link');
  const importerLog = document.getElementById('importer-log-content');
  const workerLog = document.getElementById('worker-log-content');
  const developmentLog = document.getElementById('development-log-content');

  if (!tabs.length) {
    console.log('🟡 No log tabs found, skipping logging setup.');
    return;
  }

  let activeTab = 'development'; // default

  function fetchLog(tabName) {
    let url;
    if (tabName === 'importer') {
      url = '/admin/importer_log';
    } else if (tabName === 'worker') {
      url = '/admin/worker_log';
    } else if (tabName === 'development') {
      url = '/admin/development_log';
    } else {
      return;
    }

    fetch(url)
      .then(response => response.text())
      .then(text => {
        const cleanedText = text.trim();
        const displayText = cleanedText ? cleanedText.split('\n').slice(-50).join('\n') : 'No log data found.';

        if (tabName === 'importer') {
          importerLog.innerText = displayText;
        } else if (tabName === 'worker') {
          workerLog.innerText = displayText;
        } else if (tabName === 'development') {
          developmentLog.innerText = displayText;
        }
      })
      .catch(error => {
        console.error('❌ Error fetching log:', error);
      });
  }

  tabs.forEach(function(tab) {
    tab.addEventListener('shown.bs.tab', function(event) {
      const targetId = event.target.getAttribute('href').replace('#', '');
      console.log('🟢 Tab switched to:', targetId);
      if (targetId.startsWith('importer')) {
        activeTab = 'importer';
      } else if (targetId.startsWith('worker')) {
        activeTab = 'worker';
      } else if (targetId.startsWith('development')) {
        activeTab = 'development';
      }
      fetchLog(activeTab);
    });
  });

  // Initial + auto-polling
  fetchLog(activeTab);
  setInterval(function() {
    fetchLog(activeTab);
  }, 3000);
});
