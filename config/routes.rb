Rails.application.routes.draw do
  
  get 'bibliography/index'

  get 'bibliography/show'

  mount Blacklight::Engine => '/'

  root to: "catalog#home"
  
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :search, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  get '/search' => 'catalog#search', as: :search

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  match '/contacts', to: 'contacts#new', via: 'get'
  resources "contacts", only: [:new, :create]
  
  post 'static/search' => 'static#search'
  
  get 'static/:action' => 'static', as: :static

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
