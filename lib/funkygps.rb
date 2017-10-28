# All FunkyGPS defaults are stored here
class FunkyGPS
    DEFAULTMETRICS = :meters # Sets the default metrics unit to meters

    # Sets the default folder, where FunkyGPS will look for tracks
    # which will be loaded when calling {FunkyGPS.load}
    DEFAULTTRACKFOLDER = './tracks/'

    # Show some extra STDERR.puts info when debugging
    VERBOSE = false

    # FunkyGPS base error
    class Exception < ::StandardError; end
    # FunkyGPS error that is raised when the gps file type is not supported
    class ExtentionNotSupported < FunkyGPS::Exception; end
    # FunkyGPS error when the is no map available
    class NoMapFound < FunkyGPS::Exception; end
    # FunkyGPS error when the is no track available
    class NoTrackFound < FunkyGPS::Exception; end
end

require_relative 'funkygps/signal'
require_relative 'funkygps/screen'
require_relative 'funkygps/map'


class FunkyGPS
    attr_reader :screen, :map, :signal, :menu, :trackfolder
    # @example Basic usage: simulate on PaPiRus display
    #   gps = FunkyGPS.new
    #   gps.map.loadGPSFilesFrom(folder:'./tracks/')
    #   gps.map.simulate
    # @param [Boolean] fullscreen Should we start fullscreen or show menu/info as well
    # @param [Boolean] landscape Should screen be setup as landscape or portrait
    # @param [String] file The track(s)file that should be loaded
    # @param [String] trackfolder Search all gps files here and load them (defaults to {{DEFAULTTRACKFOLDER}})
    # @param testdisplay[Hash] can be used write to fake the display
    def initialize(fullscreen:false, landscape: true, file:nil, trackfolder:DEFAULTTRACKFOLDER, testdisplay:nil)
        #folder where all tracks are stored/loaded
        @screen = Screen.new(funkygps: self, fullscreen: fullscreen, landscape: landscape, testdisplay: testdisplay)
        #Initialize the GPS signal input
        @signal = Signal.new(funkygps:self)
        #Initialize the map
        @map = Map.new(funkygps:self)
        #Initialize the menu (todo)
        @menu = nil #FunkyGPS::Menu::Screen.new(funkygps: self)
        if file
            @map.loadGPSFile(file: file)
        else
            @map.loadGPSFilesFrom(folder: trackfolder||DEFAULTTRACKFOLDER)
        end
    end
    # Are we fullscreen?
    def fullscreen
        @screen.fullscreen
    end
end
