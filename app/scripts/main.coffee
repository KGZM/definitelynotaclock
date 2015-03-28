

# Setup audio subsystem.
# Create an array for each span of time.
# Player consumes arrays and assigns voices.
# 2D canvas UI.
#
# Analysis node per track or is that crazy sauce?
# Fade entire canvas slightly per frame.
# Draw in one slice for the time period.

# Achievable?
# What are my get out points?
#
# Everything but the visuals is one get out point but not that interesting.
# Single channel, single polar display, is one possible get out point.
#
# So.. make single channel playable synth first.

# Tracks:
window.actx = new window.AudioContext()

window.trackSetup = ->
  filter = actx.createBiquadFilter()
  osc = actx.createOscillator()
  osc2 = actx.createOscillator()
  gain = actx.createGain()
  delay = actx.createDelay()

  filter.connect gain
  filter.frequency.value = 200
  filter.Q.value = 1
  filter.type = "lowpass"
  gain.connect delay

  delay.delayTime.value = 0.5

  delay.connect actx.destination
  gain.connect actx.destination
  osc.type = "sawtooth"
  osc2.type = "sawtooth"
  osc.connect filter
  osc2.connect filter
  


  gain.gain.value = 0
  osc.start()
  osc2.start()

  noteOn = (noteNumber, decay) ->
    freq = noteToFreq(noteNumber)
    now = actx.currentTime
    @gain.gain.cancelScheduledValues(now)
    @gain.gain.setValueAtTime @gain.gain.value, now
    @osc.frequency.setValueAtTime(freq, now)
    @osc2.frequency.setValueAtTime(freq  * 2 + 2, now)
    @filter.frequency.setValueAtTime(@filter.frequency.value, now)
    @filter.frequency.linearRampToValueAtTime(
      200 + Math.random() * 200,
      now + 0.1
    )

    @gain.gain.exponentialRampToValueAtTime 0.2, now + 0.01
    @gain.gain.exponentialRampToValueAtTime 0.01, now + decay


  return {
    osc,
    osc2,
    gain,
    filter,
    noteOn
  }


freqs = [16.35,17.32,18.35,19.45,20.6,21.83,23.12,24.5,25.96,27.5,29.14,30.87,32.7,34.65,36.71,38.89,41.2,43.65,46.25,49,51.91,55,58.27,61.74,65.41,69.3,73.42,77.78,82.41,87.31,92.5,98,103.83,110,116.54,123.47,130.81,138.59,146.83,155.56,164.81,174.61,185,196,207.65,220,233.08,246.94,261.63,277.18,293.66,311.13,329.63,349.23,369.99,392,415.3,440,466.16,493.88,523.25,554.37,587.33,622.25,659.25,698.46,739.99,783.99,830.61,880,932.33,987.77,1046.5,1108.73,1174.66,1244.51,1318.51,1396.91,1479.98,1567.98,1661.22,1760,1864.66,1975.53,2093,2217.46,2349.32,2489.02,2637.02,2793.83,2959.96,3135.96,3322.44,3520,3729.31,3951.07,4186.01,4434.92,4698.63,4978.03,5274.04,5587.65,5919.91,6271.93,6644.88,7040,7458.62,7902.13]

noteToFreq = (note) -> freqs[note]


track = undefined
window.createScheduler = ->
  track = trackSetup()
  noteSequence = [0,0,0,0,0,0]
  bpm = 90

  $(document).keydown (e) ->
    key = String.fromCharCode(e.keyCode)
    console.log key
    scheduler.writingnote = switch key
      when 'A' then 0
      when 'W' then 1
      when 'S' then 2
      when 'E' then 3
      when 'D' then 4
      when 'F' then 5
      when 'T' then 6
      when 'G' then 7
      when 'Y' then 8
      when 'H' then 9
      when 'U' then 10
      when 'J' then 11
      when 'K' then 12
      else 0

    if not scheduler.writing
      scheduler.track.noteOn(36 + scheduler.writingnote, 1)
    scheduler.writing = true
    scheduler.writingkey = key
  $(document).keyup (e) ->
    key = String.fromCharCode(e.keyCode)
    if key is scheduler.writingkey
      scheduler.writing = false
  tick = ->
    return if not @running
    if @writing
      @noteSequence[@index] = @writingnote
    if actx.currentTime > @nextEvent
      @lastEvent = actx.currentTime
      @index = (@index + 1) % @noteSequence.length
      if not @writing
        track.noteOn(36 + @noteSequence[@index], 1)
      @nextEvent = actx.currentTime + (60 / bpm)
    setTimeout (=> @tick()) , 16

  scheduler = {
    lastEvent: actx.currentTime,
    nextEvent: actx.currentTime,
    index: 0,
    track,
    bpm,
    noteSequence,
    tick,
    run: ->
      @running = true
      @tick()
    stop: ->
      @running = false
    running: true
  }
  

  return scheduler



window.setupVisual = ->
  canvas = $('<canvas>')[0]
  $('body').append(canvas)

  ctx = canvas.getContext('2d', {
    antialias: false,
    depth: false
  })
  canvas.height = canvas.width = 200
  canvas.style.imageRendering = "pixelated"
  $(canvas).css {
    width: "500px"
    height: "500px"
  }
  $('html, body').css {
    backgroundColor: "black"
    padding: 0
    margin: 0
  }
  deg2rad = (degrees) -> (degrees % 360) * Math.PI / 180
  render = ->
    t = performance.now()
    ctx.fillStyle = "rgba(0,0,0,0.005)"
    ctx.fillRect(0,0,canvas.width, canvas.height)
    requestAnimationFrame(render)
    cx = canvas.width / 2
    cy = canvas.height / 2
    level = scheduler.track.gain.gain.value
    dt = (actx.currentTime - scheduler.lastEvent) / (scheduler.nextEvent - scheduler.lastEvent)
    ctx.beginPath()
    ctx.arc(cx, cy, 20 * Math.abs(1.0 - dt), 0, Math.PI*2, true)
    ctx.closePath()
    ctx.fillStyle = "black"
    ctx.fill()
    ctx.fillStyle = "red"
    ctx.fill()
    degreesPerSlice = 360 / scheduler.noteSequence.length
    slice = degreesPerSlice * scheduler.index


    theta = deg2rad(-90 + slice + (degreesPerSlice * dt))
    ctx.beginPath()
    note = scheduler.noteSequence[scheduler.index] / 12
    ri = 25 + 40 * note
    rf = ri + (50 * level)
    ctx.moveTo(cx + ri * Math.cos(theta), cy + ri * Math.sin(theta))
    ctx.lineTo(cx + rf * Math.cos(theta), cy + rf * Math.sin(theta))
    ctx.lineWidth = 5
    ctx.strokeStyle = """
      rgb(
        #{Math.floor(actx.currentTime * 100) % 255},
        #{Math.floor(actx.currentTime * 127) % 255},
        #{Math.floor(actx.currentTime * 203) % 255}
      )
      
    """
    ctx.stroke()


    # nextEvent 

    #So, for each lane theta is going to equal..
    # ((360 / sequence length * currentIndex) - (currentTime - nextEvent)) % 360
    




window.scheduler = createScheduler()
scheduler.run()
setupVisual()()

