Rails.application.routes.draw do
  # Authenticate users for DelayedJobWeb
  authenticated :user do
    mount DelayedJobWeb, at: '/delayed_job'
  end

  # Static pages
  get 'pages/contact', to: 'pages#contact', as: 'contact'
  get 'pages/copyright_and_permissions', to: 'pages#copyright_and_permissions', as: 'copyright_and_permissions'
  get 'pages/interview_guidelines', to: 'pages#interview_guidelines', as: 'interview_guidelines'
  get 'pages/family_history', to: 'pages#family_history', as: 'family_history'
  get 'pages/programs', to: 'pages#programs', as: 'programs'
  get 'pages/organizations', to: 'pages#organizations', as: 'organizations'
  get 'pages/training', to: 'pages#training', as: 'training'
  get 'pages/bibliography', to: 'pages#bibliography', as: 'bibliography'

  # Admin routes
  get '/admin', to: 'admin#index', as: 'admin'
  get '/admin/logs', to: 'admin#logs', as: 'admin_logs'

  post 'admin/run_import', to: 'admin#run_import', as: 'run_import'
  post 'admin/run_single_import', to: 'admin#run_single_import', as: 'run_single_import'
  delete 'admin/delete_jobs', to: 'admin#delete_jobs', as: 'delete_jobs'
  delete 'destroy_all_delayed_jobs', to: 'admin#destroy_all_delayed_jobs'

  # Blacklight and Dynamic Sitemap Engines
  mount Blacklight::Engine => '/'
  mount BlacklightDynamicSitemap::Engine => '/'

  # Blacklight catalog and searchable routes
  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new
  concern :marc_viewable, Blacklight::Marc::Routes::MarcViewable.new

  # Custom searchable resources
  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  resource :interviewee, only: [:index], as: 'interviewee', path: '/interviewee', controller: 'interviewee' do
    concerns :searchable
  end

  resource :full_text, only: [:index], as: 'full_text', path: '/full_text', controller: 'full_text' do
    concerns :searchable
  end

  # Solr Documents (exportable and MARC viewable)
  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns [:exportable, :marc_viewable]
  end

  # Bookmarks
  resources :bookmarks, only: [:index, :update, :create, :destroy] do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # Devise authentication for users
  devise_for :users

  # Health Check (for load balancers, uptime monitoring)
  get "up" => "rails/health#show", as: :rails_health_check

  # Progressive Web App (PWA) support
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end

# Rails.application.routes.draw do
#   mount Blacklight::Engine => '/'
#   root to: "catalog#index"
#   concern :searchable, Blacklight::Routes::Searchable.new

#   resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
#     concerns :searchable
#   end

#   concern :exportable, Blacklight::Routes::Exportable.new

#   resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
#     concerns :exportable
#   end

#   resources :bookmarks, only: [:index, :update, :create, :destroy] do
#     concerns :exportable

#     collection do
#       delete 'clear'
#     end
#   end
#   # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

#   # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
#   # Can be used by load balancers and uptime monitors to verify that the app is live.
#   get "up" => "rails/health#show", as: :rails_health_check

#   # Render dynamic PWA files from app/views/pwa/*
#   get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
#   get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

#   # Defines the root path route ("/")
#   # root "posts#index"
# end
