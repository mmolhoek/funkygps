require 'nokogiri'
class FunkyGPS
    class Map
        # All supported gps formats use a loader to be ... loaded
        # If your format is not supported yet it is very easy to add
        # it. just copy the FunkyGPS::Map::GPSFormats::GPX file as a
        # starting point, and make sure it's waypoints def returns {FunkyGPS::Map::WayPoint}'s
        # and the tracks def returns {FunkyGPS::Map::Track}'
        # Default parser that is used it Nokogiri, if you want another one
        # overide the initialize with your own xml parser
        # @todo loader for KML format
        # @todo loader for txt format
        module GPSFormats
            # This is the default xml loader, which uses Nokogiri
            class Loader
                attr_reader :doc, :map
                # default, the system will use Nokogiri to load the xml
                # your can overwrite this by defining the initialize again
                # in the loader you want to implement
                def initialize(map:, file:)
                    @map = map
                    @doc = Nokogiri::XML(open(file))
                    @doc.remove_namespaces!
                    return self
                end
                # The individual loaders like GPX or KLM provide the waypoints and tracks functions
                # which we use here to load them into the map
                def load(map:)
                    waypoints.each do |waypoint|
                        # we link the map here so the individual loaders don't need to do it
                        waypoint.map = map
                        if at = waypoint.name.to_s[/^me(\d*)/]
                            # Testing purpose: wp with name 'me1' and 'me2' is treated as gps signal
                            map.funkygps.signal.track.addCoordinate(coordinate: waypoint, at: at.to_i - 1)
                        else
                            map.addWaypoint(waypoint: waypoint)
                        end
                    end
                    tracks.each do |track|
                        # We link the map here so the individual loaders don't need to do it
                        track.trackpoints.each{|coordinate| coordinate.map=map}

                        # If you name a track 'gps', It will be used as a fake gps signal
                        # other wise if just loaded like a normal track
                        if track.name == 'gps'
                            map.funkygps.signal.loadTrack(track:track)
                        else
                            map.addTrack(track: track)
                        end
                    end
                end
            end
        end
    end
end
