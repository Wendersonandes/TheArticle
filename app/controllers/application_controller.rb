class ApplicationController < ActionController::Base
	before_action :set_device_type

	def body_classes
		@body_classes ||= begin
			bclasses = []
			unless cookies[:cookie_permission_set]
				bclasses << 'show_cookie_notice'
			end
			bclasses.join(" ")
		end
	end
	helper_method	:body_classes

	def is_development?
		false
	end
	helper_method	:is_development?

	def is_staging?
		false
	end
	helper_method	:is_staging?

	def show_ads?
		false
	end
	helper_method	:show_ads?

	def is_tablet?
		browser.device.tablet?
	end
	helper_method	:is_tablet?

	def is_home_page?
		false
	end
	helper_method	:is_home_page?

	def is_article_page?
		false
	end
	helper_method	:is_article_page?

	def ad_page_type
		@ad_page_type ||= begin
		  if is_article_page?
		    'article'
		  elsif is_home_page?
		    'homepage'
		  else
		    'ros'
		  end
		end
	end
	helper_method	:ad_page_type

	def ad_page_id
		if ad_page_type == 'article'
			1540285666748
		elsif ad_page_type == 'homepage'
			1540285666750
		else
			1540285666762
		end
	end
	helper_method	:ad_page_id

private
  def set_device_type
    if browser.device.mobile?
      request.variant = :mobile
    else
      request.variant = :desktop
    end
  end

end
