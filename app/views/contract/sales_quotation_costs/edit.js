$("#sales_quotation_detail_modal").dialog({
  autoOpen: true,
  height: "auto",
  width: "auto",
  modal: true,
  title: "<%= t 'sales_quotation' %>-<%= t 'cost' %>-<%= t 'edit' %>",
  open: function() {
    $("#sales_quotation_detail_modal").html("<%= escape_javascript(render('form')) %>");
  },
});