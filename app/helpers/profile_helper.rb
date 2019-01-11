module ProfileHelper
	def bio_max_length
		User.bio_max_length
	end

	def bio_excerpt(user, cutoff)
		if user.bio
			user.bio.truncate_words(cutoff)
		else
			''
		end
	end

	def following_summary(recent_followings, direction="following")
		if recent_followings.any?
		  name_limit = 3
		  sentence = direction == "following" ? " followed " : " was followed by "
		  names = []
		  stamp = recent_followings.first.created_at.to_i
		  date = recent_followings.first.created_at.strftime("%e %b")
		  recent_followings.each_with_index do |rf, index|
		  	if direction == "following"
			    profile = rf.followed
			  else
			  	profile = rf.user
			  end
		  	names << link_to(profile.display_name, profile_path(slug: profile.slug))
		    break if index >= (name_limit - 1)
		  end
		  if names.any?
			  if recent_followings.length > name_limit
			    offset = recent_followings.length - name_limit
			    sentence << "#{names.join(", ")} and #{pluralize(offset, 'other')}"
			  else
			  	if names.length == 1
			  		sentence << names[0]
			  	else
			  		sentence << names.slice(0, names.length - 1).join(", ") + " and #{names.last}"
					end
			  end
			end
		  {
		  	sentence: sentence,
		  	stamp: stamp,
		  	date: date
		  }
		else
			{}
		end
	end

	def suggestions_as_json_data(current_user, suggestions)
		items = []
		suggestions.each do |suggestion|
			user = suggestion.suggested
			items << {
				type: 'suggestion',
				stamp: suggestion.created_at.to_i,
				date: suggestion.created_at.strftime("%e %b"),
				id: user.id,
				reason: suggestion_reason_sentence(suggestion.reason),
				isFollowingMe: current_user.is_followed_by(user),
				user: {
					displayName: user.display_name,
					username: user.username,
					image: user.profile_photo.url(:square),
					path: profile_path(slug: user.slug),
					bio: bio_excerpt(user, browser.device.mobile? ? 18 : 28),
				}
			}
		end
		items
	end

	def suggestion_reason_sentence(reason)
		case reason
		when /^exchange_([0-9]*)$/
			exchange = Exchange.find($1)
			"Also follows exchange <a href='#{exchange_path(slug: exchange.slug)}'>#{exchange.name}</a>"
		when "popular_profile"
			"This is a popular member"
		when /popular_with_following_([0-9]*)$/
			user = User.find($1)
			"Followed by <a href='#{profile_path(slug: user.slug)}'>#{user.display_name}</a>"
		when /also_highly_rated_article_([0-9]*)$/
			article = Article.find($1)
			"Also highly rated <a href='#{article_path(article)}'>#{article.title}</a>"
		end
	end
end