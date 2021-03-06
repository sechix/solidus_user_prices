# Send user when creating line items, in case special prices
# are available for that user.
module SendUserWhenCreatingLineItems

  def add(variant, quantity = 1, options = {}, rental, require_payment, require_shipping, item_rental_period, item_plan)
    line_item = add_to_line_item(variant, quantity, options, rental, require_payment, require_shipping, item_rental_period, item_plan)
    after_add_or_remove(line_item, options)
  end

  def remove(variant, quantity = 1, options = {}, rental, require_payment, require_shipping, item_rental_period, item_plan)
    line_item = remove_from_line_item(variant, quantity, options, rental, require_payment, require_shipping, item_rental_period, item_plan)
    after_add_or_remove(line_item, options)
  end


  private

    def add_to_line_item(variant, quantity, options = {}, rental, require_payment, require_shipping, item_rental_period, item_plan)
      line_item = grab_line_item_by_variant(variant, false, options)

      if item_rental_period == 'week'
        item_rental_end_date = Time.current + 7.days
      elsif item_rental_period == 'month' && item_plan.nil?
        item_rental_end_date = Time.current + 1.month
      elsif item_rental_period == 'month' && !item_plan.nil?

          @user_subscriptions = @order.user.subscriptions.undeleted.all.to_a
          if @user_subscriptions.present?
            @user_subscription_plan_id = @user_subscriptions.first.plan_id
            @user_plan = Spree::Plan.active.where(id: @user_subscription_plan_id).first
          end
        @user_plan = Spree::Plan.active.where(id: @user_subscription_plan_id).first
        if @user_plan
          Stripe.api_key = @user_plan.provider.preferred_secret_key
          stripe_customer = Stripe::Customer.retrieve(@order.user.stripe_customer_id)
          invoice = Stripe::Invoice.upcoming(:customer =>stripe_customer.id)
          date_invoice  = Time.at(invoice.period_end)

          item_rental_end_date = date_invoice
        else
          flash[:error] = Spree.t(:error_product_cart)
          redirect_to '/admin/orders'
        end
      end

      line_item ||= order.line_items.new(
          quantity: 0,
          variant: variant,
       # Add new rental fields
          rental: rental,
          require_payment: require_payment,
          require_shipping: require_shipping,
          item_rental_period: item_rental_period,
          item_plan: item_plan,
          item_rental_end_date: item_rental_end_date,
      # End Add new rental fields
      )

      line_item.quantity += quantity.to_i
      line_item.options = ActionController::Parameters.new(options)

      line_item.target_shipment = options[:shipment]


      line_item.save!
      line_item
    end


    def remove_from_line_item(variant, quantity, options = {}, rental, require_payment, require_shipping, item_rental_period, item_plan)
      line_item = grab_line_item_by_variant(variant, true, options)
      line_item.quantity -= quantity
      line_item.target_shipment = options[:shipment]

      if line_item.quantity <= 0
        order.line_items.destroy(line_item)
      else
        line_item.save!
      end

      line_item
    end


end
Spree::OrderContents.prepend SendUserWhenCreatingLineItems


