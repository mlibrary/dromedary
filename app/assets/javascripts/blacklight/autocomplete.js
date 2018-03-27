/*global Bloodhound */

BlacklightAutoComplete = function () {

    var blacklight_autocomplete = function () {
        var $el = $(this);
        if ($el.hasClass('tt-hint')) {
            return;
        }
        var suggestUrl = $el.data('autocomplete-path');
        var autocomplete_config = $el.data('autocomplete-config');

        var terms = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            remote: {
                url: suggestUrl + '?autocomplete_config=' + autocomplete_config + '&q=%QUERY',
                wildcard: '%QUERY'
            }
        });

        terms.initialize(true); // true means "reinitialixe every time" ???

        $el.typeahead('destroy');

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

    var blacklight_set_autocomplete = function (i, rawel) {
        var el = $(rawel);
        var controller_id = el.data('autocomplete-controller');
        if (controller_id) {
            var controller = $('#' + controller_id);
            el.data('autocomplete-config', controller.val());
            controller.change(
                function () {
                    var me = $(this);
                    el.data('autocomplete-config', me.val());
                    $.each([el], blacklight_autocomplete);
                });
        }
        el.trigger('change')
    };

    var setup_controller = function (i, rawel) {
        var el = $(rawel);
        var controller_id = el.data('autocomplete-controller');
        if (controller_id) {
            var controller = $('#' + controller_id);
            controller.change();
        }
    };

    return {
        set_autocomplete: blacklight_set_autocomplete,
        autocomplete: blacklight_autocomplete,
        setup_controller: setup_controller
    }

}();


Blacklight.onLoad(function () {
    'use strict';
    // Set up the connection between the controllers and the inputs
    $('[data-autocomplete-enabled="true"]').each(BlacklightAutoComplete.set_autocomplete);

    // Add the autocomplete to the inputs
    $('[data-autocomplete-enabled="true"]').each(BlacklightAutoComplete.autocomplete);

    // Inititalize with the current value of the controller.
    $('[data-autocomplete-enabled="true"]').each(BlacklightAutoComplete.setup_controller);

});

