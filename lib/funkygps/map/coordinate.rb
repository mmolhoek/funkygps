require 'geokit'
# all gps file loaders (only support for gpx at the moment)

# default metrics

class FunkyGPS
    # Set the Geokit metrics to what we are using
    Geokit::default_units = DEFAULTMETRICS
    class Map
        # A Coordinate is a point on the map({Map}). It is the base for calculations with other coordinates. It has functions for getting the distance({distanceTo}) or bearing({bearingTo}) to another coordinate.
        class Coordinate
            # @return [Float] x The x-coordinate on the map
            attr_reader :x
            # @return [Float] y The y-coordinate on the map
            attr_reader :y
            # @return [Boolean] passed Is true when you have already passed this point with your GPS
            attr_accessor :passed

            # @param [Float] lat The latitude of the coordinate
            # @param [Float] lng The longitude of the coordinate
            # @param [Map] map optional map parameter
            def initialize(lat:, lng:, time: nil, speed: nil, altitude: nil, map:nil)
                @passed = false
                @map = map if map
                @loc = Geokit::LatLng.new(lat, lng)
                geo2mapCoordinates(loc: @loc)
            end

            # @return [Geokit::LatLng] The Geokit::LatLng location
            def location
                @loc
            end

            # @return [Float] The latitude
            def latitude
                @loc.lat
            end

            # @return [Float] The longitude
            def longitude
                @loc.lng
            end

            # @param [Map] map The map the coordinate is to be located on.
            def setMap(map:)
                @map = map
            end

            # Helper to translate the Geokit location into x and y coordinates on the map
            def geo2mapCoordinates(loc:)
                radius = 6378137.0 #earths radius
                @x = radius * loc.lng * Math::PI / 180.0
                @y = radius * Math.log(Math.tan((Math::PI / 4.0) + ((loc.lat * Math::PI / 180.0) / 2.0)))
            end

            # @param [Point] point The point to calculate the distance to
            # @param [Hash] options The options to pass to distance_to
            # @option options [Label] :units (:meters, :kms, :miles, :nms) The distance unit to use
            # @option options [Label] :formula (:flat, :sphere, :miles, :nms) The formula to use
            # @return [Float] Returns the distance from self: to point:
            def distanceTo(point:, options:{})
                @loc.distance_to(point.location, options)
            end

            # @return [Integer] Returns heading in degrees between two coordinates. 0 is north, 90 is east, 180 is south, 270 is west, 359 almost North again
            # @param [Coordinate] point The point Coordinate that you want to know the bearing to
            def bearingTo(point:)
                @loc.heading_to(point.location)
            end

            # Calculates the coordinate that is located exactly in the middel of self: and point:
            # @param  [Coordinate] point The point coordinate that we want to use to calc the middle between
            # @return [Coordinate] The Coordinate that is exactly in between self and point
            def midpointTo(point:)
                pos = @loc.midpoint_to(point.location)
                Coordinate.new(lat: pos.lat, lng: pos.lng, map:@map)
            end

            # Calculates the coordinate that is located if you travel from self: in the heading: for a certain distance:
            # @param  [Integer] heading The heading in degrees(0-360) to turn from :self
            # @return [Float] distance The distance to travel written in the {DEFAULTMETRICS} unit
            def endpoint(heading:, distance:)
                pos = @loc.endpoint(heading, distance)
                Coordinate.new(lat: pos.lat, lng: pos.lng, map:@map)
            end

            # @return [Float] The x coordinate on the display
            def displayX
               (@x - @map.minX).round
            end

            # @return [Float] The y coordinate on the display
            def displayY
               @map.height - (@y - @map.minY).round
            end
        end

        # A {Point} on the {Map} can be anything. It can be a point in a {Track}, or a PoI (Point of Intrest) . It can have a discription, an icon, but they are optional.
        class Point < Coordinate
            attr_reader :description, :icon
            def initialize(lat:, lng:, description:nil, icon:nil)
                super(lat: lat, lng: lng)
                @description = description
                @icon = icon
            end

            # Creates a svg representing the point as a dot with a text if description is given
            # @return [String] The svg representing the point with a text if description is given
            # @todo Make the text appear right or left depending of the available space on screen
            def to_svg(rotate:nil, description: nil)
                out = %{<g#{rotate ? %{ transform="translate(#{rotate[:x]}, #{rotate[:y]}) rotate(#{rotate[:degrees]}) translate(-#{rotate[:x]}, -#{rotate[:y]})"}:%{}}><circle cx="#{displayX}" cy="#{displayY}" r="2" style="fill:none;stroke:black"/>\n}
                if description or @description
                    out << %{<text x="#{displayX-20}" y="#{displayY-20}" fill="black">#{description || @description}</text>}
                end
                out << %{</g>\n}
                out
            end
        end
    end
end
