require 'annoying_utilities'

Rails.application.routes.draw do

  scope Dromedary.config.relative_url_root do

    mount Blacklight::Engine => Dromedary.config.relative_url_root

    # Shunt it all to the maintenace page if we need to
    match '*path' => 'static#maintenance_mode', status: 302, via: [:get, :post],
          constraints: ->(request) { AnnoyingUtilities.maintenance_mode_enabled? }


    # Splash pages
    match "dictionary/" => "catalog#home", as: :dictionary_home, via: [:get, :post], constraints: {query_string: ""}
    match "bibliography/" => "bibliography#home", as: :bib_home, via: [:get, :post], constraints: {query_string: ""}
    match "quotations/" => "quotes#home", as: :quotes_home, via: [:get, :post], constraints: {query_string: ""}


    # Rails doesn't allow dots in matched ids by default, because reasons.
    # Override the id matcher with an explicit constraint.
    match "dictionary/(:id)/track" => 'catalog#show',
          :constraints                   => {:id => /[\p{Alnum}\-\.]+/}, via: [:get, :post]

    match "bibliography/(:id)" => 'bibliography#show', as: :bib_link,
          :constraints               => {:id => /(?:BIB|HYP)[T\d\-\.]+/i}, via: [:get, :post]



    match "bibliography/" => 'bibliography#index', via: [:get, :post]



    root to: "catalog#splash"


    # Force to go to root ('/'), not index.html
    # get "/dictionary", to: redirect('/'), constraints: {query_string: ""}

    concern :searchable, Blacklight::Routes::Searchable.new


    resource :search, only: [:index], as: 'catalog', path: "/dictionary", controller: 'catalog' do
      concerns :searchable
    end

    resource :search, only: [:index], as: 'bibliography', path: "/bibliography", controller: 'bibliography' do
      concerns :searchable
    end

    resource :search, only: [:index], as: 'quotes', path: "/quotations", controller: 'quotes' do
      concerns :searchable
    end

    get '/search' => 'catalog#search', as: :search

    concern :exportable, Blacklight::Routes::Exportable.new

    resources :solr_documents, only: [:show], path: "/dictionary", controller: 'catalog' do
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

    # post 'static/search' => 'static#search'

    get 'about' => 'static#about_med', as: :about
    get 'help' => 'help#help_root', as: :help_root
    get 'help/:page' => 'help#help_page', as: :help
    get 'static/:action' => 'static', as: :static

    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  end
end
