Crmsys::Application.routes.draw do

  root :to => 'contacts#index'

  resources :accounts
  resources :attachmends
  resources :comments
  resources :contacts do
    member do
      get  :quick_info
      post :update_avatar
    end
    collection do
      get  :imexport
      get  :export
      post :import
      post :mass_destroy
    end
  end
  resources :people
  resources :companies
  resources :ware_items
  resources :sale_items

  resources :ware_houses do
    member do
      get :edit_ware_items
      put :update_ware_items
    end
  end

  resources :sales do
    member do
      get  :cancel
      post :sip
      get  :quick_info
    end
    collection do 
      post :mass_destroy
      post :mass_state
    end
  end

  resources :cases do
    member do 
      get  :cancel
      get  :report
      get  :print
      post :sip
      get  :quick_info
      post :update_inventory
    end
    collection do
      post :mass_destroy
      post :mass_state
    end
  end

  resources :tasks do
    member do
      put :accept
      put :move
      get :quick_info
    end
    collection do
      post :mass_destroy
      post :mass_accept
      get  :mass_new
    end
  end

  namespace :settings do
    resources :account
    resources :color_schemes
    resources :sale_states do
      post :mass_destroy, :on => :collection
    end
    resources :case_states do
      post :mass_destroy, :on => :collection
    end
    resources :users do
      post :mass_destroy, :on => :collection
    end
    resources :user_groups do
      post :mass_destroy, :on => :collection
    end
    resources :recent_records do
      post :mass_destroy, :on => :collection
    end
    namespace :tariff_plans do
      resources :account_tariff_plans do
	post :mass_destroy, :on => :collection
      end
    end
  end

  namespace :reports do
    #root :to => 'sales'
    resources :tasks do
      collection do
        get  :punctuality
	post :punctuality
        get  :outcoming
	post :outcoming
      end
    end
    resources :users do
      collection do
	get  :activity
	post :activity
      end
    end
    resources :contacts do
      collection do
	get  :problem_clients
	post :problem_clients
      end
    end
    resources :logs do
      collection do
	get  :logs_view
	post :logs_view
      end
    end
  end

  match 'fuzzy/search' => 'fuzzy#search', :as => :fuzzy_search
  match 'users/:id/update_avatar' => 'users#update_avatar', :as => :update_avatar_user
  match 'feedback/create' => 'feedback#create'

  match 'sign_out' => 'clearance/sessions#destroy', :as => :sign_out
  
end
