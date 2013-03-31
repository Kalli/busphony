class Bus
    constructor: (@busnumbers, @map, @markers, @pads) ->
        @active = false

    getBusPositions: () ->
        d = new Date()
        $.ajax 
            dataType: "json"
            # url: "http://apis.is/bus/realtime"
            url: if d.getSeconds()%2==0 then "/dummybusdata.json" else "/dummybusdata2.json"
            data: []
            success: (data) =>
                @drawBusses(data)

    stop: ->
        @active = false
        for pad in @pads
            pad.off()

    start: ->
        @active = true
        @getBusses()

    drawBusses: (data, busnumbers, map, markers, pads) ->
        if @busnumbers.length != 0
            for result in data.results     
                if Number(result.busNr) in @busnumbers
                    for bus in result.busses
                        latlng = new google.maps.LatLng(bus.x, bus.y)
                        title = result.busNr + "|" + bus.from + " - " + bus.to
                        markeroptions =
                            position: latlng
                            title: title
                            icon: "/img/busphony/bus.ico"
                            zIndex: 12
                        marker = new google.maps.Marker(markeroptions) 
                        @markers.push(marker)
            timedelta = 15000/@markers.length
            @dropMarkers(timedelta, 0)

    dropMarkers: (timedelta, index) =>
        if @active and @busnumbers.length != 0
            marker = @markers[index]
            if marker?
                marker.setMap(@map)
                number = '<span class="badge badge-warning busroute">'+marker.getTitle().split("|")[0]+'</span> '
                $('#businfo').html(number+'<small>'+marker.getTitle().split("|")[1]+'</small>')
                index = index + 1
                for pad in @pads
                    if pad.contains(marker.getPosition())
                        pad.on()
                    else
                        pad.off()
            if index < @markers.length
                setTimeout ( =>
                    @dropMarkers(timedelta, index)
                ), timedelta
    

    getBusses: () ->
        if @busnumbers isnt []
            @clearBusMarkers()
            @getBusPositions()
            if @active 
                setTimeout ( =>
                    @getBusses()
                ), 15000

    getBusRoutes: () ->
        $.ajax 
            dataType: "json"
            url: "/dummybusdata.json"
            # url: "/dummybusdataempty.json"
            data: []
            success: (data) =>
                busnumbers = []
                if data.results.length == 0
                    busroute = $('<span class="badge badge-warning busroute">').text("Sorry there are no busses running at the moment")
                    $('#busroutes').append(busroute)
                else
                    for result in data.results 
                        busnumbers.push(Number(result.busNr))
                if @busnumbers.length == 0
                    @busnumbers = busnumbers
                allToggle =$('<a id="bustoggle" class="btn btn-inverse">').text("Remove All")
                buslist = $('<ul class="buslist">')
                                
                for busnumber in busnumbers
                    busroute = $('<li>').text(busnumber)
                    if busnumber in @busnumbers
                        $(busroute).attr("class", "badge badge-warning busroute")
                    else
                        $(busroute).attr("class", "badge badge-important busroute")
                    buslist.append(busroute)
                $('#busroutes').html("")
                buslabel = $('<p>').text("Busses running now:")
                $('#busroutes').append(buslabel)
                $('#busroutes').append(buslist)
                $('#busroutes').append(allToggle)
                
                # Add handlers to every route button
                $('.busroute').bind 'click', (ev) =>
                    busnumber = Number($(ev.currentTarget).text())
                    if busnumber in @busnumbers
                        $(ev.currentTarget).attr("class","badge badge-important busroute")
                        @busnumbers = (number for number in @busnumbers when number != busnumber)
                    else
                        $(ev.currentTarget).attr("class","badge badge-warning busroute")
                        @busnumbers.push(busnumber)  

                # add toggle to select/deselect all
                $('#bustoggle').bind 'click', (ev) =>
                    if @busnumbers.length == 0
                        $(ev.currentTarget).attr("class","btn btn-inverse").text("Remove all")
                        $('.busroute').attr("class","badge badge-warning busroute")
                        for button in $('.busroute')
                            @busnumbers.push(Number($(button).text()))
                    else
                        $(ev.currentTarget).attr("class","btn").text("Select All")
                        $('.busroute').attr("class","badge badge-important busroute")
                        @busnumbers = []

    clearBusMarkers: () ->
        for marker in @markers
            marker.setMap(null)
        @markers = []

    activatePadsWithMarkers = () ->
        activepads = []
        deactivedpads = []
        for marker in @markers
            for pad in @pads
                if pad.contains(marker.getPosition())
                    activepads.push(pad)
                else
                    deactivedpads.push(pad)
        for pad in activatedpads
            pad.on()
        for pad in deactivedpads
            pad.off()


