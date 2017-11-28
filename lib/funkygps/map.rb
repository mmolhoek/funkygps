require_relative 'loaders'
require_relative 'loaders/gpx'
require_relative 'map/track'
require_relative 'map/coordinate'
require_relative 'viewbox'

class FunkyGPS
    # The Map is the place where all the {Track}s and {Point}s are placed on
    class Map
        # @return [FunkyGPS] funkygps The main contoller instance
        attr_reader :funkygps
        # @return [Array<Track>] tracks All currently available tracks
        attr_reader :tracks
        # @return [Array<Point>] points All currently available points
        attr_reader :points
        # @see http://www.gpsvisualizer.com/draw/ A track and points can be made with this free tool for example
        # @param [FunkyGPS] funkygps The main control center
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
                rescue FunkyGPS::FunkyException::ExtentionNotSupported
                    STDERR.puts "skipping #{file}, format not yet supported" if FunkyGPS::VERBOSE
                    next
                end
            end
        end
        # Will load any gps file type that is supported
        # if your gps filetype is not supported, it's very easy
        # to add support for it :). just clone this repo
        # have a look at {FunkyGPS::GPSFormats::GPX} for an example
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
                raise FunkyException::ExtentionNotSupported, "The GPS::GPSFormats::#{type} if file #{file} does not seem to be supported yet. See documentation on how to add it yourself :)"
            end
            loader.load(map:self)
        end

        # @return [Track] The track that matches the name or FunkyGPS::FunkyException::NoTrackFound
        # # @param [String] name The track to find
        def getTrack(name:)
            track = @tracks.find { |tr| tr.name == name }
            raise FunkyGPS::FunkyException::NoTrackFound unless track
            track
        end

        # Clear all tracks and all value caches
        # @example Load gps file from test tracks folder
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.tracks.length #=> 1
        #   gps.map.clearTracks
        #   gps.map.tracks.length #=> 0
        def clearTracks
            @x = nil
            @y = nil
            @lats = nil
            @lons = nil
            @maxLons = nil
            @minLons = nil
            @maxLats = nil
            @minLats = nil
            @minX = nil
            @minY = nil
            @tracks = []
            @points = []
        end

        # Set the current active Track
        # @param [String] name The name of the track to set as current active track
        # @example Set a track active
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.activeTrack.name #=> raise FunkyGPS::FunkyException::NoActiveTrackFound, "No track is active or found"
        #   gps.map.setActiveTrack(name: 'track 1')
        #   gps.map.activeTrack.name #=> 'track 1'
        def setActiveTrack(name:)
            @tracks.each do |track|
                track.activeTrack = track.name == name
            end
            raise FunkyGPS::FunkyException::NoActiveTrackFound unless activeTrack
            STDERR.puts "active strack selected. track has #{activeTrack.points.length} points" if FunkyGPS::VERBOSE
        end

        # Get the current Track
        # @return [Track] The current active track
        # @see #setActiveTrack
        def activeTrack
            track = @tracks.find { |tr| tr.activeTrack }
            raise FunkyException::NoActiveTrackFound, "No track is active or found" unless track
            return track
        end

        # Adds a point to the pointslist
        def addPoint(point:)
            @points << point
        end

        # Adds a track to the tracklist
        def addTrack(track:)
            @tracks << track
        end

        # Will return the width of the loaded map in meters
        # @return [Integer] The real width in meters of the map
        # @example Getting the realwidth of a little reactangle
        def realWidth
            topLeft = Coordinate.new(lat:minLats, lng:minLons)
            topRight = Coordinate.new(lat:maxLats, lng:minLons)
            topLeft.distanceTo(point:topRight)
        end

        # Will return the height of the loaded map in meters
        # @return [Integer] The real height in meters of the map
        def realHeight
            topRight = Coordinate.new(lat:maxLats, lng:minLons)
            bottomRight = Coordinate.new(lat:maxLats, lng:maxLons)
            topRight.distanceTo(point:bottomRight)
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
            @x ||= activeTrack.points.map(&:x) + @points.map(&:x) + [@funkygps.signal.lastPos.x]
        end

        # This
        # @return [Float] All latitudes
        def lats
            @lats ||= activeTrack.points.map(&:latitude) + @points.map(&:latitude) + (@funkygps.signal.lastPos ? [@funkygps.signal.lastPos.latitude] : [])
        end

        # @return [Float] All y positions
        def y
            @y ||= activeTrack.points.map(&:y) + @points.map(&:y) + [@funkygps.signal.lastPos.y]
        end

        # @return [Float] All longitudes
        def lons
            @lons ||= activeTrack.points.map(&:longitude) + @points.map(&:longitude) + (@funkygps.signal.lastPos ? [@funkygps.signal.lastPos.longitude] : [])
        end

        # Should we use a short directions arrow or a long one? depends on the ACTIVETRACKDIRECTIONDEGREEOFFSET (ACTO)
        #     ACTO - 365/0  + ACTO
        #   -----------------------
        #   |       \******/      |
        #   |        \****/       |
        #   |        /****\       |
        #   |       /******\      |
        #   -----------------------
        #     ACTO -  180  + ACTO
        # @return [Boolean] Should we use short arrow?
        # @param [Integer] heading The current heading
        def shortarrow(heading:)
            heading.between?(0,FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET) ||
            heading.between?(180-FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET, 180+FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET) ||
            heading.between?(365-FunkyGPS::ACTIVETRACKDIRECTIONDEGREEOFFSET, 365)
        end

        # Creates a arrow pointing to the track and the distance to it
        # @param  [Coordinate] coordinate The Coordinate that is the points on the track closest to us
        # @param  [Integer] distance The distance from or current location to Coordinate in meters
        # @return [String] The svg representing the arrow with distance
        def distanceToTrackIndicator(coordinate:, distance:)
            signal = @funkygps.signal.lastPos
            heading = signal.bearingTo(point:coordinate) - @funkygps.signal.currenDirection
            #space =  (shortarrow(heading: heading) ? @viewbox.height : @viewbox.width) / 8 # / 2 to get half the screen, / 4 to get 4 equal parts = / 8
            space = @viewbox.height / 8
            startpoint = signal.endpoint(heading:heading, distance:space)
            finishpoint = startpoint.endpoint(heading:heading, distance:space)
            middle = startpoint.midpointTo(point:finishpoint)
            arrowarm1 = finishpoint.endpoint(heading:heading+135, distance:8)
            arrowarm2 = finishpoint.endpoint(heading:heading+225, distance:8)
            #%{<path d="M #{startpoint.displayX} #{startpoint.displayY} L #{finishpoint.displayX} #{finishpoint.displayY}" style="fill:none;stroke:black" #{FunkyGPS::ACTIVETRACKDIRECTIONLINE} />} +
            %{<path d="M #{finishpoint.displayX} #{finishpoint.displayY} L #{arrowarm1.displayX} #{arrowarm1.displayY}" style="fill:none;stroke:black" #{FunkyGPS::ACTIVETRACKDIRECTIONLINE} />} +
            %{<path d="M #{finishpoint.displayX} #{finishpoint.displayY} L #{arrowarm2.displayX} #{arrowarm2.displayY}" style="fill:none;stroke:black" #{FunkyGPS::ACTIVETRACKDIRECTIONLINE} />} +
            %{<text x="#{middle.displayX-20}" y="#{middle.displayY-20}" fill="black">#{distance.round}#{FunkyGPS::DEFAULTMETRICSLABEL}</text>}
        end

        # Create an SVG of the map. This includes the Signal, the Signals track history, the active track if visible and otherwise an indicator where the track is (direction and distance).
        # @return [String] The svg containing the whole track, but with a view on the last gps location
        def to_svg
            out = %{<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n}
            out << %{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n}
            out << %{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" stroke-width="#{@funkygps.menu.fullscreen ? '2' : '3'}" width="#{@funkygps.screen.width}px" height="#{@funkygps.screen.height}px" viewBox="#{@viewbox.viewboxSettings}">\n}
            out << @funkygps.signal.to_svg
            out << @funkygps.signal.trackhistory_to_svg
            out << activeTrack.to_svg(rotate: @funkygps.signal.rotateSettings)
            #closest= activeTrack.nearest_point_to(point:@funkygps.signal.lastPos)
            distance = activeTrack.distance_to_next_point(point: @funkygps.signal.lastPos)
            # are we not seeing the current track?
            if distance > (@viewbox.realWidth / 2)
                STDERR.puts "track off screen, add pointer" if FunkyGPS::VERBOSE
                out << distanceToTrackIndicator(coordinate:activeTrack.nextPoint, distance: distance)
            end
            out << @points.map { |points| points.to_svg(rotate: @funkygps.signal.rotateSettings) }.join("\n")
            out << activeTrack.nextPoint.to_svg(rotate: @funkygps.signal.rotateSettings, description: 'next')
            out << %{</svg>}
            out
        end
    end
end
