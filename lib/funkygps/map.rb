require_relative 'loaders'
require_relative 'loaders/gpx'
require_relative 'map/track'
require_relative 'map/coordinate'

class FunkyGPS
    class Map
        # @return [FunkyGPS] The main contoller instance
        attr_reader :funkygps, :gps, :tracks, :waypoints, :x, :y, :viewbox
        def initialize(funkygps:)
            @funkygps = funkygps
            clearTracks
            @viewbox = ViewBox.new(map: self, funkygps: funkygps)
        end
        # Will search for all gps files and try to load them if supported
        # @example Load all tracks from test tracks folder
        #   gps.map.loadGPSFilesFrom(folder:'./tracks/')
        #   gps.map.tracks.length #=> 3
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
                loader = GPSFormats.const_get("#{type[1..-1].upcase}").new(map: self, file:file)
            rescue NameError
                raise ExtentionNotSupported, "The GPS::GPSFormats::#{type} if file #{file} does not seem to be supported yet. See documentation on how to add it yourself :)"
            end
            loader.load(map:self)
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

        # Set the current active Track
        # @param [String] name The name of the track to set as current active track
        # @example Set a track active
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.activeTrack.name #=> raise FunkyGPS::NoActiveTrackFound, "No track is active or found"
        #   gps.map.setActiveTrack(name: 'track 1')
        #   gps.map.activeTrack.name #=> 'track 1'
        def setActiveTrack(name:)
            @tracks.each do |track|
                track.activeTrack = track.name == name
            end
        end

        # Get the current Track
        # @return [Track] The current active track
        # @see #setActiveTrack
        def activeTrack
            track = @tracks.find { |tr| tr.activeTrack }
            raise NoActiveTrackFound, "No track is active or found" unless track
            return track
        end

        # Adds a waypoint to the waypointlist
        def addWaypoint(waypoint:)
            @waypoints << waypoint
        end

        # Adds a track to the tracklist
        def addTrack(track:)
            @tracks << track
        end

        # Will return the width of the loaded map in meters
        # @return [Integer] The real width in meters of the map
        def realWidth
            topLeft = Coordinate.new(lat:minLats, lng:minLons)
            topRight = Coordinate.new(lat:maxLats, lng:minLons)
            topLeft.distanceTo(other:topRight)
        end
        # Will return the height of the loaded map in meters
        # @return [Integer] The real height in meters of the map
        def realHeight
            topRight = Coordinate.new(lat:maxLats, lng:minLons)
            bottomRight = Coordinate.new(lat:maxLats, lng:maxLons)
            topRight.distanceTo(other:bottomRight)
        end

        # @return [Float] The width of the active map in pixels
        def width
            maxX - minX
        end

        # @return [Float] The height of the active map in pixels
        def height
            maxY - minY
        end

        # @return [Float] The max width of the active map in pixels
        def maxX
            @maxX ||= x.max
        end
        # @return [Float] The min width of the active map in pixels
        def minX
            @minX ||= x.min
        end

        # @return [Float] The maximum latitude of the active map
        def maxLats
            @maxLats ||= lats.max
        end

        # @return [Float] The minimum latitude of the active map
        def minLats
            @minLats ||= lats.min
        end

        # @return [Float] The max y of the active map in pixels
        def maxY
            @maxY ||= y.max
        end

        # @return [Float] The min y of the active map in pixels
        def minY
            @minY ||= y.min
        end

        # @return [Float] The maximum longitude of the active map
        def maxLons
            @maxLons ||= lons.max
        end

        # @return [Float] The minimum longitude of the active map
        def minLons
            @minLons ||= lons.min
        end

        # @return [Float] All x positions
        def x
            @x ||= @tracks.map{|track| track.trackpoints.map{|p| p.x}}.flatten + @waypoints.map{|wp| wp.x} + [@funkygps.signal.lastPos.x]
        end

        # This
        # @return [Float] All latitudes
        def lats
            @lats ||= activeTrack.trackpoints.map{|p| p.latitude} + @waypoints.map{|wp| wp.latitude} + (@funkygps.signal.lastPos ? [@funkygps.signal.lastPos.latitude] : [])
        end

        # @return [Float] All y positions
        def y
            @y ||= activeTrack.trackpoints.map{|p| p.y} + @waypoints.map{|wp| wp.y} + [@funkygps.signal.lastPos.y]
        end

        # @return [Float] All longitudes
        def lons
            @lons ||= @tracks.map{|track| track.trackpoints.map{|p| p.longitude}}.flatten + @waypoints.map{|wp| wp.longitude} + (@funkygps.signal.lastPos ? [@funkygps.signal.lastPos.longitude] : [])
        end

        # Create an SVG of the map. This includes the Signal, the Signals track history, the active track if visible and otherwise an indicator where the track is (direction and distance).
        # @return [String] The svg containing the whole track, but with a view on the last gps location
        def to_svg
            out = %{<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n}
            out << %{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n}
            out << %{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" stroke-width="#{@funkygps.fullscreen ? '2' : '3'}" width="#{@funkygps.screen.width}px" height="#{@funkygps.screen.height}px" viewBox="#{@viewbox.x} #{@viewbox.y} #{@viewbox.width} #{@viewbox.height}">\n}
            out << @funkygps.signal.to_svg
            out << @funkygps.signal.trackhistory_to_svg
            out << activeTrack.to_svg(rotate:{degrees: -(@funkygps.signal.currenDirection), x: @funkygps.signal.lastPos.displayX, y: @funkygps.signal.lastPos.displayY})
            closestTrackPoint = activeTrack.nearestTrackpointTo(other:@funkygps.signal.lastPos)
            distance = closestTrackPoint.distanceTo(other: @funkygps.signal.lastPos)
            # are we not seeing the current track?
            if distance > (@viewbox.realWidth / 2)
                STDERR.puts "track off screen, add pointer" if FunkyGPS::VERBOSE
                out << distanceToTrackIndicator(trackpoint:closestTrackPoint, distance: distance)
            end
            out << @waypoints.map { |wp| wp.to_svg }.join("\n")
            out << %{</svg>}
            out
        end

        # Should we use a short directions arrow or a long one? depends on the ACTIVETRACKDIRECTIONDEGREEOFFSET
        # @param [Integer] heading The current heading
        def shortarrow(heading:)
            heading.between?(0,FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET) ||
            heading.between?(180-FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET, 180+FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET) ||
            heading.between?(365-FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET, 365)

        end
        # Creates a arrow pointing to the track and the distance to it
        # @return [String] The svg representing the arrow with distance
        def distanceToTrackIndicator(trackpoint:, distance:)
            signal = @funkygps.signal.lastPos
            heading = signal.bearingTo(other:trackpoint) - @funkygps.signal.currenDirection
            space =  (shortarrow(heading: heading) ? @viewbox.height : @viewbox.width) / 8 # / 2 to get half the screen, / 4 to get 4 equal parts = / 8
            startpoint = signal.endpoint(heading:heading, distance:space)
            finishpoint = startpoint.endpoint(heading:heading, distance:space)
            middle = startpoint.midpointTo(other:finishpoint)
            arrowarm1 = finishpoint.endpoint(heading:heading+135, distance:8)
            arrowarm2 = finishpoint.endpoint(heading:heading+225, distance:8)
            %{<path d="M #{startpoint.displayX} #{startpoint.displayY} L #{finishpoint.displayX} #{finishpoint.displayY}" style="fill:none;stroke:black" #{FunkyGPS::ACTIVETRACKDIRECTIONLINE} />} +
            %{<path d="M #{finishpoint.displayX} #{finishpoint.displayY} L #{arrowarm1.displayX} #{arrowarm1.displayY}" style="fill:none;stroke:black" #{FunkyGPS::ACTIVETRACKDIRECTIONLINE} />} +
            %{<path d="M #{finishpoint.displayX} #{finishpoint.displayY} L #{arrowarm2.displayX} #{arrowarm2.displayY}" style="fill:none;stroke:black" #{FunkyGPS::ACTIVETRACKDIRECTIONLINE} />} +
            %{<text x="#{middle.displayX-20}" y="#{middle.displayY-20}" fill="black">#{distance.round}#{FunkyGPS::DEFAULTMETRICSLABEL} (#{heading})</text>}
            #transform="translate(#{middle.displayX}, #{middle.displayY}) rotate(#{heading+90}) translate(-#{middle.displayX}, -#{middle.displayY})"
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

