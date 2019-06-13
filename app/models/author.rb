class Author < ApplicationRecord
	include WpCache
	has_many	:articles
	belongs_to	:author_role, foreign_key: :role_id
  mount_uploader :image, AuthorImageUploader
	has_one	:user

	def is_sponsor?
		self.author_role == AuthorRole.find_by(slug: 'sponsor')
	end

  def self.update_article_counts
    all.each do |a|
      a.update_attribute(:article_count, a.articles.size)
    end
  end

	def update_article_count
		self.update_attribute(:article_count, self.articles.size)
	end

	def self.sponsor_role
		AuthorRole.find_by(slug: 'sponsor')
	end

	def self.contributor_role
		AuthorRole.find_by(slug: 'contributor')
	end

	def self.fetch_for_exchange(exchange, limit=6)
		self.joins(articles: :exchanges)
				.where(author_role: contributor_role)
				.where("email NOT LIKE ?", '%@thearticle.com')
				.where("authors.image IS NOT NULL")
				.where("authors.article_count > 0")
				.where("exchanges.id = ?", exchange.id)
				.order(Arel.sql('RAND()'))
				.distinct
				.limit(limit)
	end

	def self.contributors_for_spotlight(limit=6, excludes=[])
		authors = self.joins(:articles)
				.where(author_role: contributor_role)
				.where("email NOT LIKE ?", '%@thearticle.com')
				.where("authors.image IS NOT NULL")
				.where("authors.article_count > 0")
				.order(Arel.sql('RAND()'))
				.distinct
				.limit(limit)

		authors = authors.where.not("authors.id": excludes) if excludes.any?
		authors
	end

	def self.prioritise_editors_in_list(list)
		editors = []
		list.each_with_index do |item, index|
			if item.email == 'stephen.rand@thearticle.com'
				editors.unshift item
			end
			if item.email == 'olivia.utley@thearticle.com'
				editors.unshift item
			end
			if item.email == 'daniel.johnson@thearticle.com'
				editors.unshift item
			end
		end
		list.reject! {|item| editors.map(&:id).include?(item.id) }
		editors.each do |editor|
			list.unshift editor
		end
		list
	end

	def self.with_complete_profile(exclude=[])
		self.contributors
				.where.not(id: exclude)
				.where.not(image: nil)
				.where("display_name > ''")
				.where("blurb > ''")
				.where("article_count > 0")
				.distinct
	end

	def random_article(tag=nil)
		random_articles = self.articles.includes(:exchanges)
																		.references(:exchanges)
																		.order(Arel.sql('RAND()'))
		random_articles = random_articles.includes(:keyword_tags)
																			.references(:keyword_tags)
																			.where("keyword_tags.slug = ?", tag) if tag
		random_articles.first
	end

	def self.sponsors_for_listings
		self.sponsors.where("article_count > ?", 0)
								.where("display_name > ''")
								.where("blurb > ''")
	end

	def self.sponsors
		@@sponsors ||= begin
			sponsors = self.where(author_role: sponsor_role)
											.includes(:articles)
											.references(:articles)
											.where.not(articles: {id: nil})
		end
	end

	def self.contributors
		@@contributors ||= begin
			contributors = self.where(author_role: contributor_role)
		end
	end

	def self.get_sponsors_single_posts(tag=nil, limit=nil)
		cache_key = "sponsors_single_posts"
		cache_key << "_#{tag}" unless tag.nil?
		cache_key << "_#{limit}" unless limit.nil?
		# Rails.cache.fetch(cache_key) do
			sponsored_articles = []
			self.sponsors.each do |sponsor|
				random_article = sponsor.random_article(tag)
				sponsored_articles << random_article unless random_article.nil?
				break if limit && (sponsored_articles.size >= limit)
			end
			sponsored_articles.sort_by! { |a| a.published_at }
			sponsored_articles.reverse
		# end
	end

	def self.wp_type
		'users'
	end

	def update_wp_cache(json)
		self.wp_id = json["id"]
		self.display_name = json["name"]
		self.first_name = json["firstname"]
		self.last_name = json["lastname"]
		self.email = json["email_address"]
		self.blurb = json["blurb"]
		self.title = json["title"]
		self.url = json["url"]
		self.slug = json["slug"]
		self.twitter_handle = json["twitter_handle"]
		self.facebook_url = json["facebook_url"]
		self.instagram_username = json["instagram_username"]
		self.youtube_url = json["youtube_url"]
		update_author_image(json)
		update_author_role(json)
		self.save

    # set local user
    if local_user = User.find_by(username: json["thearticle_username"])
    	if self.user != local_user
    		self.user = local_user
    		self.save
    	end
    end

		# update counter cache column
		update_article_count

    # bust caches
    ["sponsors_single_posts"].each do |cache_key|
    	# puts "busting cache: #{cache_key}_*"
      Rails.cache.delete_matched("#{cache_key}_*")
    end
	end

	def update_author_role(json)
		unless self.author_role && (self.author_role.slug == json["role"])
			json["role"] = json["role"] == 'journalist' ? 'contributor' : json["role"]
			if role = AuthorRole.find_by_slug(json["role"])
				self.author_role = role
			else
				self.build_author_role({
					name: json["role"].humanize,
					slug: json["role"]
				})
			end
		end
	end

	def update_author_image(json)
		remote_wp_image_id = json["author-image-id"].to_i
		if remote_wp_image_id > 0
			unless self.wp_image_id && (self.wp_image_id == remote_wp_image_id)
	      self.wp_image_id = remote_wp_image_id
				image_json = self.class.get_from_wp_api("media/#{remote_wp_image_id}")
	      self.remote_image_url = image_json["source_url"]
			end
		else
	    self.wp_image_id = nil
	    self.image = nil
		end
	end

	def post_count
		3
	end

	def author_role_id
		role_id
	end

end
