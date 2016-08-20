define_grid(:columns => 5, :rows => 8, :gutter => 10)
grid(0,0).bounding_box do
	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 110, :height => 60, :position => :center, :vposition => :top
end
grid([0,1], [0,4]).bounding_box do
	font("Times-Roman") do
		pdf.text "#{company_name}", :align => :center, :size => 15, :style => :bold
		pdf.text "#{t 'report'} #{t 'sales_order'} yang Belum Selesai", :align => :center, :size => 13, :style => :bold
		pdf.text "#{t 'period'}: #{@start_period} - #{@end_period}", :align => :center, :size => 12
	end
	# font("Times-Roman") do
	# 	pdf.text "COST CONTROL - Report of Sales Order", :align => :left, :size => 15, :style => :bold
	# 	pdf.number_pages "Period: #{@start_period} - #{@end_period}", :size => 12, :at => [0, 50]
	# 	pdf.number_pages "Supplier: #{@supplier}", :size => 12, :at => [200, 50]
	# 	pdf.number_pages "Range Total Amount: #{@start_amount} - #{@end_amount}", :size => 12, :at => [0, 35]
	# end
end

pdf.stroke do
	self.line_width = 2
	pdf.horizontal_line 0, 540, :at => 650
end

rows = [["#{t 'nomor'}", "#{t 'so_id'}", "#{t 'dates'}", "#{t 'customer'}", "#{t 'amount'}", "#{t 'disc'}", "#{t 'disc_rp'}", "#{t 'tax'}", "#{t 'tax_amount'}", "#{t 'total'}"]]

rows += @sales_orders.map do |row|
	[
		row[0], row[1], row[2], row[3], delimiter(row[4]), delimiter(row[5]), delimiter(row[6]), "#{row[7]}", delimiter(row[8]), delimiter(row[9])
	]
end

total_row = @total_rows

pdf.table(rows, :header => true, :cell_style => { :font => "Times-Roman", :size => 9 }, :row_colors => ["FFFFFF", "F5F5F5"], :column_widths => [20, 70, 60, 50, 60, 40, 60, 40, 70, 70]) do
	cells.borders = []
	rows(0).borders = [:bottom]
	row(0).font_style = :bold
	row(0).background_color = "CC99CC"
	columns(2).align = :right
	columns(4..9).align = :right
	columns(7).align = :center
	row(total_row).borders = [:bottom]
end

pdf.move_down(10)

pdf.repeat(:all) do
	pdf.stroke do
		pdf.horizontal_line 0, 540, :at => 10
	end

	pdf.number_pages "[#{t 'report'} of #{t 'sales_order'} yang Belum Selesai - #{t 'date_print'}: #{Date.today.strftime("%d/%m/%Y")} - #{t 'print_by'}: #{@employee}]", :size => 9, :at => [0, 0]
end
pdf.number_pages "(<page>/<total>)", :size => 9, :at => [500, 0]