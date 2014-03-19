class MigrateOldShippingCalculators < ActiveRecord::Migration
  def up
    Spree::ShippingMethod.find_each do |shipping_method|
      old_calculator = shipping_method.calculator
      next if old_calculator.class < Spree::ShippingCalculator # We don't want to mess with new shipping calculators
      new_calculator = eval("Spree::Calculator::Shipping::#{old_calculator.class.name.demodulize}").new
      new_calculator.preferences.keys.each do |pref|
        # Preferences can't be read/set by name, you have to prefix preferred_
        pref_method = "preferred_#{pref}"
        new_calculator.send("#{pref_method}=", old_calculator.send(pref_method))
      end
      new_calculator.calculable = old_calculator.calculable
      new_calculator.save
    end
  end

  def down
  end
end
