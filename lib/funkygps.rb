# All FunkyGPS defaults are stored here
class FunkyGPS
    # Sets the default metrics unit to meters
    DEFAULTMETRICS = :meters

    # Sets the default folder, where FunkyGPS will look for tracks
    # which will be loaded when calling {FunkyGPS.load}
    DEFAULTTRACKFOLDER = './tracks/'

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
    # initWith can be used to start FunkyGPS with  is used to return the control center instance, which is the central
    # point where all actions can be performed
    # @param [Boolean] fullscreen Should we start fullscreen or show menu/info as well
    # @param [Boolean] landscape Should screen be setup as landscape or portrait
    # @param [String] file The track(s)file that should be loaded
    # @param [String] trackfolder Search all gps files here and load them (defaults to {{FunkyGPS::DEFAULTTRACKFOLDER}})
    # @param testdisplay[Hash] can be used write to fake the display
    #
    # The Map: holds all map info, including tracksetc
    # The Info panel: showing information about speed, direction, etc
    # The Menu panel: shows a menu that gives access to all settings
    attr_reader :screen, :map, :signal, :menu, :trackfolder
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
            @map.loadTracks(folder: trackfolder||DEFAULTTRACKFOLDER)
        end
    end
    # Are we fullscreen?
    def fullscreen
        @screen.fullscreen
    end
    # Will load all tracks found in this folder
    # @param folder[string] where to search for track files, defaults to {{FunkyGPS::DEFAULTTRACKFOLDER}}
    # if multiple track files are found with same name, the order of preference is alphabetic
    def loadTracks(folder: DEFAULTTRACKFOLDER)
        @map.loadTracks(folder: folder)
    end
end
