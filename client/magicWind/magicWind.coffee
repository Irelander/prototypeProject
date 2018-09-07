import mergeImages from 'merge-images';

CanvasToSvg = (a,b,c,d)->
  e = a.toDataURL()
  g = document.createElementNS('http://www.w3.org/2000/svg', 'image')
  g.setAttribute 'id', 'importedCanvas_' + @idCounter++
  g.setAttributeNS 'http://www.w3.org/1999/xlink', 'xlink:href', e
  g.setAttribute 'x', if c then c else 0
  g.setAttribute 'y', if d then d else 0
  g.setAttribute 'width', a.width
  g.setAttribute 'height', a.height
  g.imageData = a.toDataURL()
  return g.toString()

colorThreshold = 15;
blurRadius = 5;
simplifyTolerant = 0;
simplifyCount = 30;
hatchLength = 4;
hatchOffset = 0;

imageInfo = null;
cacheInd = null;
mask = null;
downPoint = null;
allowDraw = false;
currentThreshold = colorThreshold;
templateInstance = null;

_trace = ->
  `var i`
  `var ps`
  `var j`
  cs = MagicWand.traceContours(mask)
  cs = MagicWand.simplifyContours(cs, simplifyTolerant, simplifyCount)
  mask = null
  # draw contours
  ctx = imageInfo.context
  ctx.clearRect 0, 0, imageInfo.width, imageInfo.height
  #outer
  ctx.clearRect 0, 0, imageInfo.width, imageInfo.height
  ctx.beginPath()
  i = 0
  while i < cs.length
    if cs[i].inner
      i++
      continue
    ps = cs[i].points
    ctx.moveTo ps[0].x, ps[0].y
    j = 1
    while j < ps.length
      ctx.lineTo ps[j].x, ps[j].y
      j++
    i++
#  ctx.strokeStyle = 'blue'
  ctx.stroke()

#  #inner
#  ctx.beginPath()
  i = 0
  while i < cs.length
    if !cs[i].inner
      i++
      continue
    ps = cs[i].points
    ctx.moveTo ps[0].x, ps[0].y
    j = 1
    while j < ps.length
      ctx.lineTo ps[j].x, ps[j].y
      j++
    i++
#  ctx.strokeStyle = 'red'
#  ctx.stroke()
  ctx.closePath()

  pattern = document.createElement("img");
  pattern.onload = ()->
    pat=ctx.createPattern(pattern,"repeat");
    ctx.fillStyle=pat
    ctx.fill("evenodd")

    mergeImages([templateInstance.backgroundFile.src, document.querySelector('canvas').toDataURL()]).then( (b64) ->
      document.querySelector('img').src = b64
    )
  pattern.src = templateInstance.currentPattern.get() || "/images/Asset 1.svg"
  return



_getMousePosition = (e)->
  p = $(e.target).offset()
  x = Math.round((e.clientX || e.pageX) - p.left)
  y = Math.round((e.clientY || e.pageY) - p.top)
  return { x, y }

_drawMask = (x, y)->
  if !imageInfo then return

  image =
    data : imageInfo.data.data
    width : imageInfo.width,
    height : imageInfo.height
    bytes: 4

  mask = MagicWand.floodFill(image, x, y, currentThreshold)
  mask = MagicWand.gaussBlurOnlyBorder(mask, blurRadius)

  _drawBorder()

_drawBorder = (noBorder)->
  if !mask
    return
  x = undefined
  y = undefined
  i = undefined
  j = undefined
  w = imageInfo.width
  h = imageInfo.height
  ctx = imageInfo.context
  imgData = ctx.createImageData(w, h)
  res = imgData.data
  if !noBorder
    cacheInd = MagicWand.getBorderIndices(mask)
  ctx.clearRect 0, 0, w, h
  len = cacheInd.length
  j = 0
  while j < len
    i = cacheInd[j]
    x = i % w
    # calc x by index
    y = (i - x) / w
    # calc y by index
    k = (y * w + x) * 4
    if (x + y + hatchOffset) % hatchLength * 2 < hatchLength
    # detect hatch color
      res[k + 3] = 255
    # black, change only alpha
    else
      res[k] = 255
      # white
      res[k + 1] = 255
      res[k + 2] = 255
      res[k + 3] = 255
    j++
  ctx.putImageData imgData, 0, 0
  return


window.onMouseUp = (event, args)->
  allowDraw = false

window.onMouseDown = (event, args)->

  if event.button == 0
    allowDraw = true
    downPoint = _getMousePosition(event)
    _drawMask downPoint.x, downPoint.y
  else
    allowDraw = false

window.onMouseMove = (event, args)->

  if allowDraw
    p = _getMousePosition(event)
    if p.x != downPoint.x or p.y != downPoint.y
      dx = p.x - (downPoint.x)
      dy = p.y - (downPoint.y)
      len = Math.sqrt(dx * dx + dy * dy)
      adx = Math.abs(dx)
      ady = Math.abs(dy)
      sign = if adx > ady then dx / adx else dy / ady
      sign = if sign < 0 then sign / 5 else sign / 3
      thres = Math.min(Math.max(colorThreshold + Math.floor(sign * len), 1), 255)
      #var thres = Math.min(colorThreshold + Math.floor(len / 3), 255);
      if thres != currentThreshold
        currentThreshold = thres
        _drawMask downPoint.x, downPoint.y

# 템플릿 Method 시작
Template.magicWind.onCreated ->

  templateInstance = this
  this.currentPattern = new ReactiveVar('/images/Asset 1.svg')

Template.magicWind.onRendered ->

Template.magicWind.helpers

  patternList : -> return ['/images/Asset 1.svg', '/images/Asset 2.svg', '/images/Asset 3.svg', '/images/Asset 4.svg', '/images/Asset 5.svg']

  isSelectPattern : -> return if Template.instance().currentPattern.get() is this.normalize() then 'active' else ''

Template.magicWind.events

  'change #colorThreshold': (e, t)->
    colorThreshold = parseInt($(e.currentTarget).val())
  'change #blurRadius': (e, t)->
    blurRadius = parseInt($(e.currentTarget).val())
  'change #simplifyTolerant': (e, t)->
    simplifyTolerant = parseInt($(e.currentTarget).val())
  'change #simplifyCount': (e, t)->
    simplifyCount = parseInt($(e.currentTarget).val())
  'change #hatchLength': (e, t)->
    hatchLength = parseInt($(e.currentTarget).val())
  'change #hatchOffset': (e, t)->
    hatchOffset = parseInt($(e.currentTarget).val())

  'change input[type=file]' : (e, t)->

    imgFile = URL.createObjectURL(e.currentTarget.files[0])
    img = document.querySelector('#backgroundImage')
    t.backgroundFile = img
    img.onload = ()->
      cvs = document.querySelector('canvas')
      cvs.width = img.width;
      cvs.height = img.height;
      imageInfo =
        width: img.width,
        height: img.height,
        context: cvs.getContext("2d")
      mask = null;

      tempCtx = document.createElement("canvas").getContext("2d")
      tempCtx.canvas.width = imageInfo.width
      tempCtx.canvas.height = imageInfo.height
      tempCtx.drawImage(img, 0, 0)
      imageInfo.data = tempCtx.getImageData(0, 0, imageInfo.width, imageInfo.height)
      e.currentTarget.type = ''
      e.currentTarget.type = 'file'
    img.src = imgFile

  'click span.start': (e, t)->

    _trace()

  'click .pattern-images': (e, t)->

    t.currentPattern.set this.normalize()



# 템플릿 Method 종료