class FunkyGPS
    class Map
        # A Track is a list of coordinates and has a name. The {Map} can have multiple Tracks and one is set as the activeTrack.
        class Track
            # @return [Map] map The map
            attr_reader :map
            # @return [Array<Point>] points All the points in this Track in order from start to finish
            attr_reader :points
            # @return [String] name The name of the track
            attr_reader :name
            # @return [Boolean] activeTrack Is this the current track we are using on the map?
            attr_accessor :activeTrack

            # @param [String] name The name of the track
            # @param [Array<Point>] points All points that belong to this track
            def initialize(map:nil, points:, name:)
                @map = map if map
                @name = name
                @activeTrack = false
                @points = points
            end

            # @return [Point] The first point on the track that is not passed yet
            def nextPoint
                @points.find{|point| not point.passed}
            end

            # @param [Map] map Set the map
            def setMap(map:)
                @map = map
            end

            # Calculates the total distance of the track
            # @return [Integer] distance in the current {FunkyGPS::DEFAULTMETRICS}
            def distance
                distance = 0
                @points.each_cons(2){|tp1, tp2| distance += tp1.distanceTo(point:tp2)}
                distance
            end

            # replace the points
            # @param [array<point>] points the list of points to use to replace the points
            def setpoints(points:)
                @points = points.map{|p| p}
            end

            # @return [array<point>] points the list of points (cloned)
            def getpoints
                @points.map{|p| p}
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
                STDERR.puts @points.map{|tp| tp.distanceTo(point: point).round}.inspect if FunkyGPS::VERBOSE
                @points.min{|tp| tp.distanceTo(point: point)}
            end

            # @param [Point] point The {Point} to calculate the distance to
            # @return [Float] Distance to the next point to pass
            def distance_to_next_point(point:)
                nextPoint.distanceTo(point: point)
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
                if @map
                    if next_active_trackpoint = @map.activeTrack.nextPoint
                        if next_active_trackpoint.distanceTo(point: coordinate) < FunkyGPS::ACTIVETRACKMINIMALDISTANCETOPOINT
                            next_active_trackpoint.passed = true
                        end
                    end
                end
            end

            # Resets all passed flags back to false
            def resetpassedflags
                @points.each{|p| p.passed = false}
            end

            # @return [Array<Point>] all points, but with added points in such a way that no individual distance between two point is larger then distance:
            # @param [Integer] distance (30) If two sequential points have a distance between them larger then this, a Coordinate will be added in the middle of them
            # @param [Array<Point>] points Points to split, if empty the current trackpoints are used
            def splitPoints(points:nil, distance: 30)
                (points || @points).each_slice(2).map { |point1, point2| splitPointsUntilSmallerThen(point1: point1, point2: point2, distance: distance) }.flatten
            end

            #Split two points, adding a point in the middle if distance is longer than distance:
            #@param [Coordinate] point1 The first point
            #@param [Coordinate] point2 The second point
            # @param [Integer] distance If the points have a distance between them larger then this, a Coordinate will be added in the middle of them
            def splitPointsUntilSmallerThen(point1:, point2:, distance:)
                return point1 unless point2 #last point in uneven track is empty
                if point1.distanceTo(point:point2) > distance
                    # return the split set, but split them as well if there are still longer distances
                    return splitPoints(points: [point1, point1.midpointTo(point:point2), point2], distance: distance)
                else
                    return [point1, point2]
                end
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
