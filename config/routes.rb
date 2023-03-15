Rails.application.routes.draw do

  authenticated :user do
    mount DelayedJobWeb, at: '/delayed_job'
  end

  get 'pages/contact', to: 'pages#contact', as: 'contact'

  get 'pages/copyright_and_permissions', to: 'pages#copyright_and_permissions', as: 'copyright_and_permissions'

  get 'pages/interview_guidelines', to: 'pages#interview_guidelines', as: 'interview_guidelines'

  get 'pages/family_history', to: 'pages#family_history', as: 'family_history'

  get 'pages/programs', to: 'pages#programs', as: 'programs'

  get 'pages/organizations', to: 'pages#organizations', as: 'organizations'

  get 'pages/training', to: 'pages#training', as: 'training'

  get 'pages/bibliography', to: 'pages#bibliography', as: 'bibliography'

  get '/admin', to: 'admin#index', as: 'admin'
  get '/admin/logs', to: 'admin#logs', as: 'admin_logs'

  post 'admin/run_import', to: 'admin#run_import', as: 'run_import'

  mount Blacklight::Engine => '/'
  mount BlacklightDynamicSitemap::Engine => '/'


  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :interviewee, only: [:index], as: 'interviewee', path: '/interviewee', controller: 'interviewee' do
    concerns :searchable
  end

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  resource :full_text, only: [:index], as: 'full_text', path: '/full_text', controller: 'full_text' do
    concerns :searchable
  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new
  concern :marc_viewable, Blacklight::Marc::Routes::MarcViewable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns [:exportable, :marc_viewable]
  end

  resource :bookmarks, only: [:index], as: 'bookmarks', path: '/bookmarks', controller: 'bookmarks' do
    concerns :searchable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
