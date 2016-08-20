# =====================================
# PART 1
# =====================================
@company = Company.last

define_grid(:columns => 12, :rows => 12, :gutter => 5)
# grid.show_all
grid([0,0], [0,2]).bounding_box do
	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 130, :height => 50, :vposition => :top
end
grid([0,3], [0,7]).bounding_box do
	font("Times-Roman") do
		pdf.text "NOTA", :align => :center, :size => 12, :style => :bold
		pdf.text "Gudang: #{@other_sales_invoice_header.warehouse.try(:name)}", :align => :center, :size => 8
		# pdf.move_down 15
		pdf.text "JT: #{@other_sales_invoice_header.due_date.strftime('%d-%b-%y') if @other_sales_invoice_header.due_date}#{'-' if @other_sales_invoice_header.due_date.blank?}", :size => 8
		pdf.text "Sales: #{@other_sales_invoice_header.customer.sales_name(@other_sales_invoice_header.customer.try(:sales_id))}", :size => 8
		pdf.text "No: #{@other_sales_invoice_header.si_id}", :size => 8
	end
end

grid([0,8], [0,11]).bounding_box do
	font("Times-Roman") do
		pdf.text "#{@company.try(:city).try(:name)}, #{@other_sales_invoice_header.sales_invoice_date.strftime('%d-%b-%y')}", :align => :center, :size => 8
		pdf.text "Kepada", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:name)}", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:address)}", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:city).try(:name)}", :align => :center, :size => 8
	end	
end

i=0; sum_qty=0
details = [["QTY", "KETERANGAN", "COLOUR", "@", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.description,
		detail.product.try(:colour),
		"Rp #{delimiter(detail.price.to_f - (detail.discount_item.to_f/100)*detail.price.to_f)}",
		"Rp #{delimiter(detail.discount_item_price)}",
		"Rp #{delimiter(detail.total_amount)}"
	]
end

details += [["", "", "", "", "", ""]] * (10-@sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 3}, "SUBTOTAL", "Rp #{delimiter(@other_sales_invoice_header.amount)}"],
	[{:content => "* Pembayaran  dengan BG dianggap lunas setelah cair
	    * Harga sudah termasuk PPn 10%
		* Pembayaran jatuh tempo, nota harus ditukar TT saat barang diterima
		* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar", :colspan => 4, :rowspan => 2}, "DISKON", "Rp #{delimiter((@other_sales_invoice_header.discount.to_f/100)*@other_sales_invoice_header.amount.to_f + @other_sales_invoice_header.discount_amount.to_f)}"],
	["PPN", "Rp #{delimiter(@other_sales_invoice_header.tax_amount)}"],
	[{:content => "", :colspan => 4}, "TOTAL", "Rp #{delimiter(@other_sales_invoice_header.total_amount)}"]]


pdf.table(details, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 3, 1, 1], :height => 15}) do
	self.column_widths = {0=>20, 1=>170, 2=>80, 3=>90, 4=>90, 5=>90}
	row(0).font_style = :bold
	row(0).background_color = "F5F5F5"
	columns(3..5).align = :right
	columns(0..2).align = :center
	rows(0).columns(0..5).align = :center
	rows(10+1..10+4).font_style = :bold
	rows(10+1..10+4).background_color = "F5F5F5"
	rows(10+2..10+4).columns(0..3).align = :left
	rows(10+1..10+4).columns(4).align = :center
	rows(10+4).columns(0..3).borders = [:top, :right]
end

footer = [
	["Hormat Kami,", "Accounting", {:content => "Pembayaran via transfer hanya melalui
		Rek. #{@company.try(:bank_name)} AN. #{@company.try(:bank_account_name)} | No. #{@company.try(:bank_account)}
		Jika nota tidak di dalam amplop harap dilaporkan ke perusahaan", :rowspan => 2}, "Penerima"],
	["", "", ""]]

pdf.table(footer, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 1, 1, 1], :height => 15}) do
	self.column_widths = {0=>70, 1=>70, 2=>310, 3=>90}
	rows(1).height = 25
	rows(0..1).align = :center
	columns(2).borders = [:left, :right]
end

pdf.stroke do
	pdf.move_down 5
	pdf.text "[Nota - #{t 'date_print'}: #{date_without_localtime(Date.today)} - #{t 'print_by'}: #{@employee}]", :size => 6
	pdf.move_down 3
	pdf.horizontal_line 0, 540
end

# =====================================
# PART 2
# =====================================
pdf.start_new_page

define_grid(:columns => 12, :rows => 12, :gutter => 5)
# grid.show_all
grid([0,0], [0,2]).bounding_box do
	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 130, :height => 50, :vposition => :top
end
grid([0,3], [0,7]).bounding_box do
	font("Times-Roman") do
		pdf.text "NOTA (Copy 1)", :align => :center, :size => 12, :style => :bold
		pdf.text "Gudang: #{@other_sales_invoice_header.warehouse.try(:name)}", :align => :center, :size => 8
		# pdf.move_down 15
		pdf.text "JT: #{@other_sales_invoice_header.due_date.strftime('%d-%b-%y') if @other_sales_invoice_header.due_date}#{'-' if @other_sales_invoice_header.due_date.blank?}", :size => 8
		pdf.text "Sales: #{@other_sales_invoice_header.customer.sales_name(@other_sales_invoice_header.customer.try(:sales_id))}", :size => 8
		pdf.text "No: #{@other_sales_invoice_header.si_id}", :size => 8
	end
end

grid([0,8], [0,11]).bounding_box do
	font("Times-Roman") do
		pdf.text "#{@company.try(:city).try(:name)}, #{@other_sales_invoice_header.sales_invoice_date.strftime('%d-%b-%y')}", :align => :center, :size => 8
		pdf.text "Kepada", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:name)}", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:address)}", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:city).try(:name)}", :align => :center, :size => 8
	end	
end

i=0; sum_qty=0
details = [["QTY", "KETERANGAN", "COLOUR", "@", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.description.try(:name),
		detail.product.try(:colour),
		"Rp #{delimiter(detail.price.to_f - (detail.discount_item.to_f/100)*detail.price.to_f)}",
		"Rp #{delimiter(detail.discount_item_price)}",
		"Rp #{delimiter(detail.total_amount)}"
	]
end

details += [["", "", "", "", "", ""]] * (10-@sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 3}, "SUBTOTAL", "Rp #{delimiter(@other_sales_invoice_header.amount)}"],
	[{:content => "* Pembayaran  dengan BG dianggap lunas setelah cair
		* Pembayaran jatuh tempo, nota harus ditukar TT saat barang diterima
		* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar", :colspan => 4, :rowspan => 2}, "DISKON", "Rp #{delimiter((@other_sales_invoice_header.discount.to_f/100)*@other_sales_invoice_header.amount.to_f + @other_sales_invoice_header.discount_amount.to_f)}"],
	["PPN", "Rp #{delimiter(@other_sales_invoice_header.tax_amount)}"],
	[{:content => "", :colspan => 4}, "TOTAL", "Rp #{delimiter(@other_sales_invoice_header.total_amount)}"]]


pdf.table(details, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 3, 1, 1], :height => 15}) do
	self.column_widths = {0=>20, 1=>170, 2=>80, 3=>90, 4=>90, 5=>90}
	row(0).font_style = :bold
	row(0).background_color = "F5F5F5"
	columns(3..5).align = :right
	columns(0..2).align = :center
	rows(0).columns(0..5).align = :center
	rows(10+1..10+4).font_style = :bold
	rows(10+1..10+4).background_color = "F5F5F5"
	rows(10+2..10+4).columns(0..3).align = :left
	rows(10+1..10+4).columns(4).align = :center
	rows(10+4).columns(0..3).borders = [:top, :right]
end

footer = [
	["Hormat Kami,", "Accounting", {:content => "Pembayaran via transfer hanya melalui
		Rek. #{@company.try(:bank_name)} AN. #{@company.try(:bank_account_name)} | No. #{@company.try(:bank_account)}
		Jika nota tidak di dalam amplop harap dilaporkan ke perusahaan", :rowspan => 2}, "Penerima"],
	["", "", ""]]

pdf.table(footer, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 1, 1, 1], :height => 15}) do
	self.column_widths = {0=>70, 1=>70, 2=>310, 3=>90}
	rows(1).height = 25
	rows(0..1).align = :center
	columns(2).borders = [:left, :right]
end

pdf.stroke do
	pdf.move_down 5
	pdf.text "[Nota (Copy 1) - #{t 'date_print'}: #{date_without_localtime(Date.today)} - #{t 'print_by'}: #{@employee}]", :size => 6
	pdf.move_down 3
	pdf.horizontal_line 0, 540
end

# =====================================
# PART 3
# =====================================
grid([6,0], [6,2]).bounding_box do
	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 130, :height => 50, :vposition => :top
end
grid([6,3], [6,7]).bounding_box do
	font("Times-Roman") do
		pdf.text "NOTA (Copy 2)", :align => :center, :size => 12, :style => :bold
		pdf.text "Gudang: #{@other_sales_invoice_header.warehouse.try(:name)}", :align => :center, :size => 8
		# pdf.move_down 15
		pdf.text "JT: #{@other_sales_invoice_header.due_date.strftime('%d-%b-%y') if @other_sales_invoice_header.due_date}#{'-' if @other_sales_invoice_header.due_date.blank?}", :size => 8
		pdf.text "Sales: #{@other_sales_invoice_header.customer.sales_name(@other_sales_invoice_header.customer.try(:sales_id))}", :size => 8
		pdf.text "No: #{@other_sales_invoice_header.si_id}", :size => 8
	end
end

grid([6,8], [6,11]).bounding_box do
	font("Times-Roman") do
		pdf.text "#{@company.try(:city).try(:name)}, #{@other_sales_invoice_header.sales_invoice_date.strftime('%d-%b-%y')}", :align => :center, :size => 8
		pdf.text "Kepada", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:name)}", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:address)}", :align => :center, :size => 8
		pdf.text "#{@other_sales_invoice_header.customer.try(:city).try(:name)}", :align => :center, :size => 8
	end	
end

i=0; sum_qty=0
details = [["QTY", "KETERANGAN", "COLOUR", "@", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
	i+=1; sum_qty+=detail.quantity.to_f
	[
		delimiter(detail.quantity),
		detail.description,
		detail.product.try(:colour),
		"Rp #{delimiter(detail.price.to_f - (detail.discount_item.to_f/100)*detail.price.to_f)}",
		"Rp #{delimiter(detail.discount_item_price)}",
		"Rp #{delimiter(detail.total_amount)}"
	]
end

details += [["", "", "", "", "", ""]] * (10-@sales_invoice_details.count)

details += [
	[delimiter(sum_qty), {:content => "", :colspan => 3}, "SUBTOTAL", "Rp #{delimiter(@other_sales_invoice_header.amount)}"],
	[{:content => "* Pembayaran  dengan BG dianggap lunas setelah cair
		* Pembayaran jatuh tempo, nota harus ditukar TT saat barang diterima
		* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar", :colspan => 4, :rowspan => 2}, "DISKON", "Rp #{delimiter((@other_sales_invoice_header.discount.to_f/100)*@other_sales_invoice_header.amount.to_f + @other_sales_invoice_header.discount_amount.to_f)}"],
	["PPN", "Rp #{delimiter(@other_sales_invoice_header.tax_amount)}"],
	[{:content => "", :colspan => 4}, "TOTAL", "Rp #{delimiter(@other_sales_invoice_header.total_amount)}"]]


pdf.table(details, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 3, 1, 1], :height => 15}) do
	self.column_widths = {0=>20, 1=>170, 2=>80, 3=>90, 4=>90, 5=>90}
	row(0).font_style = :bold
	row(0).background_color = "F5F5F5"
	columns(3..5).align = :right
	columns(0..2).align = :center
	rows(0).columns(0..5).align = :center
	rows(10+1..10+4).font_style = :bold
	rows(10+1..10+4).background_color = "F5F5F5"
	rows(10+2..10+4).columns(0..3).align = :left
	rows(10+1..10+4).columns(4).align = :center
	rows(10+4).columns(0..3).borders = [:top, :right]
end

footer = [
	["Hormat Kami,", "Accounting", {:content => "Pembayaran via transfer hanya melalui
		Rek. #{@company.try(:bank_name)} AN. #{@company.try(:bank_account_name)} | No. #{@company.try(:bank_account)}
		Jika nota tidak di dalam amplop harap dilaporkan ke perusahaan", :rowspan => 2}, "Penerima"],
	["", "", ""]]

pdf.table(footer, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 8, :padding => [1, 1, 1, 1], :height => 15}) do
	self.column_widths = {0=>70, 1=>70, 2=>310, 3=>90}
	rows(1).height = 25
	rows(0..1).align = :center
	columns(2).borders = [:left, :right]
end

pdf.stroke do
	pdf.move_down 5
	pdf.text "[Nota (Copy 2) - #{t 'date_print'}: #{date_without_localtime(Date.today)} - #{t 'print_by'}: #{@employee}]", :size => 6
	pdf.move_down 3
	pdf.horizontal_line 0, 540
end