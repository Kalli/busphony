getUrlParameters = ()->
    querystring = window.location.search.substring(1)
    params = {}
    for param in querystring.split("&")
        params[param.split("=")[0]] = param.split("=")[1]
    return params


$(document).ready ->
    $(".controls").hide()
    params = getUrlParameters()
    if params.v?
        createMap(true)

    if params.x? and params.y? and params.routes?
        $('#loading').html("<h3>Loading...</h3>").css("z-index","0")
        createMap(false)

    $('#useless').click ->
        $('#loading').html("<h3>Loading...</h3>").css("z-index","0")
        createMap(false)


    $('#useful').click ->
        $('#loading').html("<h3>Loading...</h3>").css("z-index","0")
        createMap(true)

    # tooltips for the buttons
    tooltipOptions = 
        placement: "top"
        title: "Press play to make the bussynth buzz!"
    $('#play').tooltip(tooltipOptions)    
        
    tooltipOptions.title = "Change the oscillator waveform"
    $('#wave').tooltip(tooltipOptions)

    tooltipOptions.title = "What is this?"
    $('#info').tooltip(tooltipOptions)

    tooltipOptions.title = "Add or remove individual bus routes" 
    $('#busroutes').tooltip(tooltipOptions)

    tooltipOptions.placement = "bottom" 
    tooltipOptions.title = "They run the busses" 
    $('#straeto').tooltip(tooltipOptions)
    
    tooltipOptions.title = "They provide positioning" 
    $('#api').tooltip(tooltipOptions)

    



    


        

