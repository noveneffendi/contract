require_dependency "contract/application_controller"
require_dependency "contract/authorize"

module Contract
  class OtherSalesInvoiceHeadersController < ApplicationController
    before_filter :set_other_sales_invoice_header, only: [:show, :edit, :update, :status_post, :status_void, :add_discount, :add_discount_put, :show_post_void, :view_note, :show_triple, :revise, :view_delivery]
    before_filter :set_tax_type, only: [:index, :show, :new, :edit, :revise, :create, :update, :add_discount, :add_discount_put, :status_post, :status_void, :show_post_void]
    before_filter :get_sales_person, only: [:new, :edit]
    before_filter :get_currencies, only: [:new, :edit, :status_post, :status_void]
    before_filter :get_customer, only: [:status_post, :status_void]
    respond_to :js, :only => [:view_note, :add_discount, :add_discount_put, :si_id_by_customer]
    # GET /other_sales_invoice_headers
    # GET /other_sales_invoice_headers.json
    def index
      if params[:date].blank?
        @other_sales_invoice_headers = OtherSalesInvoiceHeader.where("date_part('month', sales_invoice_date)=date_part('month', current_date) and date_part('year', sales_invoice_date)=date_part('year', current_date)")
      else
        @other_sales_invoice_headers = OtherSalesInvoiceHeader.order("si_id DESC").search_month(params[:date][:month]).search_year(params[:date][:year]).search_amount(params[:start_amount], params[:end_amount]).search_customer(params[:customer].to_i).search_status(params[:status]).search_currency(params[:currency])
      end

      if @tax_type.to_s == 'x' # NON TAX
        @other_sales_invoice_headers = @other_sales_invoice_headers.where("si_id like ?", "#{OT_SI_PREFIX_NON_TAX}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
      elsif @tax_type.to_s == 'l' # WITH TAX
        @other_sales_invoice_headers = @other_sales_invoice_headers.where("si_id like ?", "#{OT_SI_PREFIX_TAX}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
      else # if unknown params
        if @split_tax_and_non_tax_transaction == 1
          # redirect_to home_path
          # return
          @other_sales_invoice_headers = @other_sales_invoice_headers.where("si_id like ?", "#{OT_SI_PREFIX_DEFAULT}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
        else
          @other_sales_invoice_headers = @other_sales_invoice_headers.where("si_id like ?", "#{OT_SI_PREFIX_DEFAULT}%").order("si_id DESC").paginate(:per_page => 20, :page => params[:page])
        end
      end

      @customers = Customer.all

      if @tax_type.to_s.present?
        @can_print = load_additional_resource('/contract/other_sales_invoice_headers?tt='"#{params[:tt].to_s}",0)
      else
        @can_print = load_additional_resource('/contract/'"#{controller_name}",0)
      end

      respond_to do |format|
        format.html # index.html.erb
        format.js
      end
    end

    # GET /other_sales_invoice_headers/1
    # GET /other_sales_invoice_headers/1.json
    def show
      @other_sales_invoice_details = @other_sales_invoice_header.other_sales_invoice_details.order(:created_at)
      @status_help=0

      @total_discount = 0; @total_amount = 0
      @other_sales_invoice_details.each do |sid|
        @total_discount += sid.discount_amount.to_f
        @total_amount += sid.quantity.to_f * sid.price.to_f
      end

      prawnto :prawn => { :page_size => [595.28, 420.95], :page_layout => :portrait, :top_margin => 5, :left_margin => 10, :bottom_margin => 20 }, :inline => true

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @other_sales_invoice_header }
        format.pdf
      end
    end

    # GET /other_sales_invoice_headers/new
    # GET /other_sales_invoice_headers/new.json
    def new
      get_currencies
      @other_sales_invoice_header = OtherSalesInvoiceHeader.new
      @other_sales_invoice_header.sales_invoice_date = Date.today.strftime("%d-%m-%Y")
      @other_sales_invoice_header.currency_id = @default_currency
      @other_sales_invoice_header.exchrate = @default_rate
      @other_sales_invoice_header.status = 0
      @other_sales_invoice_header.due_date = Date.today.strftime("%d-%m-%Y")
      @other_sales_invoice_header.employee_name = current_user.full_name

      @sq_ids = SalesQuotationHeader.posted.order(:sq_id)

      # date_editor
      @readonly = false

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @other_sales_invoice_header }
      end
    end

    # GET /other_sales_invoice_headers/1/edit
    def edit
      @other_sales_invoice_header.employee_name = current_user.full_name

      @sq_ids = SalesQuotationHeader.posted.sq_has_not_invoiced.not_close
                  .where("contract_sales_quotation_headers.customer_id = ?", @other_sales_invoice_header.customer_id)
                  .uniq.order(:sq_id).reverse_order

      # date_editor
      @readonly = false
    end

    # POST /other_sales_invoice_headers
    # POST /other_sales_invoice_headers.json
    def create
      @other_sales_invoice_header = OtherSalesInvoiceHeader.new(params[:other_sales_invoice_header])

      @other_sales_invoice_header.si_id = OtherSalesInvoiceHeader.other_si_header_id(params[:other_sales_invoice_header][:sales_invoice_date].to_date, @tax_type)
      tax = FALSE
    
      if @split_tax_and_non_tax_transaction == 1
        if @tax_type == 'l'
          tax = TRUE
        else
          tax = FALSE
        end
      end

      respond_to do |format|
        if @other_sales_invoice_header.save
          # format create_log(subject, object, detail, employee_name)
          create_log("Create Header", "Other Sales Invoice", "Create new header with id:#{@other_sales_invoice_header.si_id}, customer:#{@other_sales_invoice_header.customer.try(:name)}, due date:#{@other_sales_invoice_header.due_date}, notes:#{@other_sales_invoice_header.notes}.", current_user.full_name)

          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header, :tt => @tax_type), notice: "#{t 'sales_invoice'} #{t 'created'}" }
          else
            format.html { redirect_to @other_sales_invoice_header, notice: "#{I18n.t 'sales_invoice'} #{I18n.t 'created'}" }
          end
        else
          format.html { render action: "new" }
        end
      end
    end

    # PUT /other_sales_invoice_headers/1
    # PUT /other_sales_invoice_headers/1.json
    def update
      customer_id = @other_sales_invoice_header.customer_id
      customer = @other_sales_invoice_header.customer.try(:name)
      notes = @other_sales_invoice_header.notes
      amount = @other_sales_invoice_header.amount
      discount = @other_sales_invoice_header.discount
      discount_amount = @other_sales_invoice_header.discount_amount
      tax = @other_sales_invoice_header.tax
      tax_amount = @other_sales_invoice_header.tax_amount
      total_amount = @other_sales_invoice_header.total_amount
      notes = @other_sales_invoice_header.notes

      respond_to do |format|
        if @other_sales_invoice_header.si_id[5,2].to_i == params[:other_sales_invoice_header][:sales_invoice_date].to_date.strftime("%m").to_i
          if @other_sales_invoice_header.update_attributes(params[:other_sales_invoice_header])
            # format create_log(subject, object, detail, employee_name)
            create_log("Update Header", "Other Sales Invoice", "Update header with id:#{@other_sales_invoice_header.si_id}, customer from:#{customer} to:#{@other_sales_invoice_header.customer.try(:name)}, amount from:#{amount} to:#{@other_sales_invoice_header.amount}, disc(%) from:#{discount} to:#{@other_sales_invoice_header.discount}, disc(Rp) from:#{discount_amount} to:#{@other_sales_invoice_header.discount_amount}, tax from:#{tax} to:#{@other_sales_invoice_header.tax}, tax amount from:#{tax_amount} to:#{@other_sales_invoice_header.tax_amount}, total from:#{total_amount} to:#{@other_sales_invoice_header.total_amount}, notes from:#{} to:#{@other_sales_invoice_header.notes}", current_user.full_name)

            if @split_tax_and_non_tax_transaction == 1
              format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header, :tt => @tax_type), notice: "#{t 'sales_invoice'} #{t 'updated'}" }
            else
              format.html { redirect_to @other_sales_invoice_header, notice: "#{t 'sales_invoice'} #{t 'updated'}" }
            end
          else
            format.html { render action: "edit" }
            format.json { render json: @other_sales_invoice_header.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id), notice: "#{t 'warning.different_date_with_id'}" }
        end
      end
    end

    def add_discount
      @tax_status = get_tax_status(params[:tt].to_s)
    end

    def add_discount_put
      # GET DATA BEFORE UPDATED FOR LOG
      discount_old=@other_sales_invoice_header.discount
      discount_amount_old=@other_sales_invoice_header.discount_amount
      tax_old=@other_sales_invoice_header.tax
      tax_amount_old=@other_sales_invoice_header.tax_amount
      total_amount_old=@other_sales_invoice_header.total_amount
      # END GET DATA BEFORE UPDATED FOR LOG

      # promo disc
      discount = params[:other_sales_invoice_header][:discount].to_f
      discount_amount = params[:other_sales_invoice_header][:discount_amount].to_f

      tax = params[:other_sales_invoice_header][:tax]

      amount_before_tax = @other_sales_invoice_header.amount.to_f - ((discount.to_f/100)*@other_sales_invoice_header.amount.to_f) - discount_amount.to_f

      if @tax_type.to_s == 'l' || params[:other_sales_invoice_header][:tax] == "true"
        tax_amount = amount_before_tax.to_f * 0.1
      else
        tax_amount = 0
      end

      total_amount = amount_before_tax.to_f + tax_amount.to_f

      @other_sales_invoice_header.update_attributes(:discount => discount, :discount_amount => discount_amount, :tax => tax, :tax_amount => tax_amount, :total_amount => total_amount)

      # format create_log(subject, object, detail, employee_name)
      create_log("Update Header", "Other Sales Invoice", "Update discount header with id:#{@other_sales_invoice_header.si_id}, 
        amount:#{@other_sales_invoice_header.amount}, disc(%) from:#{discount_old} to:#{@other_sales_invoice_header.discount}, 
        disc(Rp) from:#{discount_amount_old} to:#{@other_sales_invoice_header.discount_amount}, 
        tax from:#{tax_old} to:#{@other_sales_invoice_header.tax}, tax amount from:#{tax_amount_old} to:#{@other_sales_invoice_header.tax_amount}, 
        total from:#{total_amount_old} to:#{@other_sales_invoice_header.total_amount}.}", current_user.full_name)
    end

    def status_post
      if @other_sales_invoice_header.status == 0
        description = "Penjualan dengan nomor transaksi #{@other_sales_invoice_header.si_id} dari Customer #{@other_sales_invoice_header.customer.name}"
        # for application module_type with Accounting process
        # Update tax transaction
        if @module_type == 2 || @module_type == 3
          if @other_sales_invoice_header.tax == true 
            # cek ppn keluaran
            # sales_tax_account = JournalDiscTax.where(:description => 'Pajak/Tax').last.try(:chart_of_account_id)
            sales_tax_account = CurrencyStaticAccount.where(:description => 'Pajak/Tax Penjualan', 
                                :currency_id => @other_sales_invoice_header.currency_id).last.try(:chart_of_account_id)
            total_amount = @other_sales_invoice_header.total_amount / 1.1
          else
            total_amount = @other_sales_invoice_header.total_amount
          end

          receivable_account = @customer.customer_accounts.where(:currency_id => @other_sales_invoice_header.currency_id).last.account_receivable
          # Sales Account
          other_sales_account = CurrencyStaticAccount.where(:description => 'Penjualan Lain-lain', 
                                :currency_id => @other_sales_invoice_header.currency_id).last.try(:chart_of_account_id)

          # DEBET ACCOUNT
          create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, @other_sales_invoice_header.notes,
            (total_amount.to_f * @other_sales_invoice_header.exchrate.to_f), receivable_account, 'D', description, other_sales_account, 
            @other_sales_invoice_header.currency_id, @other_sales_invoice_header.exchrate, total_amount.to_f)
          general_ledger_balance(receivable_account, (total_amount.to_f * @other_sales_invoice_header.exchrate.to_f), 'D', @other_sales_invoice_header.sales_invoice_date)

          # CREDIT ACCOUNT
          create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, @other_sales_invoice_header.notes,
            (total_amount.to_f * @other_sales_invoice_header.exchrate.to_f), other_sales_account, 'C', description, receivable_account, 
            @other_sales_invoice_header.currency_id, @other_sales_invoice_header.exchrate, total_amount.to_f)
          general_ledger_balance(other_sales_account, (total_amount.to_f * @other_sales_invoice_header.exchrate.to_f), 'C', @other_sales_invoice_header.sales_invoice_date)

          if @other_sales_invoice_header.currency.try(:is_default) != true
            cross_receivable_account = ChartOfAccount.find(receivable_account).try(:acc_ref) 
            # cross_other_sales_account = ChartOfAccount.find(other_sales_account).try(:acc_ref)
            cross_other_sales_account = other_sales_account

            total_amount_conversion = total_amount.to_f * @other_sales_invoice_header.exchrate.to_f

            # OTHER PAYMENT DEBET ACCOUNT
            create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, @other_sales_invoice_header.notes,
              total_amount_conversion.to_f, cross_receivable_account, 'D', description, cross_other_sales_account, @default_currency, @default_rate, total_amount.to_f)
            general_ledger_balance(cross_receivable_account, total_amount_conversion.to_f, 'D', @other_sales_invoice_header.sales_invoice_date)

            # CROSS AP CREDIT ACCOUNT
            create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, @other_sales_invoice_header.notes,
              total_amount_conversion.to_f, cross_other_sales_account, 'C', description, cross_receivable_account, @default_currency, @default_rate, total_amount.to_f)
            general_ledger_balance(cross_other_sales_account, total_amount_conversion.to_f, 'C', @other_sales_invoice_header.sales_invoice_date)
          end

          # TAX SECTION JOURNAL
          if @other_sales_invoice_header.tax == true
            tax_amount = @other_sales_invoice_header.tax_amount
            # TAXES INPUT GL
            # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
            create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, 
              @other_sales_invoice_header.notes, (tax_amount * @other_sales_invoice_header.exchrate.to_f), sales_tax_account, 'D', description, receivable_account, 
              @other_sales_invoice_header.currency_id, @other_sales_invoice_header.exchrate, tax_amount.to_f)
            # format general_ledger_balance(coa_id, amount, transaction_status)
            general_ledger_balance(sales_tax_account, (tax_amount * @other_sales_invoice_header.exchrate.to_f), "D", @other_sales_invoice_header.sales_invoice_date)

            # AP INPUT GL
            # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
            create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, 
              @other_sales_invoice_header.notes, (tax_amount * @other_sales_invoice_header.exchrate.to_f), receivable_account, 'C', description, sales_tax_account, 
              @other_sales_invoice_header.currency_id, @other_sales_invoice_header.exchrate, tax_amount.to_f)
            # format general_ledger_balance(coa_id, amount, transaction_status)
            general_ledger_balance(receivable_account, (tax_amount * @other_sales_invoice_header.exchrate.to_f), "C", @other_sales_invoice_header.sales_invoice_date)
            # Check account currency equal with transaction currency
            # if @other_sales_invoice_header.currency_id == check_account_currency(sales_tax_account)
            if @other_purchase_invoice_header.currency.try(:is_default) != true
              tax_amount_conversion = @other_sales_invoice_header.tax_amount.to_f * @other_sales_invoice_header.exchrate  

              # TAXES DEBET GL
              # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
              create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, 
                @other_sales_invoice_header.notes, tax_amount_conversion.to_f, sales_tax_account, 'D', description, cross_receivable_account, 
                @default_currency, @default_rate, tax_amount.to_f)
              # format general_ledger_balance(coa_id, amount, transaction_status)
              general_ledger_balance(sales_tax_account, tax_amount_conversion.to_f, "D", @other_sales_invoice_header.sales_invoice_date)

              # CROSS AP CREDIT ACCOUNT
              # format create_gl(date, reference, notes, amount, coa, transaction_status, description)
              create_gl(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, 
                @other_sales_invoice_header.notes, tax_amount_conversion.to_f, cross_receivable_account, 'C', description, sales_tax_account, 
                @default_currency, @default_rate, tax_amount)
              # format general_ledger_balance(coa_id, amount, transaction_status)
              general_ledger_balance(cross_receivable_account, tax_amount_conversion.to_f, "C", @other_sales_invoice_header.sales_invoice_date)
            end
          end
        else # if module_type not accounting
          # create_account_receivable_transaction(transaction_date,ref_id,customer_id,amount,notes,transaction_status)
          create_account_receivable_transaction(@other_sales_invoice_header.sales_invoice_date, @other_sales_invoice_header.si_id, 
            @other_sales_invoice_header.customer_id, @other_sales_invoice_header.total_amount,description,'D')
        end # end of module_type

        @other_sales_invoice_header.update_attributes(:status => 1)
        # format create_log(subject, object, detail, employee_name)
        create_log("Post", "Other Sales Invoice", "Post header with id:#{@other_sales_invoice_header.si_id}, 
          customer:#{@other_sales_invoice_header.customer.try(:name)}, amount:#{@other_sales_invoice_header.amount}, 
          disc(%):#{@other_sales_invoice_header.discount}, disc(Rp):#{@other_sales_invoice_header.discount_amount}, 
          tax:#{@other_sales_invoice_header.tax}, tax amount:#{@other_sales_invoice_header.tax_amount}, 
          currency:#{@other_sales_invoice_header.currency.code}, exchange rate:#{@other_sales_invoice_header.exchrate}, 
          total:#{@other_sales_invoice_header.total_amount}, notes:#{@other_sales_invoice_header.notes}", current_user.full_name)
      
        if @split_tax_and_non_tax_transaction == 1
          redirect_to other_sales_invoice_headers_path(:tt => params[:tt].to_s)
        else
          redirect_to other_sales_invoice_headers_path
        end
      else
        respond_to do |format|
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id, :tt => params[:tt].to_s), notice: "#{t 'transaction_approved'}" }
          else
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id), notice: "#{t 'transaction_approved'}" }
          end
        end
      end
    end

    def status_void
      if @other_sales_invoice_header.status != 5
        description = "Proses void faktur penjualan dgn No.#{@other_sales_invoice_header.si_id}"

        if @module_type == 2 || @module_type == 3
          # create reversing transaction and GL entry.
          # FORMAT: reversing_gl_transaction(reference_id, updated_at, notes) => check on application_controller.rb
          reversing_gl_transaction(@other_sales_invoice_header.si_id, @other_sales_invoice_header.updated_at, description)
        else # inventory only
          create_account_receivable_transaction(@other_sales_invoice_header.updated_at, @other_sales_invoice_header.si_id,@other_sales_invoice_header.customer_id,
            total_amount, description,'C')
        end

        @other_sales_invoice_header.update_attributes(:status => 5)
        # format create_log(subject, object, detail, employee_name)
        create_log("Void", "Sales Invoice", "Void header with id:#{@other_sales_invoice_header.si_id}, customer:#{@other_sales_invoice_header.customer.try(:name)}, amount:#{@other_sales_invoice_header.amount}, disc(%):#{@other_sales_invoice_header.discount}, disc(Rp):#{@other_sales_invoice_header.discount_amount}, currency:#{@other_sales_invoice_header.currency.try(:code)}, exchange rate:#{@other_sales_invoice_header.exchrate}, tax:#{@other_sales_invoice_header.tax}, tax amount:#{@other_sales_invoice_header.tax_amount}, total:#{@other_sales_invoice_header.total_amount}, notes:#{@other_sales_invoice_header.notes}", current_user.full_name)

        respond_to do |format|
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to other_sales_invoice_headers_path(:tt => @tax_type.to_s), notice: "#{t 'sales_invoice'} #{t 'voided'}" }
          else
            format.html { redirect_to other_sales_invoice_headers_path, notice: "#{t 'sales_invoice'} #{t 'voided'}" }
          end
        end
      else
        respond_to do |format|
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id, :tt => params[:tt].to_s), notice: "#{t 'transaction_void'}" }
          else
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id), notice: "#{t 'transaction_void'}" }
          end
        end
      end
    end

    def report_generator(tt=nil)
      @other_sales_invoice_headers = OtherSalesInvoiceHeader.posted
                                      .report_period(params[:start_period].to_date, params[:end_period].to_date)
                                      .search_amount(params[:start_amount], params[:end_amount])
                                      .search_customer(params[:customer].to_i)

      if tt.to_s == 'x'
        @other_sales_invoice_headers = @other_sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_NON_TAX}%").order(:si_id)
      elsif tt.to_s == 'l'
        @other_sales_invoice_headers = @other_sales_invoice_headers.where("si_id like ?", "#{SI_PREFIX_TAX}%").order(:si_id)
      else
        @other_sales_invoice_headers = @other_sales_invoice_headers.order(:si_id)
      end

      header_ids=[]
      @other_sales_invoice_headers.each do |header|
        header_ids.push [header.id]
      end
      @other_sales_invoice_details = OtherSalesInvoiceDetail.where(:other_sales_invoice_header_id => [header_ids])

      @other_sales_invoices = []
      @total_rows = 0
      total = 0
      header_row = 0
      @other_sales_invoice_headers.each do |header|
        header_row+=1
        if header.tax==true
          tax="10%"
        else
          tax=''
        end
        @other_sales_invoices.push [header_row, 
          header.si_id, 
          header.so_id, 
          header.do_id, 
          date_without_localtime(header.sales_invoice_date), 
          header.customer.try(:name), 
          delimiter(header.amount), 
          delimiter(header.discount), 
          delimiter(header.discount_amount), 
          tax, 
          "", 
          delimiter(header.total_amount), 
          header.id]

        total+=header.total_amount.to_f
        @total_rows+=1
        @other_sales_invoice_details.each do |detail|
          if detail.other_sales_invoice_header_id==header.id
            qty = "#{delimiter(detail.quantity)} #{detail.unit_of_measure.try(:name)}"
            @other_sales_invoices.push ["", 
              detail.description, "", "", 
              qty, "(price:)", 
              delimiter(detail.price), 
              delimiter(detail.discount_item), 
              delimiter(detail.discount_item_price), "", 
              delimiter(detail.total_amount), "", ""]
            @total_rows+=1
          end
        end
      end
      @other_sales_invoices.push ["", "", "", "", "", "", "", "", "", "", "#{(t 'total').upcase}", delimiter(total), ""]
      @total_rows+=1
    end

    def report_filter
      if params[:start_period].present?
        if params[:tt].present?
          report_generator(params[:tt].to_s)
          @can_print = load_additional_resource('/other_sales_invoice_headers?tt='"#{params[:tt].to_s}",0)
        else
          report_generator
          @can_print = load_additional_resource('/'"#{controller_name}",0)
        end
      else
        @purchase_invoices = []
        @can_print = false
      end
      respond_to do |format|
        if params[:print]
          if params[:tt].present?
            format.html { redirect_to :action => "report", :format => "pdf", :start_period => params[:start_period].to_date, 
              :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount], :tt => params[:tt].to_s }
          else
            format.html { redirect_to :action => "report", :format => "pdf", :start_period => params[:start_period].to_date, 
              :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount] }
          end
        elsif params[:excel]
          if params[:tt].present?
            format.html { redirect_to :action => "report", :format => "xls", :start_period => params[:start_period].to_date, 
              :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount], :tt => params[:tt].to_s }
          else
            format.html { redirect_to :action => "report", :format => "xls", :start_period => params[:start_period].to_date, 
              :end_period => params[:end_period].to_date, :customer => params[:customer], :start_amount => params[:start_amount], 
              :end_amount => params[:end_amount] }
          end
        else
          format.html
        end
      end
    end

    def revise
      # check can revise role for current_user
      if @tax_type.to_s.present?
        can_revise = load_additional_resource('/other_sales_invoice_headers?tt='"#{@tax_type.to_s}",1)
      else
        can_revise = load_additional_resource('/'"#{controller_name}",1)
      end
    
      if can_revise == false
        raise CanCan::AccessDenied
      end

      # if not void
      if @other_sales_invoice_header.status != 5 && @other_sales_invoice_header.close == false
        @other_sales_invoice_header.revision_status = 1

        # Delete related transaction, G/L, A/P and stock
        revision_process(@other_sales_invoice_header.id)
      else
        respond_to do |format|
          if @split_tax_and_non_tax_transaction == 1
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id, :tt => @tax_type.to_s), notice: "#{t 'transaction_void'}" }
          else
            format.html { redirect_to other_sales_invoice_header_path(@other_sales_invoice_header.id), notice: "#{t 'transaction_void'}" }
          end
        end
      end
    end

    def revision_process(other_sales_invoice_header_id)
      other_sales_invoice_details = OtherSalesInvoiceDetail.where(:other_sales_invoice_header_id => @other_sales_invoice_header.id)
    
      # for module_type with accounting
      if @module_type == 2 || @module_type == 3
        # Delete G/L Transaction
        delete_general_ledger_transaction(@other_sales_invoice_header.si_id)
      else # inventory only
        delete_account_payable_transaction(@other_sales_invoice_header.si_id)
      end

      # set si status to entry
      @other_sales_invoice_header.update_attributes(:status => 0)
      # format create_log(subject, object, detail, employee_name)
      create_log("Revise", "Other Sales Invoice", "Revision header with id:#{@other_sales_invoice_header.si_id}, 
        customer:#{@other_sales_invoice_header.customer.try(:name)}, amount:#{@other_sales_invoice_header.amount}, 
        disc(%):#{@other_sales_invoice_header.discount}, disc(Rp):#{@other_sales_invoice_header.discount_amount}, 
        tax:#{@other_sales_invoice_header.tax}, tax amount:#{@other_sales_invoice_header.tax_amount}, 
        currency:#{@other_sales_invoice_header.currency.try(:code)}, exchange rate:#{@other_sales_invoice_header.exchrate},
        total:#{@other_sales_invoice_header.total_amount}, notes:#{@other_sales_invoice_header.notes}", current_user.full_name)

      respond_to do |format|
        if @split_tax_and_non_tax_transaction == 1
          format.html { redirect_to other_sales_invoice_headers_path(:tt => @tax_type.to_s), notice: "#{t 'purchase_invoice'} #{t 'can_revised'}" }
        else
          format.html { redirect_to other_sales_invoice_headers_path, notice: "#{t 'purchase_invoice'} #{t 'can_revised'}" }
        end 
      end
    end

    def si_id_by_customer
      if params[:id].present?
        @si_ids = OtherSalesInvoiceHeader.posted.si_has_outstanding_qty.where("other_sales_invoice_headers.customer_id = ?", "#{params[:id]}").order("si_id ASC").uniq
      else
        @si_ids = OtherSalesInvoiceHeader.posted.si_has_outstanding_qty.uniq
      end
    end

    def import
      employee_name = current_user.full_name

      @error_rows = []
      @error_rows.concat(OtherSalesInvoiceHeader.import(params[:file], employee_name))
      # CREATING FILE TO LIST ALL EXCEPTION
      # Create new file called 'filename.txt' at a specified path.
      dir = File.dirname("#{Rails.root}/public/import_exception/other_sales_invoice/#{Time.now.localtime.strftime('%d-%m-%Y %H-%M-%S')}.txt")

      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      @title = "#{Rails.root}/public/import_exception/other_sales_invoice/#{Time.now.localtime.strftime('%d-%m-%Y %H-%M-%S')}.txt"
      file = File.new(@title, "w")

      # Write text to the file.
      file.write "No. \t Transaction Date \t Customer \t Currency \t Amount \t Description \n"
      @error_rows.each do |row|
        file.write "#{row[0]} \t #{row[1]} \t #{row[2]} #{row[3]} #{row[4]} #{row[5]} \n"
      end
      # Close the file.
      file.close
      # END CREATING FILE TO LIST ALL EXCEPTION

      # format create_log(subject, object, detail, employee_name)
      create_log("Import", "OtherSalesInvoice", "Import other sales invoice, please see for transactions that created by this person and at this record time to see it's detail.", current_user.full_name)
    end

    private
      def set_other_sales_invoice_header
        @other_sales_invoice_header = OtherSalesInvoiceHeader.find(params[:id])
      end

      def set_tax_type
        if @split_tax_and_non_tax_transaction == 1
          render_form_tax_type_name(params[:tt].to_s)
        end
      end

      def get_sales_person
        @sales_persons = User.active.sales.not_developer.order(:first_name)
      end

      def get_customer
        @customer = Customer.find(@other_sales_invoice_header.customer_id)
        # receivable_account = @customer.try(:chart_of_account_id)
      end
  end
end
