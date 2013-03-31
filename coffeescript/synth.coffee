class Oscillator
    constructor: (context) ->
        @oscillator = context.createOscillator()
        @oscillator.type = @oscillator.SINE
        @master_gain = context.createGainNode()
        @oscillator.connect(@master_gain)
        
        @master_gain.connect(context.destination)
        
        @started = false

    setMasterGain: (value) ->
        @gain = value
        @master_gain.gain.value = @gain if @turned_on

    setAudioWaveform: (value) ->
        switch value
            when "sine" then @oscillator.type = @oscillator.SINE
            when "square" then @oscillator.type = @oscillator.SQUARE
            when "sawtooth" then @oscillator.type = @oscillator.SAWTOOTH
            when "triangle" then @oscillator.type = @oscillator.TRIANGLE

    setFrequency: (value) ->
        # see https://en.wikipedia.org/wiki/Piano_key_frequencies
        v = Math.floor(Math.pow(2,((value-49)/12))*440)
        @oscillator.frequency.value = v

    off: () ->
        @master_gain.gain.value = 0

    on: () ->
        if !@started
            @oscillator.start(0)
            @started = true
        @master_gain.gain.value = 1

class WaveSelector
    constructor: (el, @oscillator) ->
        @states = ["sine", "square", "sawtooth", "triangle"]
        @currentState = 0

        $('#'+el).click =>
            @currentState += 1
            $('#'+el).text(@states[@currentState%4])
            oscillator.setAudioWaveform(@states[@currentState%4])
