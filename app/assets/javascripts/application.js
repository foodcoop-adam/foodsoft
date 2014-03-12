//= require jquery
//= require jquery_ujs
//= require select2
//= require twitter/bootstrap
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.de
//= require bootstrap-datepicker/locales/bootstrap-datepicker.nl
//= require bootstrap-datepicker/locales/bootstrap-datepicker.fr
//= require list
//= require list.unlist
//= require list.delay
//= require list.reset
//= require rails.validations
//= require rails.validations.simple_form
//= require i18n
//= require i18n/translations
//= require_self
//= require ordering
//= require stupidtable
//= require touchclick
//= require delta_input

// Load following statements, when DOM is ready
$(function() {

    // Show/Hide a specific DOM element
    $(document).on('click', 'a[data-toggle-this]', function() {
        $($(this).data('toggle-this')).toggle();
        return false;
    });

    // Remove this item from DOM
    $(document).on('click', 'a[data-remove-this]', function() {
        $($(this).data('remove-this')).remove();
        return false;
    });

    // Check/Uncheck a single checkbox
    $(document).on('click', '[data-check-this]', function() {
        var checkbox = $($(this).data('check-this'));
        checkbox.attr('checked', !checkbox.is(':checked'));
        highlightRow(checkbox);
        return false;
    });

    // Check/Uncheck all checkboxes for a specific form
    $(document).on('click', 'input[data-check-all]', function() {
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
    $(document).on('change', 'form[data-submit-onchange] select:not([data-ignore-onchange])', function() {
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

    // Submit form when clicking on checkbox
    $(document).on('click', 'form[data-submit-onchange] input[type=checkbox]:not([data-ignore-onchange])', function() {
        $(this).parents('form').submit();
    });

    // The autocomplete attribute is used for both autocompletion and storing
    // for passwords, it's nice to store it when editing one's own profile,
    // but never autocomplete. When the data-autocomplete attribute is 'off',
    // any autocompleted values are removed again.
    // This is only implemented for passwords.
    $('input[type="password"][autocomplete="off"]').each(function() {
      // add dummy password field for autocompletion after losing username field focus
      $(this).before('<input type="password" name="_x_autocomplete_workaround" style="display:none"/>');
      // make sure we don't receive the remembered password by accident
      $(this).parentsUntil('form').on('submit', function(ev) {
        $('input[name="_x_autocomplete_workaround"]').val('');
      });
      // if the browser already filled it in here, clear the password
      $(this).val('');
    });

    // Submit form when changing text of an input field.
    // Submission will be done after 500ms of not typed, unless data-submit-onchange=changed,
    // in which case it happens when the input box loses its focus ('changed' event).
    // (changeDate is for bootstrap-datepicker)
    $(document).on('changed keyup focusin changeDate', 'form[data-submit-onchange] input[type=text]:not([data-ignore-onchange])', function(e) {
        var input = $(this);
        // when form has data-submit-onchange=changed, don't do updates while typing
        if (e.type!='changed' && e.type!='changeDate' && input.parents('form[data-submit-onchange=changed]').length>0) {
          return true;
        }
        // remember old value when it's getting the focus (unless we already have a change pending)
        if (e.type=='focusin') {
          if (!input.data('submit-timeout-id')) input.data('old-value', input.val());
          return true;
        }
        // trigger timeout to submit form when value was changed
        clearTimeout(input.data('submit-timeout-id'));
        input.data('submit-timeout-id', setTimeout(function() {
          if (input.val() != input.data('old-value')) input.parents('form').submit();
          input.removeData('submit-timeout-id');
          input.removeData('old-value');
        }, 500));
    });

    // Button to clear (search) form
    $(document).on('click', '.reset-search', function() {
      $('input.resettable', $(this).parentsUntil('form')).val('').trigger('changed');
    });

    $('[data-redirect-to]').bind('change', function() {
        var newLocation = $(this).children(':selected').val();
        if (newLocation != "") {
            document.location.href = newLocation;
        }
    });

    // Remote paginations
    $(document).on('click', 'div.pagination[data-remote] a', function() {
        $.getScript($(this).attr('href'));
        return false;
    });

    // Disable action of disabled buttons
    $(document).on('click', 'a.disabled', function() {
        return false;
    });

    // Handle ajax errors
    //     render json: {error: "can't except this!"}, status: :unprocessable_entity
    $(document).ajaxError(function(ev, xhr, settings, exception) {
        try {
            msg = xhr.responseJSON.error;
        } catch(err) {
            msg = I18n.t('errors.general');
        }
        alert(msg);
    });

    // The autocomplete attribute is used for both autocompletion and storing
    // for passwords, it's nice to store it when editing one's own profile,
    // but never autocomplete. Only implemented for passwords.
    $('input[type="password"][autocomplete="off"][data-store="on"]').each(function() {
      $(this).on('change', function() {
        $(this).removeAttr('autocomplete');
      });
    });

    // bootstrap tooltips (for price)
    //   Extra options don't work when using selector, so override defaults
    //   https://github.com/twbs/bootstrap/issues/3875 . These can still be
    //   overridden per tooltip using data-placement attributes and the like.
    $.extend($.fn.tooltip.defaults, {
      html: true,
      animation: false,
      placement: 'left',
      container: 'body'
    });
    $(document).tooltip({
      selector: '[data-toggle~="tooltip"]',
    });
    $.extend($.fn.popover.defaults, {
      html: true,
      animation: false,
      placement: 'left'
    });
    $(document).popover({
      selector: '[data-toggle~="popover"]'
    });
    
    // See stupidtable.js for initialization of local table sorting

    newElementsReady();
    $(document).ajaxComplete(function() {
      newElementsReady();
    });
});

// classic document ready functions not supporting jQuery.on()
// so that we can catch dynamically created elements too
//   data-remote functions call this after successful ajax (see above),
//   other modifications need to call this function by themselves.
function newElementsReady() {
    // Use bootstrap datepicker for dateinput
    $('.datepicker').datepicker({format: 'yyyy-mm-dd', language: I18n.locale, todayHighlight: true});

    // Use select2 for selects, except those with css class 'plain'
    $('select:not(.plain)').select2({dropdownAutoWidth: true, width: 'off'});

    // Enable client side form validations - cannot be done too early
    //   this needs the 'focusin' event (instead of 'focus') because of
    //   bubbling - http://stackoverflow.com/questions/9577971
    $('form[data-validate]').one('focusin', function() {
      $(this).enableClientSideValidations();
    });
}

// select2 jQuery function with remote capabilities
//   Usage:
//    $('#autocomplete_input').select2_remote({
//       remote_url: '#{xyz_path(:format => json)}',
//       remote_init: #{form.object.xyz.map { |u| u.token_attributes }.to_json}
//       remote_pagesize: 100,
//     });
//   Only remote_url is required.
$.fn.extend({
  select2_remote: function(options) {

    var pagesize = options.remote_pagesize || 25;
    var _options = $.extend(true, {}, options, {
      ajax: {
        url: options.remote_url,
        data: function(term, page) {
          return {q: term, limit: pagesize, offset: (page-1)*pagesize};
        },
        results: function(data, page) {
          return { results: data.results, more: ((page-1)*pagesize)<data.total };
        },
      },
      initSelection: function (el, callback) {
        var values = options.remote_init;
        // if single select is given an array as init, that's fine
        if ($.isArray(values) && !options.multiple && !options.tags)
          values = values[0];
        callback(values);
      },
      // try to avoid linebreaking long values
      dropdownAutoWidth: true,
      // we set width in css
      width: 'off',
    });

    return $(this).select2(_options);
  }
});
// select2 fix for allowing it to receive focus in modal dialogs
// http://stackoverflow.com/a/19574076/2866660
$.fn.modal.Constructor.prototype.enforceFocus = function() {};

// retrigger last local table sorting
function updateSort(table) {
  $('.sorting-asc, .sorting-desc', table).toggleClass('.sorting-asc .sorting-desc')
    .removeData('sort-dir').trigger('click'); // CAUTION: removing data field of plugin
}

// gives the row an yellow background
function highlightRow(checkbox) {
    var row = checkbox.closest('tr');
    if (checkbox.is(':checked')) {
        row.addClass('selected');
    } else {
        row.removeClass('selected');
    }
}

