// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function() {
	$.fn.bootstrapSwitch.defaults.size = 'small';
	$.fn.bootstrapSwitch.defaults.onText = 'QUOT';
	$.fn.bootstrapSwitch.defaults.offText = 'NONE';

	$("[id*='doc_type']").bootstrapSwitch();

	$("[id*='doc_type']").on('switchChange.bootstrapSwitch', function(event, state) {
  		var $this;
  		$this = $(this);
  		if ($this.is(':checked')) {
    		$("select[id*='sales_quotation_header_id']").removeAttr('disabled');
    		$("select[id*='sales_invoice_header_so_id']").empty();
    		$("select[id*='sales_invoice_header_so_id']").attr('disabled', true);
  		} else {
    		$("select[id*='sales_invoice_header_so_id']").removeAttr('disabled');
    		$("select[id*='sales_quotation_header_id']").empty();
    		$("select[id*='sales_quotation_header_id']").attr('disabled', true);
  		}
	});

	$("select[id*='other_sales_invoice_header_customer_id']").change(function() {
  		var ci, tt;
  		tt = $('#tt').val();
  		ci = $("select[id*='other_sales_invoice_header_customer_id']").val();
  		$.get('sales_quotation_headers/sq_id_by_customer', {
    		tt: tt,
    		id: ci
  		});
	});
});