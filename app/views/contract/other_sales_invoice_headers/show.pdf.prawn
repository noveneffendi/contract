@company = Company.last

#define_grid(:columns => 12, :rows => 12, :gutter => 3)
# grid.show_all
#grid([0,0], [0,2]).bounding_box do
#	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 120, :height => 50, :vposition => :top
#end

headers = [[{:content => "#{t 'other_sales_invoice'}".upcase, :colspan => 4 }]]
headers += [["No", ":", "#{@other_sales_invoice_header.si_id}", "", "KEPADA YTH :"]]
headers += [["#{t 'dates'}", ":", "#{@other_sales_invoice_header.sales_invoice_date.strftime('%d-%b-%Y')}", "", "#{@other_sales_invoice_header.customer.try(:city).try(:name)}"]]
headers += [["Sales", ":", "#{@other_sales_invoice_header.customer.sales_name(@other_sales_invoice_header.try(:sales_id))}", "", "#{@other_sales_invoice_header.customer.try(:address)}"]]
headers += [["#{t 'due_date'}", ":", "#{@other_sales_invoice_header.due_date.strftime('%d-%b-%Y') if @other_sales_invoice_header.due_date}#{'-' if @other_sales_invoice_header.due_date.blank?}", "", "#{@other_sales_invoice_header.customer.try(:name)}"]]


pdf.table(headers, :width => 570, :header => true, :cell_style => { :padding => [1,1,1,1]}) do
	self.column_widths = {0=>60, 1=>6, 2=>180, 3=>6, 4=>318}
	row(0..4).font_style = :bold
	row(0).size = 12
	rows(1..4).size = 8
	rows(1..3).columns(0..2).align = :left
	columns(0..4).borders = []
end

i=0; sum_qty=0
details = [["QTY", "ITEMS", "HARGA", "DISKON", "JUMLAH"]]
details += @other_sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.description,
		"Rp #{delimiter(detail.price.to_f)}",
		"#{delimiter(detail.discount_item.to_f)} %",
		"Rp #{delimiter((detail.quantity.to_f*detail.price.to_f).round)}"
	]
end

details += [["", "", "", "", ""]] * (6-@other_sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 2}, "SUBTOTAL", "Rp #{delimiter(@other_sales_invoice_header.amount.round)}"],
	[{:content => "* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar
		#{@other_sales_invoice_header.notes}", :colspan => 3, :rowspan => 3}, "DISKON", "Rp #{delimiter(@total_discount)}"],
	["PPN", "Rp #{delimiter(@other_sales_invoice_header.tax_amount)}"],
	["TOTAL", "Rp #{delimiter(@other_sales_invoice_header.total_amount.round)}"]]

pdf.table(details, :width => 570, :header => true, :cell_style => { :size => 8, :padding => [0, 2, 1, 1], :height => 10}) do
	self.column_widths = {0=>30, 1=>270, 2=>90, 3=>70, 4=>110}
	row(0).font_style = :bold
	#row(0).background_color = "F5F5F5"
	columns(0).align = :center
	columns(0..1).align = :left
	columns(2..5).align = :right
	rows(0).columns(0..5).align = :center
	rows(1..6).columns(0..4).borders = [:left, :right]
	rows(6+1..6+4).font_style = :bold
	#rows(6+1..6+4).columns(4..5).background_color = "F5F5F5"
	rows(6+2..6+4).columns(0..2).align = :left
	rows(6+1..6+4).columns(4).align = :right
	rows(6+1..6+4).columns(5).align = :right
end

footer = [
	["Hormat Kami,", "", "", ""]]

pdf.table(footer, :width => 570, :header => true, :cell_style => { :size => 8, :padding => [1, 1, 1, 1], :height => 10}) do
	self.column_widths = {0=>70, 1=>70, 2=>340, 3=>90}
	row(0).align = :center
	row(0).borders = []
end