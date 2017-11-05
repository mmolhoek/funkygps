require 'nokogiri'
class FunkyGPS
# All supported GPS formats use the loader to be ... loaded
    # @see GPX If your format is not supported yet. It is very easy to add it.
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

            # The individual loaders like GPX or KLM provide the points and tracks functions
            # which we use here to load them into the map
            def load(map:)
                points.each do |point|
                    # we link the map here so the individual loaders don't need to do it
                    point.setMap(map: @map)
                    if at = point.description.to_s[/^me(\d*)/]
                        # Testing purpose: wp with name 'me1' and 'me2' is treated as gps signal
                        map.funkygps.signal.track.addCoordinate(coordinate: point, at: at.to_i - 1)
                    else
                        map.addPoint(point: point)
                    end
                end
                tracks.each do |track|
                    # We link the map here so the individual loaders don't need to do it
                    track.points.each{|coordinate| coordinate.setMap(map: @map)}

                    # If you name a track 'gps', It will be used as a fake gps signal
                    # other wise if just loaded like a normal track
                    if track.name == 'gps'
                        map.funkygps.signal.setTrack(track:track)
                    else
                        map.addTrack(track: track)
                    end
                end
            end

            def points
                raise FunkyException::NotImplemented, "you have to implement the 'points' function in your loader"
            end

            def track
                raise FunkyException::NotImplemented, "you have to implement the 'tracks' function in your loader"
            end
        end
    end
end
