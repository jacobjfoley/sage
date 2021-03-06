Sage::Application.routes.draw do

  # Projects.
  resources :projects do

    # Digital objects, part of a project.
    resources :digital_objects do
      member do
        post 'add_concept'
        post 'add_created_concept'
        post 'remove_concept'
      end

      collection do
        post 'import_drive_folder'
      end
    end

    # Concepts, part of a project.
    resources :concepts do
      member do
        post 'add_object'
        post 'remove_object'
      end
    end

    member do
      get 'statistics'
      get 'import_annotations'
      post 'import_annotations'
      get 'export_annotations'
      post 'export_annotations'
      post 'generate_key'
      post 'reset_key'
      post 'remove_user'
    end

    collection do
      get 'redeem_key'
      post 'check_key'
    end
  end

  # Users.
  resources :users do
    collection do
      get 'login'
      post 'login'
      get 'logout'
    end
  end

  # Site root.
  root "site#welcome"

  # Site pages.
  get "/welcome" => "site#welcome"
  get "/application" => "site#application"
  get "/about" => "site#about"
  get "/participant_information" => "site#participant_information"

  # Oauth controller.
  get "/receive_oauth2" => "projects#receive_oauth2"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
