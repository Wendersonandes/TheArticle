class TheArticle.Home extends TheArticle.DesktopPageController

	@register window.App
	@$inject: [
	  '$scope'
	  '$http'
	  '$rootElement'
	  '$timeout'
	  'EditorsPick'
	  'SponsoredPick'
	]

	init: ->
		@bindEvents()
		@scope.editorsPicks =
			page: 1
			items:  []
			totalItemCount: 0
			loading: false
			firstLoaded: false
			moreToLoad: true
		@scope.sponsoredPicks =
			items:  []
			loading: false
			firstLoaded: false

	bindEvents: =>
		super
		$('.slick-carousel.articles').first().on 'init', (e) =>
			@getEditorsPicks()
			@getSponsoredPicks()

		$('.see_more_articles').on 'click', (e) =>
			$clicked = $(e.currentTarget)
			nextSection = Number($clicked.data('section')) + 1
			$clicked.hide().parent().find("a[data-section=#{nextSection}]").show()

	loadMore: (resource) =>
		resource = "get" + resource.charAt(0).toUpperCase() + resource.slice(1)
		@[resource]()

	getEditorsPicks: =>
		@scope.editorsPicks.loading = true
		timeoutDelay = if @scope.editorsPicks.page is 1 then 1500 else 1000
		vars = { tagged: 'editors-picks', page: @scope.editorsPicks.page, perPage: @rootElement.data('per-page') }
		@EditorsPick.query(vars).then (response) =>
			@timeout =>
				@scope.editorsPicks.totalItemCount = response.total if @scope.editorsPicks.page is 1
				angular.forEach response.articles, (article) =>
					@scope.editorsPicks.items.push article
				@scope.editorsPicks.moreToLoad = @scope.editorsPicks.totalItemCount > @scope.editorsPicks.items.length
				@scope.editorsPicks.firstLoaded = true if @scope.editorsPicks.page is 1
				@scope.editorsPicks.loading = false
				@scope.editorsPicks.page += 1
			, timeoutDelay
		, (response) =>
			@refreshPage() if response.status is 401

	getSponsoredPicks: =>
		@scope.sponsoredPicks.loading = true
		timeoutDelay = 2000
		vars = { sponsored_picks: 1 }
		@SponsoredPick.query(vars).then (response) =>
			@timeout =>
				angular.forEach response.articles, (article) =>
					@scope.sponsoredPicks.items.push article
				@scope.sponsoredPicks.firstLoaded = true
				@scope.sponsoredPicks.loading = false
			, timeoutDelay
		, (response) =>
			@refreshPage() if response.status is 401

TheArticle.ControllerModule.controller('HomeController', TheArticle.Home)