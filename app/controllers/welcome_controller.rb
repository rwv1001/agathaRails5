# coding: utf-8
#require 'ruby-prof'

class Dependency
  attr_reader :dependent_table;
  attr_reader :dependent_ids;
  def initialize(dependent_table, dependent_ids)
    @dependent_table = dependent_table
    @dependent_ids = dependent_ids
  end
end

include FilterHelper
class WelcomeController < ApplicationController
 




  def string_update
    String.class_eval do
      def pl(n)       
        ret_val = "";
        if( n == 0 || n > 1)
          if self == "0"
            ret_val = "No"
          elsif self =~ /^\d+$/
            ret_val = str;
          elsif self == "was"
            ret_val ="were"
          elsif self == "does"
            ret_val = "do"
          elsif self == "a"
            ret_val = ""
          elsif self == "has"
            ret_val = have
          else
            ret_val = self.pluralize;
          end
        else
          ret_val = self;
        end        
      end
    end
  end


  def index

    if session[:user_id]==1 && Person.first == nil
      import_csv
    end
   
 
    session[:suggest_course_id] = 0;
    user_id=session[:user_id];
    @format_controller = FormatController.new(user_id);
    @all_group_filters = FilterController.GetAllGroupFilters(user_id);

    session[:format_controller] = @format_controller
    string_update
    unless session[:search_ctls]
      create_external_filters(session);
      
      InitializeSessionController()
  #    Rails.logger.error("inialization index");
    else
   #   Rails.logger.error("no need for initialization");
      
    end

    @search_ctls = session[:search_ctls];
    @attr_lists = session[:attr_lists];

    @search_ctls.each do |table_name, search_ctl|
      
      search_ctl.UpdateFiltersFromDB
    end
    Rails.logger.flush
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people }
    end
    Rails.logger.flush
      x = 1;
  end
  
  def inactive_user_pages(except_page_name)
    user_pages = UserPage.find(:all, :conditions =>{ :user_id => @user_id});
    user_pages.each do |user_page|
      if(except_page_name!=user_page.page_name)
      user_page.is_active = false;
      user_page.save;
      end
    end
  end

  def display_page
    respond_to do |format|
      format.js  { render "display_page"}
=begin      
        render :update do |page|
          page << "unwait();";
        end
      end
=end      
    end
    Rails.logger.flush
      
  end

  def InitializeSessionController()

    table_options = ["Person","Attendee","GroupPerson","GroupLecture","GroupCourse","GroupAttendee", "GroupTutorial","GroupTutorialSchedule", "GroupInstitution", "GroupUser","GroupTerm","GroupDay","GroupLocation","GroupWillingLecturer","GroupWillingTutor","Lecture","TutorialSchedule","Tutorial","WillingTeacher","WillingLecturer","WillingTutor","EmailTemplate","AgathaEmail", "GroupEmailTemplate","GroupAgathaEmail","Course","Group","Location","Institution","Term","TermName","Day", "User", "MaximumTutorial", "AgathaFile", "EmailAttachment"];

    @search_ctls = {}
    @attr_lists = {}

    @hash_to_index = {}
    @search_ctls = {}
    @number_of_controllers =  table_options.length
    
    
    user_id = session[:user_id]
    administrator = session[:administrator];
    for controller_index in (0 .. @number_of_controllers -1)

      search_controller = SearchController.new(table_options[controller_index], user_id, administrator, session);
      attribute_eval_str = "AttributeList.new(#{table_options[controller_index]})"
     # unless session[attribute_eval_str]
        attribute_list = AttributeList.new(table_options[controller_index]);
    #    session[attribute_eval_str] = attribute_list;
   #   else
   #     attribute_list = session[attribute_eval_str];
    #  end
      #attribute_list = AttributeList.new(table_options[controller_index]);
      
      @search_ctls[table_options[controller_index]] = search_controller;
      @attr_lists[table_options[controller_index]] = attribute_list;
    end
    
    for controller_index in (0 .. @number_of_controllers -1)
      @search_ctls[table_options[controller_index]].SetExtendedFilterControllers(@search_ctls);

    end

    @search_ctls["AgathaFile"].SetCompulsoryIndices([6]);

    
    session[:search_ctls] =  @search_ctls

    session[:attr_lists] = @attr_lists
    Rails.logger.debug("inialization of search controllers complete");

  end
  def child_unload
    Rails.logger.info("Begin child_unload");
       
       
    edited_table_name = params[:table_name];
    id = params[:id];
    attribute_name = params[:attribute_name];
    ids = [];
    ids << id.to_i;
    @user_id = session[:user_id];


    sql_str = "OpenRecord.find_by_sql(\"SELECT * FROM  open_records WHERE (user_id = " + @user_id.to_s + " AND table_name = '" + @table_name + "' AND  record_id = " +@id.to_s + "  AND in_use = true)\")"
    open_records = eval(sql_str)
    if(open_records.length >0)
        open_records[0].in_use = false;
        open_records[0].save;
        Rails.logger.info("child_unload open records updated")
    end 
    @search_ctls = session[:search_ctls][edited_table_name]
    respond_to do |format|
      format.js  { render "child_unload", :locals => {:search_ctl => session[:search_ctls][edited_table_name], :edited_table_name => edited_table_name, :ids => ids, :id => id, :attribute_name => attribute_name  } }
=begin      
      do
        render :update do |page|
          search_ctl = @search_ctls = session[:search_ctls][edited_table_name];
          eval("#{edited_table_name}.set_controller(search_ctl)");
          updated_objects = search_ctl.GetUpdateObjects(edited_table_name, "id", ids);
          if updated_objects.length>0
            row = updated_objects[0];
            


               
            page << "if ($('#{row.id}_#{ edited_table_name}')) {"
            page["#{row.id}_#{ edited_table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
            page << "}"
                
            page << "open_windows.unset('#{edited_table_name}_#{row.id}')"
            page << "recolour('#{edited_table_name}');";
  
            page << "action_select_no_js();";
            
          end
        end
      end
=end      
    end
    Rails.logger.debug("child_unload_end");
    Rails.logger.flush

  end

   def update_main_(ids, edited_table_name, attribute_names,success_str,fail_str,unwait_flag)
    
    Rails.logger.info("update_main rwv args");
    @search_ctls = session[:search_ctls];
    #@search_ctls.each {|key, value| puts "#{key} is #{value}" }
    respond_to do |format|
      format.js { render "shared/update_main", :locals => {:search_ctls => @search_ctls, :edited_table_name => edited_table_name, :attribute_names => attribute_names, :ids => ids, :success_str => success_str, :fail_str => fail_str , :unwait_flag => unwait_flag } }  
=begin      
      do
        render :update do |page|
          @search_ctls.each do |table_name, search_ctl|
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(edited_table_name, attribute_name, ids);
            for row in updated_objects

              page << "if ($('#{row.id}_#{table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              page << "}"

            end
            page << "recolour('#{table_name}');";
          end


            page << "action_select_no_js();";
        end
      end
=end      
    end
    Rails.logger.debug("update_main end");
  end
  
  def update_main
    Rails.logger.info("update_main 01" );
    id = params[:id].to_i;
    
    ids = [];
    ids << id;

    edited_table_name = params[:table_name];
    Rails.logger.info("update_main 02" );
    attribute_name = params[:attribute_name];
    Rails.logger.info("update_main 03" );
    success_str="";
    fail_str ="";
    unwait_flag = false;
    Rails.logger.info("update_main 04" );
    update_main_([id], edited_table_name, [attribute_name], success_str, fail_str, unwait_flag);
    Rails.logger.info("update_main 05" );
       
    end
   

  def update_search_controller

#   start = Time.now; Rails.logger.error("update_search_controller_start");
    @search_ctls = session[:search_ctls];
    @attr_lists = session[:attr_lists]
    table_name =  params[:table_change_text];
    search_ctl = @search_ctls[table_name];    
    current_filter_indices = [];
    possible_filter_indices = [];
    number_of_available_filters =  search_ctl.extended_filters.length;
    for filter_index in (0..(number_of_available_filters-1))
      extended_filter = search_ctl.extended_filters[filter_index];
      if(params.has_key?(extended_filter.filter_object.tag))
        current_filter_indices << filter_index
        if(extended_filter.filter_object.class == SearchField)
          extended_filter.filter_object.current_filter_string = params[extended_filter.filter_object.tag]
        elsif(extended_filter.filter_object.class == SubQuery)
         
          select_value =  params[extended_filter.filter_object.tag].to_i;
          if(select_value == 0 )
            argument_class = extended_filter.filter_object.argument_class;
            if argument_class.length >0
              last_str = "#{argument_class}.last.id"
              select_value = eval(last_str);
            end
          end
                 
          extended_filter.filter_object.current_argument_value = select_value;


        end
      else
        possible_filter_indices << filter_index
      end
    end
    if current_filter_indices.length>0
      update_display = true;
      search_ctl.updateFilters(current_filter_indices,  update_display)
    end

    if(params.has_key?("order_text"))
      order_field_name = params["order_text"];
      search_ctl.UpdateOrder(order_field_name)      
    end
    exam_ids = [];
    row_ids = [];
    compulsory_ids = [];
    if(params.has_key?("row_in_list"))
      row_ids = params[:row_in_list];
      if(table_name == "Person")
        if(params.has_key?("exam_in_list"))
          exam_ids = params[:exam_in_list];
        end
        
        if(params.has_key?("compulsory_in_list"))
          compulsory_ids = params[:compulsory_in_list];
        end        
      end     
    end

    #search_ctl.updateCheckBoxes(row_ids, exam_ids, compulsory_ids);
    

    if(params.has_key?("order_indices"))

      search_indices = params["order_indices"]
      search_ctl.UpdateSearchIndices(search_indices)
    else
      search_ctl.UpdateSearchIndices("")
    end
 #   elapsed = Time.now  - start; Rails.logger.error("update_search_controller_end, time: #{elapsed}");

  end
  def QualifiersStr(in_str)
    ret_str = in_str.strip;
    ret_str = ret_str.gsub(/[a-z][A-Z]\S{1}/){|s| s.insert(1," ")}
    ret_str = ret_str.gsub(/[a-z][A-Z]\S{1}/){|s| s.insert(1," ")}
    ret_str = ret_str.gsub(/\S+$/){|s| s = s.pluralize}
    ret_str = ret_str.gsub(/\s/){|s| '_'};
    ret_str = ret_str.gsub(/\//){|s| '__'};
    ret_str = ret_str.downcase;
    return ret_str;
  end  
  def update_external_filters
      @search_ctls = session[:search_ctls];
      @attr_lists = session[:attr_lists];
      @user_id = session[:user_id];
      table_name =  params["table_change_text"];
      @tables_name =  QualifiersStr(table_name);
      search_ctl = @search_ctls[table_name];
      external_filters = search_ctl.external_filters;
      # number_of_external_filters = params[:number_of_external_filters];
      stupid_count = 0;
      sql_str = "ExternalFilterValue.find_by_sql(\"SELECT id, table_name, filter_id, member_id, group_id, in_use FROM external_filter_values WHERE (user_id = " + @user_id.to_s +  " AND table_name = '" + @tables_name + "') ORDER BY id asc\")"
      
      old_external_filter_elts = eval(sql_str);
      old_external_filter_elt_count  = old_external_filter_elts.length;
      filter_count = 0;    
      
      for external_filter in external_filters
          current_arguments = external_filter.filter_object.current_arguments;
          if current_arguments == nil
              current_arguments = [];
          end
          
          filter_id = external_filter.filter_object.id;
          num_elements_str = "number_of_filter_elements_#{filter_id}";
          
          if(params.has_key?(num_elements_str))
              
              num_elts = params[num_elements_str].to_i;
              Rails.logger.info("update_external_filters  param #{num_elements_str} = #{num_elts} ");
              if num_elts < current_arguments.length
                  current_arguments = current_arguments[0, (num_elts)];
                  Rails.logger.info("update_external_filters num_elts:#{num_elts}, current_arguments:#{current_arguments.length}");
              end
              elt_off_set = 0; 
              for elt_id in (0..(num_elts-1))
                  if filter_count >= old_external_filter_elt_count
                      external_filter_elt  = ExternalFilterValue.new;
                  else
                      external_filter_elt = old_external_filter_elts[filter_count];
                  end
                  
                  member_id = -1;
                  while(member_id == -1 && elt_off_set<1000)
                      arg_name_str = "argument_selection_#{filter_id}_#{elt_id+elt_off_set}";
                      if(params.has_key?(arg_name_str))
                          member_id = params[arg_name_str];
                      else
                          elt_off_set=elt_off_set+1;
                      end
                  end
                  if (member_id ==-1)
                      member_id = 0;
                  end
                  
                  group_name_str = "group_selection_#{filter_id}_#{elt_id+elt_off_set}"         
                  
                  if params.has_key?(group_name_str)
                      group_id = params[group_name_str];
                  else
                      group_id = 0;
                  end
                  if filter_count >= current_arguments.length                    
                      
                      
                      new_filter_elt = ExternalFilterElement.new(elt_id,external_filter.filter_object);
                      new_filter_elt.member_id = member_id;
                      new_filter_elt.group_id = group_id;
                      current_arguments << new_filter_elt
                  else
                      current_arguments[elt_id].group_id = group_id;
                      current_arguments[elt_id].member_id = member_id;
                  end
                  
                  external_filter_elt.table_name = @tables_name;
                  external_filter_elt.user_id = @user_id;
                  external_filter_elt.filter_id = external_filter.filter_object.id;
                  external_filter_elt.in_use = true;
                  external_filter_elt.member_id = member_id;
                  external_filter_elt.group_id = group_id;
                  external_filter_elt.save;
                  filter_count =filter_count+1;          
                  Rails.logger.info("update_external_filters hum current_arguments:#{current_arguments.length}");
                  Rails.logger.info("update_external_filters, group_id:#{group_id}, member_id:#{member_id}");
              end
          else
              Rails.logger.info("update_external_filters no param #{num_elements_str}");
              external_filter.filter_object.current_arguments =[];
              
          end    
          
      end
      while filter_count < old_external_filter_elt_count
          external_filter_elt = old_external_filter_elts[filter_count];
          external_filter_elt.in_use = false;
          external_filter_elt.save;
          filter_count = filter_count+1; 
      end
  end
  def id_str_generator(ids)
    id_str = "";
      ids.each do |id|
        if(id_str.length >0 )
          id_str << ", ";
        end
        id_str << id.to_s;
     end
     return id_str;
  end
  
  def table_search
#     RubyProf.start
#start = Time.now; Rails.logger.debug("table_search_start");
    unless session[:search_ctls]
      InitializeSessionController
    end
    update_search_controller
    update_external_filters
    table_name =  params[:table_change_text];
    search_ctl = @search_ctls[table_name];
    
    search_ctl.user_id = session[:user_id];
    if(params.has_key?("do_search"))
      eval_str = search_ctl.get_eval_string2();
      Rails.logger.debug( "TABLE SEARCH: before eval(#{eval_str})" );
      @table = eval(eval_str);
      eval("#{table_name}.set_controller(search_ctl)");

      Rails.logger.debug( "TABLE SEARCH: after eval(eval_str)" );
      search_results = SearchResults.new(@table, :search_results, search_ctl);
      search_results.table_type = :search_results;
    end
    search_ctl.UpdateFiltersFromDB();
    respond_to do |format|
      format.js { render "table_search", :locals => {:search_ctl => search_ctl, :params => params, :table_name => table_name, :search_results=> search_results} } 
=begin
      do
        render :update do |page|
          page.replace_html("possible_filters_div_"  + table_name, :partial => "shared/possible_filters", :object => search_ctl);
          page.replace_html("current_filters_"  + table_name, :partial => "shared/current_filters", :object => search_ctl);
          if(params.has_key?("do_search"))
            page.replace_html("search_results_" + table_name, :partial => "shared/search_results" , :object => search_results);
            
            page << "resizeX();"
            
          end            

        
          page << "action_select_no_js();"
          page << "resizeFilters();"
          page << "unwait();"
        end
      end
=end
    end

#    result = RubyProf.stop
#  printer = RubyProf::GraphHtmlPrinter.new(result)
# file = File.open('profile-graph.html', File::WRONLY |  File::CREAT)

  #  my_str = "";
## printer.print(file, :min_percent=>0)
# Rails.logger.error("Does this work?");
# file.close


#elapsed = Time.now  - start; Rails.logger.debug("table_search_end, time: #{elapsed}");

    Rails.logger.flush;
  end

  def add_external_filter
    table_name = params[:table_name];
    filter_id = params[:filter_id].to_i;
    @search_ctls = session[:search_ctls];
    search_ctl = @search_ctls[table_name];
    # search_ctl.AddExternalFilter(filter_id);
    external_filter = search_ctl.CreateNewExternalFilter(filter_id);
    
    respond_to do |format|
      format.js { render "add_external_filter", :locals => {:external_filter => external_filter, :table_name => table_name } } 
    end
=begin
    respond_to do |format|
      format.js  do
        render :update do |page|
          page.insert_html(:bottom, "external_filters_#{table_name}", :partial => "shared/external_filter", :object => external_filter );
          page << "resizeExternalFilters(\"#{table_name}\")"
          page << "unwait();"
        end
      end
    end
=end
  end
  def update_external_filter
    class_name = params[:class_name];
    filter_id = params[:filter_id].to_i;
    elt_index= params[:elt_index].to_i;
    member_id = params[:member_id].to_i;
    group_id = params[:group_id].to_i;
    @search_ctls = session[:search_ctls];
    search_ctl = @search_ctls[class_name];
    external_filter_element = search_ctl.GetExternalFilterElement(filter_id, elt_index);
    external_filter_element.member_id = member_id;
    external_filter_element.group_id = group_id;

    respond_to do |format|
      format.js  { render "update_external_filter", :locals => {:external_filter_element => external_filter_element, :class_name => class_name, :filter_id => filter_id, :elt_index=> elt_index} } 
    end
=begin
        render :update do |page|
          page.replace("external_filter_argument_span_#{class_name}_#{filter_id}_#{elt_index}",  :partial => "shared/external_filter_element", :object=> external_filter_element)
          page << "resizeExternalFilters(\"#{class_name}\")"
          page << "unwait();"
        end
      end
    end
=end    
  end

  def new
#     RubyProf.start
    class_name = params[:class_name];
    table_name = class_name.tableize;

    new_eval_str = "#{class_name}.new"
    new_obj = eval(new_eval_str);
    if(class_name == "EmailTemplate")
      new_obj.from_email = "<%= me.email %>"
      new_obj.subject = "Put the email subject here."
      new_obj.body =  %q{Dear <%= person.salutation %>,<br><br>Put your email content here }
    end    
    
    new_obj.save;
    id = new_obj.id;

    respond_to do |format|
      format.js { render "new", :locals=>{:table_name => table_name, :id => id, :class_name => class_name } }
      
=begin
        render :update do |page|
       
       page << "open_edit_window( '', 1,'#{table_name}','#{class_name}','#{id}')";
     
        end
      end
=end      
    end
    x =1;
#        result = RubyProf.stop
#  printer = RubyProf::GraphHtmlPrinter.new(result)
# file = File.open('profile-graph-new.html', File::WRONLY |  File::CREAT)

  #  my_str = "";
# printer.print(file, :min_percent=>0)
# Rails.logger.error("Does this work?");
# file.close

  end

  def suggest_tutorial
   tutorial_schedule = TutorialSchedule.new;
    previous_suggestions = params[:previous_suggestions];
    course_id = params[:suggest_id];
    if session[:suggest_course_id] !=course_id
      previous_suggestions="";
      old_person_id = SearchController::NOT_SET;
      session[:suggest_course_id] =  course_id;
    else
      old_person_id = params[:person_id].to_i;
    end

    previous_str = "";
    if previous_suggestions.length >0
        previous_suggestions << ", "
    end
    previous_suggestions << old_person_id.to_s;
    if previous_suggestions.length >0
      previous_str = "AND person_id NOT IN (#{previous_suggestions}) "
    end
    db_tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE course_id = #{course_id} #{previous_str} ORDER BY term_id DESC LIMIT 1");
    willing_tutor = WillingTutor.find_by_sql("SELECT * FROM willing_tutors WHERE course_id = #{course_id} #{previous_str} ORDER BY order_of_preference ASC LIMIT 1");
    if willing_tutor.length > 0
      tutorial_schedule.person_id = willing_tutor[0].person_id;
    else
      first_suggestion = previous_suggestions.scan(/\d+/)
      if first_suggestion
        if first_suggestion[0].to_i == SearchController::NOT_SET && first_suggestion.length>1
        tutorial_schedule.person_id = first_suggestion[1].to_i
        else
          tutorial_schedule.person_id = first_suggestion[0].to_i
        end
      else
        tutorial_schedule.person_id = SearchController::NOT_SET;
      end
      previous_suggestions = SearchController::NOT_SET.to_s;
    end
        old_term_id = params[:term_id].to_i;
    if old_term_id == SearchController::NOT_SET

      suggested_term = session[:current_term];
      if suggested_term !=nil ||   suggested_term == SearchController::NOT_SET
        tutorial_schedule.term_id = suggested_term.id
      else
        tutorial_schedule.term_id = Term.last.id;
      end
    else
      tutorial_schedule.term_id = old_term_id;
    end
    tutorial_schedule.course_id = course_id;

    old_number_of_tutorials = params[:number_of_tutorials].to_i;
    if old_number_of_tutorials == 0 && db_tutorial_schedules.length > 0
      tutorial_schedule.number_of_tutorials = db_tutorial_schedules[0].number_of_tutorials;
    else
      tutorial_schedule.number_of_tutorials = old_number_of_tutorials;
    end

    @search_ctls = session[:search_ctls];

   
    suggested_tutorial_schedule = SuggestedTutorial.new(@search_ctls["TutorialSchedule"],tutorial_schedule);
    suggested_tutorial_schedule.previous_suggestions = previous_suggestions;
    respond_to do |format|
      format.js  { render "suggest_tutorial", :locals => {:suggested_tutorial_schedule => suggested_tutorial_schedule}  }
=begin
        render :update do |page|
        page.replace_html("tutorial_schedule_div",:partial => "shared/suggested_tutorial", :object =>  suggested_tutorial_schedule);
        page << "unwait();"
        end
      end
=end      
    end
  end
  
  def suggest_lecture
    lecture = Lecture.new;
    previous_suggestions = params[:previous_suggestions];
    course_id = params[:suggest_id];
    if session[:suggest_course_id] !=course_id
      previous_suggestions="";
      old_person_id = SearchController::NOT_SET;
      session[:suggest_course_id] =  course_id;
    else
      old_person_id = params[:person_id].to_i;
    end
    
    previous_str = "";
    if previous_suggestions.length >0
        previous_suggestions << ", "
    end
    previous_suggestions << old_person_id.to_s;
    if previous_suggestions.length >0
      previous_str = "AND person_id NOT IN (#{previous_suggestions}) "
    end
    db_lectures = Lecture.find_by_sql("SELECT * FROM lectures WHERE course_id = #{course_id} #{previous_str} ORDER BY term_id DESC LIMIT 1");
    willing_lecturers = WillingLecturer.find_by_sql("SELECT * FROM willing_lecturers WHERE course_id = #{course_id} #{previous_str} ORDER BY order_of_preference ASC LIMIT 1");
    if willing_lecturers.length > 0
      lecture.person_id = willing_lecturers[0].person_id;
    else
      first_suggestion = previous_suggestions.scan(/\d+/)
      if first_suggestion
        if first_suggestion[0].to_i == SearchController::NOT_SET && first_suggestion.length>1
        lecture.person_id = first_suggestion[1].to_i
        else
          lecture.person_id = first_suggestion[0].to_i
        end
      else
        lecture.person_id = SearchController::NOT_SET;
      end      
      previous_suggestions = SearchController::NOT_SET.to_s;
    end
        old_term_id = params[:term_id].to_i;
    if old_term_id == SearchController::NOT_SET
       suggested_term = session[:current_term];
      if suggested_term !=nil ||   suggested_term == SearchController::NOT_SET
        lecture.term_id = suggested_term.id
      else
        lecture.term_id = Term.last.id;
      end
    else
      lecture.term_id = old_term_id;
    end
    old_classes = params[:number_of_classes].to_i
    if old_classes == 0  && db_lectures.length > 0
      lecture.number_of_classes = db_lectures[0].number_of_classes
    else
      lecture.number_of_classes = old_classes
    end
    old_lectures = params[:number_of_lectures].to_i;
    if old_lectures == 0 && db_lectures.length > 0
      lecture.number_of_lectures = db_lectures[0].number_of_lectures;
    else
      lecture.number_of_lectures = old_lectures;
    end
    lecture.day_id = params[:day_id].to_i;
    lecture.lecture_time = params[:lecture_time];
    @search_ctls = session[:search_ctls];

    class_name = params[:suggest_class];
    suggested_lecture = SuggestedLecture.new(@search_ctls["Lecture"],lecture);
    suggested_lecture.previous_suggestions = previous_suggestions;
    respond_to do |format|
      format.js  { render "suggest_lecture", :locals =>{:suggested_lecture => suggested_lecture, :class_name => class_name  } }
=begin      
        render :update do |page|
        #  page["#{class_name}_action_div"].select(".schedule_div")[0].replace_html(:partial => "shared/suggested_lecture", :object =>  suggested_lecture);
        page.replace_html("schedule_div",:partial => "shared/suggested_lecture", :object =>  suggested_lecture);
        page << "unwait();"
        end
      end
=end      
    end
    Rails.logger.flush
  end

  def make_suggestion
   suggest_type = params[:suggest_type];
    case suggest_type
    when "Lecture"
      suggest_lecture
    when "Tutorial"
      suggest_tutorial
    else
      x = 1;
    end
   end

  def multi_table_create
    table_name = params[:multi_table_create]
    @search_ctls = session[:search_ctls];
    search_ctl = @search_ctls[table_name];
    respond_to do |format|
        format.js { render "multi_table_create", :locals =>{:table_name => table_name, :search_ctl => search_ctl  } } 
=begin 
          render :update do |page|
            page << "wait();"
            if  table_name.length >0
             @search_ctls = session[:search_ctls];
             search_ctl = @search_ctls[table_name];
             new_multi_table = MultiTable.new("\"#{table_name}\"", search_ctl)
           # <%= render(:partial => "shared/multi_table", :object => new_multi_table ) %>
             page.replace_html("multi_change_table_div_#{table_name}" , :partial => "shared/multi_table" , :object => new_multi_table);
            else
              page << "alert('something went wrong with multi_table_create')";

            end
            page << "unwait();"
          end
        end
=end         
    end

  end

  def select_action
    action = params[:action_type];
    class_name = params[:class_name];
    ids = params[:row_in_list];
    if(ids == nil)
      ids = [];
    end
    case action
    when "delete"
      delete_array(ids, class_name);
    when "update_collection_status"
      new_status = params[:collection_status].to_i;
      update_collection_status(ids, new_status);
    when "multi_update"
      multi_update(ids, class_name);
      
    when "group"
      
      group_name = params[:new_group_name];
      group_privacy = params[:group_privacy];
      new_group(ids, class_name, group_name, group_privacy);
    when "set_tutorial_number"

      tutorial_number = params[:tutorial_number];
      update_tutorial_number(ids, tutorial_number);      
    when "add_to_group"
      
      class_name2 = params[:class_name2];
      group_id = params[:id];
      add_to_group(group_id, ids, class_name2);
    when "remove_from_group"
      
      class_name2 = params[:class_name2];
      group_id = params[:id];
      remove_from_group(group_id, ids, class_name2);
      
    when "add_to_groups"
      
      class_id = params[:id];
      add_to_groups(ids, class_id, class_name);
    when "remove_from_groups"
      
      class_id = params[:id];
      remove_from_groups(ids, class_id, class_name);
    when "create_lecture_from_course"
      create_lecture_schedule
    when "create_tutorials_from_course"
      create_tutorial_schedules(ids)
    when "create_email_from_template"
      send_flag = false;
      create_email_from_template(ids, send_flag)
    when "create_send_email_from_template"
      send_flag = true;
      create_email_from_template(ids, send_flag)
    when "send_email"
      send_email()
    when "send_emails"
      send_emails(ids)
    when "make_willing_lecturer"
      make_willing_lecturer(ids)
    when "make_willing_tutor"
      make_willing_tutor(ids)
    when "add_to_lectures"
      if class_name == "Lecture"
        add_to_lectures(ids)
      else
        make_attendee(ids)
      end
    when "assign_tutor"
      assign_tutor(ids)
    when "max_tutorials"
      max_tutorials(ids)
    when "attach_files"
      attach_files(ids)
    when "attach_to_emails"
      attach_to_emails(ids)
    when "add_tutorial_student"
      add_tutorial_student(ids)
    else
      x = 1;     
    end
     Rails.logger.flush
  end
  
  def multi_update(ids, class_name)
    error_str = "";
    success_str = "";
    attribute_list = [];
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any rows to update. "
    else      
        
        Rails.logger.info(" multi_update 1");
        update_int_fields = Hash.new;
        update_text_fields = Hash.new;
        field_str = ""
        field_count = 0;
        params.each do |key,value|
            if(key =~ /^mi_edit_*/)

                i_value = value.to_i
                Rails.logger.debug("key = #{key}, i_value = #{i_value}, value.length = #{value.length}  ");
                if (i_value  >= 0 && value.length > 0)
                  if(field_str.length > 0)
                    field_str << ", "
                  end
                  field_name = key.gsub(/^mi_edit_*/,'');
                  field_str << field_name;
                  attribute_list.push(field_name);

                  field_count = field_count + 1;
                  update_int_fields[field_name] = i_value;
                end

            elsif(key =~ /^mt_edit_*/)
                if(value.length > 0)
                  if(field_str.length > 0)
                    field_str << ", "
                  end
                  field_name = key.gsub(/^mt_edit_*/,'')
                  field_str << field_name;
                  attribute_list.push(field_name);
                  field_count = field_count + 1;
                  update_text_fields[field_name] = value;
                end
            end
        end
                Rails.logger.debug(" multi_update 2");
        ids.each do |id|
           object_str = "#{class_name}.find(#{id})";
           current_object  = eval(object_str);
           update_int_fields.each do |key,value|
              
                update_str = "current_object.#{key} = #{value}";
                eval(update_str);
              

           end
                   Rails.logger.debug(" multi_update 3");
           update_text_fields.each do |key,value|

                update_str = "current_object.#{key} = \"#{value}\"";
                eval(update_str);
              
           end
           current_object.save;
                   Rails.logger.debug(" multi_update 4");
        end
        
                Rails.logger.debug(" multi_update 5");
        if(field_count==0)
                  Rails.logger.debug(" multi_update 6");
          success_str = "No updates were made because you didn't set any fields"
        else
                  Rails.logger.debug(" multi_update 7");
          @pluralize_num =  ids.length;
          success_str = ids.length.to_s + " " +pl("#{class_name}") + " " + pl("was") + " updated with new ";
          @pluralize_num = field_count;
          success_str << pl("value") + " for " + pl("field") + " " + field_str;
        end
    end
            Rails.logger.debug(" multi_update 8");



    unwait_flag = true;
    update_main_(ids, class_name, attribute_list, success_str, error_str, unwait_flag);
            

  end  
  def add_tutorial_student(ids)
    error_str = "";
    success_str = "";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any tutorial schedules. "
    else
      id_str = "";
      ids.each do |id|
        if(id_str.length >0 )
          id_str << ", ";
        end
        id_str << id.to_s;
      end
      person_id = params[:id];
      already_present =Tutorial.find_by_sql("SELECT a0.tutorial_schedule_id FROM tutorials a0 WHERE a0.person_id = #{person_id} AND a0.tutorial_schedule_id IN (#{id_str})");
      if  already_present.length >0
        @pluralize_num = already_present.length;
        success_str = "The tutorial" + pl("schedule") + " with " + pl("id") + " = ";
        tutorial_schedule_id_str = "";
        already_present.each do |tutorial|
          if tutorial_schedule_id_str.length >0
            tutorial_schedule_id_str << ", ";
          end
          tutorial_schedule_id_str << tutorial.tutorial_schedule_id.to_s;
          ids.delete(tutorial.tutorial_schedule_id.to_s);
        end
        success_str << tutorial_schedule_id_str + " "

        success_str << " already had the student with id #{person_id} attending. "
      end
       ids.each do |tutorial_schedule_id|
        tutorial = Tutorial.new;
        tutorial.tutorial_schedule_id = tutorial_schedule_id;
        tutorial.person_id = person_id;
        tutorial.save;
      end
      @pluralize_num = ids.length;
      success_str << "You have added person with id #{person_id} to #{@pluralize_num} " + pl("tutorial schedules");

    end
      @search_ctls = session[:search_ctls];
      edited_table_name = "Tutorial";
      Rails.logger.info("add_tutorial_student success_str = #{success_str}");
      respond_to do |format|
        format.js { render "shared/update_main", :locals => {:search_ctls => @search_ctls, :edited_table_name => edited_table_name, :attribute_names => ["id"], :ids => ids, :success_str => success_str, :fail_str => error_str , :unwait_flag => true } }
 
=begin        
        do
          render :update do |page|
            if error_str.length >0
              page << "alert('#{error_str}')";
            else
              page << "alert('#{success_str}')";
              
            end
            page << "unwait();"
          end

      end
=end      
    end
  end
  def attach_to_emails(ids)
    error_str = "";
    success_str = "";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any emails to attach file to. "
    else

      id_str = "";
      ids.each do |id|
        if(id_str.length >0 )
          id_str << ", ";
        end
        id_str << id.to_s;
      end
      agatha_file_id = params[:id];
      agatha_file = AgathaFile.find(agatha_file_id);
      
      already_present =EmailAttachment.find_by_sql("SELECT  a0.agatha_email_id FROM email_attachments a0  WHERE a0.agatha_file_id = #{agatha_file_id} AND a0.agatha_email_id IN (#{id_str})");
      if  already_present.length >0
        @pluralize_num = already_present.length;
        success_str = "The " + pl("email") + " with " + pl("id") + " = ";
        attach_id_str = "";
        already_present.each do |email|
          if attach_id_str.length >0
            attach_id_str << ", ";
          end
          attach_id_str << email.agatha_email_id.to_s;
          ids.delete(email.agatha_email_id.to_s);
        end
        success_str << attach_id_str + " "        

        success_str << " already had the file #{agatha_file.agatha_data_file_name} attached. "
      end


      ids.each do |agatha_email_id|
        email_attachment = EmailAttachment.new;
        email_attachment.agatha_email_id = agatha_email_id;
        email_attachment.agatha_file_id = agatha_file_id;
        email_attachment.save;
      end
      @pluralize_num = ids.length;
      success_str << "You have attached file #{agatha_file.agatha_data_file_name} to #{@pluralize_num} " + pl("email");

    end
    @search_ctls = session[:search_ctls]
    respond_to do |format|
      format.js { render "attach_to_emails", :locals => {:error_str => error_str, :search_ctls => session[:search_ctls], :ids => ids, :success_str => success_str } }
=begin      
       do
        render :update do |page|
          if error_str.length >0
            page << "alert('#{error_str}')";
          else
            @search_ctls = session[:search_ctls];
            if ids.length > 0
              table_name = "AgathaEmail"
              search_ctl = @search_ctls[table_name];
              eval("#{table_name}.set_controller(search_ctl)");
              updated_objects = search_ctl.GetUpdateObjects(table_name, "id", ids);
              updated_objects.each do |row|
                page << "if ($('#{row.id}_#{ table_name}')) {"
                page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
                page << "setcheck('#{table_name}_check_#{row.id.to_s}',true)"
                page << "}"
              end
              page << "recolour('AgathaEmail');";
              page << "action_select_no_js();";
            end
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end
    end
  end

  def attach_files(ids)
     error_str = "";
     success_str = "";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any files to attach to email. "
    else
      id_str = "";
      ids.each do |id|
        if(id_str.length >0 )
          id_str << ", ";
        end
        id_str << id.to_s;
      end
    
      
      agatha_email_id = params[:id];

      already_present =EmailAttachment.find_by_sql("SELECT  a0.agatha_file_id, a1.agatha_data_file_name FROM email_attachments a0 INNER JOIN agatha_files a1 ON a0.agatha_file_id = a1.id  WHERE a0.agatha_email_id = #{agatha_email_id} AND a0.agatha_file_id IN (#{id_str})");
      if  already_present.length >0
        @pluralize_num = already_present.length;
        success_str = "The " + pl("file") + " ";
        attach_file_str = "";
        already_present.each do |attachment|
          if attach_file_str.length >0
            attach_file_str << ", ";
          end
          attach_file_str  << attachment.agatha_data_file_name;
          ids.delete(attachment.agatha_file_id.to_s);
        end
        success_str << attach_file_str + " "
        success_str << pl("was") + " already attached. "


      end
      ids.each do |agatha_file_id|
        email_attachment = EmailAttachment.new;
        email_attachment.agatha_email_id = agatha_email_id;
        email_attachment.agatha_file_id = agatha_file_id;
        email_attachment.save;
      end

       @pluralize_num = ids.length;
       success_str << "You have attached #{@pluralize_num} " + pl("file") + " to the selected email";

    end

    x = 1;
    @search_ctls = session[:search_ctls];
    respond_to do |format|
      format.js {render  "attach_files", :locals => {:error_str => error_str, :search_ctls => session[:search_ctls], :agatha_email_id => agatha_email_id, :success_str => success_str } }
=begin      
        do
        render :update do |page|
          if error_str.length >0
            page << "alert('#{error_str}')";
          else
            @search_ctls = session[:search_ctls];
            table_name = "AgathaEmail"
            search_ctl = @search_ctls[table_name];
            id_array = [];
            id_array << agatha_email_id.to_i;
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", id_array);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );  
              page << "}"              
            end
    

                                   
            page << "recolour('AgathaEmail');";
            page << "action_select_no_js();";
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end
    end
  end

  def send_email()
    ids = [];
    ids << params[:email_id];
    send_emails(ids)
  end
  def send_emails_routine(ids)
      error_str =""
    success_str =""
    non_emails = 0;
    has_emails = 0;
    non_email_str = "";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any emails to send. "
    else
      test_flag = params[:test_flag].to_i;
      user_id = session[:user_id];
      user = User.find(user_id)
      me = Person.find(user.person_id)


      if(test_flag == 0 || (test_flag ==1 && me.email != nil && me.email =~ /@/))



      ids.each do |id|
        agatha_email = AgathaEmail.find(id);
        agatha_email.sent = false;
        email_addresses = agatha_email.to_email.split(';');
        email_addresses.each do |email_address|
        if email_address =~ /@/
          email_address = email_address.gsub(/\s+/,'');
          has_emails = has_emails +1;
          if(test_flag ==1)
            to_email =  me.email;
          else
            to_email =  email_address
          end
          Rails.logger.debug("email to address is #{to_email}");
          Rails.logger.debug("email from address is #{agatha_email.from_email}");
          Rails.logger.debug("email subject is #{agatha_email.subject}");
          AgathaMailer.deliver_email(agatha_email, to_email)
          agatha_email.sent = true;
        else
          non_emails = non_emails + 1;
          if non_email_str.length >0
            non_email_str << ", ";
          end
          non_email_str << id.to_s
        end
        end
        agatha_email.save;

      end
           if test_flag == 1
            success_str = "Testing: "
          else
            success_str = ""
          end
        non_email_str  = non_email_str.gsub(/,\s*(\d+)$/,' and \1')
        if(non_emails >0)
          @pluralize_num = non_emails

          success_str << "The " + pl("email") +" with " +pl("id") +" "+  non_email_str +" "+ pl("does") + " not have "  + pl("a") + " valid email " + pl("address") + ". ";
        end
          @pluralize_num = has_emails
          success_str << pl(has_emails.to_s) + " " + pl("email") +" "+ pl("was") + " sent. "


      else
         error_str = "You are logged in as user #{user.name} which is associated with the person #{me.first_name} #{me.second_name}, but this person does not have a valid email which can be used for testing. "
      end
    end
    ret_val = {}
    ret_val["success_str"] = success_str
    ret_val["error_str"] = error_str
    return ret_val
  end
  def send_emails(ids)


      status_val = send_emails_routine(ids)
      error_str = status_val["error_str"];


    
      respond_to do |format|
      format.js  { render "send_emails", :locals => { :status_val => status_val, :error_str => error_str } } 
=begin
        render :update do |page|
          if error_str.length >0
            page << "alert('#{status_val["error_str"]}')";
          else
            page << "alert('#{status_val["success_str"]}')";
          end
          page << "unwait();"
        end
      end
=end
    end
  end


  def pl(str)
    x = 1;
    ret_val = "";
    if( @pluralize_num == 0 || @pluralize_num > 1)
      if str == "0"
        ret_val = "No"
      elsif str =~ /^\d+$/
        ret_val = str;
      elsif str == "was"
        ret_val ="were"
      elsif str == "does"
        ret_val = "do"
      elsif str == "a"
        ret_val = ""
      elsif str == "has"
        ret_val = have
      else
        ret_val = str.pluralize;
      end
    else
      ret_val = str;
    end
    return ret_val;

  end

  def conv(str)
    str = str.gsub(/(“|”)/,'"').gsub(/(’|‘)/,'\'').gsub(/–/,'-');

  end

  def create_email_from_template(ids, send_flag)
    string_update
    success_str = "";
    warning_str="";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any students"
    else
      email_ids = []
      error_str = ""
      email_template_id = params[:email_template_id].to_i;
      term_id = params[:term_id].to_i;
      course_id = params[:course_id].to_i;
      template = EmailTemplate.find(email_template_id);
      if(template.course_dependency && course_id == SearchController::NOT_SET)
        error_str = "This template depends on a course, but you have not selected one. "
      elsif(template.term_dependency && term_id == SearchController::NOT_SET)
        error_str = "This template depends on a term, but you have not selected one. "
      else
        term = Term.find(term_id);
        course = Course.find(course_id);
        
        if template.global_warnings != nil && template.global_warnings.length>0
        eval(template.global_warnings);
        end
        id_str = "";



        ids.each do |id|

          person = Person.find(id);
          if person.salutation != nil && person.salutation.length >0
             Rails.logger.error("email test #{person.salutation.length }");
          else
             Rails.logger.error("email test nil or 0"); 
          end
          if template.personal_warnings != nil && template.personal_warnings.length >0
            eval(template.personal_warnings);
          end

          if  template.ruby_header.length > 0
            body_str = template.ruby_header + template.body;
          else
            body_str =  template.body;
          end
          body_str  = body_str.gsub(/&amp;(?=([^<]*?)%>)/,"&");
          body_str  = body_str.gsub(/&nbsp;(?=([^<]*?)%>)/," ");


          agatha_email = AgathaEmail.new
          user_id = session[:user_id]
          user = User.find(user_id);
          user_person_id = user.person_id
          user_person = Person.find(user_person_id);
          Rails.logger.debug("test debug");

          agatha_email.from_email = render_to_string( :inline => template.from_email , :locals => { :me => user_person})
          agatha_email.to_email = person.email
          subject_str = render_to_string( :inline => template.subject , :locals => { :person => person, :term => term, :course => course })
          agatha_email.subject = conv(subject_str);
          Rails.logger.debug("pre-rendered body string = #{body_str}");
          begin
             body_str = render_to_string( :inline => body_str , :locals => { :person => person, :term => term, :course => course });
          rescue Exception =>exc
            body_str = "";
            error_str = "Agatha Email Error has occurred. There is something wrong with the template" 
          end
          Rails.logger.debug("body_string_ = #{body_str}");
          agatha_email.body = conv(body_str);
          agatha_email.sent = false
          agatha_email.email_template_id = email_template_id
          agatha_email.person_id = id;
          agatha_email.term_id = term_id;
          agatha_email.course_id = course_id;
          agatha_email.save;
          Rails.logger.info("Created email with id = #{agatha_email.id}");
          #new_emails << agatha_email;
          email_ids << agatha_email.id
          if id_str.length >0
            id_str << ", "
          end
          id_str <<  agatha_email.id.to_s;
        end
        @pluralize_num = ids.length;
        success_str = pl(@pluralize_num.to_s) + " " +  pl("email") + " " + pl("was") + " created. ";
        if send_flag
          status_val = send_emails_routine(email_ids);
          success_str = success_str + status_val["success_str"] + status_val["error_str"];
        end
      end
    end
    @search_ctls = session[:search_ctls];
    search_ctl = @search_ctls["AgathaEmail"];
    respond_to do |format|
      format.js  {render "create_email_from_template", :locals => {:error_str => error_str, :success_str => success_str, :warning_str=> warning_str, :id_str=> id_str, :search_ctl => search_ctl } }
=begin      
      do
        render :update do |page|
          page << "unwait()";
          if error_str.length >0
            page << "alert('#{error_str}')";
          else
            j_str = "alert(\"#{success_str+warning_str}\")";
            page << j_str;
          end
        end
      end
=end
    end
  end
  def max_tutorials(ids)
      people_ids = ids[0 .. -1]
      Rails.logger.info("b max_tutorials ids = #{ids.length}")
    success_str = "";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any people"
    else
      error_str = ""
      term_id = params[:term_id];
      max_tutorials_number = params[:max_tutorials];
      id_str = "";
      ids.each do |id|
        if(id_str.length >0 )
          id_str << ", ";
        end
        id_str << id.to_s;
      end

      present_max_tutorials = MaximumTutorial.find_by_sql("SELECT * FROM maximum_tutorials WHERE person_id IN (#{id_str}) AND term_id =#{term_id}");
      present_num = present_max_tutorials.length;
      present_max_tutorials.each do |max_tutorial|
        ids.delete(max_tutorial.person_id.to_s)
        max_tutorial.max_tutorials = max_tutorials_number;
        max_tutorial.save;
      end
      
      ids.each do |id|
        max_tutorial = MaximumTutorial.new;
        max_tutorial.term_id = term_id;
        max_tutorial.person_id = id;
        max_tutorial.max_tutorials = max_tutorials_number;
        max_tutorial.save;
      end
      new_num = ids.length;
      success_str  ="";
      if present_num ==1
        success_str = "1 maximum maximum tutorial entry was updated in the database. "
      elsif present_num >1
       success_str = "#{present_num} maximum tutorial entries were updated in the database. "
      end
      if new_num == 1
        success_str << "1 new maximum maximum tutorial entry was added to the database. "
      elsif new_num >1
        success_str << "#{present_num} new maximum tutorial entries were added to the database. "
      end

    end
    
    table_name = "Person"
    @search_ctls=session[:search_ctls]
    search_ctl = @search_ctls[table_name]

    
    
    respond_to do |format|
      format.js  {render "max_tutorials", :locals => {:search_ctl => search_ctl, :ids => people_ids, :success_str => success_str, :error_str => error_str} } 
=begin      
      do
        render :update do |page|
          if error_str.length >0
            page << "alert('#{error_str}')";
          else
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end      
    end

  end

  def assign_tutor(ids)
    success_str = "";
    if(ids == nil || ids.length==0)
      error_str = "You have not selected any tutorial schedules"
    else
      error_str = ""
      tutor_id = params[:id];
      id_str = "";
      ids.each do |id|
        if(id_str.length >0 )
          id_str << ", ";
        end
        id_str << id.to_s;
      end
      tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE id IN (#{id_str})");
      tutorial_schedules.each do |tutorial_schedule|
        tutorial_schedule.person_id = tutor_id;
        tutorial_schedule.save;
      end
      num_updates = tutorial_schedules.length;
      if (num_updates == 0)
        success_str = "No tutor updates were made. "
      elsif num_updates ==1
        success_str = "One tutor update was made. "
      else
        success_str = "#{num_updates} tutor updates were made. "
      end
    end
    @search_ctls = session[:search_ctls];
    edited_table_name = "TutorialSchedule";
    respond_to do |format|           
      format.js { render "shared/update_main", :locals => {:search_ctls => @search_ctls, :edited_table_name => edited_table_name, :attribute_names => ["person_id"], :ids => ids, :success_str => success_str, :fail_str => error_str , :unwait_flag => true } }

=begin      
      do
        render :update do |page|
          if error_str.length >0
            page << "alert('#{error_str}')";
          else
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end      
    end
    
  end

  def  make_willing_lecturer(ids)
     alert_str= "";
    if ids != nil && ids.length > 0
      person_id = params[:willing_id];
      already_willing = 0;
      new_willing = 0;
      ids.each do |course_id|
        present = WillingLecturer.find_by_sql("SELECT * FROM willing_lecturers WHERE person_id = #{person_id} AND course_id = #{course_id}");
        if present !=nil && present.length >0
          already_willing = already_willing + 1;
        else
          new_willing = new_willing +1;
          willing_lecturer = WillingLecturer.new;
          willing_lecturer.person_id = person_id;
          willing_lecturer.course_id = course_id;
          willing_lecturer.order_of_preference = 1;
          willing_lecturer.save;
        end
      end
      if new_willing == 0
        alert_str = "No willing lecturer entries were added to the database. "
      elsif new_willing == 1
        alert_str = "1 willing lecturer entry was added to the database. "
      else
        alert_str = "#{new_willing} willing lecturer entries were added to the database. "
      end
      if already_willing==1
        alert_str << "1 willing lecturer entry was already in the database for person with id #{person_id}. "
      elsif already_willing>1
        alert_str << "#{already_willing} willing lecturer entries were already in the database for person with id #{person_id}. "
      end
    else
      alert_str = "You did not select any courses. "
    end
    respond_to do |format|
      format.js  {render :partial => "shared/alert", :locals => {:alert_str => alert_str} }
=begin      
      do
        render :update do |page|
          page << "alert('#{alert_str}')"
          page << "unwait();"
        end
      end
=end      
    end
  end

    def  make_willing_tutor(ids)
     alert_str= "";
    if ids != nil && ids.length > 0
      person_id = params[:willing_id];
      already_willing = 0;
      new_willing = 0;
      ids.each do |course_id|
        present = WillingTutor.find_by_sql("SELECT * FROM willing_tutors WHERE person_id = #{person_id} AND course_id = #{course_id}");
        if present !=nil && present.length >0
          already_willing = already_willing + 1;
        else
          new_willing = new_willing +1;
          willing_tutor = WillingTutor.new;
          willing_tutor.person_id = person_id;
          willing_tutor.course_id = course_id;
          willing_tutor.order_of_preference = 1;
          willing_tutor.save;
        end
      end
      if new_willing == 0
        alert_str = "No willing tutor entries were added to the database. "
      elsif new_willing == 1
        alert_str = "1 willing tutor entry was added to the database. "
      else
        alert_str = "#{new_willing} willing tutor entries were added to the database. "
      end
      if already_willing==1
        alert_str << "1 willing tutor entry was already in the database for person with id #{person_id}. "
      elsif already_willing>1
        alert_str << "#{already_willing} willing tutor entries were already in the database for person with id #{person_id}. "
      end
    else
      alert_str = "You did not select any courses. "
    end
    respond_to do |format|
      format.js  {render :partial => "shared/alert", :locals => {:alert_str => alert_str} }
=begin      
do
        render :update do |page|
          page << "alert('#{alert_str}')"
          page << "unwait();"
        end
      end
=end
    end
  end
  
  def create_tutorial_schedules(ids)
    tutor_id = params[:tutor_id];
    course_id =  params[:course_id];
    class_size = params[:tutorial_class_size].to_i;
    if ids != nil && ids.length > 0
      if class_size < 1
        class_size =1;
      end

      number_of_students = ids.length+0.000001;
      number_of_classes = (number_of_students/class_size).round;

      class_count = 1;
      a_class = [];
      tutorial_classes = [];
      student_count = 1;
      upper_bound = (number_of_students * class_count/number_of_classes);
      ids.each do |student_id|
        a_class << student_id;
        student_count= student_count +1;
        if student_count > upper_bound
          tutorial_classes << a_class;
          a_class = [];
          class_count = class_count +1;
          upper_bound = (number_of_students * class_count/number_of_classes);
        end
      end
      if a_class.length>0
        tutorial_classes << a_class;
      end

      tutorial_classes.each do |tutorial_class|
        tutorial_schedule = TutorialSchedule.new;
        tutorial_schedule.course_id = course_id
        tutorial_schedule.person_id = tutor_id
        tutorial_schedule.term_id = params[:term_id];
        tutorial_schedule.number_of_tutorials = params[:number_of_tutorials];        
        tutorial_schedule.number_of_tutorial_hours = params[:number_of_tutorials];
        tutorial_schedule.save;
        tutorial_class.each do |student_id|
        tutorial = Tutorial.new;
        tutorial.person_id = student_id;
        tutorial.tutorial_schedule_id = tutorial_schedule.id;
        tutorial.collection_status = params[:collection_required];
        tutorial.save;
        end
        present = WillingTutor.find_by_sql("SELECT * FROM willing_tutors WHERE person_id = #{tutor_id} AND course_id = #{course_id}");
        if present ==nil || present.length == 0

          willing_tutor = WillingTutor.new;
          willing_tutor.person_id = tutor_id
          willing_tutor.course_id = course_id
          willing_tutor.order_of_preference = 1;
          willing_tutor.save;
        end
      end
      @pluralize_num = tutorial_classes.length;
      alert_str = "#{@pluralize_num} Tutorial/Tutorial " + pl("Schedule") +" created";
    else
      ids = [];
      alert_str = "You did not select any students. "
    end
    @search_ctls = session[:search_ctls];
    respond_to do |format|
      format.js  {render "create_tutorial_schedules", :locals => {:ids => ids, :search_ctls => @search_ctls, :alert_str => alert_str} }
=begin      
      do
        render :update do |page|

            if ids.length >0
            @search_ctls = session[:search_ctls];
            table_name = "Person"
            search_ctl = @search_ctls[table_name];
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", ids);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              page << "setcheck('#{table_name}_check_#{row.id.to_s}',true)"
              page << "}"
            end

            page << "recolour('Person');";
            page << "action_select_no_js();";
            end
            page << "alert('#{alert_str}')"
            page << "unwait();"
          end
          
      end
=end      
    end
  end
  
  def create_lecture_schedule
    lecture = Lecture.new;
    person_id = params[:person_id];
    course_id =  params[:course_id];
    lecture.course_id = params[:course_id];
    lecture.person_id = params[:person_id];
    lecture.day_id = params[:day_id];
    lecture.lecture_time = params[:lecture_time];
    lecture.location_id = SearchController::NOT_SET;
    lecture.term_id = params[:term_id];
    lecture.exam = "";
    lecture.notes = "";
    lecture.number_of_classes = params[:number_of_classes];
    lecture.number_of_lectures = params[:number_of_lectures];
    lecture.save;

     present = WillingLecturer.find_by_sql("SELECT * FROM willing_lecturers WHERE person_id = #{person_id} AND course_id = #{course_id}");
        if present ==nil || present.length == 0

          willing_lecturer = WillingLecturer.new;
          willing_lecturer.person_id =  person_id
          willing_lecturer.course_id =  course_id 
          willing_lecturer.order_of_preference = 1;
          willing_lecturer.save;
        end

    success_str = 'Lecture schedule created';
    error_str = '';
    unwait_flag = true;
    attribute_list = ['id'];
    class_name = 'Lecture'
    id = lecture.id;
    ids = [];
    update_main_([id], class_name, attribute_list, success_str, error_str, unwait_flag);
  
  end
  def make_attendee(lecture_ids)
    error_str = "";
    success_str="";
    person_id = params[:id];
    if lecture_ids == nil || lecture_ids.length == 0
      error_str = "Add/Update attendee failed: you have not selected any lectures. "
    else
      lecture_list = ""
      lecture_ids.each do |lecture_id|
      if lecture_list.length >0
        lecture_list << ", "
      end
        lecture_list << lecture_id.to_s
      end
      lectures_where_str = "(#{lecture_list})"
      non_present_lectures = Lecture.find_by_sql("SELECT * FROM lectures a0 WHERE a0.id IN #{lectures_where_str} AND (SELECT COUNT(*) FROM attendees a1 WHERE a1.person_id = #{person_id} AND a1.lecture_id = a0.id)=0");
      non_present_lectures.each do |lecture|
        attendee = Attendee.new;
        attendee.lecture_id = lecture.id;
        attendee.person_id = person_id;
        attendee.save;
      end
       exam_ids = params[:exam_in_list];
       exam_list = "";
      if exam_ids == nil || exam_ids.length == 0
         exam_ids = [];
         non_exam_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.lecture_id IN #{lectures_where_str} AND a0.person_id = #{person_id}");
         exam_attendees = []
      else
        exam_ids.each do |exam_id|
          if exam_list.length >0
            exam_list << ", "
          end
            exam_list << exam_id.to_s
        end
        exam_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.lecture_id IN (#{exam_list}) AND a0.person_id = #{person_id}");
        non_exam_attendees =  Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.lecture_id IN (#{lecture_list}) AND a0.lecture_id NOT IN (#{exam_list}) AND a0.person_id = #{person_id}");
      end
      exam_attendees.each do |attendee|
        attendee.examined = true;
        attendee.save;
      end
      non_exam_attendees.each do |attendee|
        attendee.examined = false;
        attendee.save;
      end
      compulsory_ids = params[:compulsory_in_list];
      compulsory_list = "";
      if compulsory_ids == nil || compulsory_ids.length == 0
         compulsory_ids = [];
         non_compulsory_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.lecture_id IN #{lectures_where_str} AND a0.person_id = #{person_id}");
         compulsory_attendees = []
      else
        compulsory_ids.each do |compulsory_id|
          if compulsory_list.length >0
            compulsory_list << ", "
          end
            compulsory_list << compulsory_id.to_s
        end
        compulsory_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.lecture_id IN (#{compulsory_list}) AND a0.person_id = #{person_id}");
        non_compulsory_attendees =  Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.lecture_id IN (#{lecture_list}) AND a0.lecture_id NOT IN (#{compulsory_list}) AND a0.person_id = #{person_id}");
      end
      compulsory_attendees.each do |attendee|
        attendee.compulsory = true;
        attendee.save;
      end
      non_compulsory_attendees.each do |attendee|
        attendee.compulsory = false;
        attendee.save;
      end
      non_present_num = non_present_lectures.length;
      if non_present_num == 0
        success_str = "Attendees were updated, although no new lecture was attended because lecture in the selected list was already attended the person. "
      elsif non_present_num ==1
        success_str = "The person was added to one lecture attendee list. "
      else
        success_str = "The person was added to #{non_present_num} lecture attendee lists. "
      end
      if non_present_num != 0
        present_num = lecture_ids.length - non_present_num
        if present_num ==1
          success_str << "The person was already attending the selected lecture. "
        elsif present_num > 1
          success_str << "The person was already on the lecture attendee list of #{present_num} of the lectures. "
        end
      end
    end

        @search_ctls = session[:search_ctls];
        respond_to do |format|
      format.js { render "make_attendee", :locals => { :error_str => error_str, :search_ctls => @search_ctls, :person_id => person_id, :lecture_ids => lecture_ids, :compulsory_ids => compulsory_ids, :exam_ids => exam_ids, :success_str => success_str } }
=begin      
       do
        render :update do |page|
          if error_str.length >0
            page << "alert('#{error_str}')";
          else

            @search_ctls = session[:search_ctls];
            table_name = "Person"
            search_ctl = @search_ctls[table_name];
            id_array = [];
            id_array << person_id.to_i;
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", id_array);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              page << "}"
            end
            table_name = "Lecture"
            search_ctl = @search_ctls[table_name];
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", lecture_ids);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              if compulsory_ids.index(row.id.to_s);
                page << "setcheck('#{table_name}_compulsorycheck_#{row.id.to_s}',true)"
              end
              if exam_ids.index(row.id.to_s);
                page << "setcheck('#{table_name}_examcheck_#{row.id.to_s}',true)"
              end
              page << "setcheck('#{table_name}_check_#{row.id.to_s}',true)"
              page << "}"
            end


            page << "recolour('Lecture');";
            page << "recolour('Person');";
            page << "action_select_no_js();";
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end      
    end
  end


  def add_to_lectures(people_ids)
    lecture_id = params[:id];
    error_str = "";
    success_str="";
    if people_ids == nil || people_ids.length == 0
      error_str = "Add/Update lectures failed: you have not selected any people. "
    else
      people_list = ""
      people_ids.each do |person_id|
      if people_list.length >0
        people_list << ", "
      end
        people_list << person_id.to_s
      end
      people_where_str = "(#{people_list})"
      non_present_people = Person.find_by_sql("SELECT * FROM people a0 WHERE a0.id IN #{people_where_str} AND (SELECT COUNT(*) FROM attendees a1 WHERE a1.person_id = a0.id AND a1.lecture_id = #{lecture_id})=0");
      non_present_people.each do |person|
        attendee = Attendee.new;
        attendee.lecture_id = lecture_id;
        attendee.person_id = person.id;
        attendee.save;
      end
      exam_ids = params[:exam_in_list];
      
      exam_list = "";
      if exam_ids == nil || exam_ids.length == 0
         exam_ids = [];
         non_exam_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.person_id IN #{people_where_str} AND a0.lecture_id = #{lecture_id}");
         exam_attendees = []
      else
        exam_ids.each do |exam_id|
          if exam_list.length >0
            exam_list << ", "
          end
            exam_list << exam_id.to_s
        end
        exam_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.person_id IN (#{exam_list}) AND a0.lecture_id = #{lecture_id}");
        non_exam_attendees =  Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.person_id IN (#{people_list}) AND a0.person_id NOT IN (#{exam_list}) AND a0.lecture_id = #{lecture_id}");
      end
      exam_attendees.each do |attendee|
        attendee.examined = true;
        attendee.save;
      end
      non_exam_attendees.each do |attendee|
        attendee.examined = false;
        attendee.save;
      end
      compulsory_ids = params[:compulsory_in_list];
      compulsory_list = "";
      if compulsory_ids == nil || compulsory_ids.length == 0
         compulsory_ids = [];
         non_compulsory_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.person_id IN #{people_where_str} AND a0.lecture_id = #{lecture_id}");
         compulsory_attendees = []
      else
        compulsory_ids.each do |compulsory_id|
          if compulsory_list.length >0
            compulsory_list << ", "
          end
            compulsory_list << compulsory_id.to_s
        end
        compulsory_attendees = Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.person_id IN (#{compulsory_list}) AND a0.lecture_id = #{lecture_id}");
        non_compulsory_attendees =  Attendee.find_by_sql("SELECT * FROM attendees a0 WHERE a0.person_id IN (#{people_list}) AND a0.person_id NOT IN (#{compulsory_list}) AND a0.lecture_id = #{lecture_id}");
      end
      compulsory_attendees.each do |attendee|
        attendee.compulsory = true;
        attendee.save;
      end
      non_compulsory_attendees.each do |attendee|
        attendee.compulsory = false;
        attendee.save;
      end
      non_present_num = non_present_people.length;
      if non_present_num == 0
        success_str = "Attendees were updated, although no one was added because everyone in the selected list was already attending the lecture course. "
      elsif non_present_num ==1
        success_str = "One person was added to the lecture attendee list. "
      else
        success_str = "#{non_present_num} people were added to the lecture attendee list. "
      end
      if non_present_num != 0
        present_num = people_ids.length - non_present_num
        if present_num ==1
          success_str << "One person was already on the lecture attendee list. "
        elsif present_num > 1
          success_str << "#{present_num} people were already on the lecture attendee list. "
        end
      end
    end

    

    @search_ctls = session[:search_ctls];
    respond_to do |format|
      format.js { render "add_to_lectures", :locals => { :error_str => error_str, :search_ctls => @search_ctls, :people_ids => people_ids, :lecture_id => lecture_id, :compulsory_ids => compulsory_ids, :exam_ids => exam_ids, :success_str => success_str } }
=begin      
       do
        render :update do |page|
          if error_str.length >0
            page << "alert('#{error_str}')";
          else
            
            @search_ctls = session[:search_ctls];
            table_name = "Lecture"
            search_ctl = @search_ctls[table_name];
            id_array = [];
            id_array << lecture_id.to_i;
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", id_array);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              page << "}"
            end
            table_name = "Person"
            search_ctl = @search_ctls[table_name];
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", people_ids);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              if compulsory_ids.index(row.id.to_s);
                page << "setcheck('#{table_name}_compulsorycheck_#{row.id.to_s}',true)"
              end
              if exam_ids.index(row.id.to_s);
                page << "setcheck('#{table_name}_examcheck_#{row.id.to_s}',true)"
              end
              page << "setcheck('#{table_name}_check_#{row.id.to_s}',true)"
              page << "}"
            end


            page << "recolour('Lecture');";
            page << "recolour('Person');";
            page << "action_select_no_js();";
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end      
    end
  end

  def remove_from_group(group_id, ids, class_name2)
    Rails.logger.info("RWV remove_from_group BEGIN")
    @user_id = session[:user_id];
    db_group = Group.find(group_id);
    permission = false
    class_ok= false
    num_existing = 0;
    Rails.logger.info("RWV remove_from_group A")
    if(db_group != nil)
        if db_group.private == false || db_group.owner_id = @user_id
            permission = true;
        end
    end
Rails.logger.info("RWV remove_from_group B")
    if(permission)
        Rails.logger.info("RWV remove_from_group C")
        if(class_name2.tableize == db_group.table_name)
            class_ok= true;
            Rails.logger.info("RWV remove_from_group D")
            if (ids.length > 0)
                Rails.logger.info("RWV remove_from_group E")
                id_str = ""
                ids.each do |id|
                    if id_str.length >0
                        id_str << ", "
                    end
                    id_str << id.to_s;
                end
                Rails.logger.info("RWV remove_from_group F")
                already_existing = Group.find_by_sql("SELECT * FROM group_#{class_name2.tableize} WHERE #{class_name2.underscore}_id IN (#{id_str}) AND group_id = #{group_id}");
                num_existing = already_existing.length;
                not_present_members = Array.new(ids);
                Rails.logger.info("RWV remove_from_group G")
                
                already_existing.each do |existing|
                    existing_id_str = "existing.#{class_name2.underscore}_id";
                    existing_id = eval(existing_id_str)
                    Rails.logger.info("RWV remove_from_group existing_id_str = #{existing_id_str}, existing_id = #{existing_id}")
                    not_present_members.delete(existing_id.to_s);
                end
                Rails.logger.info("RWV remove_from_group H")
                Rails.logger.info("RWV remove_from_group not_present_members = #{not_present_members.inspect}");
                already_existing.each do |delete_obj|
                    destroy_str = "Group#{class_name2}.destroy(#{delete_obj.id})";
                    Rails.logger.info("RWV remove_from_group #{destroy_str}");
                    eval(destroy_str);
                    # delete_obj.destroy;
                end
                Rails.logger.info("RWV remove_from_group I")
            end
            Rails.logger.info("RWV remove_from_group J")
        end
        Rails.logger.info("RWV remove_from_group K")
    end
    Rails.logger.info("RWV remove_from_group L")
    @search_ctls = session[:search_ctls];
    if class_ok
        Rails.logger.info("RWV remove_from_group M")
        table_name = class_name2;
        search_ctl = @search_ctls[table_name]; 
        search_ctl_group =  @search_ctls["Group"];
    else
        Rails.logger.info("RWV remove_from_group O")
        search_ctl = nil;
    end
    Rails.logger.info("RWV remove_from_group P")

    respond_to do |format|
        format.js  { render "remove_from_group", :locals => { :db_group => db_group, :group_id => group_id, :permission => permission, :class_ok => class_ok, :class_name2 => class_name2, :not_present_members => not_present_members, :num_existing => num_existing, :search_ctl => search_ctl, :search_ctl_group => search_ctl_group, :ids => ids, :table_name => table_name } }
    end
    Rails.logger.info("RWV remove_from_group END")
    Rails.logger.flush
  end      
=begin      
      do
        render :update do |page|
          if(db_group== nil)
          page << "alert('Remove Selected Failed: Could not find group id #{group_id} in database')"
          elsif(!permission )
            page << "alert('Remove Selected Failed: You do not have permission to edit group #{db_group.group_name}')"
          elsif(!class_ok)
            page << "alert('Remove Selected Failed: The #{db_group.group_name} is for members of type #{db_group.table.classify} rather than type #{class_name2}')"
          elsif(ids.length == 0)
            page << "alert('Remove Selected Failed: You have not selected any #{db_group.table_name}')"
          else
            success_str = ""
            if  num_existing == 1
              success_str << "1 #{class_name2} has been removed from the group #{db_group.group_name}. "
            elsif  num_existing >1
              success_str << "#{num_existing} #{class_name2.tableize} have been removed from the group #{db_group.group_name}. "
            end
            if not_present_members.length == 1
              success_str <<  "1 #{class_name2} was not in the group #{db_group.group_name} to begin with. "
            elsif not_present_members.length > 1
              success_str << "#{not_present_members.length} #{class_name2.tableize} were not in the group #{db_group.group_name} to begin with."
            end
            page << "alert('#{success_str}')"
           end
          page << "unwait();"
        end
      end
=end      


  def add_to_groups(group_ids, class_id, class_name)
    @user_id = session[:user_id];
    if group_ids.length >0
      group_ids_str = "";
      group_ids.each do |group_id|
        if(group_ids_str.length >0)
          group_ids_str << ", "
        end
        group_ids_str << group_id.to_s;
      end
      group_ids_str = "(#{group_ids_str})";
      unpermissioned_str = "SELECT * FROM groups WHERE id IN #{group_ids_str} AND table_name = '#{class_name.tableize}' AND (owner_id != #{@user_id} AND private = true)"
      Rails.logger.info("unpermissioned_str: #{unpermissioned_str}");
      unpermissioned = Group.find_by_sql(unpermissioned_str)
      wrong_types_str = "SELECT * FROM groups WHERE id IN #{group_ids_str} AND table_name != '#{class_name.tableize}' AND (owner_id = #{@user_id} OR private = false)";
      Rails.logger.info("wrong_types_str: #{wrong_types_str}");
      wrong_types = Group.find_by_sql(wrong_types_str)
      permissioned_str = "SELECT * FROM groups WHERE id IN #{group_ids_str} AND table_name = '#{class_name.tableize}' AND (owner_id = #{@user_id} OR private = false)"
      Rails.logger.info("permissioned_str: #{permissioned_str}");
      permissioned = Group.find_by_sql(permissioned_str)
      if permissioned.length >0
        permission_id_str = "";
        permissioned.each do |permission_group|
          if(permission_id_str.length > 0)
            permission_id_str << ", "
          end
          permission_id_str << permission_group.id.to_s
        end
         permission_id_str = "(#{permission_id_str})"
         sql_str = "SELECT * FROM groups a0 WHERE a0.id IN #{permission_id_str} AND (SELECT COUNT(*) FROM group_#{class_name.tableize} WHERE group_id = a0.id AND #{class_name.underscore}_id = #{class_id})=0"
         unpresent = Group.find_by_sql(sql_str);
         present = Group.find_by_sql("SELECT * FROM group_#{class_name.tableize} WHERE group_id  IN #{permission_id_str} AND #{class_name.underscore}_id = #{class_id}");

         unpresent.each do |db_group|
          new_group_member_str = "Group#{class_name}.new"
          new_group_member = eval(new_group_member_str);
          new_group_member.group_id = db_group.id;
          new_group_member_id_str = "new_group_member.#{class_name.underscore}_id = #{class_id}"
          eval(new_group_member_id_str);
          new_group_member.save;
         end
      end
    end
    @search_ctls = session[:search_ctls];
    table_name = class_name
    search_ctl = @search_ctls[table_name];
    search_ctl_group = @search_ctls["Group"];
    respond_to do |format|
      format.js { render "add_to_groups", :locals => { :group_ids => group_ids, :permissioned => permissioned, :unpresent => unpresent, :class_name => class_name, :present => present, :wrong_types => wrong_types, :class_id => class_id, :unpermissioned => unpermissioned, :search_ctl => search_ctl, :search_ctl_group => search_ctl_group } }
=begin      
      do
        render :update do |page|
          if(group_ids.length == 0)
            page << "alert('Add Selected Failed: You did not select any groups')"
          elsif permissioned.length == 0
            page << "alert('You do not have permission to add members to any of the selected groups')";
          else
            success_str = "";
            if unpresent.length ==1
              success_str << "#{class_name} was added to 1 group. "
            elsif unpresent.length >1
              success_str << "#{class_name} was added to #{unpresent.length} groups. "
            end
            if present.length == 1
              success_str << "#{class_name} was not added to 1 group because it was already in it. "
            elsif present.length >1
              success_str << "#{class_name} was not added to #{present.length} groups because it was already in them. "
            end
            if wrong_types.length == 1
              success_str << "#{class_name} was not added to 1 group because it was of the wrong type. "
            elsif wrong_types.length > 1
              success_str << "#{class_name} was not added to #{wrong_types.length} groups because they were of the wrong type. "
            end
            if unpermissioned.length == 1
              success_str << "#{class_name} was not added to 1 group because you did not have permission to update this group. "
            elsif unpermissioned.length >1
              success_str << "#{class_name} was not added to #{unpermissioned.length} groups because you did not have permission to update these groups. "
            end
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end      
    end    
  end
  def remove_from_groups(group_ids, class_id, class_name)
      Rails.logger.info("remove_from_groups begin ");
    @user_id = session[:user_id];
    if group_ids.length >0
      group_ids_str = "";
      group_ids.each do |group_id|
        if(group_ids_str.length >0)
          group_ids_str << ", "
        end
        group_ids_str << group_id.to_s;
      end
      group_ids_str = "(#{group_ids_str})";
      unpermissioned = Group.find_by_sql("SELECT * FROM groups WHERE id IN #{group_ids_str} AND table_name = '#{class_name.tableize}' AND (owner_id != #{@user_id} AND private = true)")
      wrong_types = Group.find_by_sql("SELECT * FROM groups WHERE id IN #{group_ids_str} AND table_name != '#{class_name.tableize}' AND (owner_id = #{@user_id} OR private = false)")
      permissioned = Group.find_by_sql("SELECT * FROM groups WHERE id IN #{group_ids_str} AND table_name = '#{class_name.tableize}' AND (owner_id = #{@user_id} OR private = false)")
      if permissioned.length >0
        permission_id_str = "";
        permissioned.each do |permission_group|
          if(permission_id_str.length > 0)
            permission_id_str << ", "
          end
          permission_id_str << permission_group.id.to_s
        end
         permission_id_str = "(#{permission_id_str})"
         sql_str = "SELECT * FROM groups a0 WHERE a0.id IN #{permission_id_str} AND (SELECT COUNT(*) FROM group_#{class_name.tableize} WHERE group_id = a0.id AND #{class_name.underscore}_id = #{class_id})=0"
         unpresent = Group.find_by_sql(sql_str);
         present = Group.find_by_sql("SELECT * FROM group_#{class_name.tableize} WHERE group_id  IN #{permission_id_str} AND #{class_name.underscore}_id = #{class_id}");

         present.each do |group_member|
           destroy_str = "Group#{class_name}.destroy(#{group_member.id})"
           eval(destroy_str);

         end
      end
    end
    @search_ctls = session[:search_ctls];
    table_name = class_name;
    search_ctl = @search_ctls[table_name];
    search_ctl_group = @search_ctls["Group"];
    Rails.logger.info("remove_from_groups 01 ");
    respond_to do |format|
      format.js  { render "remove_from_groups", :locals => {:group_ids => group_ids, :permissioned => permissioned, :present => present, :unpresent => unpresent, :wrong_types => wrong_types, :unpermissioned => unpermissioned, :search_ctl => search_ctl, :search_ctl_group => search_ctl_group, :class_name => class_name , :class_id => class_id } }
=begin      
      do
        render :update do |page|
          if(group_ids.length == 0)
            page << "alert('Remove Selected Failed: You did not select any groups')"
          elsif permissioned.length == 0
            page << "alert('You do not have permission to remove members from any of the selected groups')";
          else
            success_str = "";
            if present.length ==1
              success_str << "#{class_name} was removed from 1 group. "
            elsif present.length >1
              success_str << "#{class_name} was removed from #{present.length} groups. "
            end
            if unpresent.length == 1
              success_str << "#{class_name} was not removed from 1 group because it was not there to begin with. "
            elsif unpresent.length >1
              success_str << "#{class_name} was not removed from #{unpresent.length} groups because it was not there to begin with. "
            end
            if wrong_types.length == 1
              success_str << "#{class_name} was not removed from 1 group because it was of the wrong type. "
            elsif wrong_types.length > 1
              success_str << "#{class_name} was not removed from #{wrong_types.length} groups because they were of the wrong type. "
            end
            if unpermissioned.length == 1
              success_str << "#{class_name} was not removed from 1 group because you did not have permission to update this group. "
            elsif unpermissioned.length >1
              success_str << "#{class_name} was not removed from #{unpermissioned.length} groups because you did not have permission to update these groups. "
            end
            page << "alert('#{success_str}')";
          end
          page << "unwait();"
        end
      end
=end      
    end
  end


  def add_to_group(group_id, ids, class_name2)

  @user_id = session[:user_id];
  db_group = Group.find(group_id);
  permission = false
  class_ok= false
    if(db_group != nil)
      if db_group.private == false || db_group.owner_id = @user_id
        permission = true;
      end
    end

    if(permission)
      if(class_name2.tableize == db_group.table_name)
        class_ok= true;
        if (ids.length > 0)
        id_str = ""
        ids.each do |id|
          if id_str.length >0
            id_str << ", "
          end
          id_str << id.to_s;
        end
        already_existing_str = "SELECT * FROM group_#{class_name2.tableize} WHERE #{class_name2.underscore}_id IN (#{id_str}) AND group_id = #{group_id}";
        Rails.logger.info("RWV add_to_group, already_existing_str = #{already_existing_str}")
        already_existing = Group.find_by_sql(already_existing_str);
        new_members = Array.new(ids);
        Rails.logger.info("RWV ids = #{ids.inspect}");
        already_existing.each do |existing|
          existing_id_str = "existing.#{class_name2.underscore}_id";
          existing_id = eval(existing_id_str)
          Rails.logger.info("RWV existing_id_str = #{existing_id_str}, existing_id = #{existing_id}")
          new_members.delete(existing_id.to_s);
        end
        Rails.logger.info("RWV new_members = #{new_members.inspect}");
        new_members.each do |new_id|
          new_group_member_str = "Group#{class_name2}.new"
          new_group_member = eval(new_group_member_str);
          new_group_member.group_id = db_group.id;
          new_group_member_id_str = "new_group_member.#{class_name2.underscore}_id = #{new_id}"
          Rails.logger.info("RWV new_group_member_id_str = #{new_group_member_id_str}");
          
          eval(new_group_member_id_str);
          new_group_member.save;
        end
      end
    end
    end
   @search_ctls = session[:search_ctls];
   if class_ok
      table_name = class_name2;
      search_ctl = @search_ctls[table_name]; 
      search_ctl_group =  @search_ctls["Group"];
   else
       search_ctl = nil;
   end  
   respond_to do |format|
      format.js { render "add_to_group", :locals => { :db_group => db_group, :group_id => group_id, :permission => permission, :class_ok => class_ok, :class_name2 => class_name2, :table_name => table_name, :ids => ids, :already_existing => already_existing, :new_members => new_members, :search_ctl => search_ctl, :search_ctl_group => search_ctl_group  } }
=begin      
       do
        render :update do |page|
          if(db_group== nil)
          page << "alert('Add Selected Failed: Could not find group id #{group_id} in database')"
          elsif(!permission )
            page << "alert('Add Selected Failed: You do not have permission to edit group #{db_group.group_name}')"
          elsif(!class_ok)
            page << "alert('Add Selected Failed: The #{db_group.group_name} is for members of type #{db_group.table.classify} rather than type #{class_name2}')"
          elsif(ids.length == 0)
            page << "alert('Add Selected Failed: You have not selected any #{db_group.table_name}')"
          else
            success_str = ""
            if already_existing.length == 1
              success_str << "1 #{class_name2} was already in the group #{db_group.group_name}. "
            elsif already_existing.length >1
              success_str << "#{already_existing.length} #{class_name2.tableize} were already in the group #{db_group.group_name}. "
            end
            if new_members.length == 1
              success_str <<  "1 #{class_name2} was added to the group #{db_group.group_name}. "
            elsif new_members.length > 1
              success_str << "#{new_members.length} #{class_name2.tableize} were added to the group #{db_group.group_name}"
            end
            page << "alert('#{success_str}')"
          end
          page << "unwait();"
        end
      end
=end      
    end

  end

  def new_group(ids, class_name, group_name, group_privacy)
    group_name = group_name.gsub(/^\s+/,'').gsub(/\s+$/,'');
    if(group_name.length ==0)
      alert_str = "Group creation failed: the chosen group name #{group_name} can't be an empty string.";
      respond_to do |format|
        format.js  {render :partial => "shared/alert", :locals => {:alert_str => alert_str} }
=begin      
do
          render :update do |page|
       page << "alert(\"Group creation failed: the chosen group name #{group_name} can't be an empty string.\")"
       page << "unwait();"
          end
        end
=end
      end
      return;
    end

    table_name = class_name.tableize;
    Rails.logger.info("RWV Created new group I am here");
    existing_group = Group.where(:group_name => group_name, :table_name => table_name).first;
    if(existing_group == nil)
        Rails.logger.info("RWV Created new group");

      new_group = Group.new;
      new_group.group_name = group_name;
      new_group.table_name = table_name;
      new_group.owner_id= session[:user_id];
      new_group.readers_id = 1;
      new_group.writers_id = 1;
      new_group.private = group_privacy;
      new_group.save;
      new_group_id = new_group.id;
      if ids != nil
        for id in ids
          new_group_member_str = "Group#{class_name}.new"
          new_group_member =  eval(new_group_member_str);
          new_group_member.group_id = new_group.id
          new_group_member_member_str= "new_group_member.#{class_name.underscore}_id = #{id}"
          eval(new_group_member_member_str);
          new_group_member.save;
        end
      end

    end
    @search_ctls = session[:search_ctls];
    table_name = class_name;
    search_ctl = @search_ctls[table_name];
    search_ctl_group = @search_ctls["Group"];

    respond_to do |format|
          
       
        format.js  { render "new_group", :locals => { :existing_group => existing_group, :class_name => class_name, :table_name => table_name, :group_name => group_name, :new_group_id => new_group_id, :ids => ids, :search_ctl => search_ctl, :search_ctl_group => search_ctl_group } }
=begin         
        do
          render :update do |page|
            if(existing_group ==nil)
             page << "alert(\"Successfully created #{class_name} group with name #{group_name}\")"
             page << "add_group(\"#{class_name}\",\"#{group_name}\", \"#{new_group.id}\")"
            else
              page << "alert(\"Group creation failed: #{class_name} group with name #{group_name} already exists.\")"
            end
            page << "unwait();"
          end
        end
=end        
      end

  end
  def update_tutorial_number(ids, tutorial_number)
    tutorial_number = tutorial_number.to_i
    if(tutorial_number <0)
        alert_str = "Set Tutorial Number failed: the number of tutorial can't be negative."
        respond_to do |format|
            format.js  {render :partial => "shared/alert", :locals => {:alert_str => alert_str} }
        end    
=begin
    do
    render :update do |page|
    page << "alert(\"Set Tutorial Number failed: the number of tutorial can't be negative.\")"
    page << "unwait();"
    end
    end
=end    
        return;
    end
    if ids.length == 0
        alert_str = "Set Tutorial Number failed: you didn't select any tutorial scedules to be updated."
        respond_to do |format|
            format.js {render :partial => "shared/alert", :locals => {:alert_str => alert_str} }  
        end 
=begin        
            do
          render :update do |page|
       page << "alert(\"Set Tutorial Number failed: you didn't select any tutorial scedules to be updated.\")"
       page << "unwait();"
          end
        end
      end
=end      
      return;
    end
    id_str = ""
    ids.each do |id|
        if id_str.length >0
            id_str << ", "
        end
        id_str << id.to_s;
    end
    tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE id IN (#{id_str})");

      tutorial_schedules.each do |tutorial_schedule|
        tutorial_schedule.number_of_tutorials = tutorial_number;
        tutorial_schedule.save;
      end


      @pluralize_num = ids.length;
      success_str = "#{@pluralize_num} "+ pl("tutorial schedule") +" updated to have "
      @pluralize_num = tutorial_number;
      success_str = success_str + "#{@pluralize_num} " + pl("tutorial");
      table_name = "TutorialSchedule"
      @search_ctls = session[:search_ctls];
      search_ctl = @search_ctls[table_name];
      respond_to do |format|
        format.js { render "shared/update_main", :locals => {:search_ctls => @search_ctls, :edited_table_name => table_name, :attribute_names => ["number_of_tutorials"], :ids => ids, :success_str => success_str, :fail_str => "" , :unwait_flag => true } }  
          
 
=begin        
        do
          render :update do |page|

            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, ["id"], ids);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              page << "setcheck('#{table_name}_check_#{row.id.to_s}',true)"
              page << "}"
            end

            page << "recolour('TutorialSchedule');"
            page << "action_select_no_js();";
            page << "alert(\"#{success_str}\")"
            page << "unwait();"
          end
        end
=end
      end

  end
  
  def update_collection_status(ids, new_status)
    if (ids.length > 0)
      id_str = ""
      ids.each do |id|
        if id_str.length >0
          id_str << ", "
        end
        id_str << id.to_s;
      end
      tutorials = Tutorial.find_by_sql("SELECT * FROM tutorials WHERE id IN (#{id_str})");

     
      tutorials.each do |tutorial|
        tutorial.collection_status = new_status;
        tutorial.save;
      end

      case new_status
        when 2
          status_str = "COLLECTION HAS BEEN TAKEN"
        when 1
          status_str = "COLLECTION TO BE TAKEN"
      else
          status_str = "COLLECTION UNNECESSARY"
      end
      @pluralize_num = ids.length;
      success_str = "#{@pluralize_num} "+ pl("tutorial") +" updated with status #{status_str}";
    else
      success_str = "no tutorials were selected"
    end
      @search_ctls = session[:search_ctls];
      respond_to do |format|
        format.js  { render "update_collection_status", :locals => {:search_ctls => @search_ctls, :ids => ids, :success_str => success_str } }
=begin        
        do
          render :update do |page|
            table_name = "Tutorial"
            @search_ctls = session[:search_ctls];
            search_ctl = @search_ctls[table_name];
            eval("#{table_name}.set_controller(search_ctl)");
            updated_objects = search_ctl.GetUpdateObjects(table_name, "id", ids);
            updated_objects.each do |row|
               page << "if ($('#{row.id}_#{ table_name}')) {"
              page["#{row.id}_#{table_name}"].replace( :partial => "shared/search_results_row_button", :object =>row );
              page << "setcheck('#{table_name}_check_#{row.id.to_s}',true)"
              page << "}"
            end

            page << "action_select_no_js();";
            page << "alert(\"#{success_str}\")"
            page << "unwait();"
          end
        end
=end        
      end
    end

  def check_dependencies(ids, table_name)
    dependencies_present = [];
    if(ids.length == 0)
      return dependencies_present 
    end
    has_many_str = table_name + ".reflect_on_all_associations(:has_many)";
    has_manys = eval(has_many_str);

    dependent_str ="";
    id_str = "";
    for id in ids
      if id_str.length>0
        id_str << ", "
      end
      id_str << id.to_s;
    end
    dependent_tables = {};
    for has_many in has_manys
      dependent_table_name = has_many.class_name;
      reflection_str = dependent_table_name + ".reflect_on_all_associations(:belongs_to)"
      reflections = eval(reflection_str);

      for reflection in reflections
        if reflection.class_name == table_name
          foreign_key =reflection.options[:foreign_key] ;
          if dependent_tables.has_key?(dependent_table_name)
            if dependent_tables[dependent_table_name].index(foreign_key) == nil
              dependent_tables[dependent_table_name] << foreign_key
            end
          else
            dependent_tables[dependent_table_name] = [];
            dependent_tables[dependent_table_name] << foreign_key;
          end
        end
      end
    end
    ids.each do |id|
      id_dependencies  = []; #ret value is a list of these Dependency objects
      dependent_hash = {}
      dependent_tables.each do |dependent_table_name, foreign_keys|
        dependent_ids = []; # this is the list in a Dependency object
        foreign_keys.each do |foreign_key|
          objects_str = "#{reflection.class_name}.find_by_sql(\"SELECT id, #{foreign_key} FROM #{ dependent_table_name.tableize} WHERE #{foreign_key} = #{id}\")"
          objects = eval(objects_str);
          if objects.length >0
            objects.each do |object|
              if dependent_ids.index(object.id) == nil
                dependent_ids <<  object.id;
              end
            end

          end

        end
        if dependent_ids.length >0
          dependent_hash[dependent_table_name] = dependent_ids
          #  id_dependencies << Dependency.new(, );
        end        
      end
      dependencies_present << dependent_hash;
    end
    return dependencies_present;
  end

  def delete_array(ids, table_name)
    dependencies_present = check_dependencies(ids, table_name)


    delete_hash = {}
    delete_hash_str ={}
    error_str = ""
    success_str = "";
    deleted_ids = "";
    num_deletes = 0;
    num_ids = ids.length;
    for id_count in (0..(num_ids -1))
      do_delete = true;
      
      current_dependencies = dependencies_present[id_count];
      if table_name == "User" && ids[id_count] == session[:user].id
        do_delete = false;
        error_str = "You cannot delete your user account whilst you are logged in. "
      elsif current_dependencies.length >0
        if  current_dependencies.has_key?("WillingTutor") || current_dependencies.has_key?("WillingLecturer") ||current_dependencies.has_key?("Group") || current_dependencies.has_key?("MaxTutorial") || current_dependencies.has_key?("User") || current_dependencies.has_key?("TutorialSchedule") || current_dependencies.has_key?("Lecture") ||  current_dependencies.has_key?("Term") ||current_dependencies.has_key?("Person")||current_dependencies.has_key?("AgathaEmail") ||current_dependencies.has_key?("AgathaFile")
          do_delete = false;
        elsif  table_name == "AgathaFile" && current_dependencies.has_key?("EmailAttachment")
          do_delete = false;
        elsif table_name == "Lecture" && current_dependencies.has_key?("Attendee")
          do_delete = false;
        elsif table_name == "TutorialSchedule" && current_dependencies.has_key?("Tutorial") && current_dependencies["Tutorial"].length >1
          do_delete = false;
        elsif table_name == "Person" && current_dependencies.has_key?("TutorialSchedule")
          do_delete = false;
        else
          do_delete = true;
          
        end
      end
      if do_delete
        delete_tutorial_schedule = false;
        num_deletes = num_deletes +1;
        if table_name == "Tutorial"
          tutorial = Tutorial.find(ids[id_count]);
          tutorial_schedule_ids = [tutorial.tutorial_schedule_id];
          tutorials = Tutorial.find_by_sql("SELECT COUNT(*) AS tutee_num FROM tutorials WHERE tutorial_schedule_id = #{tutorial.tutorial_schedule_id}");
          if(tutorials[0].tutee_num.to_i == 1)
            delete_tutorial_schedule = true;
          end

        elsif table_name == "Person"
          tutorials = Tutorial.find_by_sql("SELECT * FROM tutorials WHERE person_id IN (#{ids[id_count]})");
          tutorial_schedule_id_str = "";
          tutorials.each do |tutorial2|
            if tutorial_schedule_id_str.length >0
              tutorial_schedule_id_str << ", ";
            end
            tutorial_schedule_id_str << tutorial2.tutorial_schedule_id.to_s
          end
          tutorial_schedules = [];
          if tutorials.length >0
            tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules a1 WHERE id IN (#{tutorial_schedule_id_str}) AND (SELECT COUNT(*) FROM tutorials a2 WHERE a2.tutorial_schedule_id = a1.id)=1");
          end
          if tutorial_schedules.length >0
            delete_tutorial_schedule = true;
            tutorial_schedule_ids = [];
            tutorial_schedules.each do |tutorial_schedule|
              tutorial_schedule_ids << tutorial_schedule.id;
            end
          end
          
        end

        
        current_dependencies.each do |dependent_table, dependent_ids|
          if(delete_hash.has_key?(dependent_table) == false)          
            delete_hash[dependent_table] ={}
          end
          dependent_ids.each do |dependent_id|
            delete_hash[dependent_table][dependent_id]=true;
          end
        end
        current_obj_str = "#{table_name}.find(#{ids[id_count]})"
        object = eval(current_obj_str);
        
        object.destroy;
        
        if deleted_ids.length >0
          deleted_ids << ", ";
        end
        deleted_ids << ids[id_count].to_s;
        if delete_tutorial_schedule
          if(delete_hash.has_key?("TutorialSchedule") == false)
            delete_hash["TutorialSchedule"] ={}
          end
          tutorial_schedule_id_str = ""
          tutorial_schedule_ids.each do |tutorial_schedule_id|
           delete_hash["TutorialSchedule"][tutorial_schedule_id]=true;
           if tutorial_schedule_id_str.length >0
             tutorial_schedule_id_str << ", "
           end
           tutorial_schedule_id_str << tutorial_schedule_id.to_s
          end
           tutorial_dependencies = check_dependencies(tutorial_schedule_ids, "TutorialSchedule")[0];
           tutorial_dependencies.each do |dependent_table, dependent_ids|
          if(delete_hash.has_key?(dependent_table) == false)
            delete_hash[dependent_table] ={}
          end
          dependent_ids.each do |dependent_id|
            delete_hash[dependent_table][dependent_id]=true;
          end
          tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE id IN (#{tutorial_schedule_id_str})");

          tutorial_schedules.each do |tutorial_schedule|
            tutorial_schedule.destroy;
          end
        end

        end
      else
        current_dependencies.each do |dependent_table, dependent_ids|
          @pluralize_num = dependent_ids.length ;
          error_str << "#{table_name} id = #{ids[id_count]} depends on #{dependent_table} with " + pl("id") + " = "
          id_str = ""
          dependent_ids.each do |dependent_id|
            if id_str.length >0
              id_str << ", ";
            end
            id_str << dependent_id.to_s;
          end
          id_str << ". ";
          error_str << id_str ;
        end       
      end
    end
    @pluralize_num =num_deletes  ;
    if num_deletes >0

      success_str << "#{table_name} with " + pl("id") + " = #{deleted_ids} " + pl("was")+" DELETED. "

      delete_hash.each do |delete_table, id_hash|
        delete_hash_str[delete_table] = "";
        id_hash.each do |id_key, true_value|
          if delete_hash_str[delete_table].length >0
            delete_hash_str[delete_table] << ", ";
          end
          delete_hash_str[delete_table] << id_key.to_s;

        end
      end

     




    end
   Rails.logger.info("RWV deleted_ids = #{deleted_ids.inspect}");


    respond_to do |format|
      format.js  { render "delete_array" , :locals => { :success_str => success_str, :error_str => error_str, :deleted_ids => deleted_ids, :table_name => table_name, :delete_hash_str => delete_hash_str } }
=begin
      do
        render :update do |page|

          page << "alert(\"#{success_str}#{error_str}\")"
          if deleted_ids.length>0

            page << "on_del(\"#{table_name}\", [#{deleted_ids}]);"
            delete_hash_str.each do |delete_table, delete_ids_str|
              page << "on_del(\"#{delete_table.to_s}\", [#{delete_ids_str}]);"
            end
          end
          page << "unwait();"

        end
      end
=end      
    end
    
  end

  def delete
    table_name = params[:table_name];
    id = params[:id];
    ids =[];
    ids << id.to_i;
    delete_array(ids, table_name);
  end

  def remove_dependencies(ids, table_name, dependent_table_name)
    reflection_str = dependent_table_name + ".reflect_on_all_associations(:belongs_to)"
    reflections = eval(reflection_str);
    @update_hash["#{dependent_table_name}"]={}
    for reflection in reflections
      if(reflection.class_name == table_name)
        foreign_key = reflection.options[:foreign_key];
        id_str = "";
        for id in ids
          if id_str.length>0
            id_str << ", "
          end
          id_str << id.to_s;
        end

        objects_str = "#{reflection.class_name}.find_by_sql(\"SELECT id, #{foreign_key} FROM #{ dependent_table_name.tableize} WHERE #{foreign_key} IN (#{id_str})\")"
        
        objects = eval(objects_str);
        object_update_str = "object.#{foreign_key} = 1"
        update_ids =[];
        for object in objects
          eval(object_update_str)
          object.save;
          update_ids << object.id;
        end
        @update_hash["#{dependent_table_name}][#{foreign_key}"] = update_ids;
      end
    end

  end


  def update_formats
    user_id = session[:user_id];
    @format_controller =  FormatController.new(user_id);
    for table_object in @format_controller.table_objects
      sql_str = "FormatElement.find_by_sql(\"SELECT id, field_name, insert_string, element_order, in_use FROM format_elements WHERE (user_id = " + user_id.to_s +  " AND table_name = '" + table_object.table + "') ORDER BY element_order asc\")"
 #     Rails.logger.error( "DEBUG: before eval(#{sql_str})" );
      old_fields = eval(sql_str);
      old_fields_count  = old_fields.length;
      new_fields_count = params["display_format_count_#{table_object.table}"].to_i;
      for i in (0..(new_fields_count-1))
        if i>=old_fields_count
          format_elt = FormatElement.new;
        else
          format_elt = old_fields[i];
        end
        format_elt.table_name = table_object.table;
        format_elt.user_id = user_id;
        format_elt.field_name = params["display_format_field_#{table_object.table}_#{i}"];
        format_elt.insert_string = params["display_format_string_#{table_object.table}_#{i}"];
        format_elt.element_order = i;
        format_elt.in_use = true;
        format_elt.save;


      end
      if old_fields_count > new_fields_count
        for i in (new_fields_count..(old_fields_count-1))
          old_fields[i].in_use =false;
          old_fields[i].save;
        end
      end
    end
    @format_controller.Update();

    respond_to do |format|
      format.js { render "update_formats", :locals => {:format_controller => @format_controller } }
=begin      
      do
        render :update do |page|
          page.replace_html("format_controller_div", :partial => "shared/format_controller", :object => @format_controller);
          page << "resizeFormat()";
          page << "unwait();"
        end
      end
=end      
    end
  end

  def edit
    table_name = params[:table_name];
    id = params[:id];
    object_str = "#{table_name}.find(id)";
    new_current_object  = eval(object_str );
    if new_current_object
      @current_object  = new_current_object
    end
    if new_current_object
      respond_to do |format|
        format.html {redirect_to person  }
      end
    else
      fail_str = "Failed  to find #{@table_str}  with id #{id}."
      flash[:notice] = fail_str;
      respond_to do |format|
        format.html   { redirect_to person }
      end
    end
    Rails.logger.debug("welcome/edit end")
  end

  def update_group_filters
 
    table_name = params[:group_filters_table_name]
    foreign_key = params[:group_filters_foreign_key];
    group_id = params[:group_id];
    @user_id = session[:user_id];
    sql_str = "GroupFilter.find_by_sql(\"SELECT id, table_name, group_id, foreign_key, user_id  FROM group_filters WHERE (user_id = " + @user_id.to_s +  " AND table_name = '" + table_name + "' AND foreign_key = '" +foreign_key + "') \")"
#    Rails.logger.error( "DEBUG: before eval(#{sql_str})" );
    group_filters = eval(sql_str);
    if group_filters.length == 0
      group_filter = GroupFilter.new;
      group_filter.table_name = table_name;
      group_filter.foreign_key= foreign_key;
      group_filter.user_id = @user_id;
    else
      group_filter = group_filters[0];

    end
    group_filter.group_id = group_id;
    group_filter.save;
    group_filters = FilterController.GetGroupFilters(table_name, @user_id)
    respond_to do |format|
      format.js {render "update_group_filters",  :locals => {:table_name =>table_name, :group_filters => group_filters } }
=begin     
        render :update do |page|
         
          page.replace_html("group_filters_#{table_name}", :partial => "shared/group_filters", :object => group_filters);
          page << "unwait();"
        end
      end
=end
    end
  end


  def SetNotClass(class_name)
    @snc_level = @snc_level+1
    if @snc_level >10
      @snc_level = @snc_level-1;
      return;
    end

   
    find_first_str = "#{class_name}.first"
    first_obj = eval(find_first_str)
    if(first_obj == nil)
      new_str = class_name +".new"
      not_set_obj = eval(new_str)
      reflection_str = class_name + ".reflect_on_all_associations(:belongs_to)"
      reflections = eval(reflection_str)
      for reflection in reflections

        SetNotClass(reflection.class_name)
        field_name = reflection.options[:foreign_key]

        eval_str = "not_set_obj.#{field_name} = @not_set_value"
  #      Rails.logger.error( "DEBUG: before SetNotClass(#{class_name}) eval(#{eval_str})" );
        eval(eval_str);
      end
      not_set_obj.save;
    end
    @snc_level = @snc_level-1;
  end

  def div_test
    x = 1;
        term = Term.find(20);
    person = Person.find(32);
    course = Course.find(112);
   lecture_schedules = Lecture.find_by_sql("SELECT * FROM lectures WHERE course_id = #{course.id} AND term_id = #{term.id}");     if lecture_schedules.length >0 then       lecture_id = lecture_schedules[0].id;      exam_attendees = Attendee.find_by_sql("SELECT *, a1.first_name || ' ' || a1.second_name AS student_name FROM attendees a0 INNER JOIN people a1 ON a1.id=a0.person_id AND a0.lecture_id = #{lecture_id} AND a0.examined= true ORDER BY student_name");      non_exam_attendees =  Attendee.find_by_sql("SELECT *, a1.first_name || ' ' || a1.second_name AS student_name FROM attendees a0 INNER JOIN people a1 ON a1.id=a0.person_id AND a0.lecture_id = #{lecture_id} AND a0.examined= false ORDER BY student_name");    else      exam_attendees = [];      non_exam_attendees = [];    end;
    



        EmailTemplate.create(:template_name =>"Class list and reminder of exam arrangements",
      :from_email => "<%= me.email %>",
      :subject => "Class and exam list for the coming Term at Blackfriars",
      :ruby_header=> %q{<% lecture_schedules = Lecture.find_by_sql("SELECT * FROM lectures WHERE course_id = #{course.id} AND term_id = #{term.id}");     if lecture_schedules.length >0 then       lecture_id = lecture_schedules[0].id;      exam_attendees = Attendee.find_by_sql("SELECT *, a1.first_name || ' ' || a1.second_name AS student_name FROM attendees a0 INNER JOIN people a1 ON a1.id=a0.person_id AND a0.lecture_id = #{lecture_id} AND a0.examined= true ORDER BY student_name");      non_exam_attendees =  Attendee.find_by_sql("SELECT *, a1.first_name || ' ' || a1.second_name AS student_name FROM attendees a0 INNER JOIN people a1 ON a1.id=a0.person_id AND a0.lecture_id = #{lecture_id} AND a0.examined= false ORDER BY student_name");    else      exam_attendees = [];      non_exam_attendees = [];    end;%>},
      :body=> %q{Dear <%= person.salutation %>,<br><br>This email concerns the lecture course on <%=course.name%> for the current Term. <% if (exam_attendees.length + non_exam_attendees.length) >0 %> As I understand it, the following students are supposed to attend the lecture course – there may well be others in the class, for whom it is optional.<br><% if exam_attendees.length >0 %> <br><b>Students needing an end-of-term examination</b>:<br><br>These students need a grade for the course, but are not taking tutorials in the subject. The lecturer normally determines the exam format (often a short viva-voce exam) and scope, and explains this to the students. Exams are usually held on the Monday or Tuesday of 9th Week, at a time to suit the lecturer and the students involved.<br><br><% exam_attendees.each do |attendee|%> <%=attendee.student_name%><br><%end%><br><%end%><% if non_exam_attendees.length >0 %> <b>Students not needing an end-of-term examination</b>:<br><br><% non_exam_attendees.each do |attendee|%> <%=attendee.student_name%><br><%end%><br><%end%><% else%>No one needs to be examined in this course and no one is required to attend.<%end%>If anything seems odd, surprising, alarming, or even wrong with these arrangements, let me know.<br><br>With best wishes,<br><br>Richard.<br><br>(Richard Conrad, O.P., vice-regent)<br><br>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>"",
      :personal_warnings=>"");

    respond_to do |format|
      format.js  { render "div_test" }
=begin      
      do
        render :update do |page|

          page << "alert('div_test!')"
        end
      end
=end      
    end
  end


  def import_csv
    Rails.logger.debug( "import_csv begin" );
    if session[:user_id]!=1

      return;
    end


    old_institution_ids = [];
    new_institution_ids = [];

    old_person_ids = [];
    new_person_ids = [];

    old_course_ids = [];
    new_course_ids = [];

    old_term_ids = [];
    new_term_ids = [];

    old_group_ids = [];
    new_group_ids = [];

    old_lecture_ids = [];
    new_lecture_ids = [];

    old_day_ids = [];
    new_day_ids = [];



    @not_set_value = SearchController::NOT_SET;
    @snc_level = 0;
    all_tables = ActiveRecord::Base.connection.tables;
    for t in all_tables
      if (t =~ /csvs$/ || t =~ /schema_migrations/ || t =~ /sessions/) == nil
        SetNotClass(t.classify)
      end
    end
    csv_terms = TermCsv.find(:all);
    for csv_term in csv_terms
      new_term = Term.new;
      new_term.term_name_id = csv_term.name ;
      new_term.term_name_id = new_term.term_name_id+1;
      new_term.year = csv_term.year;
      if new_term.term_name_id>=1 && new_term.term_name_id<=4
        new_term.save;
        old_term_ids << csv_term.id;
        new_term_ids << new_term.id;
      end
    end
    Rails.logger.debug( "import_csv done terms" );
    Rails.logger.flush
    status_csvs = StatusCsv.find(:all);


    for csv_status in status_csvs
      group = Group.new;
      group.table_name = "people"
      group.group_name = csv_status.status;
      group.owner_id = 1;
      group.readers_id = 0;
      group.writers_id = 1;
      group.private = false;

      group.save;
      old_group_ids << csv_status.id;
      new_group_ids << group.id;
    end
        Rails.logger.debug( "import_csv done groups" );
    Rails.logger.flush

    people_csvs = PersonCsv.find(:all);

    institutuion_group = Group.new;
    institutuion_group.table_name = "institutions"
    institutuion_group.group_name = "Institutions"
    institutuion_group.owner_id = 1;
    institutuion_group.readers_id = 0;
    institutuion_group.writers_id = 1;
    institutuion_group.private = false;
    institutuion_group.save;

    religious_group = Group.new;
    religious_group.table_name = "institutions"
    religious_group.group_name = "Religious Houses"
    religious_group.owner_id = 1;
    religious_group.readers_id = 0;
    religious_group.writers_id = 1;
    religious_group.private = false;
    religious_group.save



    
    for people_csv in people_csvs

      person = Person.new;
      person.title = people_csv.title;
      person.first_name = people_csv.first_name;
      person.second_name = people_csv.second_name;
      person.postnomials = people_csv.postnominals;
      person.salutation = people_csv.salutation;
      person.term_address = people_csv.term_address;
      person.term_city = people_csv.term_city;
      person.term_postcode = people_csv.term_postcode;
      person.term_home_phone = people_csv.term_home_phone;
      person.term_work_phone = people_csv.term_work_phone;
      person.mobile = people_csv.mobile;
      person.email = people_csv.email;
      person.other_address = people_csv.other_address;
      person.other_city = people_csv.other_city;
      person.other_postcode = people_csv.other_postcode;
      person.other_home_phone = people_csv.other_home_phone;
      person.fax = people_csv.Fax;
      person.notes = people_csv.Notes;
      entry_year = people_csv.entry_year
      if entry_year == nil
        person.entry_term_id = SearchController::NOT_SET;
      else
      entry_terms = Term.find_by_sql("SELECT * FROM terms WHERE year = #{entry_year} LIMIT 1")

      if( entry_terms.length >0 )
        person.entry_term_id = entry_terms[0].id;
      else
        person.entry_term_id = SearchController::NOT_SET;
      end
      end
      person.next_of_kin = people_csv.next_of_kin;
      person.conventual_name = people_csv.conventual_name;

      status_ids = PersonstatusCsv.find(:all,:conditions => ["person_id = ?", people_csv.id]);
      status_id_array = [];
      for status_obj_id in status_ids
        status_id_array << status_obj_id.status_id
      end

      inst_id = people_csv.home_institution;
      relig_id = people_csv.religious_house;



      inst_ids = [inst_id, relig_id];
      new_ids = [];


      for i in (0..1)
        id = inst_ids[i];
        if id !=0 && id !=nil
          processed_id =  old_institution_ids.index(id);
          if processed_id != nil
            new_ids <<  new_institution_ids[processed_id];
          else
            if institution = PersonCsv.find(id)
              new_institution = Institution.new;
              new_institution.old_name = institution.old_name;
              new_institution.title = institution.title;
              new_institution.first_name = institution.first_name;
              new_institution.second_name = institution.second_name;
              new_institution.salutation = institution.salutation;
              new_institution.term_address = institution.term_address;
              new_institution.term_city = institution.term_city;
              new_institution.term_postcode = institution.term_postcode;
              new_institution.conventual_name = institution.conventual_name;

              # new_institution.institution_type = i;
              new_institution.save;
              if i == 0
                institutuion_group_member = GroupInstitution.new;
                institutuion_group_member.group_id = institutuion_group.id;
                institutuion_group_member.institution_id = new_institution.id
                institutuion_group_member.save;
              else
                institutuion_group_member = GroupInstitution.new;
                institutuion_group_member.group_id = religious_group.id;
                institutuion_group_member.institution_id = new_institution.id
                institutuion_group_member.save;
              end
              old_institution_ids << id;
              new_institution_ids << new_institution.id;
              new_ids << new_institution.id;
            else
              new_ids << 0;
            end
          end
        else
          new_ids << 0;
        end
        if new_ids[0]!=0
          person.institution_id = new_ids[0];
        else
          person.institution_id = @not_set_value;
        end
        if new_ids[1]!=0
          person.religious_house_id = new_ids[1];
        else
          person.religious_house_id = @not_set_value;
        end
      end

      if status_id_array.index(19)||status_id_array.index(20)
        if old_institution_ids.index(people_csv.id) == nil
          new_institution = Institution.new;
          new_institution.old_name = people_csv.old_name;
          new_institution.title = people_csv.title;
          new_institution.first_name = people_csv.first_name;
          new_institution.second_name = people_csv.second_name;
          new_institution.salutation = people_csv.salutation;
          new_institution.term_address = people_csv.term_address;
          new_institution.term_city = people_csv.term_city;
          new_institution.term_postcode = people_csv.term_postcode;
          new_institution.conventual_name = people_csv.conventual_name;

          new_institution.save;
          if status_id_array.index(20)
            institutuion_group_member = GroupInstitution.new;
            institutuion_group_member.group_id = institutuion_group.id;
            institutuion_group_member.institution_id = new_institution.id
            institutuion_group_member.save;
          else
            institutuion_group_member = GroupInstitution.new;
            institutuion_group_member.group_id = religious_group.id;
            institutuion_group_member.institution_id = new_institution.id
            institutuion_group_member.save;
          end

          old_institution_ids << people_csv.id;
          new_institution_ids << new_institution.id;
        end
      else
        person.save;
        old_person_ids << people_csv.id;
        new_person_ids << person.id;
        for status_val in status_id_array

          status_index = old_group_ids.index(status_val);
          if status_index != nil
            begin
              group_person = GroupPerson.new;
              group_person.group_id = new_group_ids[status_index];
              group_person.person_id = person.id;
              group_person.save;
            rescue Exception =>exc
              Rails.logger.debug( "DEBUG: an exception has occurred (person)" );
            end
          end
        end
      end
    end
        Rails.logger.debug( "import_csv done people" );
    Rails.logger.flush

    csv_courses = CourseCsv.find(:all);
    for csv_course in csv_courses
      new_course = Course.new;
      new_course.name =  csv_course.course_name;
      new_course.save;
      old_course_ids << csv_course.id;
      new_course_ids << new_course.id;
    end

        Rails.logger.debug( "import_csv done courses" );
    Rails.logger.flush





    csv_days = DayCsv.find(:all);


    for csv_day in csv_days
      day = Day.new;
      day.long_name = csv_day.long_name;
      day.short_name = csv_day.short_name;
      if csv_day.long_name =~ /Sunday/
        day.sunday = true;
      else
        day.sunday = false;
      end
      if csv_day.long_name =~ /Monday/
        day.monday = true;
      else
        day.monday = false;
      end
      if csv_day.long_name =~ /Tuesday/
        day.tuesday = true;
      else
        day.tuesday = false;
      end
      if csv_day.long_name =~ /Wednesday/
        day.wednesday = true;
      else
        day.wednesday = false;
      end
      if csv_day.long_name =~ /Thursday/
        day.thursday = true;
      else
        day.thursday = false;
      end
      if csv_day.long_name =~ /Friday/
        day.friday = true;
      else
        day.friday = false;
      end
      if csv_day.long_name =~ /Saturday/
        day.saturday = true;
      else
        day.saturday = false;
      end

      day.save;

      old_day_ids << csv_day.id;
      new_day_ids << day.id;
    end

    Rails.logger.debug( "import_csv done days" );
    Rails.logger.flush


    csv_lectures = LectureCsv.find(:all);
    for csv_lecture in csv_lectures
      course_index = old_course_ids.index(csv_lecture.course);
      term_index = old_term_ids.index(csv_lecture.term);
      tutor_index = old_person_ids.index(csv_lecture.tutor);
      day_index = old_day_ids.index(csv_lecture.day);
      if( course_index != nil && term_index != nil && tutor_index != nil && day_index !=nil)
        new_lecture = Lecture.new;
        new_lecture.term_id = new_term_ids[term_index];
        new_lecture.course_id = new_course_ids[course_index];
        new_lecture.person_id = new_person_ids[tutor_index];
        new_lecture.exam = csv_lecture.examination;
        new_lecture.day_id = new_day_ids[day_index];
        new_lecture.location_id = @not_set_value;;
        if csv_lecture.lecture_time =~/12:13/
          x = 1;
        else
          new_lecture.lecture_time = csv_lecture.lecture_time;
        end
        new_lecture.lecture_time = csv_lecture.lecture_time;
        new_lecture.number_of_classes = csv_lecture.number_of_classes;
        new_lecture.number_of_lectures = csv_lecture.number_of_lectures;
        new_lecture.hours = csv_lecture.hours;
        new_lecture.notes = csv_lecture.notes;
        new_lecture.save;
        old_lecture_ids << csv_lecture.id;
        new_lecture_ids << new_lecture.id;
      end
    end
    Rails.logger.debug( "import_csv done lectures" );
    Rails.logger.flush

    csv_attendees = AttendeeCsv.find(:all);
    for csv_attendee in csv_attendees
      lecture_index = old_lecture_ids.index(csv_attendee.lectures_course);
      person_index = old_person_ids.index(csv_attendee.student);
      if(lecture_index != nil && person_index != nil)
        begin
          new_attendee = Attendee.new;
          new_attendee.lecture_id = new_lecture_ids[lecture_index];
          new_attendee.person_id = new_person_ids[person_index];
          new_attendee.compulsory = csv_attendee.compulsory;
          new_attendee.comment = csv_attendee.mark;
          new_attendee.examined = csv_attendee.examined;
          new_attendee.save;
        rescue Exception => exc
          Rails.logger.debug( "DEBUG: an exception has occurred (new_attendee)" );
        end
      end
    end
        Rails.logger.debug( "import_csv done attendees" );
    Rails.logger.flush


    csv_willing_teachers = WillingTeacherCsv.find(:all);
    for csv_willing_teacher in csv_willing_teachers
      person_index = old_person_ids.index(csv_willing_teacher.tutor);
      course_index = old_course_ids.index(csv_willing_teacher.course);
      if(person_index !=nil && course_index !=nil)
        willing_teacher = WillingTeacher.new;
        willing_teacher.person_id = new_person_ids[person_index];
        willing_teacher.course_id = new_course_ids[course_index];
        willing_teacher.can_lecture = true;
        willing_teacher.can_tutor = true;
        willing_teacher.notes = csv_willing_teacher.notes;
        willing_teacher.save;
      end
    end

        Rails.logger.debug( "import_csv done willing teachers" );
    Rails.logger.flush


    csv_tutorials = TutorialCsv.find(:all);
    for csv_tutorial in csv_tutorials
      student_index = old_person_ids.index(csv_tutorial.student);
      course_index = old_course_ids.index(csv_tutorial.course);
      term_index = old_term_ids.index(csv_tutorial.term);
      tutor_index = old_person_ids.index(csv_tutorial.tutor);
      if(student_index !=nil && course_index != nil && term_index != nil && tutor_index !=nil)
        tutorial = Tutorial.new;
        tutorial_schedule = TutorialSchedule.find(:first, :conditions => ["person_id = ? AND course_id = ? AND term_id = ?",
            new_person_ids[tutor_index], new_course_ids[course_index], new_term_ids[term_index]]);
        if(tutorial_schedule == nil)
          tutorial_schedule = TutorialSchedule.new;
          tutorial_schedule.person_id = new_person_ids[tutor_index];
          tutorial_schedule.course_id =  new_course_ids[course_index];
          tutorial_schedule.term_id = new_term_ids[term_index];
          tutorial_schedule.number_of_tutorials = 0;
          tutorial_schedule.save;
        end
        tutorial.person_id = new_person_ids[student_index];
        tutorial.tutorial_schedule_id = tutorial_schedule.id;
        tutorial_hours = csv_tutorial.hours;
        if tutorial_hours !=nil && tutorial_hours != 0
          tutorial_schedule.number_of_tutorial_hours  = tutorial_hours;
        else
          tutorial_schedule.number_of_tutorial_hours = 0
        end
        tutorial.notes = csv_tutorial.notes
        tutorial.comment = csv_tutorial.mark;
        tutorial_schedule.number_of_tutorials =  csv_tutorial.number;
        tutorial_schedule.save;
        begin
          tutorial.save;
        rescue Exception => exc
          Rails.logger.debug( "DEBUG: an exception has occurred (tutorial_schedule)" );
        end
      end
    end

    courses = Course.find(:all);
    courses.each do |course|
      if course.id != SearchController::NOT_SET
      tutors = TutorialSchedule.find_by_sql("SELECT person_id, max(term_id) AS term_id FROM tutorial_schedules WHERE course_id = #{course.id} GROUP BY person_id ORDER BY term_id DESC")
      preference = 1
      tutors.each do |tutor|
        willing_tutor = WillingTutor.new;
        willing_tutor.person_id = tutor.person_id;
        willing_tutor.course_id = course.id;
        willing_tutor.order_of_preference = preference;
        preference = preference +1;
        willing_tutor.save;
      end

      lecturers = Lecture.find_by_sql("SELECT person_id, max(term_id) AS term_id FROM lectures WHERE course_id = #{course.id} GROUP BY person_id ORDER BY term_id DESC");
      preference = 1;
      lecturers.each do |lecturer|

        willing_lecturer = WillingLecturer.new;
        willing_lecturer.person_id = lecturer.person_id;
        willing_lecturer.course_id = course.id;
        willing_lecturer.order_of_preference = preference;
        preference = preference + 1;
        willing_lecturer.save;
      end
      end

    end

    Rails.logger.debug( "import_csv done tutorials" );
    Rails.logger.flush

    term_name1 = TermName.new;
    term_name1.name = "Hilary"
    term_name1.save;
    term_name2 = TermName.new;
    term_name2.name = "Trinity"
    term_name2.save;
    term_name3 = TermName.new;
    term_name3.name = "Michaelmas"
    term_name3.save;

    FormatElement.create(:user_id => 0, :table_name => 'people', :field_name => 'second_name', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'people', :field_name => 'first_name', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'courses', :field_name => 'name', :insert_string => ' ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'institutions', :field_name => 'conventual_name', :insert_string => ' ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'groups', :field_name => 'group_name', :insert_string => '', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'lectures', :field_name => 'course_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'lectures', :field_name => 'term_id', :insert_string => ' ', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'term_names', :field_name => 'name', :insert_string => ' ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'terms', :field_name => 'term_name_id', :insert_string => ' ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'terms', :field_name => 'year', :insert_string => ' ', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'days', :field_name => 'short_name', :insert_string => ' ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'locations', :field_name => 'name', :insert_string => ' ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'attendees', :field_name => 'lecture_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'attendees', :field_name => 'person_id', :insert_string => '', :element_order => 2, :in_use => true)


    FormatElement.create(:user_id => 0, :table_name => 'tutorials', :field_name => 'tutorial_schedule_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'tutorials', :field_name => 'person_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'tutorial_schedules', :field_name => 'course_id', :insert_string => '', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'email_templates', :field_name => 'template_name', :insert_string => '', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'agatha_emails', :field_name => 'term_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'agatha_emails', :field_name => 'person_id', :insert_string => ', ', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'agatha_emails', :field_name => 'subject', :insert_string => '', :element_order => 3, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'agatha_files', :field_name => 'agatha_data_file_name', :insert_string => '', :element_order => 1, :in_use => true)


    FormatElement.create(:user_id => 0, :table_name => 'willing_lecturers', :field_name => 'course_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'willing_lecturers', :field_name => 'person_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'willing_tutors', :field_name => 'course_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'willing_tutors', :field_name => 'person_id', :insert_string => '', :element_order => 2, :in_use => true)


    FormatElement.create(:user_id => 0, :table_name => 'group_agatha_emails', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_agatha_emails', :field_name => 'agatha_email_id', :insert_string => ', ', :element_order => 2, :in_use => true)

    FormatElement.create(:user_id => 0, :table_name => 'group_people', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_people', :field_name => 'person_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_institutions', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_institutions', :field_name => 'institution_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_courses', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_courses', :field_name => 'course_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_lectures', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_lectures', :field_name => 'lecture_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_attendees', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_attendees', :field_name => 'attendee_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_tutorial_schedules', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_tutorial_schedules', :field_name => 'tutorial_schedule_id', :insert_string => '', :element_order => 2, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_tutorials', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_tutorials', :field_name => 'tutorial_id', :insert_string => '', :element_order => 2, :in_use => true)


    FormatElement.create(:user_id => 0, :table_name => 'group_users', :field_name => 'group_id', :insert_string => ', ', :element_order => 1, :in_use => true)
    FormatElement.create(:user_id => 0, :table_name => 'group_users', :field_name => 'user_id', :insert_string => '', :element_order => 2, :in_use => true)

     FormatElement.create(:user_id => 0, :table_name => 'users', :field_name => 'name', :insert_string => '', :element_order => 1, :in_use => true);

        Rails.logger.debug( "import_csv done format elements" );
    Rails.logger.flush

    DisplayFilter.create(:user_id => 0, :table_name => 'people', :filter_index => 0, :element_order => 0, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'people', :filter_index => 1, :element_order => 1, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'people', :filter_index => 2, :element_order => 2, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'people', :filter_index => 3, :element_order => 3, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'people', :filter_index => 4, :element_order => 4, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'people', :filter_index => 12, :element_order => 4, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'attendees', :filter_index => 0, :element_order => 0, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'attendees', :filter_index => 1, :element_order => 1, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'attendees', :filter_index => 2, :element_order => 2, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'attendees', :filter_index => 3, :element_order => 3, :in_use => true);
    DisplayFilter.create(:user_id => 0, :table_name => 'attendees', :filter_index => 6, :element_order => 4, :in_use => true);

    DisplayFilter.create(:user_id => 0, :table_name => 'courses', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'courses', :filter_index => 1, :element_order => 1, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'terms', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'terms', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'terms', :filter_index => 2, :element_order => 2, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'days', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'days', :filter_index => 1, :element_order => 1, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'groups', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'groups', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'groups', :filter_index => 4, :element_order => 2, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'group_people', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'group_people', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'group_people', :filter_index => 2, :element_order => 2, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'users', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'users', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'users', :filter_index => 6, :element_order => 2, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'willing_tutors', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'willing_tutors', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'willing_tutors', :filter_index => 2, :element_order => 2, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'willing_tutors', :filter_index => 3, :element_order => 3, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'willing_lecturers', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'willing_lecturers', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'willing_lecturers', :filter_index => 2, :element_order => 2, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'willing_lecturers', :filter_index => 3, :element_order => 3, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'maximum_tutorials', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'maximum_tutorials', :filter_index => 1, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'maximum_tutorials', :filter_index => 2, :element_order => 2, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'maximum_tutorials', :filter_index => 3, :element_order => 3, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'email_templates', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'email_templates', :filter_index => 1, :element_order => 1, :in_use => true)  
    DisplayFilter.create(:user_id => 0, :table_name => 'email_templates', :filter_index => 3, :element_order => 2, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'email_templates', :filter_index => 5, :element_order => 3, :in_use => true)

    DisplayFilter.create(:user_id => 0, :table_name => 'agatha_emails', :filter_index => 0, :element_order => 0, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'agatha_emails', :filter_index => 8, :element_order => 1, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'agatha_emails', :filter_index => 2, :element_order => 2, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'agatha_emails', :filter_index => 3, :element_order => 3, :in_use => true)
    DisplayFilter.create(:user_id => 0, :table_name => 'agatha_emails', :filter_index => 4, :element_order => 4, :in_use => true)

    
    Group.create(:group_name => 'BA', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => '2nd BA', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'MSt', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'MPhil', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'visiting student (UG - OSP)', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'visiting student (UG - not OSP)', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => "visiting student (UG - St. Clare's)", :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'visiting student (Post-Gr)', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'PGCE', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Certificate in Theology', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'BTh', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'other', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Philosophy Year', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'STB', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Lectorate', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Sapientia', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Lampeter Certificate in Theology', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Lampeter Diploma in Theology', :table_name => 'people', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Language Classes', :table_name => 'courses', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Lecturer Confirmed', :table_name => 'lectures', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
Group.create(:group_name => 'Tutor Confirmed', :table_name => 'tutorial_schedules', :owner_id => User.where(:name => "agathaapp").first.id, :private => false, :readers_id => 2, :writers_id => 2)
language_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'courses' AND group_name='Language Classes'");
confirmed_lecturer_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'lectures' AND group_name='Lecturer Confirmed'");
confirmed_tutor_groups =Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'tutorial_schedules' AND group_name='Tutor Confirmed'");

if confirmed_lecturer_groups.length >0 then confirmed_lecturer_id = confirmed_lecturer_groups[0].id else  confirmed_lecturer_id  = 0 end;
if confirmed_tutor_groups.length >0 then confirmed_tutor_id = confirmed_tutor_groups[0].id else confirmed_tutor_id = 0 end;
if language_groups.length >0 then language_group_id = language_groups[0].id else language_group_id = 0 end;
languages = [41,42,143,184,191,39,40,147,157,37,38,175,192];
languages.each do |language_id|
  GroupCourse.create(:group_id=>language_group_id, :course_id => language_id);
end
lectures = Lecture.find(:all);
lectures.each do |lecture|
  GroupLecture.create(:group_id=>confirmed_lecturer_id,:lecture_id =>lecture.id)
end
tutorial_schedules = TutorialSchedule.find(:all);
tutorial_schedules.each do |tutorial_schedule1|
  GroupTutorialSchedule.create(:group_id=>confirmed_tutor_id, :tutorial_schedule_id=>tutorial_schedule1.id)
end



    EmailTemplate.create(:template_name => "Enquiry re availability",
      :from_email => "<%= me.email %>",
      :subject => "Availability for teaching for Blackfriars next year?",
      :ruby_header=> %q{<% first_term = term;   second_term_id = term.id + 1 ;  second_term = Term.find(second_term_id); third_term_id = term.id + 2;  third_term = Term.find(third_term_id); first_term_name = TermName.find(first_term.term_name_id).name; first_term_year = first_term.year; second_term_name = TermName.find(second_term.term_name_id).name; second_term_year = second_term.year; third_term_name = TermName.find(third_term.term_name_id).name; third_term_year = third_term.year; confirmed_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'lectures' AND group_name='Lecturer Confirmed'"); if confirmed_groups.length >0 then confirmed_id = confirmed_groups[0].id else confirmed_id = 0 end; first_term_lectures = Lecture.find_by_sql("SELECT * FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)=0"); second_term_lectures =  Lecture.find_by_sql("SELECT * FROM lectures a0 WHERE a0.term_id = #{term.id+1} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)=0"); third_term_lectures =  Lecture.find_by_sql("SELECT * FROM lectures a0 WHERE a0.term_id = #{term.id+2} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)=0"); if first_term_lectures.length>0 || second_term_lectures.length>0 || third_term_lectures.length>0 then make_lecture_request = true;  else make_lecture_request = false; end; num_terms = 0; if first_term_lectures.length >0 then num_terms = num_terms+1 end; if second_term_lectures.length  >0 then num_terms = num_terms+1 end; if third_term_lectures.length  >0 then num_terms = num_terms+1 end; terms_str = "(#{term.id},#{second_term_id },#{third_term_id})"; courses = Course.find_by_sql("SELECT * FROM courses a0 WHERE (SELECT COUNT(*) FROM lectures a1 WHERE a1.course_id = a0.id AND a1.person_id = #{person.id} AND a1.term_id IN #{terms_str} AND (SELECT COUNT(*) FROM group_lectures a2 WHERE a2.group_id=#{confirmed_id} AND a2.lecture_id = a1.id)=0)>0"); num_topics = courses.length; num_lectures = first_term_lectures.length + second_term_lectures.length + third_term_lectures.length; %>},
      :body=> %q{Dear <%= person.salutation %>,<br><br>I hope you are well and the academic year has gone smoothly.<br><br>Thank you for your teaching done for Blackfriars this year soon to end.<br><br>I am soon going to have to sort out who teaches what to whom, and when, in the coming academic year. It will assist that process if at this stage I find out what you and our other tutors can offer us, insofar as you can predict your availability. I hope my questions don’t pose too much of a distraction at this time.<br><br>So, could you let me know if there’s a Term in the coming academic year that is specially good, or specially bad, for doing some tutorials for Blackfriars?<br><br>Also, roughly how many tutorials a week you could reasonably do for us?<br><br>Could you remind me which topics you would specially like to teach if students need them, and which others you could teach if necessary?<br><br><% if make_lecture_request %>Could you also let me know if you would be available to give lectures on the following <%="topic".pl(num_topics)%> in the <%="term".pl(num_terms)%> specified, and if there are any constraints on the days and times at which you can give the <%="lecture".pl(num_lectures)%>?<br><br><% if first_term_lectures.length >0 %><% i = 0; ii=first_term_lectures.length-1; %><u><b><%=first_term_name%> Term <%= first_term_year %></b></u>: <%first_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; n=lecture.number_of_lectures;%><%= n %> <%="lecture".pl(n)%> on <%=course_name%><%if i< ii-1%><%=", "%><%elsif i== ii-1%><%=" and "%><%else%><%="."%><%end%><%i=i+1%><%end%><% end %><br><br><% if second_term_lectures.length >0 %><% i = 0; ii=second_term_lectures.length-1; %><u><b><%=second_term_name%> Term <%= second_term_year %></b></u>: <%second_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; n=lecture.number_of_lectures;%><%= n %> <%="lecture".pl(n)%> on <%=course_name%><%if i< ii-1%><%=", "%><%elsif i== ii-1%><%=" and "%><%else%><%="."%><%end%><%i=i+1%><%end%><% end %><br><br><% if third_term_lectures.length >0 %><% i = 0; ii=third_term_lectures.length-1; %><u><b><%=third_term_name%> Term <%= third_term_year %></b></u>: <%third_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; n=lecture.number_of_lectures;%><%= n %> <%="lecture".pl(n)%> on <%=course_name%><%if i< ii-1%><%=", "%><%elsif i== ii-1%><%=" and "%><%else%><%="."%><%end%><%i=i+1%><%end%><% end %><br><br><%end%>With many thanks for your help, and best wishes,<br><br>Richard.<br>(Richard Conrad, O.P., Vice Regent).<i-1%><br><p></p> <p></p></i-1%>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>%q{michaelmas_term_id = TermName.where(:name =>"Michaelmas").first.id;   if michaelmas_term_id != term.term_name_id   then  warning_str << "WARNING: you haven't selected a Michaelmas term." end},
      :personal_warnings=>"");

    EmailTemplate.create(:template_name => "Next year's planned tuition, for tutors",
      :from_email => "<%= me.email %>",
      :subject => "Next year's teaching for Blackfriars?",
      :ruby_header=> %q{<%  first_term = term;     second_term_id = term.id + 1 ;     second_term = Term.find(second_term_id);     third_term_id = term.id + 2;     third_term = Term.find(third_term_id);     first_term_name = TermName.find(first_term.term_name_id).name;     first_term_year = first_term.year;     second_term_name = TermName.find(second_term.term_name_id).name;     second_term_year = second_term.year;     third_term_name = TermName.find(third_term.term_name_id).name;     third_term_year = third_term.year;       confirmed_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'lectures' AND group_name='Lecturer Confirmed'");     language_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'courses' AND group_name='Language Classes'");     if confirmed_groups.length >0 then confirmed_id = confirmed_groups[0].id else confirmed_id = 0 end;     if language_groups.length >0 then language_group_id = language_groups[0].id else language_group_id = 0 end;     first_term_lectures = Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");     second_term_lectures =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+1} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");     third_term_lectures =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+2} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0 AND(SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");     first_term_language_classes = Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  second_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+1} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  third_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+2} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND(SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");     first_term_tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE term_id = #{first_term.id} AND person_id = #{person.id}");     if first_term_tutorial_schedules.length > 0 then       first_term_tutorial_str = "";       first_term_tutorial_schedules.each do |tutorial_schedule1|         if (first_term_tutorial_str.length >0) then first_term_tutorial_str << ", "; end;         first_term_tutorial_str << tutorial_schedule1.id.to_s;       end;       first_term_tutorials = Tutorial.find_by_sql("SELECT  *, a10.number_of_tutorials AS num_tutorials, a99.first_name || '  ' || a99.second_name  AS student_name,   a83.name  AS course_name FROM tutorials a0 INNER JOIN people a99 ON  a0.person_id = a99.id INNER JOIN ( tutorial_schedules a10 INNER JOIN courses a83 ON  a10.course_id = a83.id ) ON a0.tutorial_schedule_id = a10.id  WHERE  (a0.id != 1  AND (a0.tutorial_schedule_id IN (#{first_term_tutorial_str}) )) ORDER BY  course_name asc, student_name  asc");     else       first_term_tutorials = [];     end;     second_term_language_classes = Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  second_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+1} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  third_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+2} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND(SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");     second_term_tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE term_id = #{second_term.id} AND person_id = #{person.id}");     if second_term_tutorial_schedules.length > 0 then       second_term_tutorial_str = "";       second_term_tutorial_schedules.each do |tutorial_schedule1|         if (second_term_tutorial_str.length >0) then second_term_tutorial_str << ", "; end;         second_term_tutorial_str << tutorial_schedule1.id.to_s;       end;       second_term_tutorials = Tutorial.find_by_sql("SELECT  *, a10.number_of_tutorials AS num_tutorials, a99.first_name || '  ' || a99.second_name  AS student_name,   a83.name  AS course_name FROM tutorials a0 INNER JOIN people a99 ON  a0.person_id = a99.id INNER JOIN ( tutorial_schedules a10 INNER JOIN courses a83 ON  a10.course_id = a83.id ) ON a0.tutorial_schedule_id = a10.id  WHERE  (a0.id != 1  AND (a0.tutorial_schedule_id IN (#{second_term_tutorial_str}) )) ORDER BY  course_name asc, student_name  asc");     else       second_term_tutorials = [];     end;     third_term_language_classes = Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  third_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+1} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  third_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+2} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND(SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");     third_term_tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE term_id = #{third_term.id} AND person_id = #{person.id}");     if third_term_tutorial_schedules.length > 0 then       third_term_tutorial_str = "";       third_term_tutorial_schedules.each do |tutorial_schedule1|         if (third_term_tutorial_str.length >0) then third_term_tutorial_str << ", "; end;         third_term_tutorial_str << tutorial_schedule1.id.to_s;       end;       third_term_tutorials = Tutorial.find_by_sql("SELECT  *, a10.number_of_tutorials AS num_tutorials, a99.first_name || '  ' || a99.second_name  AS student_name,   a83.name  AS course_name FROM tutorials a0 INNER JOIN people a99 ON  a0.person_id = a99.id INNER JOIN ( tutorial_schedules a10 INNER JOIN courses a83 ON  a10.course_id = a83.id ) ON a0.tutorial_schedule_id = a10.id  WHERE  (a0.id != 1  AND (a0.tutorial_schedule_id IN (#{third_term_tutorial_str}) )) ORDER BY  course_name asc, student_name  asc");     else       third_term_tutorials = [];     end;     students = Person.find_by_sql("SELECT  *, a0.first_name || '  ' || a0.second_name  AS student_name FROM people a0  WHERE (a0.id != 1  AND (SELECT COUNT(*) FROM tutorials y1 INNER JOIN tutorial_schedules y2 ON y2.id = y1.tutorial_schedule_id WHERE y1.person_id = a0.id AND y2.person_id = #{person.id} AND  y2.term_id = #{term.id})>0 ) ORDER BY  student_name  asc ");   %>},
      :body=> %q{Dear <%= person.salutation%>,<br><br>I have been working out who should teach what to whom and how at Blackfriars in the course of the coming academic year, and I should like to invite you to undertake the following teaching. If the proposed lecture courses are acceptable, they will stand. The tutorial courses are liable to fine-tuning as the year develops, but should stay substantially the same. I will of course be in touch term-by-term to confirm or fine-tune the arrangements.<br><br><% if (first_term_lectures.length + first_term_language_classes.length + first_term_tutorials.length) >0 %><u><b><%=first_term_name%> Term <%= first_term_year %></b></u>:<% if first_term_lectures.length >0%><br><br><b>Lectures</b>:<% first_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students =lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if first_term_language_classes.length >0%><br><br><b>Language Classes</b>:<% first_term_language_classes.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students = lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if first_term_tutorials.length> 0%><br><br><b>Tutorials</b>:<% first_term_tutorials.each do |tutorial| num_tutorials = tutorial.num_tutorials.to_i; student = tutorial.student_name; course = tutorial.course_name%><br><%=num_tutorials%> <%="tutorial".pl(num_tutorials)%> on <%=course%> for <%=student%> <% end %> <% end %><% end %><br><br><% if (second_term_lectures.length + second_term_language_classes.length + second_term_tutorials.length) >0 %><u><b><%=second_term_name%> Term <%= second_term_year %></b></u>:<% if second_term_lectures.length >0%><br><br><b>Lectures</b>:<% second_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students =lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if second_term_language_classes.length >0%><br><br><b>Language Classes</b>:<% second_term_language_classes.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students = lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if second_term_tutorials.length> 0%><br><br><b>Tutorials</b>:<% second_term_tutorials.each do |tutorial| num_tutorials = tutorial.num_tutorials.to_i; student = tutorial.student_name; course = tutorial.course_name%><br><%=num_tutorials%> <%="tutorial".pl(num_tutorials)%> on <%=course%> for <%=student%> <% end %> <% end %><% end %><br><br><% if (third_term_lectures.length + third_term_language_classes.length + third_term_tutorials.length) >0 %><u><b><%=third_term_name%> Term <%= third_term_year %></b></u>:<% if third_term_lectures.length >0%><br><br><b>Lectures</b>:<% third_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students =lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if third_term_language_classes.length >0%><br><br><b>Language Classes</b>:<% third_term_language_classes.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students = lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if third_term_tutorials.length> 0%><br><br><b>Tutorials</b>:<% third_term_tutorials.each do |tutorial| num_tutorials = tutorial.num_tutorials.to_i; student = tutorial.student_name; course = tutorial.course_name%><br><%=num_tutorials%> <%="tutorial".pl(num_tutorials)%> on <%=course%> for <%=student%> <% end %> <% end %><% end %><br><br><u>Please let me know</u>:<br><br>Can you manage the teaching load?<br><br>Could you reasonably fit anything more in if I needed to find a few more tutors?<br><br>Do you need details of what is prescribed for any of the lecture courses or tutorials? <span style="color: rgb(64, 160, 255);" tag="span" class="yui-tag-span yui-tag">– apart from the module descriptors attached to this email.</span><br><br>Do you need more information about any of the students you will be tutoring, their backgrounds, needs, interests?<br><br><%if students.length > 0 %><u><b>Vacation Reading and students’ contact details for Michaelmas Term:</b></u><br><br>These are the email addresses of your students for Michaelmas Term. It would be good to give them recommendations for vacation reading, if you can. Hopefully they will get in touch with you nearer Term to fix tutorial times and topics.<br><br><%students.each do |student|%><%=student.student_name%>: <%=student.email%><br><%end%><% end %><br>With many thanks, and best wishes,<br>Richard.<br>(Richard Conrad, O.P., Vice Regent).<br>   	 	 	<br>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>"",
      :personal_warnings=>"");

    EmailTemplate.create(:template_name => "Next year's planned tuition, for students",
      :from_email => "<%= me.email %>",
      :subject => "Next year's studies at Blackfriars",
      :ruby_header=> %q{<%  first_term = term;     second_term_id = term.id + 1 ;    second_term = Term.find(second_term_id);    third_term_id = term.id + 2;    third_term = Term.find(third_term_id);    first_term_name = TermName.find(first_term.term_name_id).name;    first_term_year = first_term.year;    second_term_name = TermName.find(second_term.term_name_id).name;    second_term_year = second_term.year;    third_term_name = TermName.find(third_term.term_name_id).name;    third_term_year = third_term.year;        language_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'courses' AND group_name='Language Classes'");      if language_groups.length >0 then language_group_id = language_groups[0].id; else language_group_id = 0; end;    first_term_examined =  Lecture.find_by_sql("SELECT  a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = true AND a0.term_id = #{first_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");    first_term_not_examined =  Lecture.find_by_sql("SELECT  a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = false AND a0.term_id = #{first_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");    first_term_languages = Lecture.find_by_sql("SELECT  a0.id, a30.name AS course_name, x1.first_name || ' ' || x1.second_name AS tutor_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN people x1 ON x1.id = a0.person_id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{first_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0) ORDER BY  course_name  asc ");    first_term_tutorials = TutorialSchedule.find_by_sql("SELECT  a0.id, a0.number_of_tutorials, a30.name AS course_name, a31.first_name || ' ' || a31.second_name AS tutor_name FROM tutorial_schedules a0 INNER JOIN courses a30 ON a0.course_id = a30.id INNER JOIN people a31 ON a31.id = a0.person_id INNER JOIN tutorials y1 ON y1.tutorial_schedule_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{first_term.id}) ORDER BY  course_name  asc ");    first_term_tutors = Person.find_by_sql("SELECT a0.first_name || ' ' || a0.second_name AS tutor_name, a0.email FROM people a0 WHERE (a0.id != 1 AND (SELECT COUNT(*) FROM tutorials y1 INNER JOIN tutorial_schedules y2 ON y2.id = y1.tutorial_schedule_id WHERE y2.person_id = a0.id AND y1.person_id = #{person.id} AND y2.term_id = #{first_term.id})>0) ORDER BY tutor_name asc  ");    if first_term_languages.length !=0 then     language_ids = "";    first_term_languages.each do|language|      if language_ids.length>0 then language_ids << ", "; end;  language_ids << language.id.to_s;    end;    first_term_language_tutors = Person.find_by_sql("SELECT a0.id, a0.first_name|| ' ' || a0.second_name AS tutor_name, a0.email FROM people a0 WHERE (a0.id != 1 AND (SELECT COUNT(*) FROM attendees y1 INNER JOIN lectures y2 ON y2.id = y1.lecture_id WHERE y2.person_id = a0.id AND y1.person_id = #{person.id} AND y2.term_id = #{first_term.id} AND y2.id IN (#{language_ids}) )>0) ORDER BY tutor_name asc ");  else    first_term_language_tutors = [];  end;second_term_examined =  Lecture.find_by_sql("SELECT  a0.id, a30.name  AS course_name  FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = true AND a0.term_id = #{second_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");    second_term_not_examined =  Lecture.find_by_sql("SELECT   a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = false AND a0.term_id = #{second_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");    second_term_languages = Lecture.find_by_sql("SELECT  a0.id, a30.name AS course_name, x1.first_name || ' ' || x1.second_name AS tutor_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN people x1 ON x1.id = a0.person_id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{second_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0) ORDER BY  course_name  asc ");    second_term_tutorials = TutorialSchedule.find_by_sql("SELECT   a0.id, a0.number_of_tutorials, a30.name AS course_name, a31.first_name || ' ' || a31.second_name AS tutor_name FROM tutorial_schedules a0 INNER JOIN courses a30 ON a0.course_id = a30.id INNER JOIN people a31 ON a31.id = a0.person_id INNER JOIN tutorials y1 ON y1.tutorial_schedule_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{second_term.id}) ORDER BY  course_name  asc ");third_term_examined =  Lecture.find_by_sql("SELECT   a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = true AND a0.term_id = #{third_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");    third_term_not_examined =  Lecture.find_by_sql("SELECT   a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = false AND a0.term_id = #{third_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");   third_term_languages = Lecture.find_by_sql("SELECT  a0.id, a30.name AS course_name, x1.first_name || ' ' || x1.second_name AS tutor_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN people x1 ON x1.id = a0.person_id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{third_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0) ORDER BY  course_name  asc ");    third_term_tutorials = TutorialSchedule.find_by_sql("SELECT  a0.id,a0.number_of_tutorials, a30.name AS course_name, a31.first_name || ' ' || a31.second_name AS tutor_name FROM tutorial_schedules a0 INNER JOIN courses a30 ON a0.course_id = a30.id INNER JOIN people a31 ON a31.id = a0.person_id INNER JOIN tutorials y1 ON y1.tutorial_schedule_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{third_term.id}) ORDER BY  course_name  asc ");%>},
      :body=> %q{Dear <%= person.salutation%>,<br><br>I have been organising the studies for Blackfriars’ students for the coming academic year, and have made the following arrangements for you. If anything seems odd, surprising, alarming, or even wrong, let me know. As with most years, some fine-tuning of the arrangements is only to be expected.<br><br><% if first_term_examined.length + first_term_not_examined.length + first_term_languages.length + first_term_tutorials.length > 0 %><u><b><%=first_term_name%> Term, <%= first_term_year%></b></u>:<br><% if first_term_examined.length>0 %><br><b>Lectures needing an end-of-term examination</b>:<br><% first_term_examined.each do |lecture| %><u><%=lecture.course_name%></u>.<br><% end %><% end%><% if first_term_not_examined.length>0%><br><b>Lectures not needing an end-of-term examination</b>:<br><% first_term_not_examined.each do |lecture| %><u><%= lecture.course_name%></u>.<br><%end%><%end%><% if first_term_languages.length>0%><br><b>Language classes</b>:<br><%first_term_languages.each do |lecture|%><u><%=lecture.course_name%></u> with <%=lecture.tutor_name %>.<br><%end%><%end%><% if first_term_tutorials.length>0 %><br><b>Tutorials</b>:<br><%first_term_tutorials.each do |tutorial| %><%=tutorial.number_of_tutorials%> <%="tutorial".pl(tutorial.number_of_tutorials)%> on <%= tutorial.course_name%> with <%=tutorial.tutor_name%>.<br><% end%><% end %><br><% end %><% if second_term_examined.length + second_term_not_examined.length + second_term_languages.length + second_term_tutorials.length > 0 %><u><b><%=second_term_name%> Term, <%= second_term_year%></b></u>:<br><% if second_term_examined.length>0 %><br><b>Lectures needing an end-of-term examination</b>:<br><% second_term_examined.each do |lecture| %><u><%=lecture.course_name%></u>.<br><% end %><% end%><% if second_term_not_examined.length>0%><br><b>Lectures not needing an end-of-term examination</b>:<br><% second_term_not_examined.each do |lecture| %><u><%= lecture.course_name%></u>.<br><%end%><%end%><% if second_term_languages.length>0%><br><b>Language classes</b>:<br><%second_term_languages.each do |lecture|%><u><%=lecture.course_name%></u> with <%=lecture.tutor_name %>.<br><%end%><%end%><% if second_term_tutorials.length>0 %><br><b>Tutorials</b>:<br><%second_term_tutorials.each do |tutorial| %><%=tutorial.number_of_tutorials%> <%="tutorial".pl(tutorial.number_of_tutorials)%> on <%= tutorial.course_name%> with <%=tutorial.tutor_name%>.<br><% end%><% end %><br><% end %><% if third_term_examined.length + third_term_not_examined.length + third_term_languages.length + third_term_tutorials.length > 0 %><u><b><%=third_term_name%> Term, <%= third_term_year%></b></u>:<br><% if third_term_examined.length>0 %><br><b>Lectures needing an end-of-term examination</b>:<br><% third_term_examined.each do |lecture|%><u><%= lecture.course_name%></u><br><% end %><% end%><% if third_term_not_examined.length>0%><br><b>Lectures not needing an end-of-term examination</b>:<br><% third_term_not_examined.each do |lecture| %><u><%= lecture.course_name%></u>.<br><%end%><%end%><% if third_term_languages.length>0%><br><b>Language classes</b>:<br><%third_term_languages.each do |lecture|%><u><%=lecture.course_name%></u> with <%=lecture.tutor_name %><br><%end%><%end%><% if third_term_tutorials.length>0 %><br><b>Tutorials</b>:<br><%third_term_tutorials.each do |tutorial| %><%=tutorial.number_of_tutorials%> <%="tutorial".pl(tutorial.number_of_tutorials)%> on <%= tutorial.course_name%> with <%=tutorial.tutor_name%>.<br><% end%><% end %><br><% end %><u><b>Syllabuses and Vacation Reading</b></u>:<br>I attach the “descriptors” for the Michaelmas Term courses. These include some bibliography, and it would be good to get ahead with some reading. If you can get more specific advice from your tutors, follow that; otherwise use the descriptors, and browse the library! <% if first_term_tutorials.length + first_term_languages.length>0%><br><br><u><b>Tutors’ contact details for Michaelmas Term</b></u>:<br>These are the email addresses of your tutors for Michaelmas Term, and of the lecturers who will run the language classes you are attending. It would be good to ask the tutors for recommendations for vacation reading, and to get in touch again nearer Term to fix tutorial times and topics. Ask the language-class lecturers what preparations to make for the language classes.<br><br><% if first_term_tutors.length >0 %><b>Tutorial Emails</b>:<br><%first_term_tutors.each do |a_tutor|%><%=a_tutor.tutor_name%>: <%=a_tutor.email%>.<br><%end%><br><% end %><% if first_term_language_tutors.length >0 %><b>Language Class Emails</b>:<br><%first_term_language_tutors.each do |a_tutor|%><%=a_tutor.tutor_name%>: <%=a_tutor.email%>.<br><%end%><%end%><br><%end%>If anything seems unclear, or you need more advice for the vacation, or feel the need to change some of the arrangements, please get in touch.<br>With best wishes,<br>Richard.<br>(Richard Conrad, O.P., Vice Regent).<br><br><br><p></p>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>"",
      :personal_warnings=>"");

      EmailTemplate.create(:template_name => "Confirmation of teaching plans, for tutors",
      :from_email => "<%= me.email %>",
      :subject => "The coming Term’s teaching for Blackfriars",
      :ruby_header=> %q{<%  first_term = term;  first_term_name = TermName.find(first_term.term_name_id).name;  first_term_year = first_term.year;  confirmed_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'lectures' AND group_name='Lecturer Confirmed'");  language_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'courses' AND group_name='Language Classes'");  if confirmed_groups.length >0 then confirmed_id = confirmed_groups[0].id else confirmed_id = 0 end;  if language_groups.length >0 then language_group_id = language_groups[0].id else language_group_id = 0 end;  first_term_lectures = Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  first_term_language_classes = Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  second_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+1} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND (SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  third_term_language_classes =  Lecture.find_by_sql("SELECT *, (SELECT COUNT(*) FROM attendees x1 WHERE x1.lecture_id = a0.id) AS number_of_students_at_lecture  FROM lectures a0 WHERE a0.term_id = #{term.id+2} AND a0.person_id = #{person.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0 AND(SELECT COUNT(*) FROM group_lectures a1 WHERE a1.group_id=#{confirmed_id} AND a1.lecture_id = a0.id)>0");  first_term_tutorial_schedules = TutorialSchedule.find_by_sql("SELECT * FROM tutorial_schedules WHERE term_id = #{first_term.id} AND person_id = #{person.id}");  if first_term_tutorial_schedules.length > 0 then       first_term_tutorial_str = "";       first_term_tutorial_schedules.each do |tutorial_schedule1|      if (first_term_tutorial_str.length >0) then first_term_tutorial_str << ", "; end;         first_term_tutorial_str << tutorial_schedule1.id.to_s;       end;    first_term_tutorials = Tutorial.find_by_sql("SELECT  *, a10.number_of_tutorials AS num_tutorials, a99.first_name || '  ' || a99.second_name  AS student_name,   a83.name  AS course_name FROM tutorials a0 INNER JOIN people a99 ON  a0.person_id = a99.id INNER JOIN ( tutorial_schedules a10 INNER JOIN courses a83 ON  a10.course_id = a83.id ) ON a0.tutorial_schedule_id = a10.id  WHERE  (a0.id != 1  AND (a0.tutorial_schedule_id IN (#{first_term_tutorial_str}) )) ORDER BY  course_name asc, student_name  asc");  else    first_term_tutorials = [];     end;  students = Person.find_by_sql("SELECT  *, a0.first_name || '  ' || a0.second_name  AS student_name FROM people a0  WHERE (a0.id != 1  AND (SELECT COUNT(*) FROM tutorials y1 INNER JOIN tutorial_schedules y2 ON y2.id = y1.tutorial_schedule_id WHERE y1.person_id = a0.id AND y2.person_id = #{person.id} AND  y2.term_id = #{term.id})>0 ) ORDER BY  student_name  asc ");%>},
      :body=> %q{Dear <%= person.salutation%>,<br><br><%if first_term_name == "Michaelmas"%>I hope you had a good summer.<br><br><% end%>Thanks for expressing your willingness to undertake the teaching for Blackfriars that I asked you to undertake.<br><br>This email is to confirm the arrangements <b>for the coming <%=first_term_name%> Term</b>. <span style="color: rgb(128, 192, 255);" tag="span" class="yui-tag-span yui-tag">You will see there has been a bit of fine-tuning to the tutorial courses, but this should not increase your work load</span>. If there are now any problems with the teaching, then of course please be in touch and we can modify the arrangements.<br><br>I attach the lecture list for the term in case you have mislaid the copy sent earlier.<% if (first_term_lectures.length + first_term_language_classes.length + first_term_tutorials.length) >0 %><% if first_term_lectures.length >0%><br><br><b>Lectures</b>:<% first_term_lectures.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students =lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if first_term_language_classes.length >0%><br><br><b>Language Classes</b>:<% first_term_language_classes.each do |lecture| course_name = Course.find(lecture.course_id).name; num_students = lecture.number_of_students_at_lecture.to_i %><br><u><%=course_name%></u>. <%if num_students>0%> I expect roughly <%=num_students%> <%= "student".pl(num_students)%> to attend.&nbsp; <%else%> I currently don't know how many students will attend<%end%><% end %> <% end %><% if first_term_tutorials.length> 0%><br><br><b>Tutorials</b>:<% first_term_tutorials.each do |tutorial| num_tutorials = tutorial.num_tutorials.to_i; student = tutorial.student_name; course = tutorial.course_name%><br><%=num_tutorials%> <%="tutorial".pl(num_tutorials)%> on <%=course%> for <%=student%> <% end %> <% end %><br><br><% end %>Do you need more information about any of the students you will be tutoring, their backgrounds, needs, interests?<br><br><%if students.length > 0%> <%if first_term_name == "Michaelmas" %>In case you still need to chase up any of your tutorial students for the forthcoming Michaelmas Term, here is an up-to-date list of email addresses.<br><br><%students.each do |student|%><%=student.student_name%>: <%=student.email%><br><%end%><br>With many thanks, and best wishes for the new academic year,<% else %><u><b>Vacation Reading and students’ contact details:</b></u><br><br>These are the up-to-date email addresses of your students for next Term. It would be good to give them recommendations for vacation reading, if you can. Hopefully they will get in touch with you nearer Term to fix tutorial times and topics.<br><br><%students.each do |student|%><%=student.student_name%>: <%=student.email%><br><%end%><br>I hope you have a good vacation.<br><br>With many thanks, and best wishes,<% end %><br><%end%><br>Richard.<br><br>(Richard Conrad, O.P., Vice Regent).<br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; <br><br>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>"",
      :personal_warnings=>"");

    EmailTemplate.create(:template_name => "Confirmation of teaching plans, for students",
      :from_email => "<%= me.email %>",
      :subject => "The coming Term’s studies at Blackfriars",
      :ruby_header=> %q{<%     first_term = term;       first_term_name = TermName.find(first_term.term_name_id).name;    first_term_year = first_term.year;       language_groups = Group.find_by_sql("SELECT * FROM groups WHERE table_name = 'courses' AND group_name='Language Classes'");     if language_groups.length >0 then language_group_id = language_groups[0].id; else language_group_id = 0; end;        first_term_examined =  Lecture.find_by_sql("SELECT  a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = true AND a0.term_id = #{first_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");        first_term_not_examined =  Lecture.find_by_sql("SELECT  a0.id, a30.name  AS course_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND y1.examined = false AND a0.term_id = #{first_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)=0) ORDER BY   course_name  asc ");       first_term_languages = Lecture.find_by_sql("SELECT  a0.id, a30.name AS course_name, x1.first_name || ' ' || x1.second_name AS tutor_name FROM lectures a0 INNER JOIN courses a30 ON  a0.course_id = a30.id INNER JOIN people x1 ON x1.id = a0.person_id INNER JOIN attendees y1 ON y1.lecture_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{first_term.id} AND (SELECT COUNT(*) FROM group_courses a2 WHERE a2.group_id = #{language_group_id} AND a2.course_id = a0.course_id)>0) ORDER BY  course_name  asc ");        first_term_tutorials = TutorialSchedule.find_by_sql("SELECT  a0.id, a0.number_of_tutorials, a30.name AS course_name, a31.first_name || ' ' || a31.second_name AS tutor_name FROM tutorial_schedules a0 INNER JOIN courses a30 ON a0.course_id = a30.id INNER JOIN people a31 ON a31.id = a0.person_id INNER JOIN tutorials y1 ON y1.tutorial_schedule_id = a0.id  WHERE  (a0.id != 1  AND y1.person_id =#{person.id} AND a0.term_id = #{first_term.id}) ORDER BY  course_name  asc ");        first_term_tutors = Person.find_by_sql("SELECT a0.first_name || ' ' || a0.second_name AS tutor_name, a0.email FROM people a0 WHERE (a0.id != 1 AND (SELECT COUNT(*) FROM tutorials y1 INNER JOIN tutorial_schedules y2 ON y2.id = y1.tutorial_schedule_id WHERE y2.person_id = a0.id AND y1.person_id = #{person.id} AND y2.term_id = #{first_term.id})>0) ORDER BY tutor_name asc  ");        if first_term_languages.length !=0 then     language_ids = "";    first_term_languages.each do|language|      if language_ids.length>0 then language_ids << ", "; end;  language_ids << language.id.to_s;    end;          first_term_language_tutors = Person.find_by_sql("SELECT a0.id, a0.first_name|| ' ' || a0.second_name AS tutor_name, a0.email FROM people a0 WHERE (a0.id != 1 AND (SELECT COUNT(*) FROM attendees y1 INNER JOIN lectures y2 ON y2.id = y1.lecture_id WHERE y2.person_id = a0.id AND y1.person_id = #{person.id} AND y2.term_id = #{first_term.id} AND y2.id IN (#{language_ids}) )>0) ORDER BY tutor_name asc ");      else    first_term_language_tutors = [];  end;%>},
      :body=> %q{Dear <%= person.salutation%>,<br><br><%if first_term_name == "Michaelmas"%>I hope you had a good summer.<br><br><% end%>This email is to confirm the arrangements <b>for the coming <%=first_term_name%> Term</b>. If any problems have emerged to do with these studies, then of course please be in touch and we can deal with them.<br><br>I attach the lecture list for the term in case you have mislaid the copy sent earlier.<br><br><% if first_term_examined.length + first_term_not_examined.length + first_term_languages.length + first_term_tutorials.length > 0 %><% if first_term_examined.length>0 %><b>Lectures needing an end-of-term examination</b>:<br><% first_term_examined.each do |lecture| %><u><%=lecture.course_name%></u>.<br><% end %><br><% end%><% if first_term_not_examined.length>0%><b>Lectures not needing an end-of-term examination</b>:<br><% first_term_not_examined.each do |lecture| %><u><%= lecture.course_name%></u>.<br><%end%><%end%><% if first_term_languages.length>0%><br><b>Language classes</b>:<br><%first_term_languages.each do |lecture|%><u><%=lecture.course_name%></u> with <%=lecture.tutor_name %>.<br><%end%><%end%><% if first_term_tutorials.length>0 %><br><b>Tutorials</b>:<br><%first_term_tutorials.each do |tutorial| %><%=tutorial.number_of_tutorials%> <%="tutorial".pl(tutorial.number_of_tutorials)%> on <%= tutorial.course_name%> with <%=tutorial.tutor_name%>.<br><% end%><% end %><br><% end %><% if first_term_name == "Michaelmas" %><u><b>Tutors’ contact details for Michaelmas Term</b></u>:<br>In case you still need to chase up any of your tutors and lecturers for <%if first_term_name == "Michaelmas"%>the forthcoming Michaelmas<%else%> next <%end%> Term, here is an up-to-date list of email addresses. <br><br><% if first_term_tutors.length >0 %><b>Tutorial Emails</b>:<br><%first_term_tutors.each do |a_tutor|%><%=a_tutor.tutor_name%>: <%=a_tutor.email%>.<br><%end%><br><% end %><% if first_term_language_tutors.length >0 %><b>Language Class Emails</b>:<br><%first_term_language_tutors.each do |a_tutor|%><%=a_tutor.tutor_name%>: <%=a_tutor.email%>.<br><%end%><br><%end%>With best wishes for the new academic year,<% else %><u><b>Syllabuses and Vacation Reading</b></u>:<br>I attach the “descriptors” for next Term’s courses. These include some bibliography, and it would be good to get ahead with some reading. If you can get more specific advice from your tutors, follow that; otherwise use the descriptors, and browse the library!<br><br><u><b>Tutors’ contact details for next Term</b></u>:<br>These are the up-to-date email addresses of your tutors for next Term. It would be good to ask them for recommendations for vacation reading, and to get in touch again nearer Term to fix tutorial times and topics.<br><br><% if first_term_tutors.length >0 %><b>Tutorial Emails</b>:<br><%first_term_tutors.each do |a_tutor|%><%=a_tutor.tutor_name%>: <%=a_tutor.email%>.<br><%end%><br><% end %><% if first_term_language_tutors.length >0 %><b>Language Class Emails</b>:<br><%first_term_language_tutors.each do |a_tutor|%><%=a_tutor.tutor_name%>: <%=a_tutor.email%>.<br><% end %><br><%end%> If anything seems unclear, or you need more advice for the vacation, or feel the need to change some of the arrangements, please get in touch.<br><br>I hope you have a good vacation.<br><br>With best wishes,<%end%><br><br>Richard.<br><br>(Richard Conrad, O.P., Vice Regent).<br>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>"",
      :personal_warnings=>"");

    EmailTemplate.create(:template_name =>"Class list and reminder of exam arrangements",
      :from_email => "<%= me.email %>",
      :subject => "Class and exam list for the coming Term at Blackfriars",
      :ruby_header=> %q{<% lecture_schedules = Lecture.find_by_sql("SELECT * FROM lectures WHERE course_id = #{course.id} AND term_id = #{term.id}");     if lecture_schedules.length >0 then       lecture_id = lecture_schedules[0].id;      exam_attendees = Attendee.find_by_sql("SELECT *, a1.first_name || ' ' || a1.second_name AS student_name FROM attendees a0 INNER JOIN people a1 ON a1.id=a0.person_id AND a0.lecture_id = #{lecture_id} AND a0.examined= true ORDER BY student_name");      non_exam_attendees =  Attendee.find_by_sql("SELECT *, a1.first_name || ' ' || a1.second_name AS student_name FROM attendees a0 INNER JOIN people a1 ON a1.id=a0.person_id AND a0.lecture_id = #{lecture_id} AND a0.examined= false ORDER BY student_name");    else      exam_attendees = [];      non_exam_attendees = [];    end;%>},
      :body=> %q{Dear <%= person.salutation %>,<br><br>This email concerns the lecture course on <%=course.name%> for the current Term. <% if (exam_attendees.length + non_exam_attendees.length) >0 %> As I understand it, the following students are supposed to attend the lecture course – there may well be others in the class, for whom it is optional.<br><% if exam_attendees.length >0 %> <br><b>Students needing an end-of-term examination</b>:<br><br>These students need a grade for the course, but are not taking tutorials in the subject. The lecturer normally determines the exam format (often a short viva-voce exam) and scope, and explains this to the students. Exams are usually held on the Monday or Tuesday of 9th Week, at a time to suit the lecturer and the students involved.<br><br><% exam_attendees.each do |attendee|%> <%=attendee.student_name%><br><%end%><br><%end%><% if non_exam_attendees.length >0 %> <b>Students not needing an end-of-term examination</b>:<br><br><% non_exam_attendees.each do |attendee|%> <%=attendee.student_name%><br><%end%><br><%end%><% else%>No one needs to be examined in this course and no one is required to attend.<%end%>If anything seems odd, surprising, alarming, or even wrong with these arrangements, let me know.<br><br>With best wishes,<br><br>Richard.<br><br>(Richard Conrad, O.P., vice-regent)<br><br>},
      :term_dependency=>true,
      :course_dependency=>false,
      :global_warnings=>"",
      :personal_warnings=>"");

        Rails.logger.debug( "import_csv done display filters" );
    Rails.logger.flush

  end
end
