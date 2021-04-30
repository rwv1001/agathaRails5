class AgathaMailer < ActionMailer::Base  

  def email(agatha_email, to_email)
    subject    agatha_email.subject
    recipients to_email
    from       "<#{agatha_email.from_email.gsub(/\s+/,'').split(';')[0];}>"
    sent_on    Time.now    
    content_type "multipart/mixed"




    part(:content_type => "multipart/alternative") do |a|
      a.part "text/plain" do |p|
        plain_text = render_message("email.text.plain",:body_text => agatha_email.body)
        plain_text   = plain_text.gsub(/&nbsp;/," ")
        plain_text   =  plain_text.gsub(/<br>\s*/i,"\n")
        plain_text   =  plain_text.gsub(/<p\b[^>]*>(.*?)<\/p>/i,"\n" + '\1'+"\n")
        plain_text   =  plain_text.gsub(/<div\b[^>]*>(.*?)<\/div>/i,"\n" + '\1'+"\n")
        plain_text   =  plain_text.gsub(/<([A-z][A-z0-9]*)\b[^>]*>(.*?)<\/\1>/,'\2')
        plain_text   =  plain_text.gsub(/<([A-z][A-z0-9]*)\b[^>]*>(.*?)<\/\1>/,'\2')
        plain_text   =  plain_text.gsub(/<div\b[^>]*>/i,"")
        plain_text   =  plain_text.gsub(/<\/div>/i,"")
        p.body = plain_text
        RAILS_DEFAULT_LOGGER.debug("plain email is #{p.body}")
      end

      a.part "text/html" do |p|
        p.body = render_message("email.text.html",:body_text => agatha_email.body)
        RAILS_DEFAULT_LOGGER.debug("html email is #{p.body}")
      end
    end
    


    agatha_email.agatha_files.each do |agatha_file|
      if agatha_file.agatha_data_file_name != nil

  #    attachment  :content_type => agatha_file.agatha_data_content_type,
   #               :body => File.read(agatha_file.agatha_data.path),
  #                :filename =>  agatha_file.agatha_data_file_name
      attachment agatha_file.agatha_data_content_type do |a|
        a.body = File.read(agatha_file.agatha_data.path)
        a.filename = agatha_file.agatha_data_file_name
      end
      end
    end

    
  end
end

