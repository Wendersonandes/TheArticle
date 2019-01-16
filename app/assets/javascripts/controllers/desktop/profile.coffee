class TheArticle.Profile extends TheArticle.mixOf TheArticle.DesktopPageController, TheArticle.Feeds

	@register window.App
	@$inject: [
	  '$scope'
	  '$rootScope'
	  '$http'
	  '$rootElement'
	  '$timeout'
	  '$compile'
	  '$sce'
	  'Profile'
	  'MyProfile'
	  'Comment'
	  'Opinion'
	]

	init: ->
		@getVars = @getUrlVars()
		@setDefaultHttpHeaders()
		@rootScope.isSignedIn = false
		@scope.selectedTab = 'all'
		@scope.allExchanges = []
		@scope.replyingToComment =
			comment: {}
			parentComment: {}
			replyingToReply: false
		@scope.commentForSubmission =
			value: ''
		@scope.commentChildLimit = false
		@scope.authActionMessage =
			heading: ''
			msg: ''
		@scope.profile =
			isMe: window.location.pathname is "/my-profile"
			loaded: false
			loadError: false
			digest: []
			follows:
				followings: []
				followers: []
				page: 1
				perPage: 10
				moreToLoad: false
				totalItems: 0
			shares:
				data: []
				page: 1
				perPage: 10
				moreToLoad: false
				totalItems: 0
			ratings:
				data: []
				page: 1
				perPage: 10
				moreToLoad: false
				totalItems: 0
			exchanges:
				data: []
				page: 1
				perPage: 10
				moreToLoad: false
				totalItems: 0
			opinionActions:
				data: []
				page: 1
				perPage: 10
				moreToLoad: false
				totalItems: 0
			commentActions:
				data: []
				page: 1
				perPage: 10
				moreToLoad: false
				totalItems: 0
			data:
				id: null
				displayName: ""
				username: ""
				orginalUsername: ""
				recentFollowingSummary: ""
				recentFollowedSummary: ""
				ratingsSummary: []
				commentActions: []
				joined: ""
				joinedAt: ""
				location: ""
				bio: ""
				isNew: true
				imFollowing: false
				profilePhoto:
					image: ""
					source: ""
				coverPhoto:
					image: ""
					source: ""
			errors:
				main: false
				displayName: false
				username: false
				photo: false
		@bindEvents()
		@detectPanelOpeners() if 'panel' of @getVars
		if @scope.profile.isMe is true
			@rootScope.isSignedIn = true
			@getMyProfile @getProfileCallback
		else
			id = @rootElement.data('id')
			@getProfile id, @getProfileCallback

	getProfileCallback: =>
		@getUserExchanges()
		@getFollows()
		@getShares()
		@getRatings()
		@getCommentActions()
		@getOpinionActions()

	bindEvents: =>
		$(document).on 'click', "#upload_profilePhoto_btn", (e) =>
			$("#profilePhoto_uploader").focus().trigger('click')

		$(document).on 'click', "#upload_coverPhoto_btn", (e) =>
			$("#coverPhoto_uploader").focus().trigger('click')

		@scope.$watch 'profile.data.profilePhoto.source', (newVal, oldVal) =>
			if (oldVal isnt newVal) and newVal.length > 0
				@showProfilePhotoCropper document.getElementById('profilePhoto_holder'), 300, 300, 'circle'

		@scope.$watch 'profile.data.coverPhoto.source', (newVal, oldVal) =>
			if (oldVal isnt newVal) and newVal.length > 0
				@showProfilePhotoCropper document.getElementById('coverPhoto_holder'), 570, 114, 'square'

	actionRequiresSignIn: ($event, action) =>
		$event.preventDefault()
		@requiresSignIn(action)

	selectTab: (tab='all') =>
		@scope.selectedTab = tab
		$('#feed').scrollTop(0)

	detectPanelOpeners: =>
		@timeout =>
			$("#activity-#{@getVars['panel']}-tab").click()
		, 750

	loadMoreRatings: =>
		@scope.profile.ratings.page += 1
		@getRatings()

	getRatings: =>
		url = "/user_ratings/#{@scope.profile.data.id}?page=#{@scope.profile.ratings.page}&per_page=#{@scope.profile.ratings.perPage}"
		@http.get(url).then (response) =>
			angular.forEach response.data.ratings, (item) =>
				@scope.profile.ratings.data.push item
			@scope.profile.ratings.totalItems = response.data.total if @scope.profile.ratings.page is 1
			@scope.profile.ratings.moreToLoad = @scope.profile.ratings.totalItems > (@scope.profile.ratings.page * @scope.profile.ratings.perPage)
			@scope.profile.ratings.loaded = true
		 if @scope.profile.ratings.moreToLoad is true
				@timeout =>
					@loadMoreRatings()
				, 500
			# for the 'All' tab
			angular.forEach response.data.ratings, (item) =>
				item.type = 'rating'
				@scope.profile.digest.push item
			@reorderDigest()

	loadMoreShares: =>
		@scope.profile.shares.page += 1
		@getShares()

	getShares: =>
		url = "/user_shares/#{@scope.profile.data.id}?page=#{@scope.profile.shares.page}&per_page=#{@scope.profile.shares.perPage}"
		@http.get(url).then (response) =>
			angular.forEach response.data.shares, (item) =>
				@scope.profile.shares.data.push item
			@scope.profile.shares.totalItems = response.data.total if @scope.profile.shares.page is 1
			@scope.profile.shares.moreToLoad = @scope.profile.shares.totalItems > (@scope.profile.shares.page * @scope.profile.shares.perPage)
			@scope.profile.shares.loaded = true
		 if @scope.profile.shares.moreToLoad is true
				@timeout =>
					@loadMoreShares()
				, 500
			# for the 'All' tab
			angular.forEach response.data.shares, (item) =>
				item.type = 'share'
				@scope.profile.digest.push item
			@reorderDigest()

	loadMoreCommentActions: =>
		@scope.profile.commentActions.page += 1
		@getCommentActions()

	getCommentActions: =>
		url = "/user_comments/#{@scope.profile.data.id}?page=#{@scope.profile.commentActions.page}&per_page=#{@scope.profile.commentActions.perPage}"
		@http.get(url).then (response) =>
			angular.forEach response.data.comments, (item) =>
				@scope.profile.commentActions.data.push item
			@scope.profile.commentActions.totalItems = response.data.total if @scope.profile.commentActions.page is 1
			@scope.profile.commentActions.moreToLoad = @scope.profile.commentActions.totalItems > (@scope.profile.commentActions.page * @scope.profile.commentActions.perPage)
			@scope.profile.commentActions.loaded = true
		 if @scope.profile.commentActions.moreToLoad is true
				@timeout =>
					@loadMoreCommentActions()
				, 500
			# for the 'All' tab
			angular.forEach response.data.comments, (item) =>
				item.type = 'commentAction'
				@scope.profile.digest.push item
			@reorderDigest()


	loadMoreOpinionActions: =>
		@scope.profile.opinionActions.page += 1
		@getOpinionActions()

	getOpinionActions: =>
		url = "/user_opinions/#{@scope.profile.data.id}?page=#{@scope.profile.opinionActions.page}&per_page=#{@scope.profile.opinionActions.perPage}"
		@http.get(url).then (response) =>
			angular.forEach response.data.opinions, (item) =>
				@scope.profile.opinionActions.data.push item
			@scope.profile.opinionActions.totalItems = response.data.total if @scope.profile.opinionActions.page is 1
			@scope.profile.opinionActions.moreToLoad = @scope.profile.opinionActions.totalItems > (@scope.profile.opinionActions.page * @scope.profile.opinionActions.perPage)
			@scope.profile.opinionActions.loaded = true
		 if @scope.profile.opinionActions.moreToLoad is true
				@timeout =>
					@loadMoreOpinionActions()
				, 500
			# for the 'All' tab
			angular.forEach response.data.opinions, (item) =>
				item.type = 'opinionAction'
				@scope.profile.digest.push item
			@reorderDigest()

	loadMoreFollows: =>
		@scope.profile.follows.page += 1
		@getFollows()

	getFollows: =>
		url = "/user_followings/#{@scope.profile.data.id}?page=#{@scope.profile.follows.page}&per_page=#{@scope.profile.follows.perPage}"
		@http.get(url).then (response) =>
			angular.forEach response.data.list.followings, (item) =>
				@scope.profile.follows.followings.push item
			angular.forEach response.data.list.followers, (item) =>
				@scope.profile.follows.followers.push item
			@scope.profile.follows.totalItems = response.data.total if @scope.profile.follows.page is 1
			@scope.profile.follows.moreToLoad = @scope.profile.follows.totalItems > (@scope.profile.follows.page * @scope.profile.follows.perPage)
			@scope.profile.follows.loaded = true
		 if @scope.profile.follows.moreToLoad is true
				@timeout =>
					@loadMoreFollows()
				, 500

	loadMoreExchanges: =>
		@scope.profile.exchanges.page += 1
		@getUserExchanges()

	getUserExchanges: =>
		url = if @scope.profile.isMe then "/user_exchanges" else "/user_exchanges/#{@scope.profile.data.id}"
		url += "?page=#{@scope.profile.exchanges.page}&per_page=#{@scope.profile.exchanges.perPage}"
		@http.get(url).then (response) =>
			angular.forEach response.data.exchanges, (item) =>
				@scope.profile.exchanges.data.push item
			@scope.profile.exchanges.totalItems = response.data.total if @scope.profile.exchanges.page is 1
			@scope.profile.exchanges.moreToLoad = @scope.profile.exchanges.totalItems > (@scope.profile.exchanges.page * @scope.profile.exchanges.perPage)
			@scope.profile.exchanges.loaded = true
			if @scope.profile.exchanges.moreToLoad is true
				@timeout =>
					@loadMoreExchanges()
				, 500
			# for the 'view all' modal
			@scope.allExchanges = @sortExchangesByName(@scope.profile.exchanges.data)
			# for the 'All' tab
			angular.forEach response.data.exchanges, (item) =>
				item.type = 'exchange'
				@scope.profile.digest.push item
			@reorderDigest()

	sortExchangesByName: (list) =>
		list.sort (a,b) =>
			a[0]-b[0]

	reorderDigest: =>
		@scope.profile.digest.sort (a,b) =>
			new Date(b.stamp*1000) - new Date(a.stamp*1000)

	showProfilePhotoCropper: (element, width, height, shape) =>
		type = $(element).data('type')
		c = new Croppie element,
			viewport:
				width: width
				height: height
				type: shape
			update: =>
				c.result({type: 'canvas', size: {'1140', '228'}}).then (img) =>
					@scope.$apply =>
						@scope.profile.data[type].image = img

	saveCroppedPhoto: ($event, type) =>
		$event.preventDefault()
		profile = new @MyProfile({id: @scope.profile.data.id, photo: @scope.profile.data[type].image, mode: type })
		profile.update().then (response) =>
			if response.status is 'error'
				@savePhotoError response.message
			else
				@timeout =>
					$('button[data-dismiss=modal]', "#edit#{type}Modal").click()
				, 750
		, (error) =>
			@savePhotoError error.statusText

	savePhotoError: (msg) =>
		@scope.profile.errors.photo = "Error uploading new photo: #{msg}"

	getMyProfile: (callback=null) =>
		@MyProfile.get().then (profile) =>
			@timeout =>
				@scope.profile.data = profile
				@scope.profile.loaded = true
				@buildDigestFromProfileData(@scope.profile.data)
				@reorderDigest()
				callback.call(@) if callback?
			, 750
		, (error) =>
			@scope.profile.loaded = true
			@scope.profile.loadError = "Sorry there has been an error loading this profile: #{error.statusText}"

	getProfile: (id, callback=null) =>
		@Profile.get({id: @rootElement.data('user-id')}).then (profile) =>
			@timeout =>
				@rootScope.isSignedIn = profile.isSignedIn
				@scope.profile.data = profile
				@scope.profile.loaded = true
				@buildDigestFromProfileData(@scope.profile.data)
				@reorderDigest()
				callback.call(@) if callback?
			, 750
		, (error) =>
			@scope.profile.loaded = true
			@scope.profile.loadError = "Sorry there has been an error loading this profile: #{error.statusText}"

	buildDigestFromProfileData: (data) =>
		# angular.forEach data.commentActions, (item) =>
		# 	item.type = 'commentAction'
		# 	@scope.profile.digest.push item
		# angular.forEach data.opinionActions, (item) =>
		# 	item.type = 'opinionAction'
		# 	@scope.profile.digest.push item

		item = data.recentFollowingSummary
		item.type = 'recentFollowingSummary'
		@scope.profile.digest.push item unless item.sentence.length == 0

		item = data.recentFollowedSummary
		item.type = 'recentFollowedSummary'
		@scope.profile.digest.push item unless item.sentence.length == 0

	editProfile: (section=null) =>
		return false unless @scope.profile.isMe
		tpl = $("#editProfileForm").html().trim()
		$formContent = @compile(tpl)(@scope)
		$('body').append $formContent
		$("#editProfileFormModal").modal()
		@timeout =>
			$("#user_#{section}", ".form-group").focus()
		, 500

	saveProfile: ($event) =>
		$event.preventDefault()
		@scope.mode = 'view'
		@validateProfile @updateProfile

	validateProfile: (callback=null) =>
		@scope.profile.errors.displayName = @scope.profile.errors.username = @scope.profile.errors.main = false
		if !@scope.profile.data.displayName?
			@scope.profile.errors.displayName = "Please choose a Display Name"
		else if !(/^[a-z][a-z\s]*$/i.test(@scope.profile.data.displayName))
			@scope.profile.errors.displayName = "Your Display Name can only contain letters and a space"
		else if !@scope.profile.data.username?
			@scope.profile.errors.username = "Please enter a username"
		else if @scope.profile.data.username.length < 6
			@scope.profile.errors.username = "Your Username must be at least 6 characters long"
		else if !(/^[0-9a-zA-Z_]+$/i.test(@scope.profile.data.username))
			@scope.profile.errors.username = "Your Username can only contain letters, numbers and an '_'"

		if @scope.profile.errors.displayName or @scope.profile.errors.username
			return false
		else
			if "@#{@scope.profile.data.username}" is @scope.profile.data.originalUsername
				callback.call(@) if callback?
			else
				@http.get("/username-availability?username=@#{@scope.profile.data.username}").then (response) =>
					if response.data is false
						@scope.profile.errors.username = "Username has already been taken"
						return false
					else
						callback.call(@) if callback?

	updateProfile: =>
		@scope.profile.data.originalUsername = "@#{@scope.profile.data.username}"
		profile = new @MyProfile @setProfileData(@scope.profile.data)
		profile.update().then (response) =>
			if response.status is 'error'
				@updateProfileError response.message
			else
				@timeout =>
					$('button[data-dismiss=modal]', '#editProfileFormModal').click()
				, 750
		, (error) =>
			@updateProfileError error.statusText

	updateProfileError: (msg) =>
		@scope.profile.errors.main = "Error updating profile: #{msg}"

	setProfileData: (profile) =>
		{
			id: profile.id
			displayName: profile.displayName
			username: "@#{profile.username}"
			location: profile.location
			bio: profile.bio
		}

	editProfilePhoto: =>
		return false unless @scope.profile.isMe
		tpl = $("#editProfilePhoto").html().trim()
		$content = @compile(tpl)(@scope)
		$('body').append $content
		$("#editprofilePhotoModal").modal()

	editCoverPhoto: =>
		return false unless @scope.profile.isMe
		tpl = $("#editCoverPhoto").html().trim()
		$content = @compile(tpl)(@scope)
		$('body').append $content
		$("#editcoverPhotoModal").modal()

	toggleFollowUser: =>
		if @rootScope.isSignedIn
			userId = @scope.profile.data.id
			if @scope.profile.data.imFollowing
				@unfollowUser userId, =>
					@scope.profile.data.imFollowing = false
			else
				@followUser userId, =>
					@scope.profile.data.imFollowing = true
				, false
		else
			@requiresSignIn("follow #{@scope.profile.data.displayName}")

	toggleFollowUserFromCard: (member) =>
		if @rootScope.isSignedIn
			if member.imFollowing
				@unfollowUser member.id ,=>
					@scope.profile.data.followings = _.filter @scope.profile.data.followings, (item) =>
						item.id isnt member.id
					if followerItem = _.findWhere @scope.profile.data.followers, { id: member.id }
						followerItem.imFollowing = false
					member.imFollowing = false
			else
				@followUser member.id, =>
					member.imFollowing = true
					@scope.profile.data.followings.push member
				, false
		else
			@requiresSignIn("follow #{member.displayName}")

	openExchangesModal: ($event) =>
		$event.preventDefault()
		@timeout =>
			tpl = $("#allUserExchanges").html().trim()
			$content = @compile(tpl)(@scope)
			$('body').append $content
			$("#allUserExchangesModal").modal()
		, 350

TheArticle.ControllerModule.controller('ProfileController', TheArticle.Profile)