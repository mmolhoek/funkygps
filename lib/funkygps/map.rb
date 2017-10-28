require_relative 'loaders'
require_relative 'loaders/gpx'
require_relative 'map/track'
require_relative 'map/coordinate'

class FunkyGPS
    class Map
        attr_reader :funkygps, :gps, :tracks, :waypoints, :x, :y, :viewbox
        def initialize(funkygps:)
            @funkygps = funkygps
            clearTracks
            @viewbox = ViewBox.new(map: self, funkygps: funkygps)
        end
        # Will search for all gps files and try to load them if supported
        # @example Load all tracks from test tracks folder
        #   gps.map.loadGPSFilesFrom(folder:'./tracks/')
        #   gps.map.tracks.length #=> 2
        # @example Will skip unknown files
        #   gps.map.loadGPSFilesFrom(folder:'.')
        #   gps.map.tracks.length #=> 0
        def loadGPSFilesFrom(folder:)
            Dir["#{folder}/*"].each do |file|
                begin
                    loadGPSFile(file: file)
                rescue FunkyGPS::ExtentionNotSupported
                    STDERR.puts "skipping #{file}, format not yet supported" if FunkyGPS::VERBOSE
                    next
                end
            end
        end
        # Will load any gps file type that is supported
        # if your gps filetype is not supported, it's very easy
        # to add support for it :). just clone this repo
        # have a look at {FunkyGPS::Map::GPSFormats::GPX} for an example
        # create your own, make a PR and submit it.
        # @example Load gps file from test tracks folder
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.tracks.length #=> 1
        def loadGPSFile(file:)
            begin
                type = File.extname(file)
                raise NameError unless type
                loader = GPSFormats.const_get("#{type[1..-1].upcase}").new(file:file)
            rescue NameError
                raise ExtentionNotSupported, "The GPS::GPSFormats::#{type} if file #{file} does not seem to be supported yet. See documentation on how to add it yourself :)"
            end
            loader.waypoints.each do |waypoint|
                if at = waypoint.name[/^me(\d*)/]
                    # testing purpose: wp with name 'me' is treated as gps signal
                    addSignal(trackpoint: waypoint, at: at.to_i - 1)
                else
                    addWaypoint(waypoint: waypoint)
                end
            end
            loader.tracks.each {|track| addTrack(track: track)}
        end

        # Clear all tracks
        # @example Load gps file from test tracks folder
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.tracks.length #=> 1
        #   gps.map.clearTracks
        #   gps.map.tracks.length #=> 0
        def clearTracks
            @tracks = []
            @waypoints = []
        end

        # Simulate a track by moving from start to end trackpoints
        # on the PaPiRus display, as fast as possible
        # @example simulate to fake display
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.simulate(track:'track 1')
        def simulate(track:)
            if track = @tracks.find{|t| t.name === track}
                oldTrack = @funkygps.signal.clearSignal
                addSignal(trackpoint:track.trackpoints.shift)
                addSignal(trackpoint:track.trackpoints.shift)
                funkygps.screen.update
                track.trackpoints.each do |trackpoint|
                    addSignal(trackpoint:trackpoint)
                    funkygps.screen.update
                end
                @funkygps.signal.restoreTrack(track: oldTrack)
            else
                raise NoTrackFound, "track @{track} not found"
            end
        end

        # Simulate a track by moving from start to end trackpoints
        # at a x second interval, creating an animated gif of the result
        def simulateToGif(track:, name: 'track.gif', delay: 100)
            if track = @tracks.find{|t| t.name === track}
                STDERR.puts "creating gif animation of track '#{track.name}' to #{name} with #{delay} delay"
                list = Magick::ImageList.new
                oldTrack = @funkygps.signal.clearSignal
                addSignal(trackpoint:track.trackpoints.shift)
                addSignal(trackpoint:track.trackpoints.shift)
                list.read funkygps.screen.to_image()
                track.trackpoints.each do |trackpoint|
                    addSignal(trackpoint:trackpoint)
                    list.read funkygps.screen.to_image
                end
                @funkygps.signal.restoreTrack(track: oldTrack)
                list.each {|image| image.delay = delay }
                list.write(name)
            else
                raise NoTrackFound, "track @{track} not found"
            end
        end

        # Simulate a track by moving from start to end trackpoints
        # at a x second interval, updating the screen with an ascii
        # art representation of the screen
        def simulateToAscii(track:)
            if track = @tracks.find{|t| t.name === track}
                oldTrack = @funkygps.signal.clearSignal
                addSignal(trackpoint:track.trackpoints.shift)
                addSignal(trackpoint:track.trackpoints.shift)
                funkygps.screen.to_file(name:'ascii')
                sleep 2
                track.trackpoints.each do |trackpoint|
                    addSignal(trackpoint:trackpoint)
                    funkygps.screen.to_file(name:'ascii')
                    sleep 2
                end
                @funkygps.signal.restoreTrack(track: oldTrack)
            else
                raise NoTrackFound, "track @{track} not found"
            end
        end

        # Adds a GPS signal to the list of signals received by the GPS module
        # @example Add a signal to the list
        #   gps.signal.track.length #=> 4
        #   gps.map.addSignal(trackpoint:FunkyGPS::Map::Coordinate.new(lat:0,lng:0))
        #   gps.signal.track.length #=> 5
        def addSignal(trackpoint:, at:nil)
            trackpoint.map = self
            @funkygps.signal.addTrackpoint(trackpoint: trackpoint, at: at)
        end
        def addWaypoint(waypoint:)
            waypoint.map = self
            @waypoints << waypoint
        end
        def addTrack(track:)
            track.trackpoints.map{|tp|tp.map = self; tp}
            @tracks << track
        end
        # width of map in meters
        def realWidth
            topLeft = Coordinate.new(lat:minLats, lng:minLons)
            topRight = Coordinate.new(lat:maxLats, lng:minLons)
            topLeft.distanceTo(other:topRight)
        end
        # Map height in meters
        def realHeight
            topRight = Coordinate.new(lat:maxLats, lng:minLons)
            bottomRight = Coordinate.new(lat:maxLats, lng:maxLons)
            topRight.distanceTo(other:bottomRight)
        end
        # Create an svg of the map
        def to_svg
            out = %{<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n}
            out << %{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n}
            out << %{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" stroke-width="#{@funkygps.fullscreen ? '2' : '3'}" width="#{@funkygps.screen.width}px" height="#{@funkygps.screen.height}px" viewBox="#{@viewbox.x} #{@viewbox.y} #{@viewbox.width} #{@viewbox.height}">\n}
            out << @funkygps.signal.to_svg
            out << @tracks.map { |track| track.to_svg(rotate:{degrees: -(@funkygps.signal.currenDirection), x: @funkygps.signal.lastPos.displayX, y: @funkygps.signal.lastPos.displayY}) }.join("\n")
            #out << @tracks.map { |track| track.to_svg }.join("\n")
            out << @waypoints.map { |wp| wp.to_svg }.join("\n")
            out << %{</svg>}
            out
        end

        # width in pixels
        def width
            maxX - minX
        end

        # height in pixels
        def height
            maxY - minY
        end

        # max value of all display x
        def maxX
            @maxX ||= x.max
        end
        # min value of all display x
        def minX
            @minX ||= x.min
        end

        # max value of all Latitudes
        def maxLats
            @maxLats ||= lats.max
        end
        # min value of all Latitudes
        def minLats
            @minLats ||= lats.min
        end

        # max value of all display y
        def maxY
            @maxY ||= y.max
        end
        # min value of all display y
        def minY
            @minY ||= y.min
        end

        # max value of all Longitudes
        def maxLons
            @maxLons ||= lons.max
        end
        # min value of all Longitudes
        def minLons
            @minLons ||= lons.min
        end

        # all Latitudes of all tracks
        def x
            @x ||= @tracks.map{|track| track.trackpoints.map{|p| p.x}}.flatten + @waypoints.map{|wp| wp.x} + [@funkygps.signal.lastPos.x]
        end
        def lats
            @lats ||= @tracks.map{|track| track.trackpoints.map{|p| p.latitude}}.flatten + @waypoints.map{|wp| wp.latitude} + (@funkygps.signal.lastPos ? [@funkygps.signal.lastPos.latitude] : [])
        end
        # all Longitudes of all tracks
        def y
            @y ||= @tracks.map{|track| track.trackpoints.map{|p| p.y}}.flatten + @waypoints.map{|wp| wp.y} + [@funkygps.signal.lastPos.y]
        end
        def lons
            @lons ||= @tracks.map{|track| track.trackpoints.map{|p| p.longitude}}.flatten + @waypoints.map{|wp| wp.longitude} + (@funkygps.signal.lastPos ? [@funkygps.signal.lastPos.longitude] : [])
        end
    end
    class ViewBox
        attr_reader :map, :funkygps
        def initialize(map:, funkygps:)
            @map = map
            @funkygps = funkygps
        end
        def width
            @funkygps.screen.width
        end
        def height
            @funkygps.screen.height
        end
        def x
            @funkygps.signal.lastPos.displayX - (width/2)
        end
        def y
            @funkygps.signal.lastPos.displayY - (height/2)
        end
        def realWidth
            @map.realWidth / @map.width * width
        end
        def realHeight
            @map.realHeight / @map.height * height
        end
    end
end

