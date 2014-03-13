HpiHiwiPortal::Application.routes.draw do
  mount Bootsy::Engine => '/bootsy', as: 'bootsy'
  scope "(:locale)", locale: /en|de/ do

    get "home/index"
    get "home/imprint"

    namespace :admin do
      resource :configurable, except: [:index]
    end
    
    devise_scope :user do 
      root :to => 'sessions#new'
    end

    resources :job_offers do
      collection do
        get "archive"
        get "matching"
      end
      member do
        get "complete"
        get "accept"
        get "decline"
        get "reopen"
        put "prolong"
        post "fire"
      end
    end

    get "employers/external", to: "employers#index_external", as: "external_employers"

    resources :employers do
    end

    #resources :users, only: [:edit, :update]

    resources :applications, only: [:create, :destroy] do
      member do
        get "accept"
        get "decline"
      end
    end

    devise_for :users, controllers: { sessions: 'sessions' }

    resources :users, only: [:show, :edit, :update]

    resources :studentsearch
    resources :faqs

    resources :staff, except: [:new, :create] do
    end

    resources :students do
      collection do
        get 'students/new' => 'students#new'
        post 'students' => 'students#create'
        get 'matching'
      end
    end
  end
end
