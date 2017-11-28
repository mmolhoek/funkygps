require_relative 'funkygps/defaults'
require_relative 'funkygps/signal'
require_relative 'funkygps/screen'
require_relative 'funkygps/menu'
require_relative 'funkygps/map'
require_relative 'funkygps/deepclone'

# FunkyGPS, the svg gps application for RaspBerry Pi with PaPiRus display
# @author Mischa Molhoek
# @see https://github.com/mmolhoek/funkygps GPS too be used on a RaspBerry PI with an PaPiRus display attached
class FunkyGPS
    # @todo Create the info panel showing the speed, direction, distance traveled, distance to go etc.
    # @return [Screen] screen The screen calculates screen layout and the position and dimensions of all items on the screen like the Map and the Menu and InfoPanel
    attr_reader :screen
    # @return [Map] map The map manages the drawing of the track(s) and your location, distance to track if off screen etc
    attr_reader :map
    # @return [Signal] signal The signal manages all things related to the GPS hw signal and your current location.
    attr_reader :signal
    # @return [Menu] menu The menu deals with external input like buttons and powerlevel and selecting settings and options
    attr_reader :menu
    # @param [Boolean] fullscreen Should we start fullscreen or show menu/info as well
    # @example Basic usage: Load a track and start tracking
    #   gps = FunkyGPS.new
    #   gps.map.loadGPSFile(file:'./tracks/track_direction_test.gpx')
    #   gps.map.setActiveTrack(name: 'track')
    #   gps.signal.start_tracking
    # @example Basic usage: simulate on PaPiRus display
    #   gps = FunkyGPS.new
    #   gps.map.loadGPSFile(file:'./tracks/track_direction_test.gpx')
    #   # Track_direction_test is made with http://www.gpsvisualizer.com/draw/. It contains two tracks.
    #   # The first is called 'track', which is the planned trip.
    #   # The second is called 'gps', FunkyGPS will use this one for the fake signal
    #   gps.map.setActiveTrack(name: 'track')
    #   # Set the track to be followed
    #   gps.signal.simulateToGif
    #   # Will create a track.gif, containing the trip
    # @param [Boolean] landscape Should screen be setup as landscape or portrait
    # @param [String] file The track(s)file that should be loaded
    # @param testdisplay[Hash] can be used write to fake the display
    def initialize(fullscreen:true, landscape: true, file:nil, testdisplay:nil)
        @menu = Menu.new
        @screen = Screen.new(funkygps: self, fullscreen: fullscreen, landscape: landscape, testdisplay: testdisplay)
        @signal = Signal.new(funkygps:self)
        @map = Map.new(funkygps:self)
        @map.loadGPSFile(file: file) if file
    end
end
