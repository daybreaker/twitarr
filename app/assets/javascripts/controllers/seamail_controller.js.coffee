Twitarr.SeamailIndexController = Twitarr.ArrayController.extend
  actions:
    compose_seamail: ->
      @transitionToRoute('seamail.new')

Twitarr.SeamailMetaPartialController = Twitarr.Controller.extend()

Twitarr.SeamailDetailController = Twitarr.Controller.extend
  errors: Ember.A()
  text: null

  actions:
    post: ->
      return if @get('posting')
      @set 'posting', true
      Twitarr.Seamail.new_message(@get('model.id'), @get('model.text')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Message could not be sent! Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        Ember.run =>
          @set 'posting', false
          @set 'model.text', null
          @get('errors').clear()
          @send('reload')
      )

Twitarr.SeamailNewController = Twitarr.Controller.extend
  searchResults: Ember.A()
  toUsers: Ember.A()
  errors: Ember.A()
  toInput: ''

  autoComplete_change: (->
    val = @get('toInput').trim()
    return if @last_search is val
    if !val
      @get('searchResults').clear()
      return
    @last_search = val
    $.getJSON("#{Twitarr.api_path}/user/ac/#{encodeURIComponent val}").then (data) =>
      if @last_search is val
        @get('searchResults').clear()
        existing_usernames = (user.username for user in @get('toUsers'))
        names = (user for user in data.users when user.username not in existing_usernames)
        @get('searchResults').pushObjects names
  ).observes('toInput')

  actions:
    cancel_autocomplete: ->
      @get('searchResults').clear()

    new: ->
      return if @get('posting')
      @set 'posting', true
      users = @get('toUsers').filter((user) -> !!user).map((user) -> user.username)
      Twitarr.Seamail.new_seamail(users, @get('subject'), @get('text')).fail((response) =>
        @set 'posting', false
        if response.responseJSON?.error?
          @set 'errors', [response.responseJSON.error]
        else if response.responseJSON?.errors?
          @set 'errors', response.responseJSON.errors
        else
          alert 'Message could not be sent. Please try again later. Or try again someplace without so many seamonkeys.'
        return
      ).then((response) =>
        Ember.run =>
          @set 'posting', false
          @get('errors').clear()
          @get('toUsers').clear()
          @set 'subject', ''
          @set 'text', ''
          @transitionToRoute('seamail.detail', response.seamail.id)
      )

    remove: (user) ->
      @get('toUsers').removeObject(user)

    select: (name) ->
      @get('toUsers').unshiftObject(name)
      @set 'toInput', ''
      @get('searchResults').clear()
      @last_search = ''
      $('#seamail-user-autocomplete').focus()


