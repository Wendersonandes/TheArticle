class TheArticle.Home extends TheArticle.MobilePageController
	constructor: ->
		super()
		@bindEvents()

	bindEvents: =>
		super()
		$('.see_more_articles').on 'click', (e) =>
			$clicked = $(e.currentTarget)
			nextSection = Number($clicked.data('section')) + 1
			$clicked.hide().parent().find("a[data-section=#{nextSection}]").show()