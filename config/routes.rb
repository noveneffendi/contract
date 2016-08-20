Contract::Engine.routes.draw do
	postable = Proc.new do
	    member do
	      get :status_post
	      get :status_void
	      get :show_post_void
	    end
	end

	noteable = Proc.new do
	    member do
	      get :view_note
	    end
	end

	reportable = Proc.new do
	    collection do
	      get :report_filter
	      get :report
	    end
	end

	revisable = Proc.new do
    	member do
      		get :revise
    	end
  	end

  	discountable = Proc.new do
    	member do
      		get :add_discount
      		put :add_discount_put
    	end
  	end

  	with_options except: :destroy do |list_except|
		with_options except: [:index, :show] do |list_detail|
			list_except.resources :other_sales_invoice_headers do
				list_detail.resources :other_sales_invoice_details
				reportable.call
		        noteable.call
		        discountable.call
		        revisable.call
		        postable.call
		        member do 
		          get :show_triple
		        end
		        collection { post :import }
			end

			list_except.resources :sales_invoice_headers do
				list_detail.resources :sales_invoice_details do
					list_detail.resources :sales_invoice_materials
					list_detail.resources :sales_invoice_costs
				end
				collection do
		        	get :cross_tab_report_filter
		        	get :cross_tab_report
		        	get :cross_tab_report_income_filter
		        	get :cross_tab_report_income
		        	get :tax_invoice_filter
		        	get :tax_invoice
		        	get :tax_invoice_report
		        	get :unpaid_invoice
		        	get :paid_invoices
		        end
		        member do
		        	get :view_delivery
		        	get :show_triple
		        end
		        reportable.call
		        noteable.call
		        discountable.call
		        postable.call
		        revisable.call
			end

			list_except.resources :sales_quotation_headers do
				list_detail.resources :sales_quotation_details do
					list_detail.resources :sales_quotation_materials
					member do
						get :show_materials
					end
				end
				list_detail.resources :sales_quotation_costs
				collection do
		        	get :unfinish_report_filter
		        	get :unfinish_report
		        	get :cross_tab_report_filter
		        	get :cross_tab_report
		        end
		        member do
		        	get :approval_notes
		        	put :approval_status
		        end
		        reportable.call
		        noteable.call
		        discountable.call
		        postable.call
		        revisable.call
			end
	  	end
	end

	match "*module/sales_quotation_materials/:sales_quotation_detail_id/so_detail_by_product" => "sales_quotation_materials#so_detail_by_product"

	get "*module/sales_quotation_headers/sq_id_by_customer" => "sales_quotation_headers#sq_id_by_customer"
end
