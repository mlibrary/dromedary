require "annoying_utilities"

require "dromedary/services"

# This is a very expensive-to-find workaround for https://github.com/rails/rails/issues/21459
#
# The relative root URL *MUST NOT* end in a slash, but the script_name *MUST*, in order to
# avoid chopping off the last segment of the prefix for things like suggest_index_path.
Rails.application.routes.default_url_options ||= {}
Rails.application.routes.default_url_options[:script_name] = Dromedary::Services[:relative_url_root].chomp("/") + "/"

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # This scope should go away. The production prefix is managed at the Rack level.
  # scope "/" do
  mount Blacklight::Engine => "/"
  # config/routes.rb, at any priority that suits you
  mount OkComputer::Engine, at: "/status"

  # scope '/' do
  #   mount Blacklight::Engine => '/'

  # Shunt it all to the maintenace page if we need to
  match "*path" => "static#maintenance_mode", :status => 302, :via => [:get, :post],
        :constraints => ->(request) { AnnoyingUtilities.maintenance_mode_enabled? }

  # Admin access for uploading new data and changing the alias

  if [1, "1", "true"].include? ENV["ALLOW_ADMIN_ACCESS"]
    match "admin" => "admin#home", via: [:get, :post]
    get   "admin/release" => "admin#release", via: [:get]
    post  "admin/delete", to: "admin#delete"
    mount Shrine.presign_endpoint(:incoming), at: "/s3/params"
    mount Shrine.uppy_s3_multipart(:incoming), at: "/s3/multipart"
  end

  # Splash pages
  match "dictionary/" => "catalog#home", :as => :dictionary_home, :via => [:get, :post], :constraints => { query_string: "" }
  match "bibliography/" => "bibliography#home", :as => :bib_home, :via => [:get, :post], :constraints => { query_string: "" }
  match "quotations/" => "quotes#home", :as => :quotes_home, :via => [:get, :post], :constraints => { query_string: "" }

  # Rails doesn't allow dots in matched ids by default, because reasons.
  # Override the id matcher with an explicit constraint.
  match "dictionary/:id(/)(track)" => "catalog#show",
        :constraints => { id: /MED[\p{Alnum}\-.]+/ }, :via => [:get, :post]

  match "bibliography/:id(/*rest)" => "bibliography#show", :as => :bib_link,
        :constraints => { id: /(?:BIB|HYP)[T\d\-.]+/i }, :via => [:get, :post]

  match "bibliography/" => "bibliography#index", :via => [:get, :post]

  root to: "catalog#splash"

  # Force to go to root ('/'), not index.html
  # get "/dictionary", to: redirect('/'), constraints: {query_string: ""}

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :search, only: [:index], as: "catalog", path: "/dictionary", controller: "catalog" do
    concerns :searchable
  end

  resource :search, only: [:index], as: "bibliography", path: "/bibliography", controller: "bibliography" do
    concerns :searchable
  end

  resource :search, only: [:index], as: "quotes", path: "/quotations", controller: "quotes" do
    concerns :searchable
  end

  get "/search" => "catalog#search", :as => :search

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: "/dictionary", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end

  match "/contacts", to: "contacts#new", via: "get"
  resources "contacts", only: [:new, :create]

  # post 'static/search' => 'static#search'

  get "about" => "static#about_med", :as => :about
  get "help" => "help#help_root", :as => :help_root
  get "help/:page" => "help#help_page", :as => :help
  # get 'static/*' => 'static#about_med', as: :static

  # 404s -- will only match if nothing else did

  match "quotations/*path" => "quotes#show404", :via => [:get, :post]
  match "dictionary/*path" => "catalog#show404", :via => [:get, :post]
  match "bibliography/*path" => "bibliography#show404", :via => [:get, :post]
  match "*path" => "catalog#show404", :via => [:get, :post]
end
