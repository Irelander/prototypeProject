FlowRouter.route '/',
    name : 'index'
    action : ->
        BlazeLayout.render 'test'

FlowRouter.route '/colorExtract',
    name : 'colorExtract'
    action : ->
        BlazeLayout.render 'colorExtract'

FlowRouter.route '/magicWind',
    name : 'magicWind'
    action : ->
        BlazeLayout.render 'magicWind'