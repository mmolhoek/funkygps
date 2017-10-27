# All FunkyGPS defaults are stored here
module FunkyGPS
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

require_relative 'funkygps/screen'
require_relative 'funkygps/map'
#require_relative 'funkygps/menu'


module FunkyGPS
    # Start FunkyGPS with all defaults
    def self.load
        self.loadWith
    end

    # loadWith can be used to start FunkyGPS with  is used to return the control center instance, which is the central
    # point where all actions can be performed
    # @param [Boolean] fullscreen Should we start fullscreen or show menu/info as well
    # @param [Boolean] landscape Should screen be setup as landscape or portrait
    # @param [String] track The trackfile that should be loaded
    # @param [String] trackfolder Search all gps files here and load them (defaults to {{FunkyGPS::DEFAULTTRACKFOLDER}})
    # @param epd_path[string] can be used write to fake display file (debugging, see papirus gem)
    # returns a controlcenter instance
    def self.loadWith(fullscreen: false, landscape: true, track: nil, trackfolder: DEFAULTTRACKFOLDER, epd_path: '/dev/epd')
        ControlCenter.new(
            fullscreen: fullscreen,
            landscape: landscape,
            track: track,
            trackfolder: trackfolder,
            epd_path: epd_path
        )
    end

    # FunkyGPS ControlCenter consists of the following parts
    # The Map: holds all map info, including tracksetc
    # The Info panel: showing information about speed, direction, etc
    # The Menu panel: shows a menu that gives access to all settings
    class ControlCenter
        attr_reader :screen, :map, :menu, :trackfolder
        def initialize(fullscreen:, landscape:, track:, trackfolder:, epd_path:)
            #folder where all tracks are stored/loaded
            @screen = FunkyGPS::Screen.new(controlcenter: self, fullscreen: fullscreen, landscape: landscape, epd_path: epd_path)
            @map = FunkyGPS::Map.new(controlcenter:self)
            @menu = nil #FunkyGPS::Menu::Screen.new(controlcenter: self)
            if track
                @map.loadTrack(track: track)
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
end
