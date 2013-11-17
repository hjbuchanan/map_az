class AddHeatToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :heat, :integer
  end
end
