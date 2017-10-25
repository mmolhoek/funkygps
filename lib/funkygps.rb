=begin
= funkygps

O yes, here we go...

== Contributing to funkygps

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2017 Mischa Molhoek. See LICENSE.txt for further details.
=end

module FunkyGPS
    # Sets the default metrics unit
    DEFAULTMETRICS = :meters
    DEFAULTTRACKFOLDER = './tracks/'
    class Exception < ::StandardError; end
    class ExtentionNotSupported < FunkyGPS::Exception; end
    class NoMapFound < FunkyGPS::Exception; end
end

require_relative 'funkygps/screen'
require_relative 'funkygps/map'
#require_relative 'funkygps/menu'

# extend extends the class
# include extends the instance of the class


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
    def self.loadWith(fullscreen: false, landscape: true, track: nil, trackfolder: DEFAULTTRACKFOLDER, epd_path: nil)
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

gps = FunkyGPS.loadWith(epd_path: '/tmp/epd')
#gps.simulate(track:'track 1')
gps.map.simulate(track:'track 1', name:'display.png')
#gps.toggleFullscreen
gps.screen.update
#gps.screen.to_ascii
#File.open('test.svg', 'w+') {|f| f.write gps.map.to_svg}
STDERR.puts "the track distances in meters:\n#{gps.map.tracks.map{|tr| %{\t#{tr.name}:#{tr.distanceInMeters} meters\n}}.join('')}"
STDERR.puts "the track distances in km:\n#{gps.map.tracks.map{|tr| %{\t#{tr.name}:#{tr.distanceInKilometers} km\n}}.join('')}"
STDERR.puts "the maps square distance is #{gps.map.realWidth.round} meters by #{gps.map.realHeight.round} meters"
STDERR.puts "the maps viewBox square distance is #{gps.map.viewbox.realWidth.round} meters by #{gps.map.viewbox.realHeight.round} meters"
STDERR.puts "the current bearing of the signal is #{gps.map.signal.currenDirection} degrees"
