require_dependency "contract/application_controller"

module Contract
  class SalesQuotationDetailsController < ApplicationController
    before_filter :get_sales_quotation_header, :only => [:new, :edit, :create, :update, :destroy, :get_sales_quotation_details]
    before_filter :get_sales_quotation_detail, :only => [:show_materials]
    before_filter :get_unit_of_measures, :only => [:new, :edit]

    # GET /sales_quotation_details/1/show_materials
    def show_materials
      soh_id = SalesQuotationDetail.find(params[:id]).sales_quotation_header_id
      @sales_quotation_header = SalesQuotationHeader.find(soh_id)
      @sales_quotation_materials = @sales_quotation_detail.sales_quotation_materials.where(:sales_quotation_detail_id => params[:id])
      @sum_som = @sales_quotation_materials.sum(:amount)

      respond_to do |format|
        format.js
      end
    end

    # GET /sales_quotation_details/new
    # GET /sales_quotation_details/new.json
    def new
      @sales_quotation_detail = @sales_quotation_header.sales_quotation_details.new
    end
  
    # GET /sales_quotation_details/1/edit
    def edit
      @sales_quotation_detail = SalesQuotationDetail.find(params[:id])
    end
  
    # POST /sales_quotation_details
    # POST /sales_quotation_details.json
    def create
      @sales_quotation_detail = @sales_quotation_header.sales_quotation_details.new(params[:sales_quotation_detail])

      uom_name = UnitOfMeasure.find(params[:sales_quotation_detail][:unit_of_measure_id])

      # format create_log(subject, object, detail, employee_name)
      create_log("Create Detail", "Sales Quotation", "Create new detail with header id:#{@sales_quotation_header.sq_id}, 
        description:#{params[:sales_quotation_detail][:description]}, quantity:#{params[:sales_quotation_detail][:quantity]}, 
        unit:#{uom_name}, category:#{params[:sales_quotation_detail][:category]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_quotation_detail.save
          get_sales_quotation_details
          format.js
          format.json { render json: @sales_quotation_detail, status: :created, location: @sales_quotation_detail }
        else
          format.html { render action: "new" }
          format.json { render json: @sales_quotation_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /sales_quotation_details/1
    # PUT /sales_quotation_details/1.json
    def update
      @sales_quotation_detail = SalesQuotationDetail.find(params[:id])

      uom_name = UnitOfMeasure.find(params[:sales_quotation_detail][:unit_of_measure_id])

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Detail", "Sales Quotation", "Update detail with header id:#{@sales_quotation_header.sq_id}, 
        description from:#{@sales_quotation_detail.description} to:#{params[:sales_quotation_detail][:description]}, 
        quantity from:#{@sales_quotation_detail.quantity} to:#{params[:sales_quotation_detail][:quantity]}, 
        unit:#{@sales_quotation_detail.unit_of_measure.try(:name)} to:#{uom_name}, 
        category:#{@sales_quotation_detail.category} to:#{params[:sales_quotation_detail][:category]}.".strip, current_user.full_name)
  
      respond_to do |format|
        if @sales_quotation_detail.update_attributes(params[:sales_quotation_detail])
          get_sales_quotation_details
          format.js
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @sales_quotation_detail.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /sales_quotation_details/1
    # DELETE /sales_quotation_details/1.json
    def destroy
      @sales_quotation_detail = SalesQuotationDetail.find(params[:id])
      @sales_quotation_detail.destroy
      @sales_quotation_header = SalesQuotationHeader.find(@sales_quotation_detail.sales_quotation_header_id)

      # format create_log(subject, object, detail, employee_name)
      create_log("Destroy Detail", "Sales Quotation", "Destroy detail with header id:#{@sales_quotation_header.sq_id}, 
        description:#{@sales_quotation_detail.description}, quantity:#{@sales_quotation_detail.quantity}, 
        unit:#{@sales_quotation_detail.unit_of_measure.try(:name)}, category:#{@sales_quotation_detail.category}.".strip, current_user.full_name)

      get_sales_quotation_details
  
      respond_to do |format|
        format.js
        format.json { head :no_content }
      end
    end

    private
      def get_sales_quotation_header
        @sales_quotation_header = SalesQuotationHeader.find(params[:sales_quotation_header_id])
      end

      def get_sales_quotation_detail
        @sales_quotation_detail = SalesQuotationDetail.find(params[:id])
      end

      def get_sales_quotation_details
        @sales_quotation_categories = @sales_quotation_header.sales_quotation_details.select("DISTINCT(contract_sales_quotation_details.category)")
                                .order(:category)
        @sales_quotation_details = @sales_quotation_header.sales_quotation_details.order(:id)
        @sales_quotation_materials = SalesQuotationMaterial.where(:sales_quotation_detail_id => params[:id])
      end

      def get_sales_material_details
        @sales_quotation_materials = SalesQuotationMaterial.where(:sales_quotation_detail_id => params[:id])
      end
  end
end
