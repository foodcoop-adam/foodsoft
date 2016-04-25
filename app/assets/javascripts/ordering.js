// JavaScript that handles the dynamic ordering quantities on the ordering page.
//
// In a javascript block of the actual view, make sure to override these globals:
var minimumBalance = 0;              // minimum group balance for the order to be succesful
var toleranceIsCostly = false;       // default tolerance behaviour
var quantityTimeDeltaClientMs = 500; // throttling for sending updates (in ms)
//

$(function() {
  $(document).on('changed', '#articles_table input[data-delta]', function() {
    var row = $(this).closest('tr');
    var form = $(row).closest('form');
    var ajaxvars = $('#articles_table tbody').data('ajaxvars');

    // send change server-side, after a delay to rate-limit
    clearTimeout(row.data('ordering-timeout-id'));
    row.data('ordering-timeout-id', setTimeout(function() {
      $.ajax({
        url: form.attr('action'),
        type: form.attr('method') || 'post',
        data: $('input, select, textarea', row).serialize()
              + '&' + $('input[type="hidden"]', form).serialize()
              + '&' + $.param(ajaxvars),
        dataType: 'script'
      });
      row.removeData('ordering-timeout-id');
    }, quantityTimeDeltaClientMs));

    $(this).trigger('foodsoft-ordering-state-changed');
  });

  $(document).on('foodsoft-ordering-state-changed', '#articles_table input[data-delta]', function() {
    var row = $(this).closest('tr');

    //
    // update page locally
    //
    var quantity = Number($('.quantity input[data-delta]', row).val());
    var tolerance = Number($('.tolerance input[data-delta]', row).val());
    var price_item = Number($('.price', row).data('value'));
    var old_price_sum = Number($('.price_sum', row).data('value'));
    var unit_quantity = Number($('.unit', row).data('unit-quantity'));

    var price_sum = price_item * quantity;
    if (toleranceIsCostly) price_sum += price_item * tolerance;

    // article sum
    $('.price_sum', row)
      .html(I18n.l('currency', price_sum)).data('value', price_sum)
      .toggleClass('muted', quantity == 0 && tolerance == 0);

    // total group orders sum
    var old_price_total = Number($('.price_total').data('value'));
    var new_price_total = old_price_total - old_price_sum + price_sum;
    $('.price_total').html(I18n.l('currency', new_price_total)).data('value', new_price_total);

    // calculate filled units
    var quantity_others = Number($('.quantity [data-value-others]', row).data('value-others'));
    var tolerance_others = Number($('.tolerance [data-value-others]', row).data('value-others'));
    var total_quantity = quantity_others + quantity;
    var total_tolerance = tolerance_others + tolerance;
    // (same as OrderArticle#calculate_units_to_order)
    var units_to_order = Math.floor(total_quantity/unit_quantity);
    var remainder = total_quantity % unit_quantity;
    units_to_order += ((remainder > 0) && (remainder + total_tolerance >= unit_quantity) ? 1 : 0)
    $('.units_to_order_value', row).html(units_to_order);

    // update colors
    // see GroupOrdersHelper#group_order_article_class_name
    var quantity_available = (units_to_order * unit_quantity) - quantity_others;
    $('.quantity input[data-delta]', row)
      .toggleClass('unused',   quantity > 0 && quantity_available <= 0)
      .toggleClass('used',     quantity > 0 && quantity_available >= quantity)
      .toggleClass('partused', quantity > 0 && quantity_available > 0 && quantity_available < quantity);

    // progess bar update
    //   update decreasing number first, to make sure that together it's no more than 100%
    //   otherwise one of the numbers in the progress bar may temporarily disappear
    // (same as GroupOrdersHelper#final_unit_bar)
    var amount_to_order = units_to_order * unit_quantity,
        quantity_left = Math.max(total_quantity - amount_to_order, 0),
        tolerance_left = total_tolerance - Math.max(amount_to_order - total_quantity, 0),
        tolerance_left_clip = Math.min(tolerance_left, unit_quantity),
        missing = Math.max(unit_quantity - quantity_left - tolerance_left, 0);

    function spct(x) { return String(Math.floor(100*x/unit_quantity)) + '%'; }

    $('.progress .bar:nth-child(1)', row)
      .width(spct(quantity_left))
      .text(quantity_left);
    $('.progress .bar:nth-child(2)', row)
      .width(spct(tolerance_left_clip))
      .text(tolerance_left_clip + (tolerance_left > tolerance_left_clip ? '+' : ''))
      .toggleClass('bar-light', quantity_left != 0)
      .toggleClass('bar-lighter', quantity_left == 0);
    $('.progress .text', row).text(missing);
    $('.progress', row).toggleClass('progress-reverse', quantity_left == 0);
  });
});


/* TODO support minimum balance
function updateBalance() {
    // update total price and order balance
    var total = 0;
    for (i in itemTotal) {
        total += itemTotal[i];
    }
    $('#total_price').html(I18n.l("currency", total));
    var balance = groupBalance - total;
    $(document).triggerHandler({type: 'foodsoft:group_order_sum_changed'}, total, balance);
    $('#new_balance').html(I18n.l("currency", balance));
    $('#total_balance').val(I18n.l("currency", balance));
    // determine bgcolor and submit button state according to balance
    var bgcolor = '';
    if (balance < minimumBalance) {
        bgcolor = '#FF0000';
        $('#submit_button').attr('disabled', 'disabled')
    } else {
        $('#submit_button').removeAttr('disabled')
    }
    // update bgcolor
    for (i in itemTotal) {
        $('#td_price_' + i).css('background-color', bgcolor);
    }
}
*/
