define_grid(:columns => 5, :rows => 8, :gutter => 10)
grid(0,0).bounding_box do
	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 110, :height => 60, :position => :center, :vposition => :top
end
grid([0,1], [0,4]).bounding_box do
	font("Times-Roman") do
		pdf.text "#{company_name}", :align => :center, :size => 15, :style => :bold
		pdf.text "#{t 'sales_invoice'}", :align => :center, :size => 13, :style => :bold
	end
end

pdf.stroke do
	self.line_width = 2
	pdf.horizontal_line 0, 540, :at => 650
end

header_info = [
	["#{t 'si_id'}", ":", @sales_invoice_header.si_id, "#{t 'so_id'}", ":", @sales_invoice_header.so_id],
	["#{t 'dates'}", ":", @sales_invoice_header.sales_invoice_date.strftime("%d %B %Y"), "#{t 'do_id'}", ":", @sales_invoice_header.do_id],
	["#{t 'employee'}", ":", @sales_invoice_header.employee_name, "#{t 'customer'}", ":", "#{@sales_invoice_header.customer.try(:name)}"],
	["", "", "", "#{t 'notes'}", ":", @sales_invoice_header.notes]
]

pdf.table(header_info, :position => :center, :column_widths => [110, 20, 100, 110, 20, 180], :cell_style => { :font => "Times-Roman", :size => 10}) do
	cells.borders = []
	row(0).columns(2).font_style = :bold
	row(0..3).columns(0..1).font_style = :bold
	row(0..3).columns(3..4).font_style = :bold
	row(0..2).borders = [:bottom]
	row(3).columns(2).borders = [:right]
	row(0..2).columns(2).borders = [:right, :bottom]
end

pdf.move_down(15)

details = [["#{t 'product'}", "#{t 'quantity'}", "#{t 'unit'}", "#{t 'price'}", "#{t 'disc_rp'}", "#{t 'disc'}", "#{t 'total'}"]]

details += @sales_invoice_details.map do |detail|
	[
		detail.product.try(:name),
		delimiter(detail.quantity),
		detail.unit_of_measure.try(:name),
		delimiter(detail.price),
		delimiter(detail.discount_item_price),
		delimiter(detail.discount_item),
		delimiter(detail.total_amount)
	]
end

total_row = @sales_invoice_details[0].row_number(@sales_invoice_header.id)

pdf.table(details, :width => 540, :header => true, :row_colors => ["FFFFFF", "F5F5F5"], :cell_style => { :font => "Times-Roman", :size => 10}) do
	cells.borders = []
	rows(0).borders = [:bottom]
	row(0).font_style = :bold
	row(0).background_color = "FF8533"
	columns(1..6).align = :right
	columns(2).align = :center
	row(total_row).borders = [:bottom]
end

pdf.move_down(10)

header_total = [
	["#{t 'sub_amount'}", ": Rp ", delimiter(@sales_invoice_header.amount)],
	["#{t 'discount'}", ":", "#{delimiter(@sales_invoice_header.discount)} %"],
	["#{t 'discount_amount'}", ": Rp ", delimiter(@sales_invoice_header.discount_amount)],
	["#{t 'tax'}", ":", "#{'10%' if @sales_invoice_header.tax==true}#{'-' if @sales_invoice_header.tax==false}"],
	["#{t 'tax_amount'}", ": Rp ", delimiter(@sales_invoice_header.tax_amount)],
	["#{t 'total_amount'}", ": Rp ", delimiter(@sales_invoice_header.total_amount)]
]

pdf.table(header_total, :width => 200, :position => :right, :row_colors => ["FFFFFF", "F5F5F5"], :cell_style => { :font => "Times-Roman", :size => 10}) do
	cells.borders = []
	columns(2).align = :right
	row(4).borders = [:bottom]
	row(5).font_style = :bold
end

pdf.repeat(:all) do
	pdf.stroke do
		pdf.horizontal_line 0, 540, :at => 10
	end
	pdf.number_pages "[#{t 'sales_invoice'} - #{t 'date_print'}: #{Date.today.strftime("%d/%m/%Y")} - #{t 'print_by'}: #{@employee}]", :size => 8, :at => [0, 0]
end
pdf.number_pages "(<page>/<total>)", :size => 8, :at => [510, 0]