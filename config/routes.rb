Rails.application.routes.draw do
  match '' => 'welcome#default', via: [:get, :post]
  match 'admin' => 'welcome#index', via: [:get, :post]
  match 'accessdenied' => 'welcome#accessdenied', via: [:get, :post]
  match 'index' => 'welcome#index', via: [:get, :post]
  match 'termly' => 'welcome#termly', via: [:get, :post]
  match 'mailing' => 'welcome#mailing', via: [:get, :post]
  match 'clear_filter' => 'people#clear_filter', via: [:get, :post]
  match 'help' => 'welcome#help', via: [:get, :post]
  resources :attendees
  resources :lectures
  resources :pcourses
  resources :student_programmes
  resources :programmes
  resources :people
  resources :courses
  resources :users
  resources :institutions
  resources :locations
  resources :tutorials
  resources :groups
  resources :tutorial_schedules
  resources :willing_tutors
  resources :willing_lecturers
  resources :email_templates
  resources :agatha_emails
  resources :agatha_files
  resources :maximum_tutorials
 # get '/:controller(/:action(/:id))'
  match '/:controller(/:action(/:id))', via: [:get, :post]
  
  
  
  
  
  
  
  
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
