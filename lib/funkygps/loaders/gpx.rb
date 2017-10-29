class FunkyGPS
    class Map
        module GPSFormats
            # This is the loader for gpx files
            # If you want to create yor own loader, please feel free (create a PR)
            # simply copy this file to a new name and implement your own GPS loader
            # using this one as a template. by default the loader will use nokogiri
            # to load the file into @doc, but you can override this by implementing
            # the initialize(file:) function as well. see lib/loaders.rb
            class GPX < Loader
                # returns an array containing all the {FunkyGPS::GPS::WayPoint}'s
                def waypoints
                    @doc.xpath('//wpt').map do |waypoint|
                        WayPoint.new(lat: waypoint.attr('lat'), lng: waypoint.attr('lon'), name: (waypoint.xpath('name').first.content rescue 'unknown'), icon: (waypoint.xpath('sym').first.content rescue nil))
                    end
                end
                # returns an array containing all the {FunkyGPS::GPS::Track}'s
                # which in turn should contain all the {FunkyGPS::GPS::Coordinate}'s of each {FunkyGPS::GPS::Track}
                def tracks
                    @doc.xpath('//trk').map do |track|
                        Track.new(trackpoints: track.xpath('.//trkpt').map{|pt| Coordinate.new(lat: pt.attr('lat'), lng: pt.attr('lon'))}, name: (track.xpath('name').first.content rescue 'unknown'))
                    end
                end
            end
        end
    end
end
