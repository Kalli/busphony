class Pad
    constructor: (@oscillator, @rectangle, @number, @active, @map) ->

    contains: (latLng)->
        @rectangle.getBounds().contains(latLng)

    setFrequency: ->
        @oscillator.setFrequency(@number)

    on:->
        if @active
            @setFrequency()
            @oscillator.on()
            @drawRect(true)

    off:->
        @drawRect(false)    

    activate: ->
        @active = true
        @drawRect(false)    

    deactivate: ->
        @active = false
        @drawRect(false)    

    drawRect:(turned_on)->
        if !@active
            opacity = 0
        else if turned_on
            opacity = 0.6
            fill = "#ffc20e"
        else if @number%2==0
            opacity = 0.3
            fill = "#ffffff"
        else 
            opacity = 0.1
            fill = "#ffffff"
        rectOptions = 
            strokeColor: "#ffffff",
            strokeOpacity: 0.2,
            strokeWeight: 1,
            fillColor: fill,
            fillOpacity: opacity,
            map: @map,
            bounds: @rectangle.getBounds()
            zindex:10
        @rectangle.setOptions(rectOptions)



class CheckboxOverlay extends google.maps.OverlayView
    constructor: (@map, @axis, @number, @sw, @ne, @pads, @active) ->
        @setMap(map)
        @div = document.createElement('div')
        checkbox = document.createElement('input')
        checkbox.value = @axis+@number.toString()
        checkbox.type = "checkbox"
        if @active
            checkbox.checked = "checked"
        else 
            for pad in @pads
                pad.deactivate()
        checkbox.className = "cb"
        @div.appendChild(checkbox)
        n = document.createElement('div')
        n.textContent = @number.toString()
        @div.appendChild(n)

    CheckboxOverlay.prototype.draw = ->
        overlayProjection = @getProjection()
        sw = overlayProjection.fromLatLngToDivPixel(@sw)
        ne = overlayProjection.fromLatLngToDivPixel(@ne)
        @div.style.position = 'absolute'
        @div.style.left = sw.x+'px'
        @div.style.top = ne.y+'px'
        @div.style.width = (ne.x - sw.x - 8) + 'px'
        @div.style.height = (sw.y - ne.y - 20) + 'px'
        @div.className = "panel label"


    CheckboxOverlay.prototype.onAdd = ->
        panes = @getPanes()
        panes.overlayImage.appendChild(@div)
        google.maps.event.addDomListener @div, 'click', (ev) =>
            if !ev.currentTarget.children[0].checked
                for pad in @pads
                    pad.deactivate()
                ev.currentTarget.children[0].checked = false                    
            else
                for pad in @pads
                    pad.activate()
                ev.currentTarget.children[0].checked = true


        