namespace :sessions do

  desc "Clear expired sessions (more than 30 days old)"
  task :cleanup => :environment do
    sql = "DELETE FROM sessions WHERE (updated_at < '#{Date.today - 30.days}')"
    ActiveRecord::Base.connection.execute(sql)
  end

end
