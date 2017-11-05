class FunkyGPS
    module GPSFormats
        # This is the loader for GPX files. If you want to create yor own loader,
        # please feel free. How? copy this file and name is the same as the extension of the file.
        # So, if you would have a new map file type like cooltracks.sds, your file should be named
        # sds.rb and in it implement your own GPS loader using this one as a template.
        # make sure that your implementation implements both the pois (Points of Intrest) and tracks functions
        # and make sure they return a Coordinate Array and a Track Array.
        # By default the loader will use nokogiri to load the file into @doc,
        # but you can override this by implementing the initialize(file:) function as well.
        class GPX < Loader
            # @return [Array<Point>] All Points of Intrest
            def points
                @doc.xpath('//wpt').map do |point|
                    FunkyGPS::Map::Point.new(lat: point.attr('lat'), lng: point.attr('lon'), description: (point.xpath('name').first.content rescue nil), icon: (point.xpath('sym').first.content rescue nil))
                end
            end
            # @return [Array<Track>] All the Tracks found in the file
            def tracks
                @doc.xpath('//trk').map do |track|
                    FunkyGPS::Map::Track.new(points: track.xpath('.//trkpt').map{|pt| FunkyGPS::Map::Point.new(lat: pt.attr('lat'), lng: pt.attr('lon'))}, name: (track.xpath('name').first.content rescue nil))
                end
            end
        end
    end
end
