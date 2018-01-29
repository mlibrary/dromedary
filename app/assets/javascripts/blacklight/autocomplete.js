/*global Bloodhound */

var blacklight_autocomplete = function () {
    var $el = $(this);
    if ($el.hasClass('tt-hint')) {
        return;
    }
    var suggestUrl = $el.data().autocompletePath;
    var autocomplete_solr_handler = $el.data().autocompleteSolrHandler;

    var terms = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
            url: suggestUrl + '?autocomplete_solr_handler=' + autocomplete_solr_handler + '&q=%QUERY',
            wildcard: '%QUERY',
        }
    });

    terms.initialize();

    $el.typeahead({
            hint: true,
            highlight: true,
            minLength: 2
        },
        {
            name: 'terms',
            displayKey: 'term',
            source: terms.ttAdapter(),
            limit: 15
        }).on('typeahead:selected',
        function (event, data) {
            $(event.target).closest('form').submit();
        });
};

var blacklight_set_autocomplete = function(i, rawel) {
    var el = $(rawel);
    var controller_id = el.data('autocomplete-controller');
    if (controller_id) {
        var controller = $('#' + controller_id);
        el.data('autocomplete-config', controller.val());
        controller.change(
            function() {
                var me = $(this);
                el.data('autocomplete-config', me.val());
                alert("Controller value is " + el.data('autocomplete-config'));

            });
    }
};


Blacklight.onLoad(function () {
    'use strict';
    $('[data-autocomplete-enabled="true"]').each(blacklight_autocomplete);
    $('[data-autocomplete-enabled="true"]').each(blacklight_set_autocomplete);
});

