class TheArticle.Exchanges extends TheArticle.DesktopPageController

	@register window.App
	@$inject: [
	  '$scope'
	  '$http'
	  '$rootElement'
	  '$timeout'
	  'EditorsPick'
	]

	init: ->
		@bindEvents()

	bindEvents: ->
		super

TheArticle.ControllerModule.controller('ExchangesController', TheArticle.Exchanges)