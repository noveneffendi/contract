$("#max_qty").val("<%= @product.try(:outstanding_qty).to_f %>");
$("#available_qty").val("<%= @product.try(:end_qty_ready).to_f %>");
$("#stock_uom").val("<%= UnitOfMeasure.find_by_id(@product.try(:stock_uom)).try(:name) %>");
$("#ordered_qty").val("<%= @product.try(:outstanding_qty).to_f %>");
<% if @product.try(:end_qty_ready).to_f >= @product.try(:outstanding_qty).to_f %>
	$("#sales_invoice_detail_quantity").val("<%= @product.try(:outstanding_qty).to_f %>");
<% else %>
	$("#sales_invoice_detail_quantity").val("<%= @product.try(:end_qty_ready).to_f %>");
<% end %>
$("#unit_of_measure_name").val("<%= @product.try(:uom_name) if @product.try(:uom_name).present? %>")
$("select[id*='detail_uom_conv']").empty();
$("select[id*='detail_uom_conv']").append($("<option></option>").attr("value","").text("<%= t 'prompt' %> <%= t 'unit_of_measure' %>"));
<% for uom in @uoms %>
	<% if uom.id == @product.try(:unit_of_measure_id) %>
	$("select[id*='detail_uom_conv']").append($("<option></option>").attr("value","<%= uom.id %>").attr("selected", true).text('<%= uom.name %>'));
	<% else %>
	$("select[id*='detail_uom_conv']").append($("<option></option>").attr("value","<%= uom.id %>").text('<%= uom.name %>'));
	<% end %>
<% end %>
$("#sales_invoice_detail_unit_of_measure_id").val("<%= @product.try(:unit_of_measure_id) %>")
$("#sales_invoice_detail_price").val("<%= @product.try(:price).to_f %>");
$("#sales_invoice_detail_discount_item").val("<%= @product.try(:discount_item).to_f %>");
$("#sales_invoice_detail_discount_item_price").val("<%= @product.try(:discount_item_price).to_f %>");