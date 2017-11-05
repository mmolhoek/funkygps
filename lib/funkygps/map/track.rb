class FunkyGPS
    class Map
        # A Track is a list of coordinates and has a name. The {Map} can have multiple Tracks and one is set as the activeTrack.
        class Track
            # @return [Array<Point>] points All the points in this Track in order from start to finish
            attr_reader :points
            # @return [String] name The name of the track
            attr_reader :name
            # @return [Boolean] activeTrack Is this the current track we are using on the map?
            attr_accessor :activeTrack

            # @param [String] name The name of the track
            # @param [Array<Point>] points All points that belong to this track
            def initialize(points:, name:)
                @name = name
                @activeTrack = false
                @points = points
            end

            # Calculates the total distance of the track
            # @return [Integer] distance in the current {FunkyGPS::DEFAULTMETRICS}
            def distance
                distance = 0
                @points.each_cons(2){|tp1, tp2| distance += tp1.distanceTo(point:tp2)}
                distance
            end

            # Replace the points
            # @param [Array<Point>] points The list of points to use to replace the points
            def setPoints(points:)
                @points = points
            end

            # @return [Integer] nr of points in track
            def nr_of_points
                @points.length
            end

            # Clears all points of track
            def clearTrack
                @points = []
            end

            # Find the point in the track that lies the nearest to point:
            # @param [Point] point The {Point} to calculate the distance to
            # @return [Point] The {Point} in the track that is the closest to point:
            # @todo keep track direction in mind and passed points
            def nearest_point_to(point:)
                @points.min{|tp| tp.distanceTo(point: point)}
            end

            # @return [Integer] The total distance of the track in meters
            def distanceInMeters
                distance.round
            end

            # @return [Float, 2] The total distance of the track in kilometers with 2 digit percision
            def distanceInKilometers
                (distance/10.0).round/100.0
            end

            # Adds a GPS coordinate to the track list
            # @example Add a signal to the list
            #   gps.activeTrack.clearSignal
            #   gps.activeTrack.nr_of_points #=> 0
            #   gps.activeTrack.addCoordinate(coordinate:FunkyGPS::Map::Coordinate.new(lat:0,lng:0))
            #   gps.activeTrack.nr_of_points #=> 1
            def addCoordinate(coordinate:, at:nil)
                if at
                    @points.insert(at, coordinate)
                else
                    @points << coordinate
                end
            end

            # Clones the track
            # @return [Track] The cloned track
            def clone
                Marshal.load(Marshal.dump(self))
            end

            # @param [Integer{0,365}] rotate The rotation the track should be printed. Used to put the map face forward to your direction
            # @param [String] pathparams The extra attributes to add to the path
            # @return the track as svg (path) to place on the svg canvas
            def to_svg(rotate:nil, pathparams:nil)
                pointlist = @points.map{|tp| %{#{tp.displayX} #{tp.displayY}}}.join(' ')
                %{<g#{rotate ? %{ transform="translate(#{rotate[:x]}, #{rotate[:y]}) rotate(#{rotate[:degrees]}) translate(-#{rotate[:x]}, -#{rotate[:y]})"}:%{}}><path d="M #{pointlist}" style="fill:none;stroke:black" #{pathparams||FunkyGPS::ACTIVETRACKLINEPARAMS}/></g>\n}
            end
        end
    end
end
