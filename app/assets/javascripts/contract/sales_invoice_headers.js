// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function() {
	$("#doc_type").on('switchChange.bootstrapSwitch', function(event, state) {
	    var $this;
	    $this = $(this);
	    if ($this.is(':checked')) {
	      $("select[id*='sales_quotation_header_id']").removeAttr('disabled');
	      $("select[id*='sales_invoice_header_so_id']").attr('disabled', true);
	    } else {
	      $("select[id*='sales_invoice_header_so_id']").removeAttr('disabled');
	      $("select[id*='sales_quotation_header_id']").attr('disabled', true);
	    }
	});

	$("#sales_invoice_header_customer_id").change(function() {
  		var ci, tt;
  		tt = $("#tt").val();
  		ci = $("#sales_invoice_header_customer_id").val();
  		if ($("#doc_type").is(':checked'))
  			{
  				return $.get("sales_quotation_headers/so_id_by_customer", {
    				tt: tt,
    				id: ci });  	
  			}
  		else
  			{	
  				return $.get("sales_order_headers/so_id_by_customer", {
    				tt: tt,
    				id: ci });
  			}
	});
});