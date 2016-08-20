define_grid(:columns => 5, :rows => 8, :gutter => 10)
grid(0,0).bounding_box do
	pdf.image "#{Rails.root}/public/assets/images/logo/logo.png", :width => 70, :height => 60, :position => :center, :vposition => :top
end

grid([0,1], [0,4]).bounding_box do
	font("Times-Roman") do
		pdf.text "#{company_name}", :align => :center, :size => 15, :style => :bold
		pdf.text "#{t 'sales_quotation'}", :align => :center, :size => 13, :style => :bold
	end
end

pdf.stroke do
	self.line_width = 2
	pdf.horizontal_line 0, 540, :at => 650
end

header_info = [
	["#{t 'sq_id'}", ":", @sales_quotation_header.sq_id, "#{t 'customer'}", ":", @sales_quotation_header.customer.try(:name)],
	["#{t 'dates'}", ":", @sales_quotation_header.sales_quotation_date.strftime("%d %B %Y"), "#{t 'cp'}", ":", @sales_quotation_header.customer.try(:contact_person)],
	["#{t 'employee'}", ":", @sales_quotation_header.employee_name, "#{t 'notes'}", ":", @sales_quotation_header.notes]
]

pdf.table(header_info, :position => :center, :column_widths => [110, 20, 100, 110, 20, 180], :cell_style => { :font => "Times-Roman", :size => 10}) do
	cells.borders = []
	row(0).columns(2).font_style = :bold
	row(0..2).columns(0..1).font_style = :bold
	row(0..2).columns(3..4).font_style = :bold
	row(0..1).borders = [:bottom]
	row(2).columns(2).borders = [:right]
	row(0..1).columns(2).borders = [:right, :bottom]
end

pdf.move_down(15)

details = []

details += @sqds.map do |detail|
	if (detail[2].blank?) && (detail[2].to_s != "#{t 'unit'}") && (detail[0].to_s != "#{t 'total'}")
		[	"#{detail[0]} - #{detail[1]}".upcase, {:content => "", :colspan => 6}	]
	elsif (detail[0].to_s == "#{t 'product'}")
		[	detail[0], detail[1], detail[2], detail[3], detail[4], detail[5], detail[6]	]
	elsif (detail[0].to_s == "#{t 'total'}")
		[	{:content => "#{detail[0]}", :colspan => 6 }, delimiter(detail[6])	]
	else
		[	detail[0], delimiter(detail[1]), detail[2], delimiter(detail[3]), delimiter(detail[4]), delimiter(detail[5]), delimiter(detail[6])	]
	end
end
total_row = @sqds.count

pdf.table(details, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 10}) do
	cells.borders = []
	
	column(0).filter { |cell| cell.content == "#{I18n.t 'product'}" }.background_color = "C0C0C0"
	column(0).filter { |cell| cell.content == "#{I18n.t 'product'}" }.borders = [:bottom]
	column(0).filter { |cell| cell.content == "#{I18n.t 'product'}" }.font_style = :bold
	
	column(1).filter { |cell| cell.content == "#{I18n.t 'quantity'}" }.background_color = "C0C0C0"
	column(1).filter { |cell| cell.content == "#{I18n.t 'quantity'}" }.borders = [:bottom]
	column(1).filter { |cell| cell.content == "#{I18n.t 'quantity'}" }.font_style = :bold
	
	column(2).filter { |cell| cell.content == "#{I18n.t 'unit'}" }.background_color = "C0C0C0"
	column(2).filter { |cell| cell.content == "#{I18n.t 'unit'}" }.borders = [:bottom]
	column(2).filter { |cell| cell.content == "#{I18n.t 'unit'}" }.font_style = :bold
	
	column(3).filter { |cell| cell.content == "#{I18n.t 'price'}" }.background_color = "C0C0C0"
	column(3).filter { |cell| cell.content == "#{I18n.t 'price'}" }.borders = [:bottom]
	column(3).filter { |cell| cell.content == "#{I18n.t 'price'}" }.font_style = :bold
	
	column(4).filter { |cell| cell.content == "#{I18n.t 'disc_rp'}" }.background_color = "C0C0C0"
	column(4).filter { |cell| cell.content == "#{I18n.t 'disc_rp'}" }.borders = [:bottom]
	column(4).filter { |cell| cell.content == "#{I18n.t 'disc_rp'}" }.font_style = :bold
	
	column(5).filter { |cell| cell.content == "#{I18n.t 'disc'}" }.background_color = "C0C0C0"
	column(5).filter { |cell| cell.content == "#{I18n.t 'disc'}" }.borders = [:bottom]
	column(5).filter { |cell| cell.content == "#{I18n.t 'disc'}" }.font_style = :bold
	
	column(6).filter { |cell| cell.content == "#{I18n.t 'total'}" }.background_color = "C0C0C0"
	column(6).filter { |cell| cell.content == "#{I18n.t 'total'}" }.borders = [:bottom]
	column(6).filter { |cell| cell.content == "#{I18n.t 'total'}" }.font_style = :bold

	columns(1..6).align = :right
	columns(2).align = :center

	column(0).filter { |cell| cell.content == "#{I18n.t 'total'}" }.borders = [:top]
	column(0).filter { |cell| cell.content == "#{I18n.t 'total'}" }.font_style = :bold
end

pdf.move_down(10)

costs = [[{ :content => "#{t 'cost'}".upcase, :colspan => 7 }]]
costs += [["#{t 'description'}", "#{I18n.t 'quantity'}", "#{I18n.t 'unit'}", 
                "#{I18n.t 'price'}", "#{I18n.t 'disc_rp'}", "#{I18n.t 'disc'}", "#{I18n.t 'total'}"]]

costs += @sales_quotation_costs.map do |mat|
	[	
		mat.description, 
		delimiter(mat.quantity), 
		mat.unit_of_measure.try(:name), 
		delimiter(mat.price), 
		delimiter(mat.discount_item),
		delimiter(mat.discount_item_price),
		delimiter(mat.amount)
	]
end

pdf.table(costs, :width => 540, :header => true, :cell_style => { :font => "Times-Roman", :size => 10}) do
	cells.borders = []
	row(1).background_color = "C0C0C0"
	rows(0..1).font_style = :bold
	columns(1..6).align = :right
	columns(2).align = :center
end

header_total = [
	["#{t 'sub_amount'}", ": Rp ", delimiter(@sales_quotation_header.amount)],
	["#{t 'discount'}", ":", "#{delimiter(@sales_quotation_header.discount)} %"],
	["#{t 'discount_amount'}", ": Rp ", delimiter(@sales_quotation_header.discount_amount)],
	["#{t 'tax'}", ":", "#{@tax}"],
	["#{t 'tax_amount'}", ": Rp ", delimiter(@sales_quotation_header.tax_amount)],
	["#{t 'total_amount'}", ": Rp ", delimiter(@sales_quotation_header.total_amount)]
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
	pdf.number_pages "[#{t 'sales_quotation'} - #{t 'date_print'}: #{Date.today.strftime("%d/%m/%Y")} - #{t 'print_by'}: #{@employee}]", :size => 8, :at => [0, 0]
end
pdf.number_pages "(<page>/<total>)", :size => 8, :at => [510, 0]