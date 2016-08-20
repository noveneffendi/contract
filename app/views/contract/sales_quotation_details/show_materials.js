$("#mat_table").html("<%= escape_javascript(render 'contract/sales_quotation_materials/table') %>");

$("#sq_amount_<%= @sales_quotation_header.id %>").html("<%= @sales_quotation_header.currency.try(:code) %> <%= delimiter(@sales_quotation_header.amount.to_f) %>");
$("#sq_discount_amount_<%= @sales_quotation_header.id %>").html("<%= @sales_quotation_header.currency.try(:code) %> <%= delimiter(@discount_amount.to_f) %>");
$("#sales_quotation_header_<%= @sales_quotation_header.id %>_tax").prop('checked', "<%= @tax_status %>");
$("#sq_tax_amount_<%= @sales_quotation_header.id %>").html("<%= @sales_quotation_header.currency.try(:code) %> <%= delimiter(@tax_amount.to_f) %>");
$("#sq_total_amount_<%= @sales_quotation_header.id %>").html("<b><%= @sales_quotation_header.currency.try(:code) %> " + "<%= delimiter(@sales_quotation_header.total_amount.to_f) %>" + "</b>");