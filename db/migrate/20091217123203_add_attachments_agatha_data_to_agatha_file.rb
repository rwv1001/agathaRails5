class AddAttachmentsAgathaDataToAgathaFile < ActiveRecord::Migration
  def self.up
    add_column :agatha_files, :agatha_data_file_name, :string
    add_column :agatha_files, :agatha_data_content_type, :string
    add_column :agatha_files, :agatha_data_file_size, :integer
    add_column :agatha_files, :agatha_data_updated_at, :datetime
  end

  def self.down
    remove_column :agatha_files, :agatha_data_file_name
    remove_column :agatha_files, :agatha_data_content_type
    remove_column :agatha_files, :agatha_data_file_size
    remove_column :agatha_files, :agatha_data_updated_at
  end
end
