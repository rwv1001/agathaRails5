include EditHelper
class CoursesController < ApplicationController
  # GET /courses
  # GET /courses.xml
  
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
    update_helper();

  end
  def update_main
    update_main_helper("Course");
  end
end
