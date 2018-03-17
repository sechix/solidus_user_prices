Spree::LineItem.class_eval do

  # Overridden to check special prices for particular users or roles
  def set_pricing_attributes
    return handle_copy_price_override if respond_to?(:copy_price)

    self.currency ||= order.currency
    self.cost_price ||= variant.cost_price

    if price.nil?
        self.money_price = variant.user_price_for(pricing_options, order.user)
        if item_rental_period == "week"
          self.price = variant.product.price_week.to_d
          self.item_total = self.quantity * self.price
        elsif item_rental_period == "month"
          if item_points == 0
            self.price = variant.product.price_month.to_d
            self.item_total = self.quantity * self.price
          else
            self.price = 0
          end
        end
    end


    true
  end

  # Overridden to use user prices if available for the order's user
  def options=(options = {})
    return unless options.present?
    # We will be deleting from the hash, so leave the caller's copy intact
    opts = options.dup
    user = opts.delete(:user)

    assign_attributes opts

    # There's no need to call a pricer if we'll set the price directly.
    unless opts.key?(:price) || opts.key?('price')
      self.money_price = variant.user_price_for(pricing_options, user)

      if item_rental_period == "week"
        self.price = variant.product.price_week.to_d
      elsif item_rental_period == "month"
        if item_points == 0
          self.price = variant.product.price_month.to_d
        else
          self.price = 0
        end
      end


    end
  end
end