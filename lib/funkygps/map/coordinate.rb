require 'geokit'
# all gps file loaders (only support for gpx at the moment)

# default metrics

module FunkyGPS
    Geokit::default_units = DEFAULTMETRICS # others :kms, :nms, :meters
    module Map
        class Coordinate
            attr_accessor :map
            attr_reader :x, :y, :loc
            def initialize(lat:, lng:, map: nil)
                @loc = Geokit::LatLng.new(lat, lng)
                @map = map if map
                # map x / y coordinates
                radius = 6378137.0
                @x = radius * @loc.lng * Math::PI / 180.0
                @y = radius * Math.log(Math.tan((Math::PI / 4.0) + ((@loc.lat * Math::PI / 180.0) / 2.0)))
            end
            # Valid options are:
            # :units - valid val"ues are :miles, :kms, :or :nms (:meters is the default)
            # :formula - valid values are :flat or :sphere (:sphere is the default)
            def distanceTo(other:, options:{})
                @loc.distance_to(other.loc, options)
            end
            # Returns heading in degrees between two coordinates
            # 0 is north, 90 is east, 180 is south, 270 is west,
            # 359...almost north again
            def bearingTo(other:)
                @loc.heading_to(other.loc).round
            end

            def endpoint(heading:, distance:)
                pos = @loc.endpoint(heading, distance)
                Coordinate.new(lat: pos.lat, lng: pos.lng, map:@map)
            end

            def latitude
                @loc.lat
            end

            def longitude
                @loc.lng
            end
            def displayX
               (@x - @map.minX).round
            end
            def displayY
               @map.height - (@y - @map.minY).round
            end
        end
        class WayPoint < Coordinate
            attr_reader :name, :icon
            # A waypoint is a Coordinate with a name and icon
            def initialize(lat:, lng:, name:nil, icon:nil)
                super(lat: lat, lng: lng)
                @name = name
                @icon = icon
            end
            def to_svg
               %{<g><circle cx="#{displayX}" cy="#{displayY}" r="2" style="fill:none;stroke:black"/></g>\n}
            end
        end
    end
end
