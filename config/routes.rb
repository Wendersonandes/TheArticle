require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations", sessions: "sessions" }
  root 'home#index'
  get 'cookie-acceptance',                     to: 'cookie_acceptance#new'
  get 'search-suggestions',                    to: 'search#index', mode: :suggestions
  get 'search',                                to: 'search#index', as: :search, mode: :full
  get 'articles',                              to: 'articles#index', as: :articles
  get 'contact',                               to: 'contact#new'
  post 'contact',                              to: 'contact#create'

  get 'exchanges',				 					           to: 'exchanges#index'
  get 'exchange/:slug',				 			           to: 'exchanges#show', as: :exchange
  get 'user_exchanges',                        to: 'user_exchanges#index'
  get 'user_exchanges/:id',                    to: 'user_exchanges#index'
  post 'user_exchanges',                       to: 'user_exchanges#create'
  delete 'user_exchanges/:id',                 to: 'user_exchanges#destroy'

  get 'contributors',                          to: 'contributors#index'
  get 'contributor/:slug',                     to: 'contributors#show', as: :contributor
  get 'sponsors',                              to: 'sponsors#index'
  get 'sponsor',                               to: 'sponsors#show', as: :sponsor

  post   'wp-connector/:model',                to: 'wp_connector#model_save'
	delete 'wp-connector/:model/:id',            to: 'wp_connector#model_delete'
  post   'wp-connector/:model/:id/unpublish',  to: 'wp_connector#model_delete'

  post 'register',                             to: 'register#create'

  get 'username-availability',                 to: 'username_availability#new'
  get 'profile/new',                           to: 'profile_wizard#new', as: :profile_wizard
  post 'my-profile',                           to: 'profile_wizard#create', as: :save_profile_wizard

  get 'my-profile',                            to: 'users#show', as: :my_profile, me: true
  get 'account-settings',                      to: 'account_settings#edit'
  put 'account-settings',                      to: 'account_settings#update'
  put 'update-email',                          to: 'account_settings#update_email'
  put 'update-password',                          to: 'account_settings#update_password'
  get 'profile/:slug',                         to: 'users#show', as: :profile, identifier: :slug
  get 'profile-by-id/:id',                     to: 'users#show', identifier: :id
  put 'my-profile/:id',                        to: 'users#update'

  get 'user_followings',                       to: 'user_followings#index'
  get 'user_followings/:id',                   to: 'user_followings#index'
  post 'user_followings',                      to: 'user_followings#create'
  delete 'user_followings/:id',                to: 'user_followings#destroy'
  get 'follow-suggestions',                    to: 'profile_suggestions#index'
  get 'suggestion-search',                     to: 'profile_suggestions#index'
  get 'connects',                              to: 'connects#index'

  get 'front-page',                            to: 'front_page#index', as: :front_page
  get 'following',                             to: 'follows#index', mode: :following
  get 'followers',                             to: 'follows#index', mode: :followers
  get 'follow-suggestions',                    to: 'follows#index', mode: :suggestions
  get 'account-settings',                      to: 'account_settings#edit'

  get 'user_shares',                           to: 'user_shares#index'
  get 'user_shares/:id',                       to: 'user_shares#index'
  get 'user_ratings',                          to: 'user_ratings#index'
  get 'user_ratings/:id',                      to: 'user_ratings#index'
  get 'share/:id',                             to: 'shares#show'
  post 'share',                                to: 'shares#create', as: :share

  get 'comments',                              to: 'comments#index', as: :comments
  get 'comments/:id',                          to: 'comments#show', as: :comment
  post 'comments',                             to: 'comments#create'
  get 'user_comments',                         to: 'user_comments#index'
  get 'user_comments/:id',                     to: 'user_comments#index'

  get 'opinions',                              to: 'opinions#index', as: :opinions
  get 'opinions/:id',                          to: 'opinions#show', as: :opinion
  post 'opinions',                             to: 'opinions#create'
  get 'user_opinions',                         to: 'user_opinions#index'
  get 'user_opinions/:id',                     to: 'user_opinions#index'

  get 'notifications',                         to: 'notifications#index', as: :notifications
  put 'notification/:id',                      to: 'notifications#update'
  get 'notification-count',                    to: 'notifications#index', as: :notification_count, count: true
  get 'follow-groups/:id',                     to: 'follow_groups#show', as: :follow_group

  post 'concern-reports',                      to: 'concern_reports#create'

  get 'mutes',                                 to: 'mutes#index'
  post 'mutes',                                to: 'mutes#create'
  delete 'mutes/:id',                          to: 'mutes#destroy'
  get 'blocks',                                to: 'blocks#index'
  post 'blocks',                               to: 'blocks#create'
  delete 'blocks/:id',                         to: 'blocks#destroy'

  put 'deactivate',                            to: 'account_settings#deactivate'
  put 'reactivate',                            to: 'account_settings#reactivate'
  delete 'delete-account',                     to: 'account_settings#destroy'

  put 'notification-settings',                 to: 'notification_settings#update'
  put 'communication-preferences',             to: 'communication_preferences#update'

  PageRouter.load
	mount Sidekiq::Web, at: '/sidekiq'
  get "*slug", to: "articles#show", as: :article, constraints: lambda { |req|
    req.path.exclude? 'amazonaws.com'
  }
end
