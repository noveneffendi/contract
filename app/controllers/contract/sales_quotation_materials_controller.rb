require_dependency "contract/application_controller"

module Contract
  class SalesQuotationMaterialsController < ApplicationController
    before_filter :get_sales_quotation_header, :only => [:new, :edit, :create, :update, :destroy]
    before_filter :get_sales_quotation_detail, :only => [:new, :edit, :create, :update, :destroy]
    before_filter :get_unit_of_measures, :only => [:new, :edit]
    before_filter :get_products, :only => [:new, :edit]

    # GET /sales_quotation_materials/new
    # GET /sales_quotation_materials/new.json
    def new
      @sales_quotation_material = @sales_quotation_detail.sales_quotation_materials.new
      # get_sales_quotation_header
  
      respond_to do |format|
        format.js
      end
    end
  
    # GET /sales_quotation_materials/1/edit
    def edit
      @sales_quotation_material = SalesQuotationMaterial.find(params[:id])
    end
  
    # POST /sales_quotation_materials
    # POST /sales_quotation_materials.json
    def create
      @sales_quotation_material = @sales_quotation_detail.sales_quotation_materials.new(params[:sales_quotation_material])
  
      respond_to do |format|
        if @sales_quotation_material.save
          refresh_sales_quotation_material_data

          get_sales_quotation_header

          # format create_log(subject, object, detail, employee_name)
          create_log("Create Material", "Sales Quotation", "Create new material with header id:#{@sales_quotation_header.sq_id}, 
              product:#{@sales_quotation_material.product.try(:name)}, quantity:#{params[:sales_quotation_material][:quantity]}, 
              unit:#{@sales_quotation_material.unit_of_measure.try(:name)}, price:#{params[:sales_quotation_material][:price]}, 
              disc price:#{params[:sales_quotation_material][:discount_item_price]}, disc:#{params[:sales_quotation_material][:discount_item]}, 
              total:#{params[:sales_quotation_material][:amount]}.".strip, current_user.full_name)

          format.js
          # format.html { redirect_to @sales_quotation_material, notice: 'Sales order material was successfully created.' }
          format.json { render json: @sales_quotation_material, status: :created, location: @sales_quotation_material }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_quotation_material.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_quotation_materials/1
    # PUT /sales_quotation_materials/1.json
    def update
      @sales_quotation_material = SalesQuotationMaterial.find(params[:id])

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Detail", "Sales Quotation", "Update detail with header id:#{@sales_quotation_header.sq_id}, 
        product:#{@sales_quotation_material.product.try(:name)}, 
        quantity from:#{@sales_quotation_material.quantity} to:#{params[:sales_quotation_material][:quantity]}, 
        unit:#{@sales_quotation_material.unit_of_measure.try(:name)}, 
        price from:#{@sales_quotation_material.price} to:#{params[:sales_quotation_material][:price]}, 
        disc price from:#{@sales_quotation_material.discount_item_price} to:#{params[:sales_quotation_material][:discount_item_price]}, 
        disc from:#{@sales_quotation_material.discount_item} to:#{params[:sales_quotation_material][:discount_item]}, 
        total from:#{@sales_quotation_material.amount} to:#{params[:sales_quotation_material][:amount]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_quotation_material.update_attributes(params[:sales_quotation_material])
          refresh_sales_quotation_material_data
          format.js
          # format.html { redirect_to @sales_quotation_material, notice: 'Sales order material was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_quotation_material.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_quotation_materials/1
    # DELETE /sales_quotation_materials/1.json
    def destroy
      @sales_quotation_material = SalesQuotationMaterial.find(params[:id])
      @sales_quotation_material.destroy

      refresh_sales_quotation_material_data

      get_sales_quotation_header
  
      respond_to do |format|
        # format.html { redirect_to sales_quotation_materials_url }
        format.js
        format.json { head :no_content }
      end
    end

    def sq_detail_by_product
      product_id = params[:product_id].to_i
      warehouse_id = params[:warehouse_id].to_i
      sq_id = params[:sq_id]

      @uoms = ProductConversion.select("product_conversions.unit_of_measure_id id, unit_of_measures.name")
              .joins("LEFT JOIN unit_of_measures ON product_conversions.unit_of_measure_id = unit_of_measures.id")
              .where("product_conversions.product_id = ?", params[:product_id].to_i)

      if (product_id!=0 && warehouse_id!=0) && params[:so_id].present? 
        @product = SalesQuotationDetail
        .select("sales_quotation_details.*, u.name uom_name, COALESCE(s.end_qty_ready,0) end_qty_ready, COALESCE(s.end_quantity,0) end_quantity, s.unit_of_measure_id stock_uom")
        .joins("INNER JOIN sales_quotation_headers soh ON sales_quotation_details.sales_quotation_header_id = soh.id")
        .joins("LEFT OUTER JOIN stock_on_hand_headers s ON sales_quotation_details.product_id = s.product_id")
        .joins("LEFT OUTER JOIN unit_of_measures u ON sales_quotation_details.unit_of_measure_id = u.id")
        .where("soh.sq_id = ? AND sales_quotation_details.product_id = ? AND s.warehouse_id = ?", sq_id, product_id, warehouse_id).last
      else
        @product = SalesQuotationDetail
        .select("sales_quotation_details.*, u.name uom_name, COALESCE(s.end_qty_ready,0) end_qty_ready, COALESCE(s.end_quantity,0) end_quantity, s.unit_of_measure_id stock_uom")
        .joins("INNER JOIN sales_quotation_headers soh ON sales_quotation_details.sales_quotation_header_id = soh.id")
        .joins("LEFT OUTER JOIN stock_on_hand_headers s ON sales_quotation_details.product_id = s.product_id")
        .joins("LEFT OUTER JOIN unit_of_measures u ON sales_quotation_details.unit_of_measure_id = u.id")
        .where("sales_quotation_details.id = ?", 0).last
      end

      respond_to do |format|
        format.js
      end
    end

    private
      def get_sales_quotation_header
        @sales_quotation_header = SalesQuotationHeader.find(params[:sales_quotation_header_id])
        # soh_id = SalesQuotationDetail.find(@sales_quotation_material.sales_quotation_detail_id).sales_quotation_header_id
        # @sales_quotation_header = SalesQuotationHeader.find(soh_id)
      end

      def get_sales_quotation_detail
        @sales_quotation_detail = SalesQuotationDetail.find(params[:sales_quotation_detail_id])
      end

      def show_sales_quotation_materials
        @sales_quotation_materials = @sales_quotation_header.sales_quotation_materials.order(:id)
      end

      def refresh_sales_quotation_material_data
        @sales_quotation_materials = SalesQuotationMaterial.where(:sales_quotation_detail_id => @sales_quotation_material.sales_quotation_detail_id)
        @sum_som = @sales_quotation_materials.sum(:amount)    
      end
  end
end
