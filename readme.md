## Busphony

A synthesizer powered by the busses of Reykjavik.

Busphony is a bus powered syntheziser with a map interface, 81 pads are overlaid on a map of the city of Reykjavik. Each pad triggers a synthesizer note (you can try it out by hovering above the pads). 

Every 15 seconds Busphony fetches the current position of the buses in busroutes selected by the user, the location of each bus is then shown on the map and the corresponding synth pad/note is triggered.

## How does it work

The synthesizer uses the [web audio api](http://www.w3.org/TR/webaudio/) the map is powered by the [Google Maps api](https://developers.google.com/maps/), bus positioning is fetched from [Apis.is](http://docs.apis.is/). 

## How to use

Compile the coffeescript into a javascript file: 

    coffee -cj busphony.js synth.coffee map.coffee bus.coffee main.coffee

Stick the html and javascript on a webserver and open in a browser.

## Demo

*Due to changes in the terms and conditions for bus.is api access Busphony no longer has access to position data for the busses, leaving the demo defunct*

Demo at http://www.karltryggvason.com/busphony
