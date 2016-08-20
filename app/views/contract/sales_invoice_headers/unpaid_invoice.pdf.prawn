font_families.update("Verdana" => {
    :normal => "#{Rails.root}/public/assets/fonts/Verdana.ttf",
    :italic => "#{Rails.root}/public/assets/fonts/Verdana_Italic.ttf",
    :bold => "#{Rails.root}/public/assets/fonts/Verdana_Bold.ttf",
    :bold_italic => "#{Rails.root}/public/assets/fonts/Verdana_Bold_Italic.ttf"
})

headers = [[{:content => "#{t 'unpaid_sales_invoice'}".upcase, :colspan => 5 }]]
headers += [[{:content => "", :colspan => 5 }]]

@reports.map do |row|
	if row[1] == "Pelanggan"
		headers +=  [[{:content => "#{row[1]}: #{row[2]}", :colspan => 3}, row[3], delimiter(row[4])]]
	else
		if row[0].is_a? Integer
			headers += [[row[0], row[1], row[2], row[3], delimiter(row[4])]]
		else
			headers += [[row[0], row[1], row[2], row[3], row[4]]]
		end
	end
end

pdf.table(headers, :width => 570, :header => true, :cell_style => { :font => "Verdana", :size => 8, :padding => [0, 1, 1, 1], :height => 10}) do
	#self.column_widths = {0=>15, 1=>70, 2=>290, 3=>95, 4=>100}
	row(0).font_style = :bold
	row(0).size = 10
	row(0).align = :center
	rows(0).borders = [:bottom]
	columns(4).align = :right
end

pdf.number_pages "(<page>/<total>)", :size => 9, :at => [500, 0]