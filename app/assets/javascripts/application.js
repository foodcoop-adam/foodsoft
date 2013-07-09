//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require select2
//= require twitter/bootstrap
//= require jquery.tokeninput
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.de
//= require bootstrap-datepicker/locales/bootstrap-datepicker.nl
//= require jquery.observe_field
//= require rails.validations
//= require_self
//= require ordering

// allow touch devices to work on click events
//   http://stackoverflow.com/a/16221066
$.fn.extend({ _on: (function(){ return $.fn.on; })() });
$.fn.extend({
    on: (function(){
        var isTouchSupported = 'ontouchstart' in window || window.DocumentTouch && document instanceof DocumentTouch;
        return function( types, selector, data, fn, one ) {
            if (typeof types == 'string' && isTouchSupported && !(types.match(/touch/gi))) types = types.replace(/click/gi, 'touchstart');
            return this._on( types, selector, data, fn, one );
        };
    }()),
});

// Load following statements, when DOM is ready
$(function() {

    // Show/Hide a specific DOM element
    $('a[data-toggle-this]').live('click', function() {
        $($(this).data('toggle-this')).toggle();
        return false;
    });

    // Remove this item from DOM
    $('a[data-remove-this]').live('click', function() {
        $($(this).data('remove-this')).remove();
        return false;
    });

    // Check/Uncheck a single checkbox
    $('[data-check-this]').live('click', function() {
        var checkbox = $($(this).data('check-this'));
        checkbox.attr('checked', !checkbox.is(':checked'));
        highlightRow(checkbox);
        return false;
    });

    // Check/Uncheck all checkboxes for a specific form
    $('input[data-check-all]').live('click', function() {
        var status = $(this).is(':checked');
        var context = $(this).data('check-all');
        var elms = $('input[type="checkbox"]', context);
        for(i=elms.length-1; i>=0; --i) { // performance can be an issue here, so use native loop
          var elm = elms[i];
          elm.checked = status;
          highlightRow($(elm));
        }
    });

    // Submit form when changing a select menu.
    $('form[data-submit-onchange] select').live('change', function() {
        var confirmMessage = $(this).children(':selected').data('confirm');
        if (confirmMessage) {
            if (confirm(confirmMessage)) {
                $(this).parents('form').submit();
            }
        } else {
            $(this).parents('form').submit();
        }
        return false;
    });

    // Submit form when changing text of an input field
    // Use jquery observe_field plugin
    $('form[data-submit-onchange] input[type=text]').each(function() {
        $(this).observe_field(1, function() {
            $(this).parents('form').submit();
        });
    });

    // Submit form when clicking on checkbox
    $('form[data-submit-onchange] input[type=checkbox]:not(input[data-ignore-onchange])').click(function() {
        $(this).parents('form').submit();
    });

    $('[data-redirect-to]').bind('change', function() {
        var newLocation = $(this).children(':selected').val();
        if (newLocation != "") {
            document.location.href = newLocation;
        }
    });

    // Remote paginations
    $('div.pagination[data-remote] a').live('click', function() {
        $.getScript($(this).attr('href'));
        return false;
    });

    // Show and hide loader on ajax callbacks
    $('*[data-remote]').bind('ajax:beforeSend', function() {
        $('#loader').show();
    });

    $('*[data-remote]').bind('ajax:complete', function() {
        newElementsReady();
        $('#loader').hide();
    });

    // Disable submit button on ajax forms
    $('form[data-remote]').bind('ajax:beforeSend', function() {
        $(this).children('input[type="submit"]').attr('disabled', 'disabled');
    });

    newElementsReady();
});

// classic document ready functions not supporting jQuery.on()
// so that we can catch dynamically created elements too
//   data-remote functions call this after successful ajax (see above),
//   other modifications need to call this function by themselves.
function newElementsReady() {
    // Use bootstrap datepicker for dateinput
    $('.datepicker').datepicker({format: 'yyyy-mm-dd', language: I18n.locale});

    // Use select2 for selects, except those with css class 'plain'
    $('select').not('.plain').select2({dropdownAutoWidth: true});
}

// select2 jQuery function with remote capabilities
//   usage: $('#autocomplete_input').select2_remote({
//     remote_url: '#{xyz_path(:format => json)}',
//     remote_field: 'title',
//     remote_init: #{form.object.xyz.map { |u| u.token_attributes }.to_json}
//   });
$.fn.extend({
  select2_remote: function(options={}) {

    function select2_parse(data, text_attr, id_attr='id') {
      return $(data).map(function(i, o) {
        return {id:o[id_attr], text:o[text_attr] };
      });
    }

    var field = options.remote_field || 'name';
    var _options = $.extend(true, {}, options, {
      ajax: {
        url: options.remote_url,
        data: function(term, page) {
          return {q: term};
        },
        results: function(data, page) {
          return { results: select2_parse(data, field) };
        },
      },
      initSelection: function (el, callback) {
        var values = select2_parse(options.remote_init, field);
        if (!options.multiple && !options.tags)
          values = values[0];
        callback(values);
      },
      dropdownAutoWidth: true,
    });

    if (options.tags || options.multiple)
      $.extend(_options, {width: 'element'});
    return $(this).select2(_options);
  }
});

// gives the row an yellow background
function highlightRow(checkbox) {
    var row = checkbox.closest('tr');
    if (checkbox.is(':checked')) {
        row.addClass('selected');
    } else {
        row.removeClass('selected');
    }
}

// Use with auto_complete to set a unique id,
// e.g. when the user selects a (may not unique) name
// There must be a hidden field with the id 'hidden_field'
function setHiddenId(text, li) {
  $('hidden_id').value = li.id;
}
