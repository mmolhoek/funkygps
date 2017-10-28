module FunkyGPS
    class Map
        # A Track is a list of coordinates and has a name
        class Track
            attr_reader :trackpoints, :name
            def initialize(trackpoints:, name:)
                @name = name
                @trackpoints = trackpoints
            end
            # returns the distance of the track
            def distance
                distance = 0
                @trackpoints.each_cons(2){|tp1, tp2| distance += tp1.distanceTo(other:tp2)}
                distance
            end
            # returns the distance of the track in meters
            def distanceInMeters
                distance.round

            end
            # returns the distance of the track in kilometers with 2 digit percision
            def distanceInKilometers
                (distance/10.0).round/100.0
            end
            # returns the track as svg (path) to place on the svg canvas
            def to_svg(rotate:nil)
                trackpoints = @trackpoints.map{|tp| %{#{tp.displayX} #{tp.displayY}}}.join(' ')
                %{<g#{rotate ? %{ transform="translate(#{rotate[:x]}, #{rotate[:y]}) rotate(#{rotate[:degrees]}) translate(-#{rotate[:x]}, -#{rotate[:y]})"}:%{}}><path d="M #{trackpoints}" style="fill:none;stroke:black"/></g>\n}
            end
        end
    end
end
