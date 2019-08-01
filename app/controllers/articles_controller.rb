class ArticlesController < ApplicationController
	def index
		respond_to do |format|
			format.html do
				render_404
			end
			format.rss do
				@articles = Article.latest.limit(100)
				render :layout => false
			end
			format.json do
				params[:page] ||= 1
				params[:per_page] ||= articles_per_page
				if params[:tagged]
					if params[:tagged] == 'editors-picks'
						@articles = Article.editors_picks(params[:page].to_i, params[:per_page].to_i)
						if params[:page].to_i == 1
							@total = Article.editors_picks(0).size
							leading_article = Article.leading_editor_article
							if leading_article.present?
								@articles = @articles.all.to_a.unshift(leading_article)
								# @articles.delete_at(params[:per_page].to_i - 1)
							end
						end
					end
				elsif params[:exchange]
					per_page = params[:per_page].to_i
					if params[:include_sponsored]
						sponsored_frequency = 5
						offset = (params[:page].to_i % 2 == 0) ? 6 : 0
						sponsored_articles = Article.sponsored.includes(:exchanges)
																				.references(:exchanges)
																				.order(published_at: :desc)
																				.limit(6)
																				.offset(offset)
																				.to_a
						items_to_get = articles_per_page - (sponsored_articles.length)
					else
						items_to_get = per_page
					end

					if params[:exchange] == 'latest-articles'
						@articles = Article.latest.page(params[:page]).per(items_to_get)
						@total = Article.not_sponsored.not_remote.size if params[:page].to_i == 1
					elsif exchange = Exchange.find_by(slug: params[:exchange])
						@articles = exchange.articles.not_sponsored
																.includes(:author).references(:author)
																.includes(:exchanges).references(:exchanges)
																.order("published_at DESC")
																.page(params[:page]).per(items_to_get)
						if params[:exclude_id]
							@articles = @articles.where.not("articles.id = ?", params[:exclude_id])
						end
						if params[:page].to_i == 1
							if params[:exclude_id]
								@total = exchange.articles.where.not("articles.id = ?", params[:exclude_id]).not_sponsored.not_remote.size
							else
								@total = exchange.articles.not_sponsored.not_remote.size
							end
						end
					else
						@articles = []
						@total = 0
					end

					if params[:include_sponsored]
						@articles = @articles.to_a
						first_key = (params[:page].to_i == 1) ? 3 : 4
						sponsored_articles.each_with_index do |sa, i|
							key = (first_key + (i * sponsored_frequency))
							if @articles[key]
								@articles.insert(key, sa)
							else
								@articles.push(sa) if @articles.length > 3
								break
							end
						end
					end

				elsif params[:author]
					@contributor = Author.find_by(id: params[:author])
					@articles = @contributor.articles
																	.includes(:exchanges)
																	.references(:exchanges)
																	.order("published_at DESC")
																	.page(params[:page])
																	.per(params[:per_page].to_i)
					if params[:page].to_i == 1
						@total = @contributor.articles.size
					end
				elsif params[:sponsored_picks]
					@articles = Author.get_sponsors_single_posts('sponsored-pick', 6)
					ordered = @articles.map(&:published_at)
				end
			end
		end
	end

	def show
		@ad_page_type = 'article'
		if @article = Article.not_remote.where(slug: params[:slug])
													.includes(:author).references(:author)
													.includes(:exchanges).references(:exchanges)
													.first
			@sponsored_picks = []
			unless @article.is_sponsored?
				@sponsored_picks = Article.sponsored.includes(:exchanges)
																		.references(:exchanges)
																		.includes(:keyword_tags)
																		.references(:keyword_tags)
																		.where("keyword_tags.slug = ?", 'sponsored-pick')
																		.order(Arel.sql('RAND()'))
																		.limit(4)
																		.to_a
			end
			if rand(1..2) == 1
				@firstSideAdType = 'sidecolumn'
				@firstSideAdSlot = 1
				@secondSideAdType = 'bottomsidecolumn'
				@secondSideAdSlot = 0
			else
				@firstSideAdType = 'bottomsidecolumn'
				@firstSideAdSlot = 0
				@secondSideAdType = 'sidecolumn'
				@secondSideAdSlot = 1
			end
			@trending_articles = Article.latest.limit(Author.sponsors.any? ? 4 : 5).all.to_a
			if @sponsored_picks.any? && Author.sponsors.any?
				trending_sponsored_article = Article.sponsored.includes(:exchanges)
																				.references(:exchanges)
																				.includes(:keyword_tags)
																				.references(:keyword_tags)
																				.where("keyword_tags.slug = ?", 'sponsored-pick')
																				.where.not(id: [102])
																				.order(Arel.sql('RAND()'))
																				.limit(1)
																				.first
				@trending_articles.insert(2, trending_sponsored_article) unless trending_sponsored_article.nil?
			end
			@article_share = {
				'comments' => '',
				'rating_well_written' => nil,
				'rating_valid_points' => nil,
				'rating_agree' => nil
			}
			@article_share = current_user.existing_article_rating(@article).as_json if user_signed_in? && current_user.existing_article_rating(@article)
		else
			render_404
		end
	end
end
