$("#sales_quotation_detail_modal").dialog({
  autoOpen: true,
  height: "auto",
  width: "auto",
  modal: true,
  title: "<%= t 'sales_quotation' %>-<%= t 'detail' %>-<%= t 'new' %>",
  open: function() {
    $("#sales_quotation_detail_modal").html("<%= escape_javascript(render('form')) %>")
  },
  buttons: {
    "<%= t 'cancel' %>": function() { $(this).dialog("close") }
  },
});

$("#detail_uom_conv").change(function() {
  var uom_id; 
  var product_id;
  uom_id = $(this).val();
  product_id = $("#sales_quotation_detail_product_id").val();
  curr = $("#cuid").val();

  return $.get("products/conversion_value_by_product_id_uom_id", { product_id: product_id, uom_id: uom_id, curr: curr});
});