class MultiTable
  attr_reader :table_name;
  attr_reader :search_controller;

     def initialize(table_name, search_controller)
  #     RAILS_DEFAULT_LOGGER.error( "new EditObject" );
       @table_name = table_name
       @search_controller = search_controller
     end
end
