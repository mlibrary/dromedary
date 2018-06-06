Rails.application.routes.draw do


  match "bibliography/(:id)/track" => 'bibliography#show', via: [:get, :post]
  match "bibliography/(:id)" => 'bibliography#show', via: [:get, :post]
  get "/bibliography" => 'bibliography#index', constraints: {query_string: ""}
  get "/bibliography/index", to: redirect('/bibliography'), constraints: {query_string: ""}

  mount Blacklight::Engine => '/'

  # Where should it look like it's mounted?
  default_route = 'dictionary'

  # Rails doesn't allow dots in matched ids by default, because reasons.
  # Override the id matcher with an explicit constraint.
  match "#{default_route}/(:id)/track" => 'catalog#show',
        :constraints => { :id => /[\p{Alnum}\-\.]+/ }, via: [:get, :post]

  root to: "catalog#home"




  # Force to go to root ('/'), not index.html
  get "/#{default_route}", to: redirect('/'), constraints: {query_string: ""}
  
  concern :searchable, Blacklight::Routes::Searchable.new


  resource :search, only: [:index], as: 'catalog', path: "/#{default_route}", controller: 'catalog' do
    concerns :searchable
  end

  resource :search, only: [:index], as: 'bibliography', path: "/bibliography", controller: 'bibliography' do
    concerns :searchable
  end

  get '/search' => 'catalog#search', as: :search

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: "/#{default_route}" , controller: 'catalog' do
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
