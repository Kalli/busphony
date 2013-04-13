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


        

createMap = (useful) ->
    params = getUrlParameters()

    # create the oscillator
    try
        context = new webkitAudioContext
        oscillator = new Oscillator(context)
        waveselector = new WaveSelector("wave", oscillator)
    
    catch error
        warningtext = '<button type="button" class="close" data-dismiss="alert">&times;</button>Busphony only works with browsers that support the Web Audio Api 
        (like Chrome and recent versions of Safari). You probably will not hear any sound!'
        warning = $('<div class="alert alert-error"></div>').html(warningtext)
        $('#loading').html(warning).css("z-index","10")
        oscillator = ""

    # upper right boundary
    northeast = new google.maps.LatLng("64.18242164","-21.64787292")

    # lower left boundary
    southwest = new google.maps.LatLng("64.03302989","-22.05436707")
    center = new google.maps.LatLng("64.107087","-21.961670")

    bounds = new google.maps.LatLngBounds(southwest, northeast)
    
    mapOptions = 
        zoom: 11
        mapTypeId: google.maps.MapTypeId.HYBRID
        center: center
        draggable: true
        zoomControl: useful
        mapTypeControl: false
        rotateControl: useful
        scaleControl: useful
        streetViewControl: false
        panControl: false
        disableDoubleClickZoom: !useful
        scrollwheel: useful

    if useful
        mapOptions.zoomControlOptions = 
            position: google.maps.ControlPosition.RIGHT_CENTER


    map = new google.maps.Map(document.getElementById('map'), mapOptions)

    if not useful
        pads = createPads(map, southwest, northeast, params, oscillator)
        createOffBounds(map, pads)
        padMouseOver = (rect) ->
            for pad in pads
                if pad.contains(rect.latLng)
                    pad.on()
                else
                    pad.off()        
        for pad in pads
            google.maps.event.addListener(pad.rectangle, 'mouseover', padMouseOver)
    else 
        pads = createEditableBounds(map, bounds, oscillator, params)  
        

    markers = []
    busnumbers = []
    if params.routes
        for route in params.routes.split(",")
            busnumbers.push(Number(route))
    bus = new Bus(busnumbers, map, markers, pads, useful)
    busplaybutton = new BusPlayButton("play", bus)
    bus.getBusRoutes()
    $(".controls").show()
    if useful
        addSaveButton(pads[0], bus)
        $('#directionsoverlay').modal()




createEditableBounds = (map, bounds, oscillator, params) ->
    pads = []
    if params.ne? and params.sw?
        bounds = new google.maps.LatLngBounds(new google.maps.LatLng(params.sw.split(",")[0],params.sw.split(",")[1]), new google.maps.LatLng(params.ne.split(",")[0],params.ne.split(",")[1]))
    rectangleoptions = 
        bounds: bounds
        map: map
        zindex: 10
        strokeColor: "#ffffff"
        strokeOpacity: 0.1
        strokeWeight: 1
        fillColor: "#ffffff"
        fillOpacity: 0.1
        editable: true
        draggable: true
    rectangle = new google.maps.Rectangle(rectangleoptions)
    pad = new Pad(oscillator, rectangle, 49, true, map) #A440!  

    pads.push(pad)
    padMouseOver = (rect) ->
        pad.on()
    padMouseOut = (rect) ->
        pad.off()
        pad.oscillator.off()

    google.maps.event.addListener(pad.rectangle, 'mouseover', padMouseOver)
    google.maps.event.addListener(pad.rectangle, 'mouseout', padMouseOut)

    return pads


addSaveButton = (pad,bus) ->
    savebutton = $('<a id="save" class="btn txt-center">')
    savebutton.append($('<i class="icon-hdd">&nbsp;</i>'))
    $('#info').after(savebutton)
    tooltipOptions = 
        placement: "top"
        title: "Save this busphony"
    $('#save').tooltip(tooltipOptions)

    $('#save').click ->
        ne = pad.rectangle.getBounds().getNorthEast().toString().replace("(","").replace(")","").replace(" ","")
        sw = pad.rectangle.getBounds().getSouthWest().toString().replace("(","").replace(")","").replace(" ","")
        routes = bus.busnumbers.toString()
        longurl = "http://www.karltryggvason.com/busphony?v=true&ne="+ne+"&sw="+sw+"&routes="+routes
        shortenUrl(longurl)


shortenUrl = (longurl) ->
    data = 
        apiKey:"R_a4ee6edc274e6025761d2e6dea5461c7"
        login: "busphony"
        longurl: longurl
    $.ajax
        dataType: "jsonp"
        data: data
        url: "http://api.bit.ly/v3/shorten"
        success: (response) ->
            overlay = $('<div class="alert alert-success" />')
            overlayhtml = '<button type="button" class="close" data-dismiss="alert">&times;</button>The link for this busphony is:<br>'
            overlayhtml += '<a href="'+response.data.url+'">'+response.data.url+"</a>"
            overlay.html(overlayhtml)
            $('#loading').html(overlay).css("z-index","11")

# A big rectangle with the whole world as its bounds
# Used for turning of pads when mousing outside the pad overlay
createOffBounds = (map, pads) ->
    # Mousing over anything outside the rect will turn off all oscillators:
    worldbounds = new google.maps.LatLngBounds(new google.maps.LatLng(-89.999999,-179.999999), new google.maps.LatLng(89.999999,179.999999))
    bigrectangleOptions = 
        bounds: worldbounds
        map: map
        fillOpacity: 0
        zindex:1
    bigrect = new google.maps.Rectangle(bigrectangleOptions)

    allOff = () ->
        for pad in pads
            pad.off()
            pad.oscillator.off()
    google.maps.event.addListener(bigrect, 'mouseover', allOff)
    bigrect

createPads = (map, southwest, northeast, params, oscillator) ->
    xaxis = 9
    yaxis = xaxis
    latdelta = Math.abs((northeast.lat() - southwest.lat())/xaxis)
    lngdelta = Math.abs((northeast.lng() - southwest.lng())/xaxis)
    rectOptions = 
        strokeColor: "#ffffff"
        strokeOpacity: 0.1
        strokeWeight: 1
        fillColor: "#ffffff"
        fillOpacity: 0.1
        map: map
        bounds: bounds
        zindex:10
    pads = []
    for x in [1..xaxis]
        for y in [1..yaxis]
                sw = new google.maps.LatLng(southwest.lat() + (x-1)*latdelta, southwest.lng() + (y-1)*lngdelta)
                ne = new google.maps.LatLng(southwest.lat() + (x)*latdelta, southwest.lng() + (y)*lngdelta)
                bounds = new google.maps.LatLngBounds(sw,ne)
                rectOptions.fillOpacity = if (x+y)%2==0 then 0.1 else 0.3
                rectOptions.bounds = bounds
                rectangle = new google.maps.Rectangle(rectOptions)
                pad = new Pad(oscillator, rectangle, (x-1)*xaxis+y, true, map)
                pads.push(pad)

    if params.x
        activex = []
        for x in params.x.split(",")
            activex.push(Number(x))
    else
        activex = [1..xaxis]
    if params.y
        activey = []
        for y in params.y.split(",")
            activey.push(Number(y))
    else
        activey = [1..yaxis]

    for y in [1..yaxis]
        sw = new google.maps.LatLng(southwest.lat()+((y-1)*latdelta), southwest.lng() - lngdelta)
        ne = new google.maps.LatLng(southwest.lat()+((y)*latdelta), southwest.lng())
        active = if y in activey then true else false
        overlay = new CheckboxOverlay(map, "y", y.toString(), sw, ne, pads[(9*(y-1))..(9*y-1)], active)                

    for x in [1..xaxis]
        sw = new google.maps.LatLng(southwest.lat()-latdelta, southwest.lng() + (x-1)*lngdelta)
        ne = new google.maps.LatLng(southwest.lat(), southwest.lng() + (x)*lngdelta)
        xpads = []
        for pad in pads
            if pad.number%xaxis==x
                xpads.push(pad)
        active = if x in activex then true else false
        overlay = new CheckboxOverlay(map, "x", x.toString(), sw, ne, xpads, active)

    return pads



    