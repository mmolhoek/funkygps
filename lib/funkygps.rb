# @author Mischa Molhoek
# @see https://github.com/mmolhoek/funkygps GPS too be used on a RaspBerry PI with an PaPiRus display attached
#
# All FunkyGPS defaults are stored here
class FunkyGPS
    # @return [:meters, :kms, :miles, :nms] DEFAULTMETRICS Sets the default metrics unit
    DEFAULTMETRICS = :meters

    # @return [String] DEFAULTMETRICSLABEL Sets the default metrics unit
    DEFAULTMETRICSLABEL = 'm'  # Sets the default metrics label

    # @return [String] DEFAULTTRACKFOLDER Sets the default folder, where FunkyGPS will load and store tracks from and to
    DEFAULTTRACKFOLDER = './tracks/'

    # @return [Boolean] VERBOSE Set to true when you want to see some extra STDERR.puts info when debugging
    VERBOSE = false

    # @return [String] ACTIVETRACKLINEPARAMS Active track line. Empty means black
    # @see FunkyGPS::ACTIVETRACKDIRECTIONLINE for other configuration example
    ACTIVETRACKLINEPARAMS=''

    # @return [String] ACTIVETRACKDIRECTIONLINE Active track direction pointer. the first number represents the dash length, the second the gap length
    ACTIVETRACKDIRECTIONLINE='stroke-dasharray="3, 3"'

    # @return [String] GPS signals track
    # @see FunkyGPS::ACTIVETRACKLINEPARAMS for other configuration example
    GPSSIGNALTRACKLINEPARAMS='stroke-dasharray="2, 6"'

    # @return [Integer] ACTIVETRACKDIRECTIONLINE How many degrees left and right of 0 and 180 off we have to be before short arrow kicks in
    ACTIVETRACKDIRECTIONDEGREEOFFSET=35

    # FunkyGPS base error
    class Exception < ::StandardError; end
    # FunkyGPS error that is raised when the gps file type is not supported
    class ExtentionNotSupported < FunkyGPS::Exception; end
    # FunkyGPS error when the is no map available
    class NoMapFound < FunkyGPS::Exception; end
    # FunkyGPS error when the is no track available
    class NoTrackFound < FunkyGPS::Exception; end
    # FunkyGPS error when the is no active track available
    class NoActiveTrackFound < FunkyGPS::Exception; end
end

require_relative 'funkygps/signal'
require_relative 'funkygps/screen'
require_relative 'funkygps/menu'
require_relative 'funkygps/map'


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
    # @example Basic usage: simulate on PaPiRus display
    #   gps = FunkyGPS.new
    #   gps.map.loadGPSFilesFrom(folder:'./tracks/')
    #   gps.map.simulate
    # @param [Boolean] landscape Should screen be setup as landscape or portrait
    # @param [String] file The track(s)file that should be loaded
    # @param testdisplay[Hash] can be used write to fake the display
    def initialize(fullscreen:true, landscape: true, file:nil, testdisplay:nil)
        @menu = Menu.new
        #folder where all tracks are stored/loaded
        @screen = Screen.new(funkygps: self, fullscreen: fullscreen, landscape: landscape, testdisplay: testdisplay)
        #Initialize the GPS signal input
        @signal = Signal.new(funkygps:self)
        #Initialize the map
        @map = Map.new(funkygps:self)
        #todo: menu not yet implemented
        @map.loadGPSFile(file: file) if file
    end
end
