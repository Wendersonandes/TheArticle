class TheArticle.Profile extends TheArticle.MobilePageController

	@register window.App
	@$inject: [
	  '$scope'
	  '$rootScope'
	  '$http'
	  '$rootElement'
	  '$timeout'
	  '$sce'
	  'Profile'
	  'MyProfile'
	]

	init: ->
		@scope.profilePhotoReadyForCrop = false
		@scope.mode = 'view'
		@scope.profile =
			isMe: window.location.pathname is "/my-profile"
			loaded: false
			loadError: false
			profilePhoto:
				image: ""
				source: ""
			data:
				displayName: ""
				username: ""
				ratings: 0
				followers: 0
				following: 0
				joined: ""
				joinedAt: ""
				location: ""
				bio: ""
				isNew: true
			errors:
				displayName: false
				username: false

		@bindEvents()
		if @scope.profile.isMe is true
			@getMyProfile()
		else
			id = @rootElement.data('id')
			@getProfile(id)

	bindEvents: =>
		super

		@scope.$watch 'profile.profilePhoto.source', (newVal, oldVal) =>
			if (oldVal isnt newVal) and newVal.length > 0
				# console.log newVal
				# @scope.profilePhotoReadyForCrop = true
				@showProfilePhotoCropper document.getElementById('profile_photo_holder')

		# Broadcast from HeaderBarController
		@scope.$on 'edit_profile', =>
			@editProfile()
		@scope.$on 'edit_profile_photo', =>
			@editProfilePhoto()
		@scope.$on 'edit_cover_photo', =>
			@editCoverPhoto()

	trustSrc: (src) =>
		@sce.trustAsResourceUrl(src)

	showProfilePhotoCropper: (element) =>
		c = new Croppie element,
			viewport:
				width: 400
				height: 400
			update: =>
				c.result('canvas').then (img) =>
					@scope.$apply =>
						@scope.profile.profilePhoto.image = img

	getMyProfile: =>
		@MyProfile.get().then (profile) =>
			@timeout =>
				@scope.profile.data = profile
				@scope.profile.loaded = true
			, 750
		, (error) =>
			@scope.profile.loaded = true
			@scope.profile.loadError = "Sorry there has been an error loading this profile: #{error.statusText}"

	getProfile:(id) =>
		@Profile.get({id: @rootElement.data('user-id')}).then (profile) =>
			@timeout =>
				@scope.profile.data = profile
				@scope.profile.loaded = true
			, 750
		, (error) =>
			@scope.profile.loaded = true
			@scope.profile.loadError = "Sorry there has been an error loading this profile: #{error.statusText}"

	editProfile: =>
		@scope.mode = 'edit'

	editProfilePhoto: =>
		@scope.mode = 'edit-profile-photo'
		console.log 'editProfilePhoto'

	editCoverPhoto: =>
		@scope.mode = 'edit-cover-photo'
		console.log 'editCoverPhoto'

	saveProfile: ($event) =>
		$event.preventDefault()
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
				@scope.mode = 'view'
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

	cancelEditProfile: =>
		@scope.mode = 'view'

TheArticle.ControllerModule.controller('ProfileController', TheArticle.Profile)