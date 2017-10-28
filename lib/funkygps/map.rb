require_relative 'loaders'
require_relative 'loaders/gpx'
require_relative 'map/track'
require_relative 'map/coordinate'

class FunkyGPS
    class Map
        attr_reader :funkygps, :gps, :tracks, :waypoints, :x, :y, :viewbox
        def initialize(funkygps:)
            @funkygps = funkygps
            @tracks = []
            @waypoints = []
            @viewbox = ViewBox.new(map: self, funkygps: funkygps)
        end
        # Will search for all track files and load them
        def loadTracks(folder:)
            Dir["#{folder}/*.gpx"].each{|file| loadTrack(file: file)}
        end
        # Will load any trackfile type that is supported
        # if your gps filetype is not supported, it's very easy
        # to add support for it :). just clone this repo
        # have a look at lib/loaders/gpx.rb for an example
        # create your own, make a PR and submit it.
        def loadGPSFile(file:)
            type = File.extname(file)[1..-1].upcase
            begin
                loader = GPSFormats.const_get("#{type}").new(file:file)
            rescue NameError
                raise ExtentionNotSupported, "The GPS::GPSFormats::#{type} does not seem to be supported yet. See documentation on how to add it yourself :)"
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

        # Simulate a track by moving from start to end trackpoints
        # at a x second interval on the PaPiRus display
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

