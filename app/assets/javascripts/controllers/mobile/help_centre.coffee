class TheArticle.HelpCentre extends TheArticle.mixOf TheArticle.MobilePageController, TheArticle.PageTransitions

	@register window.App
	@$inject: [
	  '$scope'
	  '$rootScope'
	  '$http'
	  '$element'
	  '$timeout'
	  '$compile'
	  '$cookies'
	  '$ngConfirm'
	]

	init: ->
		@bindEvents()

	bindEvents: =>
		super
		$('[data-section-id]').on 'click', (e) =>
			$('#sidebarCollapse').css({opacity: 0})
			e.preventDefault()
			$('[data-section-id]').removeClass('active')
			$('.question_list').hide()
			$('.answer').hide()
			$("[data-outcome-show]").hide()
			$('#section_list').hide()
			$('a#show_left_menu_button').hide()
			$('.feedback_question').show()
			$('.feedback_answer').show()
			$clicked = $(e.currentTarget)
			$clicked.addClass('active')
			sectionId = $clicked.data('section-id')
			$("#question_list_#{sectionId}").show()

		$('[data-question-id]').on 'click', (e) =>
			e.preventDefault()
			$('.answer').hide()
			$("[data-outcome-show]").hide()
			$clicked = $(e.currentTarget)
			questionId = $clicked.data('question-id')
			$('.question_list').hide()
			$("#answer_#{questionId}").show()

		$('[data-back-to]').on 'click', (e) =>
			e.preventDefault()
			$('.answer').hide()
			$("[data-outcome-show]").hide()
			$('.feedback_question').show()
			$('.feedback_answer').show()
			$clicked = $(e.currentTarget)
			sectionId = $clicked.data('back-to')
			$("#question_list_#{sectionId}").show()

		$('[data-reset]').on 'click', (e) =>
			e.preventDefault()
			$('.answer').hide()
			$("[data-outcome-show]").hide()
			$('.feedback_question').hide()
			$('.feedback_answer').hide()
			$('.question_list').hide()
			$('#section_list').show()
			$('a#show_left_menu_button').show()
			$clicked = $(e.currentTarget)
			sectionId = $clicked.data('back-to')
			$("#question_list_#{sectionId}").show()
			$('#sidebarCollapse').css({opacity: 1})

		$(document).on 'click', '[data-feedback-id]', (e) =>
			e.preventDefault()
			$clicked = $(e.currentTarget)
			questionId = $clicked.data('feedback-id')
			outcome = $clicked.data('feedback-outcome')
			$('.feedback_question').hide()
			$('.feedback_answer').hide()
			$('.feedback_loading').show()
			$.getJSON "/help-feedback/#{questionId}/#{outcome}", (response) =>
				@timeout =>
					$('.feedback_loading').hide()
					$("[data-outcome-show=#{outcome}]").show()
				, 350

		$('[data-toggle=collapser]').on 'click', (e) =>
			e.preventDefault()
			$clicked = $(e.currentTarget)
			$('[data-toggle=collapser]').removeClass('active')
			$clicked.addClass('active')
			target = $clicked.attr('href')
			$('.accordion-body').slideUp().removeClass('active')
			$(target).slideDown().addClass('active')

TheArticle.ControllerModule.controller('HelpCentreController', TheArticle.HelpCentre)