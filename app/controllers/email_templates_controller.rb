include EditHelper

class EmailTemplatesController < ApplicationController
  # GET /lectures
  # GET /lectures.xml

  # GET /lectures/1/edit
  def edit
    @table_name = params[:table_name];
    @id = params[:id];

    @short_name = session[:search_ctls][@table_name].GetShortField(@id );

    edit_helper(@table_name,[]);
  end



  def win_load

    win_load_helper();

  end

  def win_unload
    win_unload_helper();



  end

  def updater
    email_update();
  end



 
end