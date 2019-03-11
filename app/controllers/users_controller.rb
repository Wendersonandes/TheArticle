class UsersController < ApplicationController
	before_action :authenticate_user!, except: [:show]

	def show
		if params[:me]
			authenticate_user!
			@user = current_user
		elsif params[:identifier] == :slug
			@user = User.active.find_by(slug: params[:slug])
		elsif params[:identifier] == :id
			@user = User.active.find_by(id: params[:id])
		end

		if (@user == current_user) && !params[:me]
			redirect_to_my_profile
		elsif !@user.has_active_status?
			flash[:notice] = "That profile is unavailable"
			redirect_to_my_profile
		end

		respond_to do |format|
			format.html do
				@sponsored_picks = Author.get_sponsors_single_posts(nil, 3)
				@trending_articles = Article.latest.limit(Author.sponsors.any? ? 4 : 5).all.to_a
				@trending_articles.insert(2, @sponsored_picks.first) if Author.sponsors.any?
			end
			format.json
		end
	end

	def update_photo
		if params[:mode] == 'coverPhoto'
			current_user.cover_photo = params[:photo]
			if current_user.save
				@status = :success
			else
				@status = :error
				@message = current_user.errors.full_messages.first
			end
		elsif params[:mode] == 'profilePhoto'
			current_user.profile_photo = params[:photo]
			if current_user.save
				@status = :success
			else
				@status = :error
				@message = current_user.errors.full_messages.first
			end
		end
	end

	def update
		profile_params = params[:profile]
		if current_user.update_attributes({
				display_name: profile_params[:display_name],
				username: profile_params[:username],
		    location: profile_params[:location][:value],
		    lat: profile_params[:location][:lat],
		    lng: profile_params[:location][:lng],
		    country_code: profile_params[:location][:country_code],
				bio: profile_params[:bio]
			})
			@status = :success
		else
			@status = :error
			@message = current_user.errors.full_messages.first
		end
	end

private

	def redirect_to_my_profile
		redirect_to my_profile_path
		# if browser.device.mobile?
		# 	redirect_to "/my-home?route=myprofile"
		# else
		# end
	end
end