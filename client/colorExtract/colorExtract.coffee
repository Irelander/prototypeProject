import Vibrant from 'node-vibrant'

# 템플릿 Method 시작
Template.colorExtract.onCreated ->

  this.currentFile = new ReactiveVar('')
  this.colorList = new ReactiveVar([])

Template.colorExtract.onRendered ->

Template.colorExtract.helpers

  currentFile : ()-> Template.instance().currentFile.get()

  colorList : ()-> Template.instance().colorList.get()

Template.colorExtract.events
  'change input[type=file]': (e, t)->

    file = e.currentTarget.files[0]
    fileUrl = URL.createObjectURL(file)

    t.currentFile.set fileUrl

  'click .extract-btn': (e, t)->
    Vibrant.from(t.find('img')).getPalette (err, palette)->
      console.log(palette)
      list = Object.keys(palette).map (pal) ->
        return {
          label : pal
          value : palette[pal]
        }

      console.log(list)
      t.colorList.set list

# 템플릿 Method 종료