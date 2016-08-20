@company = Company.last

font_families.update("Verdana" => {
    :normal => "#{Rails.root}/public/assets/fonts/Verdana.ttf",
    :italic => "#{Rails.root}/public/assets/fonts/Verdana_Italic.ttf",
    :bold => "#{Rails.root}/public/assets/fonts/Verdana_Bold.ttf",
    :bold_italic => "#{Rails.root}/public/assets/fonts/Verdana_Bold_Italic.ttf"
})

headers = [[{:content => "#{t 'sales_invoice'}".upcase, :colspan => 4 }]]
headers += [["No", ":", "#{@sales_invoice_header.si_id}", "", "KEPADA YTH :"]]
headers += [["#{t 'dates'}", ":", "#{@sales_invoice_header.sales_invoice_date.strftime('%d-%b-%Y')}", "", "#{@sales_invoice_header.customer.try(:name)}"]]
headers += [["Sales", ":", "#{@sales_invoice_header.customer.sales_name(@sales_invoice_header.try(:sales_id))}", "", "#{@sales_invoice_header.customer.try(:address)}"]]
headers += [["#{t 'due_date'}", ":", "#{@sales_invoice_header.due_date.strftime('%d-%b-%Y') if @sales_invoice_header.due_date}#{'-' if @sales_invoice_header.due_date.blank?}", "", "#{@sales_invoice_header.customer.try(:city).try(:name)}"]]

pdf.table(headers, :width => 570, :header => true, :cell_style => { :font => "Verdana", :padding => [1,1,1,1]}) do
        self.column_widths = {0=>56, 1=>6, 2=>180, 3=>6, 4=>322}
        row(0..4).font_style = :bold
        row(0).size = 10
        rows(1..3).size = 8
        rows(1..3).columns(0..2).align = :left
        row(4).size = 8
        #row(4).columns(0..2).font_style = :bold
        columns(0..4).borders = []
end

i=0; sum_qty=0
details = [["QTY", "ITEMS", "HARGA", "DISKON", "TOTAL"]]
details += @sales_invoice_details.map do |detail|
        i+=1; sum_qty+=detail.quantity.to_f
        [
            delimiter(detail.quantity),
            detail.product.try(:name),
            "Rp #{delimiter(detail.price.to_f)}",
            "#{delimiter(detail.discount_item.to_f)} %",
            "Rp #{delimiter((detail.quantity.to_f*detail.price.to_f).to_f)}"
        ]
end

details += [["", "", "", "", ""]] * (6-@sales_invoice_details.count)

details += [
        [delimiter(sum_qty), {:content => "", :colspan => 2}, "SUBTOTAL", "Rp #{delimiter(@total_amount.to_f.round)}"],
        [{:content => "* Barang yang sudah dibeli tidak dapat dikembalikan/ditukar
                       #{@sales_invoice_header.notes}", :colspan => 3, :rowspan => 3}, "DISKON", "Rp #{delimiter(@total_discount.to_f)}"],
        ["PPN", "Rp #{delimiter(@sales_invoice_header.tax_amount.floor)}"],
        ["TOTAL", "Rp #{delimiter(@sales_invoice_header.total_amount.floor)}"]]


pdf.table(details, :width => 570, :header => true, :cell_style => { :font => "Verdana", :size => 8, :padding => [0, 1, 1, 1], :height => 10}) do
        self.column_widths = {0=>30, 1=>270, 2=>90, 3=>70, 4=>110}
        row(0).font_style = :bold
        columns(0).align = :center
        columns(1).align = :left
        columns(2..4).align = :right
        rows(0).columns(0..4).align = :center
        rows(1..6).columns(0..4).borders = [:left, :right]
        rows(6+1..6+4).font_style = :bold
        #rows(6+1..6+4).columns(4..5).background_color = "F5F5F5"
        rows(6+2..6+4).columns(0..2).align = :left
        rows(6+1..6+4).columns(4).align = :right
        rows(6+1..6+4).columns(5).align = :right
        #rows(6+4).columns(0..3).borders = [:top, :right]
end

footer = [
        ["Hormat Kami,", "", "", ""]]

pdf.table(footer, :width => 570, :header => true, :cell_style => { :font => "Verdana", :size => 8, :padding => [1, 1, 1, 1], :height => 10}) do
        self.column_widths = {0=>70, 1=>70, 2=>340, 3=>90}
        row(1).height = 25
        row(0).align = :center
        row(0).borders = []
end
