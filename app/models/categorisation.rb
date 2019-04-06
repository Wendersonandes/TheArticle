class Categorisation < ApplicationRecord
  has_many :feeds, as: :actionable
  has_many :notifications, as: :eventable
	belongs_to	:article
	belongs_to	:exchange
	before_create	:update_feeds
	after_destroy	:delete_feed_and_notification

	def handle_email_notifications(excluded_users=[])
		handled_users = []
		self.exchange.users.each do |user|
			unless excluded_users.include?(user)
		    preference = user.notification_settings.find_by(key: :email_exchanges)
		    if preference
		      if preference.value == 'as_it_happens'
		      	CategorisationEmailAsItHappensJob.set(wait_until: 20.seconds.from_now).perform_later(user, self.article, self.exchange)
		      elsif preference.value == 'daily'
		        DailyUserMailItem.create({
		          user_id: user.id,
		          action_type: 'categorisation',
		          action_id: self.id
		        })
		      elsif preference.value == 'weekly'
		        WeeklyUserMailItem.create({
		          user_id: user.id,
		          action_type: 'categorisation',
		          action_id: self.id
		        })
		      end
		    	handled_users << user
		    end
		  end
		end

		handled_users
	end

	def update_feeds
		self.exchange.users.each do |user|
			self.feeds.build({user_id: user.id})
		end
	end

	def self.build_notifications_for_article(article)
		list = []
		user_ids = []

		article.categorisations.each do |categorisation|
			exchange = categorisation.exchange
			exchange.users.each do |user|
				unless user_ids.include?(user.id)
					user_ids << user.id
					list << { user: user, exchange: exchange, categorisation: categorisation }
				end
			end
		end

		list.each do |item|
			item[:categorisation].notifications.build({
				user_id: item[:user].id,
				specific_type: nil,
				body: "New article in <a href='/exchange/#{item[:exchange].slug}' class='text-green'>#{item[:exchange].name}</a>: #{article.title.html_safe}",
				feed_id: nil
			})
		end
	end

	def delete_feed_and_notification
		self.feeds.destroy_all
		self.notifications.destroy_all
	end

	def self.table_name
		'articles_exchanges'
	end

end