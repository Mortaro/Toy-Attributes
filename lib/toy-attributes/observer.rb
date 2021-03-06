module ToyAttributes::Observer

  def self.watch! column_name, column_type, model, options={}
    assert_existence_of_table(model)
    assert_existence_of_column(column_name, column_type, model, options)
    model.reset_column_information
    model.attr_accessible column_name
  end

  private

  def self.assert_existence_of_table model
    unless ActiveRecord::Base.connection.table_exists? model.table_name
      Class.new(ActiveRecord::Migration).create_table(model.table_name.to_sym) { |t| t.timestamps }
    end
  end

  def self.assert_existence_of_column column_name, column_type, model, options
    add_column_to_table(column_name, column_type, model, options)
    update_table_column(column_name, column_type, model, options)
  end

  def self.add_column_to_table column_name, column_type, model, options
    unless model.columns_hash[column_name.to_s]
      Class.new(ActiveRecord::Migration).add_column model.table_name.to_sym, column_name, column_type, options
    end
  end

  def self.update_table_column column_name, column_type, model, options
    if model.columns_hash[column_name.to_s] && model.columns_hash[column_name.to_s].type != column_type
      klass = Class.new(ActiveRecord::Migration)
      old_type_column_name = "#{column_name}_old_type"
      klass.rename_column model.table_name.to_sym, column_name, old_type_column_name
      klass.add_column model.table_name.to_sym, column_name, column_type, options
      model.reset_column_information
      model.find_each { |instance| instance.update_attribute column_name, instanceold_type_column_name }
      klass.remove_column model.table_name.to_sym, old_type_column_name
    end
  end

end
