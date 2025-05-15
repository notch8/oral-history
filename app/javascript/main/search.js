document.addEventListener('turbo:load', function () {
  console.log("search.js loaded");

  const form = document.getElementById('dynamic-search-form');
  const select = document.getElementById('search_field_select');

  if (!form || !select) return;

  // Keep form action in sync with selected field
  const updateAction = () => {
    const selected = select.value;
    const action = selected === 'interview' ? '/' : '/full_text';
    form.setAttribute('action', action);
  };

  // Remove pagination on submit to ensure clean query
  const cleanURLParams = () => {
    const url = new URL(window.location);
    url.searchParams.delete("page");
    url.searchParams.delete("start");
    history.replaceState(null, "", url);
  };

  // Initial setup
  updateAction();

  // Update on dropdown change
  select.addEventListener('change', updateAction);

  // Clean + update before submit
  form.addEventListener('submit', function () {
    updateAction();
    cleanURLParams();
  });
});
