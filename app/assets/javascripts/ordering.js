// JavaScript that handles the dynamic ordering quantities on the ordering page.
//
// In a javascript block of the actual view, make sure to override these globals:
var minimumBalance = 0;          // minimum group balance for the order to be succesful
var toleranceIsCostly = false;   // default tolerance behaviour
//

$(function() {
  $(document).on('changed', '#articles_table input[data-delta]', function() {
    var row = $(this).closest('tr');
    var form = $(row).closest('form');
    // send change server-side
    $.ajax({
      url: form.attr('action'),
      type: form.attr('method') || 'post',
      data: $('input, select, textarea', row).serialize() + '&' + $('input[type="hidden"]', form).serialize(),
      dataType: 'script'
    });

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
    $('.price_sum', row).html(I18n.l('currency', price_sum)).data('value', price_sum);

    // total group orders sum
    var old_price_total = Number($('.price_total').data('value'));
    var new_price_total = old_price_total - old_price_sum + price_sum;
    $('.price_total').html(I18n.l('currency', new_price_total)).data('value', new_price_total);

    // calculate filled units
    var total_quantity = Number($('.quantity [data-value-others]', row).data('value-others')) + quantity;
    var total_tolerance = Number($('.tolerance [data-value-others]', row).data('value-others')) + tolerance;
    // (same as OrderArticle#calculate_units_to_order)
    var units_to_order = Math.floor(total_quantity/unit_quantity);
    var remainder = total_quantity % unit_quantity;
    units_to_order += ((remainder > 0) && (remainder + total_tolerance >= unit_quantity) ? 1 : 0)
    // (same as OrderArticle#missing_units)
    var missing_units = unit_quantity - ((quantity % unit_quantity) + tolerance)
    if (missing_units < 0) missing_units = 0
    $('.missing_units', row).html(missing_units);
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
