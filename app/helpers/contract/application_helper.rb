module Contract
  module ApplicationHelper
  	def delimiter(number)
	    number_with_precision(number.to_f, :delimiter => ",", :separator => ".", :precision => 2)
	end

	def date_without_localtime(date)
	    return date.to_time.strftime("%d-%m-%Y") if date
	end
  end
end
