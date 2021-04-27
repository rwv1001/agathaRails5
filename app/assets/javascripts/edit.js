var open_windows = new MyHash();
function div_test()
{

    
    //jQuery('#div_test').submit();
    elem = document.getElementById('div_test');
    Rails.fire(elem, 'submit');    

}



function on_load()
{
    win_load_obj = jQuery('#win_load')
    if(win_load_obj.get(0)){
    //win_load_obj.submit();
    elem = document.getElementById('win_load');
    Rails.fire(elem, 'submit');;

    }
}

function file_change()
{

    disable_div = jQuery("<div></div>").attr({style: "position:absolute; top:0; right:0; width:100%; height: 100%; background-color: #ff0000;  opacity:0.0" });
    main_div = jQuery('#main_div');
    main_div.insert( {
            'after':disable_div
        } );
     disable_div.css('cursor','wait');
    submit_upload_obj = jQuery('#file_upload');
   // submit_upload_obj.submit();
    elem = document.getElementById('file_upload');
    Rails.fire(elem, 'submit');
 
}

function file_change2()
{
    submit_upload_obj = jQuery('#edit_agatha_file');
    elem = document.getElementById('edit_agatha_file');
    Rails.fire(elem, 'submit');
  //  submit_upload_obj.submit();
    x = 1;
}
function myBlur()
{
 x =1;
 y = 2;
 z = x+y;
}





function on_unload()
{

    parent_win=window.opener;
    if(parent_win!=null)
        {
            id_obj = jQuery(parent_win.document.getElementById('child_unload_main_id'));
            table_obj = jQuery(parent_win.document.getElementById('child_unloade_main_table_name'));
            attribute_obj = jQuery(parent_win.document.getElementById('child_unload_main_attribute_name'));

            unload_id_obj = jQuery('#unload_id_value');
            unload_table_obj = jQuery('#unload_table_name');
            unload_attribute_obj =  jQuery('#unload_attribute_name');
            unload_data_type_obj =  jQuery('#unload_data_type');
            
            id_obj.val(  unload_id_obj.val());
            table_obj.val(  unload_table_obj.val());
            attribute_obj.val( unload_attribute_obj.val());
            attr_val = unload_attribute_obj.val();
            data_type_val = unload_data_type_obj.val();
            editBlur(attr_val, data_type_val);
            //submit_obj = parent_win.document.getElementById('child_unload_main');
           // Rails.fire(submit_obj, 'submit');
           // submit_obj.submit();
        }

    win_unload_obj = jQuery('#win_unload')
    if(win_unload_obj.get(0)){
    	//win_unload_obj.submit();
    	elem = document.getElementById('win_unload');
        Rails.fire(elem, 'submit');;
    }
}

function open_win()
{
my_window = window.open("http://localhost:3000/people/13/edit?table_name=Person");
}


function update_parent(table_name, attribute_name, id)
{
    parent_win=window.opener;
    if(parent_win == null)
        {
            first_parent = window.open('','main_window');
            if(first_parent != jQuery(window))
            {
                    parent_win = first_parent
            }
        }
    if(parent_win!=null)
        {
            id_obj = parent_win.document.getElementById('update_main_id');
            table_obj = parent_win.document.getElementById('update_main_class_name');
            attribute_obj = parent_win.document.getElementById('update_main_attribute_name');
            update_opener_attribute_name_obj = parent_win.document.getElementById('update_opener_attribute_name');
            update_opener_id_obj = parent_win.document.getElementById('update_opener_id');
            jQuery(id_obj).val( id);
            jQuery(table_obj).val( table_name);
            jQuery(attribute_obj).val( attribute_name);
            jQuery(update_opener_attribute_name_obj).val( jQuery('#sensible_update_opener_attribute_name').val());
            jQuery(update_opener_id_obj).val( jQuery('#sensible_update_opener_id').val());
            submit_obj = parent_win.document.getElementById('update_main');
            //submit_obj.submit();
            Rails.fire(submit_obj, 'submit');
        }
}

function on_edit( table_name,class_name,id)
{
    span_aref_obj_str = "a_edit_"+table_name +"_" + id;

    span_aref_obj_str120 = "#"+span_aref_obj_str;
    span_aref_obj  = jQuery(span_aref_obj_str120 );
    aref_obj = span_aref_obj.find('a').first();
    var  disabled_a = jQuery("<label></label>").attr({'class': 'alabel'});
    disabled_a.html('Edit ')
    aref_obj.remove();
    span_aref_obj.replaceWith(disabled_a);

    attribute_opener =''
    opener_id = 1;
    open_windows.set('main', jQuery(window));
    open_edit_window(attribute_opener,  opener_id, table_name, class_name, id);


    y= 2;
   
  
}
function open_edit_window(attribute_opener, opener_id, table_name,class_name,id)
{

      new_name = class_name + '_' + id;
   url = '/'+table_name +'/' + id +'/edit?table_name='+ class_name;
   new_height = screen.height-20;

    var config_window = 'toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=1,width='+ (screen.width/2 - 16)+ ', height=' + new_height  +',left='+(screen.width/2 +17)+',top=20'

    stupid_update_opener_attribute_name_obj = jQuery('#stupid_update_opener_attribute_name');
    stupid_update_opener_attribute_name_obj.val(attribute_opener);
    stupid_update_opener_id_obj = jQuery('#stupid_update_opener_id');
    stupid_update_opener_id_obj.val( opener_id);
    
    win_ref = window.open(url,new_name, config_window);
    update_opener_attribute_name_obj = win_ref.document.getElementById('update_opener_attribute_name');
    jQuery(update_opener_attribute_name_obj).val( attribute_opener);

    update_opener_id_obj = win_ref.document.getElementById('update_opener_id');
    jQuery(update_opener_id_obj).val( opener_id);
    open_windows.set(new_name , win_ref );

}
function silly_update()
{
 
    parent_win=window.opener;
    if(parent_win!=null)
    {
          
         stupid_update_opener_attribute_name_obj = parent_win.document.getElementById('stupid_update_opener_attribute_name');
         stupid_update_opener_id_obj = parent_win.document.getElementById('stupid_update_opener_id');
         jQuery('#sensible_update_opener_attribute_name').val( jQuery(stupid_update_opener_attribute_name_obj).val());
        
         jQuery('#sensible_update_opener_id').val( stupid_update_opener_id_obj.val());
         
       //   
    }

}

function OnChangeNewGroup(class_name)
{
    button_id = "create_group_button_"+class_name;

    button_id181 = "#"+button_id;
    button_elt  = jQuery(button_id181 );
    group_name_id = "new_group_name_" + class_name;

    group_name_id183 = "#"+group_name_id;
    group_name_elt  = jQuery(group_name_id183);
    current_str = group_name_elt.val();
    new_str = current_str.replace(/^\s+/,'').replace(/\s+$/,'');
    if(new_str.length!=0)
        {
            button_elt.disabled = false;
        }
        else
            {
                 button_elt.disabled = true;
                
            }
}

function setcheck(check_id, value)
{

    check_id199 = "#"+check_id;
    check_obj  = jQuery(check_id199);
    check_obj.checked = value;
}

function on_checkbox_click(row_id, type_name, class_name)
{
    check_str = class_name +'_'+ type_name +'_'+  row_id

     check_str206 = "#"+check_str;
     check_obj  = jQuery(check_str206)
    if( check_obj != null && check_obj.checked)
        {

            class_name209 = "#"+class_name;
            select_box  = jQuery(class_name209 + "_check_"+row_id);
            select_box.checked = true;
        }
        return check_obj.checked
}

function on_select_check_click(row_id, class_name)
{

    class_name217 = "#"+class_name;
    select_box  = jQuery(class_name217 +"_check_"+row_id);
    
    if(select_box && !select_box.checked)
        {

            class_name221 = "#"+class_name;
            compulosry_box  = jQuery(class_name221 + "_compulsorycheck_"+row_id);
            compulosry_box.checked = false;

            class_name223 = "#"+class_name;
            exam_box  = jQuery(class_name223 + "_examcheck_"+row_id);
            exam_box.checked = false;
        }
        return select_box.checked
}
function on_assign(id)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
        });
     sent_tutor = jQuery("<input></input>").attr({ type: 'text', name: 'id',  value: id  });
     specific_div.insert({ 'bottom': sent_tutor  });
     class_name = jQuery('#action_class').val();
     search_results_div_str = "search_results_" + class_name;

     search_results_div_str239 = "#"+search_results_div_str;
     search_results_div  = jQuery(search_results_div_str239)
     search_results_div.find('.check').each(function()
     {
            new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
            specific_div.append(new_elt  )
      });

    form_obj = jQuery('#action_form');
   // form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');;

}

function on_willing(id)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
        });
     sent_willing = jQuery("<input></input>").attr({ type: 'text', name: 'willing_id',  value: id  });
     specific_div.insert({ 'bottom': sent_willing   });
     class_name = jQuery('#action_class').val();
     search_results_div_str = "search_results_" + class_name;

     search_results_div_str261 = "#"+search_results_div_str;
     search_results_div  = jQuery(search_results_div_str261)
     search_results_div.find('.check').each(function()
     {
            new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
            specific_div.append(new_elt  )
      });

    form_obj = jQuery('#action_form');
    //form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');;

}

function on_agatha_send(id,test_flag)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
        });

    sent_email = jQuery("<input></input>").attr({ type: 'text', name: 'email_id',  value: id  })
    sent_test_flag = jQuery("<input></input>").attr({ type: 'text', name: 'test_flag',  value: test_flag  })
    specific_div.insert({ 'bottom': sent_email });
     specific_div.insert({ 'bottom': sent_test_flag  });
    jQuery('#action_type').val( "send_email")
    form_obj = jQuery('#action_form');
   // form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');
}

function on_sends(test_flag)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
        });

   
     search_results_div_str = "search_results_AgathaEmail" ;

     search_results_div_str299 = "#"+search_results_div_str;
     search_results_div  = jQuery(search_results_div_str299)
     search_results_div.find('.check').each(function()
     {
            new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
            specific_div.append(new_elt  )
      });
     sent_test_flag = jQuery("<input></input>").attr({ type: 'text', name: 'test_flag',  value: test_flag  })
     specific_div.insert({ 'bottom': sent_test_flag  });
    jQuery('#action_type').val( "send_emails")
    form_obj = jQuery('#action_form');
   // form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');;
    
}
function on_create_send(id)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
        });
    jQuery('#action_type').val(  "create_send_email_from_template");
             class_name = jQuery('#action_class').val();

            class_name320 = "#"+class_name;
            action_div  = jQuery(class_name320 +'_action_div');
            email_template_div = action_div.find('email_template_div:first');

            term_elt = jQuery('#email_template_term');
            term_id = term_elt.val();
            course_elt = jQuery('#email_template_course');
            course_id = course_elt.val();
            sent_template = jQuery("<input></input>").attr({ type: 'text', name: 'email_template_id',  value: id  })
            sent_term = jQuery("<input></input>").attr({ type: 'text',  name: 'term_id', value: term_id });
            sent_course = jQuery("<input></input>").attr({ type: 'text',  name: 'course_id', value: course_id });
            specific_div.insert({  'bottom': sent_template});
            specific_div.insert({  'bottom': sent_term});
            specific_div.insert({  'bottom': sent_course});
            class_name2 = jQuery('#action_class2').val();
            search_results_div_str = "search_results_" + class_name2;

            search_results_div_str335 = "#"+search_results_div_str;
            search_results_div  = jQuery(search_results_div_str335)
            search_results_div.find('.check').each(function()
            {
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
                specific_div.append(new_elt  )
            });

        form_obj = jQuery('#action_form');
      //  form_obj.submit();
        elem = document.getElementById('action_form');
        Rails.fire(elem, 'submit');;
      
}

function on_create(id)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
        });
    action_type = jQuery('#action_type').val();
    switch (action_type)
    {
        case 'create_lecture_from_course':
            
            class_name = jQuery('#action_class').val();

            class_name359 = "#"+class_name;
            action_div  = jQuery(class_name359 +'_action_div');
            schedule_div = action_div.find('schedule_div:first');
            lecturer_elt = jQuery('#new_lecturer');
            person_id = lecturer_elt .val();
            term_elt = jQuery('#lecture_term')
            term_id = term_elt.val();
            day_elt = jQuery('#lecture_day')
            day_id = day_elt.val();
            time_elt = jQuery('#lecture_time')
            lecture_time = time_elt.val();
            num_lectures_elt = jQuery('#number_of_lectures');
            number_of_lectures = num_lectures_elt.val();
            num_classes_elt = jQuery('#number_of_classes');
            number_of_classes = num_classes_elt.val();

            previous_suggestion_elt = jQuery('#previous_lecture_suggestions')
            previous_suggestions = previous_suggestion_elt.val();

            sent_course = jQuery("<input></input>").attr({ type: 'text', name: 'course_id',  value: id  })
            sent_lecturer = jQuery("<input></input>").attr({type: 'text',name: 'person_id',  value: person_id })
            sent_term = jQuery("<input></input>").attr({ type: 'text',  name: 'term_id', value: term_id })
            sent_day = jQuery("<input></input>").attr({ type: 'text', name: 'day_id', value: day_id  })
            sent_time = jQuery("<input></input>").attr({ type: 'text', name: 'lecture_time', value: lecture_time });
            sent_num_lectures = jQuery("<input></input>").attr({ type: 'text',   name: 'number_of_lectures',  value: number_of_lectures   })
            sent_num_classes = jQuery("<input></input>").attr({  type: 'text',  name: 'number_of_classes',  value: number_of_classes })
            sent_previous_suggestions =  jQuery("<input></input>").attr({ type: 'text',  name: 'previous_suggestions', value: previous_suggestions  })

            specific_div.insert({ 'bottom': sent_course  });
            specific_div.insert({  'bottom': sent_lecturer   });
            specific_div.insert({  'bottom': sent_term});
            specific_div.insert({  'bottom': sent_day  });
            specific_div.insert({  'bottom': sent_time  });
            specific_div.insert({  'bottom': sent_num_lectures });
            specific_div.insert({  'bottom': sent_num_classes});
            specific_div.insert({   'bottom': sent_previous_suggestions });
            break;
        case 'create_tutorials_from_course':
            class_name = jQuery('#action_class').val();

            class_name397 = "#"+class_name;
            action_div  = jQuery(class_name397 +'_action_div');
            tutorial_schedule_div = action_div.find('tutorial_schedule_div:first');
            tutor_elt = jQuery('#new_tutor');
            tutor_id = tutor_elt .val();
            term_elt = jQuery('#tutorial_schedule_term')
            term_id = term_elt.val();

            num_tutorials_elt = jQuery('#number_of_tutorials');
            number_of_tutorials = num_tutorials_elt.val();

            collection_required_elt = jQuery('#collection_required');
            if(collection_required_elt.checked)
            {
                collection_required = "1"
            }
            else
            {
                collection_required = "0";
            }
            previous_suggestion_elt = jQuery('#previous_tutorial_schedule_suggestions')
            previous_suggestions = previous_suggestion_elt.val();

            sent_course = jQuery("<input></input>").attr({ type: 'text', name: 'course_id',  value: id  })
            sent_tutor = jQuery("<input></input>").attr({type: 'text',name: 'tutor_id',  value: tutor_id })
            sent_term = jQuery("<input></input>").attr({ type: 'text',  name: 'term_id', value: term_id })
            sent_num_tutorials = jQuery("<input></input>").attr({ type: 'text',   name: 'number_of_tutorials',  value: number_of_tutorials   })
            sent_collection_required =  jQuery("<input></input>").attr({ type: 'text',   name: 'collection_required',  value: collection_required   })
            sent_previous_suggestions =  jQuery("<input></input>").attr({ type: 'text',  name: 'previous_suggestions', value: previous_suggestions  })

            specific_div.insert({ 'bottom': sent_course  });
            specific_div.insert({  'bottom': sent_tutor   });
            specific_div.insert({  'bottom': sent_term});
            specific_div.insert({  'bottom': sent_num_tutorials });
            specific_div.insert({  'bottom': sent_collection_required });
            specific_div.insert({   'bottom': sent_previous_suggestions });

            class_name2 = jQuery('#action_class2').val();
            search_results_div_str = "search_results_" + class_name2;

            search_results_div_str435 = "#"+search_results_div_str;
            search_results_div  = jQuery(search_results_div_str435)
            search_results_div.find('.check').each(function()
            {
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
                specific_div.append(new_elt  )
            });
            break;
          case 'create_email_from_template':
             class_name = jQuery('#action_class').val();

            class_name444 = "#"+class_name;
            action_div  = jQuery(class_name444 +'_action_div');
            email_template_div = action_div.find('email_template_div:first');

            term_elt = jQuery('#email_template_term');
            term_id = term_elt.val();
            course_elt = jQuery('#email_template_course');
            course_id = course_elt.val();
            sent_template = jQuery("<input></input>").attr({ type: 'text', name: 'email_template_id',  value: id  })
            sent_term = jQuery("<input></input>").attr({ type: 'text',  name: 'term_id', value: term_id });
            sent_course = jQuery("<input></input>").attr({ type: 'text',  name: 'course_id', value: course_id });
            specific_div.insert({  'bottom': sent_template});
            specific_div.insert({  'bottom': sent_term});
            specific_div.insert({  'bottom': sent_course});
            class_name2 = jQuery('#action_class2').val();
            search_results_div_str = "search_results_" + class_name2;

            search_results_div_str459 = "#"+search_results_div_str;
            search_results_div  = jQuery(search_results_div_str459)
            search_results_div.find('.check').each(function()
            {
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
                specific_div.append(new_elt  )
            });
            break;
        }
        form_obj = jQuery('#action_form');
        //form_obj.submit();
        elem = document.getElementById('action_form');
        Rails.fire(elem, 'submit');;
        


}
function on_add_attendees(lecture_id)
{

}

function on_action( id)
{
    wait();
    action_type = jQuery('#action_type').val();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){
        jQuery(this).remove()
    });

    id_elt = new Element('input',{
        type: 'text',
        name: 'id',
        value: id
    });
    specific_div.insert({
        'bottom': id_elt
    });
    switch (action_type)
    {
        case 'add_to_group': case 'remove_from_group': case 'add_to_groups': case 'remove_from_groups': case 'attach_files': case 'attach_to_emails':
            class_name2 = jQuery('#action_class2').val();
            search_results_div_str = "search_results_" + class_name2;

            search_results_div_str499 = "#"+search_results_div_str;
            search_results_div  = jQuery(search_results_div_str499)
            search_results_div.find('.check').each(function(){
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');
                specific_div.insert({
                    'bottom': new_elt
                })
            });
            break;

        case 'add_to_lectures':
            class_name2 = jQuery('#action_class2').val();
            search_results_div_str = "search_results_" + class_name2;

            search_results_div_str511 = "#"+search_results_div_str;
            search_results_div  = jQuery(search_results_div_str511)
            search_results_div.find('.check').each(function(){
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id'); specific_div.insert({
                    'bottom': new_elt
                })
            });
            search_results_div.find('.examcheck').each(function(){
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');specific_div.insert({
                    'bottom': new_elt
                })
            });
            search_results_div.find('.compulsorycheck').each(function(){
                new_elt = jQuery(this).clone(true); new_elt.removeAttribute('id');specific_div.insert({
                    'bottom': new_elt
                })
            });
            break;

    }
    form_obj = jQuery('#action_form');
 //   form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');;
     
}
function set_suggestion_class(suggest_type_str, suggestion_class)
{
    suggest_obj = jQuery('#suggest_type')
    suggest_obj.val( suggest_type_str);
    suggest_class_obj = jQuery('#suggest_class')
    suggest_class_obj.val( suggestion_class);

}
function set_action_class(class_name, class_name2, action_type)
{
    action_obj = jQuery('#action_type');

    action_table = jQuery('#action_class');
    action_class2= jQuery('#action_class2');
    action_class2.val( class_name2);
    action_table.val( class_name);

    action_obj.val(  action_type);
}

function on_remove(class_name, id)
{
    on_action(class_name, id, "remove_from_group")
}

function on_add(class_name, id)
{
    on_action(class_name, id,  "add_to_group")
}
function on_suggest(course_id)
{
    wait();
    action_type = jQuery('#action_type').val();
    suggest_div = jQuery('#specific_suggest_variables');
    suggest_div.remove();
    new_suggest_div = jQuery("<div></div>").attr({id: 'specific_suggest_variables'});
    jQuery('#make_suggestion_div').append(new_suggest_div);
    suggest_div = jQuery('#specific_suggest_variables'); 
    //suggest_div.descendants().each(function()
    //{
      //  jQuery(this).remove()
    //});
    suggest_id = jQuery('#suggest_id');
    suggest_id.val( course_id)
    class_name = jQuery('#action_class').val();

    class_name578 = "#"+class_name;
    action_div  = jQuery(class_name578 +'_action_div');
    switch(action_type)
    {
        case 'create_lecture_from_course':
            schedule_div = action_div.find('schedule_div:first');
            lecturer_elt = jQuery('#new_lecturer');
            person_id = lecturer_elt .val();
            term_elt = jQuery('#lecture_term')
            term_id = term_elt.val();
            day_elt = jQuery('#lecture_day')
            day_id = day_elt.val();
            time_elt = jQuery('#lecture_time')
            lecture_time = time_elt.val();
            num_lectures_elt = jQuery('#number_of_lectures');
            number_of_lectures = num_lectures_elt.val();
            num_classes_elt = jQuery('#number_of_classes');
            number_of_classes = num_classes_elt.val();

            previous_suggestion_elt = jQuery('#previous_lecture_suggestions')
            previous_suggestions = previous_suggestion_elt.val();


            sent_lecturer = jQuery("<input></input>").attr({type: 'text', name: 'person_id', value: person_id})
            sent_term = jQuery("<input></input>").attr({type: 'text', name: 'term_id', value: term_id})
            sent_day = jQuery("<input></input>").attr({type: 'text', name: 'day_id', value: day_id})
             sent_time = jQuery("<input></input>").attr({ type: 'text', name: 'lecture_time', value: lecture_time });
            sent_num_lectures = jQuery("<input></input>").attr({type: 'text', name: 'number_of_lectures', value: number_of_lectures})
            sent_num_classes = jQuery("<input></input>").attr({type: 'text', name: 'number_of_classes', value: number_of_classes})
            sent_previous_suggestions =  jQuery("<input></input>").attr({type: 'text', name: 'previous_suggestions', value: previous_suggestions})
            suggest_div.append(sent_lecturer);
            suggest_div.append(sent_term);
            suggest_div.append(sent_day);
            suggest_div.append(sent_time);
            suggest_div.append(sent_num_lectures);
            suggest_div.append(sent_num_classes);
            suggest_div.append(sent_previous_suggestions);
            break;
     case 'create_tutorials_from_course':
            tutorial_schedule_div = action_div.find('tutorial_schedule_div:first');
            tutor_elt = jQuery('#new_tutor');
            tutor_id = tutor_elt .val();
            term_elt = jQuery('#tutorial_schedule_term')
            term_id = term_elt.val();
            num_tutorials_elt = jQuery('#number_of_tutorials');
            number_of_tutorials = num_tutorials_elt.val();
            previous_suggestion_elt = jQuery('#previous_tutorial_schedule_suggestions')
            previous_suggestions = previous_suggestion_elt.val();
            
            sent_tutor = jQuery("<input></input>").attr({type: 'text', name: 'person_id', value: tutor_id})
            sent_term = jQuery("<input></input>").attr({type: 'text', name: 'term_id', value: term_id})
            sent_num_tutorials = jQuery("<input></input>").attr({type: 'text', name: 'number_of_lectures', value: number_of_tutorials})
            sent_previous_suggestions =  jQuery("<input></input>").attr({type: 'text', name: 'previous_suggestions', value: previous_suggestions})
            suggest_div.append(sent_tutor);
            suggest_div.append(sent_term);
            suggest_div.append(sent_num_tutorials);
            suggest_div.append(sent_previous_suggestions);
            break;
    }
    
//    descended_elt = schedule_div.firstDescendant();
//    while(descended_elt != null)
//        {
 //           insert_elt = descended_elt.clone(true);
 ///           suggest_div.append(insert_elt );
  //          descended_elt = descended_elt.next();
  //      }
        make_suggestion_form = jQuery('#make_suggestion')
        //make_suggestion_form.submit();    
        elem = document.getElementById('make_suggestion');
        Rails.fire(elem, 'submit');        
}



function SetMaxTutorials()
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){jQuery(this).remove()});
    term_elt = jQuery('#max_tutorials_term')
    term_id = term_elt.val();
    sent_term = jQuery("<input></input>").attr({type: 'text', name: 'term_id', value: term_id})
    specific_div.append(sent_term);

    max_tutorials_elt = jQuery('#max_tutorials')
    max_tutorials = max_tutorials_elt.val();
    sent_max_tutorials = jQuery("<input></input>").attr({type: 'text', name: 'max_tutorials', value: max_tutorials})
    specific_div.append(sent_max_tutorials);

    search_results_div_str = "search_results_Person";

    search_results_div_str666 = "#"+search_results_div_str;
    search_results_div  = jQuery(search_results_div_str666)
    search_results_div.find('.check').each(function(){new_elt = jQuery(this).clone(true); specific_div.append(new_elt)});

  

    action_obj = jQuery('#action_type')
    action_obj.val( "max_tutorials")
    action_table = jQuery('#action_class');
    action_table.val( "Person");

    form_obj = jQuery('#action_form');
  //  form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');  

}

function CreateGroup(class_name)
{
    wait();
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){jQuery(this).remove()});
    group_name_id = "new_group_name_" + class_name;

    group_name_id687 = "#"+group_name_id;
    group_name_elt  = jQuery(group_name_id687);
    cloned_group_name_elt = jQuery("<input></input>").attr({type: 'text', name: 'new_group_name', value: group_name_elt.val()})
    group_name_elt.val( "");
    specific_div.append(cloned_group_name_elt);
    search_results_div_str = "search_results_" + class_name;

    search_results_div_str692 = "#"+search_results_div_str;
    search_results_div  = jQuery(search_results_div_str692)
    search_results_div.find('.check').each(function(){new_elt = jQuery(this).clone(true); specific_div.append(new_elt)});


    class_name695 = "#"+class_name;
    action_div  = jQuery(class_name695 +'_action_div');
    action_div.find('.group_privacy').each(function(){new_elt = jQuery(this).clone(true); specific_div.append(new_elt)});


    action_obj = jQuery('#action_type')
    action_obj.val( "group")
    action_table = jQuery('#action_class');
    action_table.val( class_name);

    form_obj = jQuery('#action_form');
 //   form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');;
}

function GetRadioValue(radio_list)
{
    default_ret_val = radio_list[0].val();
    length = radio_list.length;
    for(i=0;i<length; i++)
    {
        if(radio_list[i].checked == true)
        {
            return radio_list[i].val();
        }
    }
    return default_ret_val;
}
function UpdateCollectionStatus()
{
    wait();
    class_name = "Tutorial"
    specific_div = jQuery('#specific_action_variables');
    specific_div.descendants().each(function(){jQuery(this).remove()});

    search_results_div_str = "search_results_" + class_name;

    search_results_div_str729 = "#"+search_results_div_str;
    search_results_div  = jQuery(search_results_div_str729)
    search_results_div.find('.check').each(function(){new_elt = jQuery(this).clone(true); specific_div.append(new_elt)});



    class_name733 = "#"+class_name;
    action_div  = jQuery(class_name733 +'_action_div');
    radio_list = action_div.find('.collection_status');
    collection_status = GetRadioValue(radio_list);
    cloned_collection_status_elt = jQuery("<input></input>").attr({type: 'text', name: 'collection_status', value: collection_status});
    specific_div.append(cloned_collection_status_elt);


    action_obj = jQuery('#action_type')
    action_obj.val( "update_collection_status")
    action_table = jQuery('#action_class');
    action_table.val( class_name);

    form_obj = jQuery('#action_form');
 //   form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');



}

function add_group(class_name, group_name, new_group_id)
{
   external_filter_group_selection_class =  ".external_filter_group_selection_"+class_name;
   external_filter_group_selection_classes = jQuery(external_filter_group_selection_class)
   external_filter_group_selection_classes.each(function()
   {
       insert_option(select_elt, group_name, new_group_id);
   });
   argument_selection_group_span_class = ".argument_selection_group_" + class_name;
   jQuery(argument_selection_group_span_class).each(function()
   {
       select_elt = span_sibling.next('select');
       if(select_elt !=null)
           {
       insert_option(select_elt, group_name, new_group_id);
           }
   });   
}

function insert_option(select_elt, group_name, new_group_id)
{
    first_option = select_elt.find('option:first');

    current_option = first_option;
    next_option = first_option.next('option');
    while(next_option != null && next_option.text.toLowerCase() < group_name.toLowerCase())
        {
            current_option = next_option;
            next_option = current_option.next('option');
        }
        var new_option = jQuery("<option></option>").attr({'value': new_group_id, 'class': 'group_class_' + new_group_id })
        new_option.text = group_name;
        current_option.after(new_option);
}
function any_selected(class_name)
{
    var ret_val = false

    search_results_div_str = "search_results_" + class_name;

    search_results_div_str792 = "#"+search_results_div_str;
    search_results_div  = jQuery(search_results_div_str792)
    search_results_div.find('.check').each(function(){
        if(jQuery(this).checked)
        {
            ret_val = true;
            throw $break;
        }
        else
            {
                x = 1;
            }
    });
    return ret_val;
}

function DeleteMembers(class_name)
{

    if(!any_selected(class_name))
        {
            alert('You have not selected any items for deletion!');
            return;
        }
        wait();

        confirm_str = "Are you sure you want to delete selected members from " + class_name + " table?";
    var answer = confirm (confirm_str)
if (!answer)
    {
        unwait();

 return;
    }

    specific_action_variables825 = "#"+specific_action_variables;
    specific_div  = jQuery(specific_action_variables825);
    specific_div.descendants().each(function(){jQuery(this).remove()});
    search_results_div_str = "search_results_" + class_name;

    search_results_div_str828 = "#"+search_results_div_str;
    search_results_div  = jQuery(search_results_div_str828)
    search_results_div.find('.check').each(function(){new_elt = jQuery(this).clone(true); jQuery(this).removeAttribute('id'); specific_div.append(new_elt)});

    action_obj = jQuery('#action_type')
    action_obj.val( "delete")
    action_table = jQuery('#action_class');
    action_table.val( class_name);
   
    form_obj = jQuery('#action_form');
//    form_obj.submit();
    elem = document.getElementById('action_form');
    Rails.fire(elem, 'submit');
   
}


function on_delete(table_name,id)
{
    confirm_str = "Are you sure you want to delete " + table_name + " with id = " + id +"?";
    var answer = confirm (confirm_str)
    wait();
if (!answer)
    {
        unwait();

 return;
    }


   table_obj_str = "delete_table_name"

   table_obj_str857 = "#"+table_obj_str;
   table_obj  = jQuery(table_obj_str857);
   id_obj_str = "delete_id"

   id_obj_str859 = "#"+id_obj_str;
   id_obj  = jQuery(id_obj_str859);
   form_obj_str = "form_delete";

   form_obj_str861 = "#"+form_obj_str;
   form_obj  = jQuery(form_obj_str861);
   table_obj.val( table_name);
   id_obj.val( id);
   ids = new Array;
   ids[0] = id;
   
   //form_obj.submit();
   elem = document.getElementById('form_obj_str');
   Rails.fire(elem, 'submit');;  
   
}

var row_count = 0;

function recolour(table_name)
{
    row_objs_str = ".row_" + table_name
    row_count = 0;
    jQuery(row_objs_str).each(function(){
        if( row_count  % 2 == 0)
        {
            row.attr({
                background:'#CCCCCC'
            });
        }
        else
        {
            row.attr({
                background:'#EEEEEE'
            });
        }
        row_count  = row_count +1;
    });

}
function on_del(table_name, ids)
{
//    alert_str = "table = " + table_name + ", ids = ";
//   ids.each(function(){alert_str = alert_str + id + ", "});
//    alert(alert_str);
    ids.each(function(){
        name = table_name + '_' + id;
        win_ref = open_windows.get(name);
        if(win_ref!=null && !win_ref.closed)
        {
            win_ref.close();
        }
        open_windows.unset(name);
        row_obj_str = ""+ id +"_"+ table_name;

        row_obj_str907 = "#"+row_obj_str;
        row_obj  = jQuery(row_obj_str907);
        if(row_obj != null)
        {
            row_obj.remove();
        }
    });
    row_objs_str = ".row_" + table_name
    row_count = 0;
    jQuery(row_objs_str).each(function(){
        if( row_count  % 2 == 0)
        {
            row.attr({
                background:'#CCCCCC'
            });
        }
        else
        {
            row.attr({
                background:'#EEEEEE'
            });
        }
        row_count  = row_count +1;
    });



  //  action_obj_str = "action_" + table_name

  action_obj_str934 = "#"+action_obj_str;
  //  action_obj  = jQuery(action_obj_str934)
  //  action_obj.val( "delete")


  form_obj_str937 = "#"+form_obj_str;
  //  form_obj  = jQuery(form_obj_str937);
  //  form_obj.submit();
}






function updateRecord(class_name)
{

// alert('updateRecord!');
x = 1;

}
function documentBlur()
{
  //  on_unload();
}

function editClick(attribute_opener,  opener_id, table_name, class_name, current_id, e)
{
    if(e.shiftKey && current_id != 1)
    {
       open_edit_window(attribute_opener, opener_id, table_name,class_name,current_id);
      //  alert("attribute_name = " + attribute_name + ", data_type = " +data_type +", current_id = "+current_id+ ", shift_key = " + e.shiftKey);
    }
}

function editBlur(attribute_name, data_type)
{
    emailBlur();
    field_name_obj = jQuery('#field_name');
    field_value_obj = jQuery('#field_value');
    field_data_type_obj = jQuery('#field_data_type');
    field_name_obj.val( attribute_name);
    field_data_type_obj.val( data_type);
    current_attribute_obj_str ="edit_"+ attribute_name;
    if(attribute_name=="collection_status")
    {
        radio_elts = jQuery("input.collection_status");
        found = false;
        found_val = 0;
        num_elts=radio_elts.length;
        for(i=0;i<num_elts && !found; i++)
        {
            if(radio_elts[i].checked)
            {
               found=true;
               found_val = radio_elts[i].val();
            }
        }
        field_value_obj.val( found_val);

    }
    else if(data_type.length !=0)
    {
    if(data_type== "boolean")
        {
            current_attribute_obj_str=  current_attribute_obj_str + "_1"
        }



    current_attribute_obj_str1001 = "#"+current_attribute_obj_str;
    current_attribute_obj  = jQuery(current_attribute_obj_str1001);
    if(data_type != "boolean")
        {
        field_value_obj.val( current_attribute_obj.val());
        }
    else
        {
            field_value_obj.val( current_attribute_obj.checked);
        }
    }

    form_obj = jQuery('#update_form');
    elem = document.getElementById('update_form');
    Rails.fire(elem, 'submit');
    //form_obj.submit();
}

function editFocus(attribute_name, data_type)
{
    jQuery('#unload_attribute').val( attribute_name);
    jQuery('#unload_data_type').val( data_type);

}

function emailBlur()
{
    table_name = jQuery('#unload_table_name');
    body_id = table_name.val()+"_body";

    body_id1027 = "#"+body_id;
    body_obj  = jQuery(body_id1027);
    if(body_obj.get(0) == null)
     {
         return;
    }

    body_id1032 = "#"+body_id;
    my_iframes  = jQuery(body_id1032).find('iframe');


     my_iframe =  my_iframes[0];
     iframe_ind =1;
     while (my_iframe.className!= "yui-editor-editable" && iframe_ind < my_iframes.length)
         {
             my_iframe = my_iframes[iframe_ind];
             iframe_ind = iframe_ind + 1;

             }


  my_body = my_iframe._document().body;
  text_content = my_body.html();
  if(/&lt;/.test(text_content))
      {
          text_content = text_content.replace(/&lt;/g,'<');

          }
            if(/&gt;/.test(text_content))
      {
          text_content = text_content.replace(/&gt;/g,'>');

          }
      
    body_value_obj = jQuery('#body_value');
   
 
   
   body_value_obj.val( text_content);

    return;

}
var myEditor = null;
function add_blur_listener()
{
    myEditor.on('editorWindowBlur', function()
{
   myEditor.saveHTML();

   editBlur("","")



},myEditor, true);

    }

function  yahoo_widget()
{

    var myEditor2 = new YAHOO.widget.Editor('edit_body', {
    height: '250px',
    width: '522px',
    dompath: true, //Turns on the bar at the bottom
    animate: true //Animates the opening, closing and moving of Editor windows
});
myEditor2._defaultToolbar.titlebar = false
myEditor2._defaultToolbar.buttonType = 'advanced';
myEditor2.render();

 myEditor =myEditor2;
add_blur_listener();

x=1;



    }
