items = []

# USER FEEDS
@user_feeds.each do |user_feed_item|
	if user_feed_item.feeds.any?
		if user_feed_item.action_type == 'opinion'
			if item = group_user_opinion_feed_item(user_feed_item)
				items << item
			end
		elsif user_feed_item.action_type == 'comment'
			if item = group_user_comment_feed_item(user_feed_item)
				items << item
			end
		elsif (user_feed_item.action_type == 'follow') && (user_feed_item.feeds.length > 1)
			unless @my_followings_ids.include?(user_feed_item.source_id) || @my_muted_follow_ids.include?(user_feed_item.source_id)
				if item = group_user_follow_feed_item(user_feed_item, current_user)
					items << item
				end
			end
		elsif user_feed_item.action_type == 'subscription'
			unless @my_exchange_ids.include?(user_feed_item.source_id) || @my_muted_exchange_ids.include?(user_feed_item.source_id)
				if item = group_user_subscription_feed_item(user_feed_item)
					items << item
				end
			end
		end
	end
end

# FEEDS
json.total @total_feeds if @total_feeds
@feeds.each do |feed_item|
	unless feed_item.actionable.nil?
		case feed_item.actionable_type
		when 'Share'
			items << share_as_json_data(feed_item.user, feed_item.actionable)
		when 'Categorisation'
			items << categorisation_as_json_data(feed_item.user, feed_item.actionable)
		end
	end
end

if items.any?
	json.feedItems items.sort! { |a, b| b[:stamp] <=> a[:stamp] }
end


# SUGGESTIONS
json.suggestions suggestions_as_json_data(current_user, @suggestions) if @suggestions