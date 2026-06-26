document.addEventListener('DOMContentLoaded', function() {
  // The current help-sidebar page is marked server-side: the view adds
  // `li.current` + `aria-current="page"` to the matching link via Rails
  // `current_page?`. That is the single source of truth, so no client-side
  // class toggling is needed. (A previous click handler that moved `current`
  // onto the clicked item before navigation caused a stale highlight after
  // using the Back button, because bfcache restored the mutated DOM.)

  // Special character keyboard entry for search form input
  document.addEventListener('click', function(e) {
    var btn = e.target.closest('.keyboard-char');
    if (!btn) return;
    e.preventDefault();
    var char = btn.getAttribute('data-char');
    var input = document.querySelector('#q, input[name="q"]');
    if (input && char) {
      input.value += char;
      input.focus();
    }
  });

  // Update auto-complete src when search field dropdown changes
  document.addEventListener('change', function(e) {
    if (e.target.id !== 'search_field') return;
    var autoComplete = e.target.closest('form').querySelector('auto-complete');
    if (!autoComplete) return;
    var src = autoComplete.getAttribute('src');
    var basePart = src.split('?')[0];
    var params = new URLSearchParams(src.split('?')[1] || '');
    params.set('search_field', e.target.value);
    autoComplete.setAttribute('src', basePart + '?' + params.toString());
  });

  // Navigate to show page on Enter key in autocomplete dropdown
  document.addEventListener('combobox-commit', function(e) {
    var option = e.target;
    if (!(option instanceof HTMLElement)) return;
    var anchor = option.querySelector('a[data-url]');
    if (anchor) {
      window.location.href = anchor.getAttribute('data-url') || anchor.href;
    }
  });
});
