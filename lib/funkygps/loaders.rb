require 'nokogiri'
class FunkyGPS
    class Map
        module GPSFormats
            # All supported gps formats use a loader to be ... loaded
            # If your format is not supported yet it is very easy to add
            # it. just copy the FunkyGPS::Map::GPSFormats::GPX file as a
            # starting point, and make sure it's waypoints def returns {FunkyGPS::Map::WayPoint}'s
            # and the tracks def returns {FunkyGPS::Map::Track}'
            # Default parser that is used it Nokogiri, if you want another one
            # overide the initialize with your own xml parser

            # This is the default xml loader, which uses Nokogiri
            class Loader
                attr_reader :doc
                # default, the system will use Nokogiri to load the xml
                # your can overwrite this by defining the initialize again
                # in the loader you want to implement
                def initialize(file:)
                    @doc = Nokogiri::XML(open(file))
                    @doc.remove_namespaces!
                    return self
                end
            end
        end
    end
end
