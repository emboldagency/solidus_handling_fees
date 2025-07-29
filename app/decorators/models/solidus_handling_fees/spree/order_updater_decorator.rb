# frozen_string_literal: true

module OverrideOrderUpdater
  def recalculate_adjustments
    update_handling
    super
  end

  def update_handling
    [*shipments].each do |item|
      handling_adjustments = item.adjustments.select(&:handling?)

      # Update each adjustment by recalculating its amount from the source
      handling_adjustments.each do |adjustment|
        if adjustment.source&.calculator
          new_amount = adjustment.source.calculator.compute_shipment(item)
          adjustment.update!(amount: new_amount)
        end
      end

      item.handling_total = handling_adjustments.sum(&:amount)
    end
  end

  def update_adjustment_total
    super
    # DD: updated merely for consistency (not used in calculations)
    order.handling_total = shipments.sum(:handling_total)
  end
end

Spree::OrderUpdater.class_eval do
  prepend OverrideOrderUpdater
end
