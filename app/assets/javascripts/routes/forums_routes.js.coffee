Twitarr.ForumsLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.ForumsIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo('forums.page', 0)

Twitarr.ForumsPageRoute = Ember.Route.extend
  queryParams: {
    participated: {
      refreshModel: true
    }
  }

  model: (params) ->
    Twitarr.ForumMeta.page(params.page, params.participated).fail((response) =>
      @transitionTo('help')
    )

  actions:
    reload: ->
      @refresh()
    mark_all_read: ->
      participated = @get('controller.participated')
      prompt = "Are you sure you want to mark all forums as read?"
      if participated
        prompt = "Are you sure you want to mark all forums you have participated in as read?"
      if(confirm(prompt))
        $.post("#{Twitarr.api_path}/forum/mark_all_read?participated=#{@get('controller.participated')}").fail((response) =>
          if response.responseJSON?.error?
            alert(response.responseJSON.error)
          else
            alert 'Something went wrong. Please try again later. Or try again someplace without so many seamonkeys.'
        ).then((response) =>
          if (response.status isnt 'ok')
            alert response.status
          else
            @refresh()
        )

Twitarr.ForumsDetailRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.Forum.get(params.id, params.page).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('forums')
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    controller.scroll()
    controller.setupUpload()

  actions:
    reload: ->
      @refresh()

Twitarr.ForumsEditRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.ForumPost.get(params.forum_id, params.post_id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('forums')
    )
  
  setupController: (controller, model) ->
    this._super(controller, model)
    if(model.status isnt 'ok')
      alert model.status
      return
    controller.set 'model', model.forum_post
    pics = Ember.A()
    pics.push (photo.id) for photo in model.forum_post.photos
    controller.set('photo_ids', pics)
    controller.setupUpload()

Twitarr.ForumsNewRoute = Ember.Route.extend
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.set('errors', Ember.A())
    controller.setupUpload()
    controller.set('subject', null)
    controller.set('text', null)
    controller.set('photo_ids', Ember.A())
    controller.set('as_mod', false)
    controller.set('as_admin', false)
