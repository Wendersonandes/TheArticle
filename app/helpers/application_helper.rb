module ApplicationHelper
	def ga_tracking_id
		Rails.application.credentials.ga_tracking_id[Rails.env.to_sym]
	end

	def exchange_badge_url(exchange)
		exchange.slug == 'sponsored' ? '/sponsors' : exchange_path(slug: exchange.slug)
	end

	def strip_protocol(url)
		url.sub('https://','').sub('http://','')
	end

	def body_classes
		bclasses = [Rails.env]
		unless cookies[:cookie_permission_set]
			bclasses << 'show_cookie_notice'
		end
		bclasses.join(" ")
	end
end
