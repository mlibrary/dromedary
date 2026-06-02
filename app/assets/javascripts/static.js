document.addEventListener('DOMContentLoaded', function() {
  // Mark current help sidebar link as active
  var currentLink = document.querySelector('ul.help-ul li.current a');
  if (currentLink) {
    currentLink.classList.add('currentlyActive');
  }

  // For help page sidebar links, toggle current/active on click
  document.querySelectorAll('ul.help-ul li').forEach(function(li) {
    li.addEventListener('click', function() {
      document.querySelectorAll('ul.help-ul li').forEach(function(item) {
        item.classList.remove('current');
      });
      this.classList.add('current');
    });
  });

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
    var baseUrl = autoComplete.getAttribute('src').split('?')[0];
    autoComplete.setAttribute('src', baseUrl + '?search_field=' + encodeURIComponent(e.target.value));
  });
});
