require_dependency "contract/application_controller"

module Contract
  class OtherSalesInvoiceDetailsController < ApplicationController
    before_filter :set_other_sales_invoice_header, only: [:new, :edit, :create, :update, :destroy]
    before_filter :set_other_sales_invoice_detail, only: [:edit, :update, :destroy]

    def get_data
      @other_sales_invoice_details = @other_sales_invoice_header.other_sales_invoice_details.order(:id)
    end
    # GET /other_sales_invoice_details/new
    # GET /other_sales_invoice_details/new.json
    def new
      @other_sales_invoice_detail = OtherSalesInvoiceDetail.new

      respond_to do |format|
        format.json { render json: @other_sales_invoice_detail }
        format.js
      end
    end

    # GET /other_sales_invoice_details/1/edit
    def edit
    
    end

    # POST /other_sales_invoice_details
    # POST /other_sales_invoice_details.json
    def create
      @other_sales_invoice_detail = OtherSalesInvoiceDetail.new(params[:other_sales_invoice_detail])

      description = params[:other_sales_invoice_detail][:description]
      quantity = params[:other_sales_invoice_detail][:quantity].to_f
      price = params[:other_sales_invoice_detail][:price].to_f
      discount_item = params[:other_sales_invoice_detail][:discount_item].to_f
      discount_item_price = params[:other_sales_invoice_detail][:discount_item_price].to_f

      amount = (quantity.to_f*price.to_f) - ((discount_item.to_f/100)*(quantity.to_f*price.to_f.to_f)) - discount_item_price.to_f

      @other_sales_invoice_detail = @other_sales_invoice_header.other_sales_invoice_details.create(:description => description, 
                                                                                 :quantity => quantity.to_f, 
                                                                                 :price => price.to_f, 
                                                                                 :discount_item => discount_item.to_f, 
                                                                                 :discount_item_price => discount_item_price.to_f,
                                                                                 :total_amount => amount.to_f)

      @subtotal_amount = OtherSalesInvoiceDetail.find(:all, 
          :select => "sum(contract_other_sales_invoice_details.total_amount) as sdetail_amount", :joins => [:other_sales_invoice_header], 
          :conditions => ["contract_other_sales_invoice_details.other_sales_invoice_header_id= ?", @other_sales_invoice_header.id.to_s]).last.sdetail_amount

      amount_before_tax = @subtotal_amount.to_f - ((@other_sales_invoice_header.discount.to_f/100)*@subtotal_amount.to_f) - @other_sales_invoice_header.discount_amount.to_f

      if @sales_price_include_tax == 1
        @tax_amount = amount_before_tax.to_f * 0.1
        @tax_status = true
      else
        @tax_amount = 0
        @tax_status = false
      end
    
      @total_amount = amount_before_tax + @tax_amount.to_f

      @other_sales_invoice_header.update_attributes(:amount => amount_before_tax.to_f, :tax_amount => @tax_amount.to_f, :tax => @tax_status,
          :total_amount => @total_amount.to_f, :outstanding_total_amount => @total_amount.to_f)

      get_data

      # format create_log(subject, object, detail, employee_name)
      create_log("Create Detail", "Other Sales Invoice", "Create new detail with header id:#{@other_sales_invoice_header.si_id}, 
        description:#{@other_sales_invoice_detail.description}, quantity:#{@other_sales_invoice_detail.quantity}, 
        price:#{@other_sales_invoice_detail.price}, disc price:#{@other_sales_invoice_detail.discount_item_price}, 
        disc:#{@other_sales_invoice_detail.discount_item}, total:#{@other_sales_invoice_detail.total_amount}.", current_user.full_name)

      respond_to do |format|
        format.js
      end
    end

    # PUT /other_sales_invoice_details/1
    # PUT /other_sales_invoice_details/1.json
    def update
      description = @other_sales_invoice_detail.description
      quantity = @other_sales_invoice_detail.quantity.to_f
      price = @other_sales_invoice_detail.price.to_f
      discount_item = @other_sales_invoice_detail.discount_item.to_f
      discount_item_price = @other_sales_invoice_detail.discount_item_price.to_f

      amount=(quantity*price)-((quantity*price)*(discount_item.to_f/100))-discount_item_price.to_f
      total_amount = @other_sales_invoice_detail.total_amount.to_f

      respond_to do |format|
        if @other_sales_invoice_detail.update_attributes(params[:other_sales_invoice_detail])
          @other_sales_invoice_detail.update_attributes(:total_amount => amount.to_f)

          @subtotal_amount = OtherSalesInvoiceDetail.find(:all, 
            :select => "sum(contract_other_sales_invoice_details.total_amount) as sdetail_amount", 
            :joins => [:other_sales_invoice_header], 
            :conditions => ["contract_other_sales_invoice_details.other_sales_invoice_header_id = ?", @other_sales_invoice_header.id.to_s]).last.sdetail_amount

          amount_before_tax = @subtotal_amount.to_f - ((@other_sales_invoice_header.discount.to_f/100)*@subtotal_amount.to_f) - @other_sales_invoice_header.discount_amount.to_f

          if @sales_price_include_tax == 1
            @tax_amount = amount_before_tax.to_f*0.1
            @tax_status = true
          else
            @tax_amount = 0
            @tax_status = false
          end

          @total_amount = amount_before_tax.to_f + @tax_amount.to_f

          @other_sales_invoice_header.update_attributes(:amount => amount_before_tax.to_f, :tax_amount => @tax_amount.to_f, 
            :total_amount => @total_amount, :tax => @tax_status, :outstanding_total_amount => @total_amount)

          # format create_log(subject, object, detail, employee_name)
          create_log("Update Detail", "Other Sales Invoice", "Update detail with header id:#{@other_sales_invoice_header.si_id}, 
            description:#{@other_sales_invoice_detail.description}, quantity from:#{quantity} to:#{@other_sales_invoice_detail.quantity}, 
            price from:#{price} to:#{@other_sales_invoice_detail.price}, disc price from:#{discount_item_price} to:#{@other_sales_invoice_detail.discount_item_price}, 
            disc from:#{discount_item} to:#{@other_sales_invoice_detail.discount_item}, total from:#{total_amount} to:#{@other_sales_invoice_detail.total_amount}.", current_user.full_name)

          get_data
        end
        format.js
      end
    end

    # DELETE /other_sales_invoice_details/1
    # DELETE /other_sales_invoice_details/1.json
    def destroy
      # format create_log(subject, object, detail, employee_name)
      create_log("Destroy Detail", "Other Sales Invoice", "Destroy detail with header id:#{@other_sales_invoice_header.si_id}, 
        description:#{@other_sales_invoice_detail.description}, quantity:#{@other_sales_invoice_detail.quantity}, 
        price:#{@other_sales_invoice_detail.price}, disc price:#{@other_sales_invoice_detail.discount_item_price}, 
        disc:#{@other_sales_invoice_detail.discount_item}, total:#{@other_sales_invoice_detail.total_amount}.", current_user.full_name)

      @other_sales_invoice_detail.destroy

      @other_sales_invoice_details = OtherSalesInvoiceDetail.find(:all, 
          :conditions => ["contract_other_sales_invoice_details.other_sales_invoice_header_id = ?", @other_sales_invoice_header.id.to_i], 
          :order => "contract_other_sales_invoice_details.created_at")

      @subtotal_amount = OtherSalesInvoiceDetail.find(:all, :select => "sum(contract_other_sales_invoice_details.total_amount) as sdetail_amount", 
        :joins => [:other_sales_invoice_header], 
        :conditions => ["contract_other_sales_invoice_details.other_sales_invoice_header_id= ?", @other_sales_invoice_header.id.to_i]).last.sdetail_amount

      amount_before_tax = @subtotal_amount.to_f - ((@other_sales_invoice_header.discount.to_f/100)*@subtotal_amount.to_f) - @other_sales_invoice_header.discount_amount.to_f

      if @other_sales_invoice_header.tax==true
        @tax_amount = amount_before_tax.to_f*0.1
      else
        @tax_amount = 0
      end

      @total_amount = amount_before_tax + @tax_amount.to_f

      @other_sales_invoice_header.update_attributes(:amount => amount_before_tax.to_f, :tax_amount => @tax_amount.to_f, 
        :total_amount => @total_amount.to_f, :outstanding_total_amount => @total_amount.to_f)

      get_data

      respond_to do |format|
        format.js
      end
    end

    private
      def set_other_sales_invoice_header
        @other_sales_invoice_header = OtherSalesInvoiceHeader.find(params[:other_sales_invoice_header_id])
      end
    
      def set_other_sales_invoice_detail
        @other_sales_invoice_detail = OtherSalesInvoiceDetail.find(params[:id])
      end
  end
end
