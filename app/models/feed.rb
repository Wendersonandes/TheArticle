class Feed < ApplicationRecord
	belongs_to	:user
	belongs_to	:actionable, polymorphic: true

	def self.types_for_followings
		['Share', 'Comment', 'Subscription', 'Follow', 'Opinion']
	end

	def self.types_for_user
		['Categorisation']
	end

	def self.fetch_for_followings_of_user(current_user, page=1, per_page=25)
		sql = "(
						SELECT  feeds.* FROM `follows`
						LEFT JOIN `users` ON `users`.`id` = `follows`.`followed_id`
						LEFT  JOIN `feeds` ON `feeds`.`user_id` = `users`.`id`
						WHERE follows.user_id = #{current_user.id} AND
						feeds.actionable_type IN (\"#{self.types_for_followings.join('", "')}\") AND
						followed_id NOT IN ('#{current_user.muted_id_list.join('\', \'')}') AND
						followed_id NOT IN ('#{current_user.blocked_id_list.join('\', \'')}') AND
						feeds.created_at > DATE_SUB(follows.created_at, INTERVAL 1 DAY)
					) UNION ALL (
						SELECT * FROM feeds WHERE feeds.user_id = #{current_user.id} AND actionable_type IN (\"#{self.types_for_user.join('", "')}\")
					) ORDER BY created_at DESC
				"
		if per_page > 0
			offset = (page-1) * per_page
			sql += " LIMIT #{per_page} OFFSET #{offset}"
		end
		self.find_by_sql(sql)
	end
end
