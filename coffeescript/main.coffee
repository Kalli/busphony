
getUrlParameters = ()->
    querystring = window.location.search.substring(1)
    params = {}
    for param in querystring.split("&")
        params[param.split("=")[0]] = param.split("=")[1]
    return params



$(document).ready ->
    params = getUrlParameters()

    # create the oscillator
    try
        context = new webkitAudioContext
        oscillator = new Oscillator(context)
    
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

    xaxis = 9
    yaxis = xaxis
    latdelta = Math.abs((northeast.lat() - southwest.lat())/xaxis)
    lngdelta = Math.abs((northeast.lng() - southwest.lng())/xaxis)
    
    mapOptions = 
        zoom: 11
        mapTypeId: google.maps.MapTypeId.HYBRID
        center: center
        draggable: true
        zoomControl: false
        mapTypeControl: false
        rotateControl: false
        scaleControl: false
        streetViewControl: false
        panControl: false
        disableDoubleClickZoom: true
        scrollwheel: false


    map = new google.maps.Map(document.getElementById('map'), mapOptions)

    # Mousing over anything outside the rect will turn off all oscillators:
    wholeworld = new google.maps.LatLngBounds(new google.maps.LatLng(-89.999999,-179.999999), new google.maps.LatLng(89.999999,179.999999))
    rectOptions = 
        bounds: wholeworld
        map: map
        fillOpacity: 0
        zindex:1
    bigrect = new google.maps.Rectangle(rectOptions)

    # Map mouseover handlers 
    padMouseOver = (rect) ->
        for pad in pads
            if pad.contains(rect.latLng)
                pad.on()
            else
                pad.off()

    allOff = () ->
        for pad in pads
            pad.off()
            pad.oscillator.off()

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
                google.maps.event.addListener(rectangle, 'mouseover', padMouseOver)

    
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

    google.maps.event.addListener(bigrect, 'mouseover', allOff)
    markers = []
    busnumbers = []
    if params.routes
        for route in params.routes.split(",")
            busnumbers.push(Number(route))
    bus = new Bus(busnumbers, map, markers, pads)
    bus.getBusRoutes()
    
    srcImage = 'img/raveon.png'

    $('#play').bind 'click', (ev) =>
        if bus.active
            $(ev.currentTarget).find("i").attr("class","icon-play")
            bus.stop()
        else
            $(ev.currentTarget).find("i").attr("class","icon-pause")
            bus.start()

    tooltipOptions = 
        placement: "right"
        title: "Press play to make the bussynth buzz!"
    $('#play').tooltip(tooltipOptions)

    tooltipOptions.title = "Add or remove individual bus routes" 
    tooltipOptions.placement = "top" 
    $('#busroutes').tooltip(tooltipOptions)

    


        

