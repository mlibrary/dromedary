$( document ).ready(function() {
  
  // if we are on a help page (include the contacts page) mark the link for that page in the sidebar
  $('ul.help-ul li.current a').addClass('currentlyActive');

  // Special character keyboard entry for search form input
    $('#thorn').on('click', function () {
        var text = $('#q');
        text.val(text.val() + 'þ');    
    });
    
    $('#eth').on('click', function () {
        var text = $('#q');
        text.val(text.val() + 'ð');    
    });
    
     $('#yogh').on('click', function () {
        var text = $('#q');
        text.val(text.val() + 'ȝ');    
    });
     $('#ash').on('click', function () {
        var text = $('#q');
        text.val(text.val() + 'æ');    
    });

});
