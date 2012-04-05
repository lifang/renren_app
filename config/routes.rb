RenrenApp::Application.routes.draw do

  
  match "/cet4" => "similarities#cet4"
  match "/cet6" => "similarities#cet6"
  match "/kaixin4" => "similarities#kaixin_cet4"
  match "/kaixin6" => "similarities#kaixin_cet6"
  match "/sina4" => "similarities#sina_cet4"
  match "/sina6" => "similarities#sina_cet6"
  match "/qq_cet4" => "similarities#qq_cet4"
  resources :similarities do
    member do
      get :join,:redo_paper
      post :ajax_save_question_answer,:ajax_change_status
    end
    collection do
      post :ajax_add_collect,:add_collection,:ajax_report_error,:ajax_load_about_words,:ajax_add_word,:ajax_load_sheets
      get :cet4,:oauth_login_cet4,:cet6,:oauth_login_cet6,:renren_share4,:renren_share6,:refresh,:ajax_free_sum
      get :kaixin_cet4,:kaixin_cet6,:renren_like,:close_window
      get :sina_cet4,:sina_cet6,:cet4_url_generate,:cet6_url_generate,:request_qq,:manage_qq
      post :sina_share4,:sina_share6,:check_status
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  #root :to => 'similarities#welcome'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
