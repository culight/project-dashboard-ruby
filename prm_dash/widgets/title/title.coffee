class Dashing.Title extends Dashing.Widget
  @accessor 'project', Dashing.AnimatedValue
  @accessor 'description', Dashing.AnimatedValue
  @accessor 'creation', Dashing.AnimatedValue

  onData: (data) ->
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"
