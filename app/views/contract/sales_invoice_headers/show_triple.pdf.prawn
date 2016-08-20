# =====================================
# PART 1
# =====================================
@company = Company.last
@employee = current_user.full_name

define_grid(:columns => 12, :rows => 12, :gutter => 5)
# grid.show_all

headers = [[{:content => "#{t 'sales_invoice'}".upcase, :colspan => 5 }]]
headers += [["Gudang", ":", "#{@sales_invoice_header.warehouse.try(:name)}", "", "", "KEPADA YTH :"]]
headers += [["#{t 'due_date'}", ":", "#{@sales_invoice_header.due_date.strftime('%d-%b-%y') if @sales_invoice_header.due_date}#{'-' if @sales_invoice_header.due_date.blank?}", "", "", "#{@sales_invoice_header.customer.try(:name)}"]]
headers += [["Sales", ":", "#{@sales_invoice_header.customer.sales_name(@sales_invoice_header.customer.try(:sales_id))}", "", "", "#{@sales_invoice_header.customer.try(:address)}"]]
headers += [["No", ":", "#{@sales_invoice_header.si_id}", "", "", "#{@sales_invoice_header.customer.try(:city).try(:name)}"]]

pdf.table(headers, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :padding => [1,1,1,1]}) do
	self.column_widths = {0=>56, 1=>6, 2=>180, 3=>130, 4=>6, 5=>172}
	row(0).font_style = :bold
	row(0).size = 14
	rows(1..3).size = 9
	rows(1..3).columns(0..2).align = :left
	row(4).size = 10
	row(4).columns(0..2).font_style = :bold
	columns(0..5).borders = []
end

pdf.move_down 10

i=0; sum_qty=0
details = [["QTY", "ITEMS", "COLOUR", "@", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.product.try(:name),
		detail.product.try(:colour),
		"Rp #{delimiter(detail.price.to_f - (detail.discount_item.to_f/100)*detail.price.to_f)}",
		"Rp #{delimiter(detail.discount_amount)}",
		"Rp #{delimiter(detail.total_amount.to_f)}"
	]
end

details += [["", "", "", "", "", ""]] * (10-@sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 3}, "SUBTOTAL", "Rp #{delimiter(@sales_invoice_header.amount.round)}"],
	[{:content => "* Pembayaran  dengan BG dianggap lunas setelah cair
		* Pembayaran jatuh tempo, nota harus ditukar TT saat barang diterima
		* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar", :colspan => 4, :rowspan => 3}, "DISKON", "Rp #{delimiter((@sales_invoice_header.discount.to_f/100)*@sales_invoice_header.amount.to_f + @sales_invoice_header.discount_amount.to_f)}"],
	["PPN", "Rp #{delimiter(@sales_invoice_header.tax_amount.floor)}"],
	["TOTAL", "Rp #{delimiter(@sales_invoice_header.total_amount.floor)}"]]


pdf.table(details, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 3, 1, 1], :height => 15}) do
	self.column_widths = {0=>30, 1=>200, 2=>50, 3=>90, 4=>90, 5=>90}
	row(0).font_style = :bold
	row(0).background_color = "F5F5F5"
	columns(3..5).align = :right
	columns(0..2).align = :center
	rows(0).columns(0..5).align = :center
	rows(10+1..10+4).font_style = :bold
	rows(10+1..10+4).columns(4..5).background_color = "F5F5F5"
	rows(10+2..10+4).columns(0..3).align = :left
	rows(10+1..10+4).columns(4).align = :center
	rows(10+4).columns(0..3).borders = [:top, :right]
end

footer = [
	["Hormat Kami,", "Accounting", {:content => "Pembayaran via transfer hanya melalui
		Rek. #{@company.try(:bank_name)} AN. #{@company.try(:bank_account_name)} | No. #{@company.try(:bank_account)}
		Jika nota tidak di dalam amplop harap dilaporkan ke perusahaan", :rowspan => 3}, "Penerima"],
	["", "", ""],
	["", "", ""]]

pdf.move_down 10

pdf.table(footer, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 1, 1, 1], :height => 15}) do
	self.column_widths = {0=>70, 1=>70, 2=>320, 3=>90}
	rows(1).height = 25
	rows(0..1).align = :center
	columns(2).borders = [:left, :right]
	rows(1..2).columns(0..1).borders = [:left]
	rows(1..2).columns(3).borders = [:right]
	row(2).columns(0..1).borders = [:left, :bottom]
	row(2).columns(3).borders = [:right, :bottom]
end

pdf.stroke do
	pdf.move_down 10
	pdf.text "[#{t 'sales_invoice'} - #{t 'date_print'}: #{Date.today.strftime("%d-%m-%Y")} - #{t 'print_by'}: #{@employee}]", :size => 6
	pdf.move_down 3
	pdf.horizontal_line 0, 550
end

# =====================================
# PART 2
# =====================================
pdf.start_new_page

define_grid(:columns => 12, :rows => 12, :gutter => 5)
# grid.show_all

headers = [[{:content => "#{t 'sales_invoice'} - (copy 1)".upcase, :colspan => 5 }]]
headers += [["Gudang", ":", "#{@sales_invoice_header.warehouse.try(:name)}", "", "", "KEPADA YTH :"]]
headers += [["#{t 'due_date'}", ":", "#{@sales_invoice_header.due_date.strftime('%d-%b-%y') if @sales_invoice_header.due_date}#{'-' if @sales_invoice_header.due_date.blank?}", "", "", "#{@sales_invoice_header.customer.try(:name)}"]]
headers += [["Sales", ":", "#{@sales_invoice_header.customer.sales_name(@sales_invoice_header.customer.try(:sales_id))}", "", "", "#{@sales_invoice_header.customer.try(:address)}"]]
headers += [["No", ":", "#{@sales_invoice_header.si_id}", "", "", "#{@sales_invoice_header.customer.try(:city).try(:name)}"]]

pdf.table(headers, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :padding => [1,1,1,1]}) do
	self.column_widths = {0=>56, 1=>6, 2=>180, 3=>130, 4=>6, 5=>172}
	row(0).font_style = :bold
	row(0).size = 14
	rows(1..3).size = 9
	rows(1..3).columns(0..2).align = :left
	row(4).size = 10
	row(4).columns(0..2).font_style = :bold
	columns(0..5).borders = []
end

pdf.move_down 10

i=0; sum_qty=0
details = [["QTY", "ITEMS", "COLOUR", "@", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.product.try(:name),
		detail.product.try(:colour),
		"Rp #{delimiter(detail.price.to_f - (detail.discount_item.to_f/100)*detail.price.to_f)}",
		"Rp #{delimiter(detail.discount_item_price)}",
		"Rp #{delimiter(detail.total_amount)}"
	]
end

details += [["", "", "", "", "", ""]] * (10-@sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 3}, "SUBTOTAL", "Rp #{delimiter(@sales_invoice_header.amount)}"],
	[{:content => "* Pembayaran  dengan BG dianggap lunas setelah cair
		* Pembayaran jatuh tempo, nota harus ditukar TT saat barang diterima
		* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar", :colspan => 4, :rowspan => 3}, "DISKON", "Rp #{delimiter((@sales_invoice_header.discount.to_f/100)*@sales_invoice_header.amount.to_f + @sales_invoice_header.discount_amount.to_f)}"],
	["PPN", "Rp #{delimiter(@sales_invoice_header.tax_amount)}"],
	["TOTAL", "Rp #{delimiter(@sales_invoice_header.total_amount)}"]]


pdf.table(details, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 3, 1, 1], :height => 15}) do
	self.column_widths = {0=>30, 1=>200, 2=>50, 3=>90, 4=>90, 5=>90}
	row(0).font_style = :bold
	row(0).background_color = "F5F5F5"
	columns(3..5).align = :right
	columns(0..2).align = :center
	rows(0).columns(0..5).align = :center
	rows(10+1..10+4).font_style = :bold
	rows(10+1..10+4).columns(4..5).background_color = "F5F5F5"
	rows(10+2..10+4).columns(0..3).align = :left
	rows(10+1..10+4).columns(4).align = :center
	rows(10+4).columns(0..3).borders = [:top, :right]
end

footer = [
	["Hormat Kami,", "Accounting", {:content => "Pembayaran via transfer hanya melalui
		Rek. #{@company.try(:bank_name)} AN. #{@company.try(:bank_account_name)} | No. #{@company.try(:bank_account)}
		Jika nota tidak di dalam amplop harap dilaporkan ke perusahaan", :rowspan => 3}, "Penerima"],
	["", "", ""],
	["", "", ""]]

pdf.move_down 10

pdf.table(footer, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 1, 1, 1], :height => 15}) do
	self.column_widths = {0=>70, 1=>70, 2=>320, 3=>90}
	rows(1).height = 25
	rows(0..1).align = :center
	columns(2).borders = [:left, :right]
	rows(1..2).columns(0..1).borders = [:left]
	rows(1..2).columns(3).borders = [:right]
	row(2).columns(0..1).borders = [:left, :bottom]
	row(2).columns(3).borders = [:right, :bottom]
end

pdf.stroke do
	pdf.move_down 10
	pdf.text "[#{t 'sales_invoice'} (Copy 1) - #{t 'date_print'}: #{Date.today.strftime("%d-%m-%Y")} - #{t 'print_by'}: #{@employee}]", :size => 6
	pdf.move_down 3
	pdf.horizontal_line 0, 550
end

# =====================================
# PART 3
# =====================================
pdf.start_new_page

define_grid(:columns => 12, :rows => 12, :gutter => 5)

headers = [[{:content => "#{t 'sales_invoice'} - (copy 2)".upcase, :colspan => 5 }]]
headers += [["Gudang", ":", "#{@sales_invoice_header.warehouse.try(:name)}", "", "", "KEPADA YTH :"]]
headers += [["#{t 'due_date'}", ":", "#{@sales_invoice_header.due_date.strftime('%d-%b-%y') if @sales_invoice_header.due_date}#{'-' if @sales_invoice_header.due_date.blank?}", "", "", "#{@sales_invoice_header.customer.try(:name)}"]]
headers += [["Sales", ":", "#{@sales_invoice_header.customer.sales_name(@sales_invoice_header.customer.try(:sales_id))}", "", "", "#{@sales_invoice_header.customer.try(:address)}"]]
headers += [["No", ":", "#{@sales_invoice_header.si_id}", "", "", "#{@sales_invoice_header.customer.try(:city).try(:name)}"]]

pdf.table(headers, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :padding => [1,1,1,1]}) do
	self.column_widths = {0=>56, 1=>6, 2=>180, 3=>130, 4=>6, 5=>172}
	row(0).font_style = :bold
	row(0).size = 14
	rows(1..3).size = 9
	rows(1..3).columns(0..2).align = :left
	row(4).size = 10
	row(4).columns(0..2).font_style = :bold
	columns(0..5).borders = []
end

pdf.move_down 10

i=0; sum_qty=0
details = [["QTY", "ITEMS", "COLOUR", "@", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.product.try(:name),
		detail.product.try(:colour),
		"Rp #{delimiter(detail.price.to_f - (detail.discount_item.to_f/100)*detail.price.to_f)}",
		"Rp #{delimiter(detail.discount_amount)}",
		"Rp #{delimiter(detail.total_amount.round)}"
	]
end

details += [["", "", "", "", "", ""]] * (10-@sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 3}, "SUBTOTAL", "Rp #{delimiter(@sales_invoice_header.amount)}"],
	[{:content => "* Pembayaran  dengan BG dianggap lunas setelah cair
		* Pembayaran jatuh tempo, nota harus ditukar TT saat barang diterima
		* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar", :colspan => 4, :rowspan => 3}, "DISKON", "Rp #{delimiter((@sales_invoice_header.discount.to_f/100)*@sales_invoice_header.amount.to_f + @sales_invoice_header.discount_amount.to_f)}"],
	["PPN", "Rp #{delimiter(@sales_invoice_header.tax_amount.round)}"],
	["TOTAL", "Rp #{delimiter(@sales_invoice_header.total_amount.round)}"]]


pdf.table(details, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 3, 1, 1], :height => 15}) do
	self.column_widths = {0=>30, 1=>200, 2=>50, 3=>90, 4=>90, 5=>90}
	row(0).font_style = :bold
	row(0).background_color = "F5F5F5"
	columns(3..5).align = :right
	columns(0..2).align = :center
	rows(0).columns(0..5).align = :center
	rows(10+1..10+4).font_style = :bold
	rows(10+1..10+4).columns(4..5).background_color = "F5F5F5"
	rows(10+2..10+4).columns(0..3).align = :left
	rows(10+1..10+4).columns(4).align = :center
	rows(10+4).columns(0..3).borders = [:top, :right]
end

footer = [
	["Hormat Kami,", "Accounting", {:content => "Pembayaran via transfer hanya melalui
		Rek. #{@company.try(:bank_name)} AN. #{@company.try(:bank_account_name)} | No. #{@company.try(:bank_account)}
		Jika nota tidak di dalam amplop harap dilaporkan ke perusahaan", :rowspan => 3}, "Penerima"],
	["", "", ""],
	["", "", ""]]

pdf.move_down 10

pdf.table(footer, :width => 550, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 1, 1, 1], :height => 15}) do
	self.column_widths = {0=>70, 1=>70, 2=>320, 3=>90}
	rows(1).height = 25
	rows(0..1).align = :center
	columns(2).borders = [:left, :right]
	rows(1..2).columns(0..1).borders = [:left]
	rows(1..2).columns(3).borders = [:right]
	row(2).columns(0..1).borders = [:left, :bottom]
	row(2).columns(3).borders = [:right, :bottom]
end

pdf.stroke do
	pdf.move_down 10
	pdf.text "[#{t 'sales_invoice'} (Copy 2) - #{t 'date_print'}: #{Date.today.strftime("%d-%m-%Y")} - #{t 'print_by'}: #{@employee}]", :size => 6
	pdf.move_down 3
	pdf.horizontal_line 0, 550
end