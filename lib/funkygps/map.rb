require_relative 'loaders'
require_relative 'loaders/gpx'
require_relative 'map/track'
require_relative 'map/coordinate'
require_relative 'map/signal'

module FunkyGPS
    module Map
        def self.new(*args)
            System.new(*args)
        end
        class System
            attr_reader :controlcenter, :gps, :width, :height, :tracks, :waypoints, :x, :y, :signal, :viewbox
            def initialize(controlcenter:)
                @controlcenter = controlcenter
                @width = controlcenter.screen.width
                @height = controlcenter.screen.height
                @tracks = []
                @waypoints = []
                @signal = Signal.new(map:self)
                @viewbox = ViewBox.new(map: self)
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
            def loadTrack(file:)
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
            # at a x second interval, updating the screen
            def simulate(track:, name:'ascii')
                if track = @tracks.find{|t| t.name === track}
                    oldTrack = @signal.clearSignal
                    addSignal(trackpoint:track.trackpoints.shift)
                    addSignal(trackpoint:track.trackpoints.shift)
                    controlcenter.screen.to_file(name:name)
                    sleep 2
                    track.trackpoints.each do |trackpoint|
                        addSignal(trackpoint:trackpoint)
                        controlcenter.screen.to_file(name:name)
                        sleep 2
                    end
                    @signal.restoreTrack(track: oldTrack)
                else
                    raise "track @{track} not found"
                end
            end

            def addSignal(trackpoint:, at:nil)
                trackpoint.map = self
                @signal.addTrackpoint(trackpoint: trackpoint, at: at)
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
                out << %{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" stroke-width="#{@controlcenter.fullscreen ? '2' : '3'}" width="#{@width}px" height="#{@height}px" viewBox="#{@viewbox.x} #{@viewbox.y} #{@viewbox.width} #{@viewbox.height}">\n}
                out << @signal.to_svg
                out << @tracks.map { |track| track.to_svg }.join("\n")
                out << @waypoints.map { |wp| wp.to_svg }.join("\n")
                out << %{</svg>}
                out
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
                @x ||= @tracks.map{|track| track.trackpoints.map{|p| p.x}}.flatten + @waypoints.map{|wp| wp.x} + [@signal.lastPos.x]
            end
            def lats
                @lats ||= @tracks.map{|track| track.trackpoints.map{|p| p.latitude}}.flatten + @waypoints.map{|wp| wp.latitude} + (@signal.lastPos ? [@signal.lastPos.latitude] : [])
            end
            # all Longitudes of all tracks
            def y
                @y ||= @tracks.map{|track| track.trackpoints.map{|p| p.y}}.flatten + @waypoints.map{|wp| wp.y} + [@signal.lastPos.y]
            end
            def lons
                @lons ||= @tracks.map{|track| track.trackpoints.map{|p| p.longitude}}.flatten + @waypoints.map{|wp| wp.longitude} + (@signal.lastPos ? [@signal.lastPos.longitude] : [])
            end
        end
    end
    class ViewBox
        attr_reader :width, :height, :map
        def initialize(map:)
            @map = map
        end
        def width
            @map.width
        end
        def height
            @map.height
        end
        def x
            @map.signal.lastPos.displayX - (@map.width/2)
        end
        def y
            @map.signal.lastPos.displayY - (@map.height/2)
        end
        def realWidth
            @map.realWidth / @map.width * width
        end
        def realHeight
            @map.realHeight / @map.height * height
        end
    end
end
