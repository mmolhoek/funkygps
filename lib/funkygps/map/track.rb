class FunkyGPS
    class Map
        # A Track is a list of coordinates and has a name
        class Track
            attr_reader :trackpoints, :name
            # @return [Boolean] currentTrack Is this the current track?
            attr_accessor :activeTrack
            # @param [Array<Trackpoint>] trackpoints All trackpoints tha belong to this track

            def initialize(trackpoints:, name:)
                @name = name
                @activeTrack = false
                @trackpoints = trackpoints
            end

            # Calculates the total distance of the track
            # @return [Integer] distance in the current {FunkyGPS::DEFAULTMETRICS}
            def distance
                distance = 0
                @trackpoints.each_cons(2){|tp1, tp2| distance += tp1.distanceTo(other:tp2)}
                distance
            end

            # Replace the trackpoints
            def replaceTrackpoints(trackpoints:)
                @trackpoints = trackpoints
            end

            # @return [Integer] nr of trackpoints in track
            def nrOfTrackpoints
                @trackpoints.length
            end

            # Clears all trackpoints of track
            def clearTrack
                @trackpoints = []
            end

            # Find the trackpoint in the track that lies the nearest to other:
            # @param [Trackpoint] other The trackpoint (the gps) to calculate the distance to
            # @return [Trackpoint] The trackpoint in the track that is the closest to other:
            # @todo keep track direction in mind and passed trackpoints
            def nearestTrackpointTo(other:)
                @trackpoints.min{|tp| tp.distanceTo(other: other)}
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
            #   gps.activeTrack.nrOfTrackpoints #=> 0
            #   gps.activeTrack.addCoordinate(coordinate:FunkyGPS::Map::Coordinate.new(lat:0,lng:0))
            #   gps.activeTrack.nrOfTrackpoints #=> 1
            def addCoordinate(coordinate:, at:nil)
                if at
                    @trackpoints.insert(at, coordinate)
                else
                    @trackpoints << coordinate
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
                trackpoints = @trackpoints.map{|tp| %{#{tp.displayX} #{tp.displayY}}}.join(' ')
                %{<g#{rotate ? %{ transform="translate(#{rotate[:x]}, #{rotate[:y]}) rotate(#{rotate[:degrees]}) translate(-#{rotate[:x]}, -#{rotate[:y]})"}:%{}}><path d="M #{trackpoints}" style="fill:none;stroke:black" #{pathparams||FunkyGPS::ACTIVETRACKLINEPARAMS}/></g>\n}
            end
        end
    end
end
