# 템플릿 Method 시작
Template.test.onCreated ->
  this.loading = new ReactiveVar(false)
  this.percent = new ReactiveVar('0%')

Template.test.onRendered -> {}

Template.test.helpers
  loading : ()-> return Template.instance().loading.get()
  percent : ()-> return Template.instance().percent.get()

Template.test.events
  'click .start': (e, t)->

    t.loading.set(true)
    t.percent.set('0%')
    $('#convert').empty()
    $('#button').empty()
    $('#origin').empty()
    originUrl = URL.createObjectURL($('input[type="file"]')[0].files[0])
    originImg = document.createElement('img')
    originImg.setAttribute('width', '640px')
    originImg.src = originUrl

    xhr = new XMLHttpRequest()
    fd  = new FormData()

    style = $("input[name='style']:checked").val()
    noise = parseInt($("input[name='noise']:checked").val())
    scale = parseInt($("input[name='scale']:checked").val())
    file  = $('input[type="file"]')[0].files[0]

    selectScale = parseInt($("input[name='scale']:checked").val())

    if selectScale > 2
      scale = 2

    fd.append 'style', style
    fd.append 'noise', noise
    fd.append 'scale', scale
    fd.append 'file', file

    xhr.onload = (e)->
      result = new Blob([xhr.response], {type: "image/png"})

      resultProcessing = (result)->
        url = URL.createObjectURL(result);
        img = document.createElement('img')
        img.setAttribute('width', '640px')
        img.src = url
        img2 = document.createElement('a')
        img2.href = url
        img2.setAttribute('download', 'convertImg.png')
        img2.setAttribute('class', 'btn waves-effect waves-light')
        img2.text = 'download'
        $('#convert').append(img)
        $('#button').append(img2)
        $('#origin').append(originImg)
        t.loading.set(false)

      upscale = (file, scale)->
        xhr2 = new XMLHttpRequest()
        fd2  = new FormData()

        fd2.append 'style', style
        fd2.append 'noise', -1
        fd2.append 'scale', scale
        fd2.append 'file', file

        xhr2.onload = (e)->
          result2 = new Blob([xhr2.response], {type: "image/png"})
          resultProcessing(result2)

        xhr2.onprogress = (e)->
          t.percent.set Math.ceil(((e.loaded) / e.total) * 100 + 50)+'%'

        xhr2.responseType = 'arraybuffer'
        xhr2.open('POST', 'http://172.16.0.199:8812/api')
        xhr2.send(fd2)

      if selectScale <= 2
        resultProcessing(result)
      else if selectScale is 3
        upscale(result, 1)
      else if selectScale is 4
        upscale(result, 2)

    xhr.onprogress = (e)->
      if selectScale > 2
        t.percent.set Math.ceil(((e.loaded) / e.total) * 100 / 50)+'%'
      else
        t.percent.set Math.ceil(((e.loaded) / e.total) * 100)+'%'


    xhr.responseType = 'arraybuffer'
    xhr.open('POST', 'http://172.16.0.199:8812/api')
    xhr.send(fd)

# 템플릿 Method 종료