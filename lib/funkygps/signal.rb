class FunkyGPS
    # The Signal class holds all info received from the hardware GPS
    # it will store all received GPS Coordinates in its @attr(track) list
    class Signal
        # @return [Map] map The map area containing all tracks, points, etc
        # @return [Map::Track] track The track received so for by the GPS
        attr_reader :funkygps, :map, :track
        # @param [FunkyGPS] funkygps The main control center
        def initialize(funkygps:)
            @funkygps = funkygps
            @track = Map::Track.new(map: @funkygps.map, points: [], name: 'gps')
        end
        # Set the track. This is used to fake a track as the signal. As if you received all track's points as gps signals
        def setTrack(track:)
            @track = track.deep_clone
        end
        # Clears the current track, returning that track
        # @return [Map::Track] The old trackdata, before the clearing
        def clearSignal
            previousTrack = @track.deep_clone
            @track.clearTrack
            previousTrack
        end
        # @return [Integer] The distance traveled after seconds:
        def distanceAfter(seconds:5)
            seconds * speed
        end
        # @todo getting the speed from the GPS hw
        # @return [Integer] Current speed
        def speed
            10
        end
        # The last know position
        # @return [Map::Coordinate] the last Coordinate of the signal's track
        def lastPos
            @track.points.last
        end
        # The direction of the last know movement. This is either coming directly from the GPS
        # or is calculated with the last two coordinates of the signals's track
        # @todo getting the direction from the GPS hw
        # @return [Integer] degrees (0-365)
        def currenDirection
            @track.points[-2].bearingTo(point:@track.points[-1])
        end

        # @return [Array<Point>] all points, but with added points in such a way that no indual distance between two point is larger then `distance`
        # @param [Array<Point>] points The track to split
        # @param [Integer] distance If two sequential points have a distance between them larger then this, a Coordinate will be added in the middle of them
        def splitPoints(points:, distance:30)
            points.each_slice(2).map { |point1, point2| splitPointsUntilSmallerThen(point1: point1, point2: point2, distance: distance) }.flatten
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

        # You can use this to use any track as a fake gps signal.
        # @param [String] name The name of the track to use as fake signal
        def copyTrackPointsToSignal(name:)
            @track.setPoints(points:@funkygps.map.getTrack(name: name).points)
            @track.points.each{|p| p.isPassed(passed: false)}
        end

        # Simulate a track by moving from start to end points
        # at a x ms interval, creating an animated gif of the result
        # @example Simulate to an animated gif name track.gif
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(track:'name of track')
        #   gps.signal.simulateToGif()
        # @example Simulate to an animated gif name hi.gif
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(track:'name of track')
        #   gps.signal.simulateToGif(name: 'hi.gif')
        # @example Simulate to an animated gif with delay of 500 ms between each move
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(track:'name of track')
        #   gps.signal.simulateToGif(delay: 500)
        def simulateToGif(name: 'track.gif', delay: 100)
            STDERR.puts "creating gif animation of track '#{track.name}' with #{track.nr_of_points} points to #{name} with #{delay} delay" if FunkyGPS::VERBOSE
            list = Magick::ImageList.new
            # tempTrack is used to restore the track when the simulation is finished
            STDERR.puts "track has #{@track.points.length} points, we will add points so no point is furter than 15 meters apart" if FunkyGPS::VERBOSE
            # the points of this track, but split into chunks of max 15 meter
            points = splitPoints(points:@track.points, distance: 15)
            STDERR.puts "track now has #{points.length} points, let's start the simulation" if FunkyGPS::VERBOSE
            # Start your engines...
            startpoint = points.shift
            #create a second point close to startpoint to make the first image
            @track.addCoordinate(coordinate: startpoint)
            @track.addCoordinate(coordinate: startpoint.endpoint(heading:startpoint.bearingTo(point: points.first), distance: 5))
            list.read @funkygps.screen.to_image
            (1..points.length).each_with_index do |coordinate, index|
                STDERR.puts "point #{index} of #{points.length}" if FunkyGPS::VERBOSE
                @track.addCoordinate(coordinate: points.shift)
                list.read @funkygps.screen.to_image
            end
            # add the delay between images
            list.each {|image| image.delay = delay } if delay
            list.write(name)
        end

        # Simulate a track by moving from start to end points
        # on the PaPiRus display, as fast as possible
        # @example Simulate to PaPiRus display
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(name:'name of track')
        #   gps.signal.simulate(track:'track 1')
        def simulate(track:)
            # tempTrack is used to restore the track when the simulation is finished
            tempTrack = clearSignal
            # our track to simultae
            simTrack = tempTrack.deep_clone
            # Start your engines...
            @track.addCoordinate(coordinate: simTrack.points.shift)
            simTrack.points.each do |coordinate|
                @track.addCoordinate(coordinate: simTrack.points.shift)
                @funkygps.screen.update
            end
            # Restore track
            @track.setPoints(points: tempTrack.points) if tempTrack.points
        end

        # Draw the GPS track as dotted line.
        # @return [String] The svg that represents track of the gps
        def trackhistory_to_svg
            @track.to_svg(rotate:rotateSettings, pathparams: FunkyGPS::GPSSIGNALTRACKLINEPARAMS)
        end

        # Draws a dot on the last know location and a line from that location
        # in the last know direction with a length representing the speed
        # @return [String] The svg that represents the current position/direction/speed
        def to_svg
            endpoint = lastPos.endpoint(heading:0, distance:distanceAfter)
            out = %{<g>}
            out << %{<circle cx="#{lastPos.displayX}" cy="#{lastPos.displayY}" r="4" style="fill:none;stroke:black"/>}
            out << %{<path d="M #{lastPos.displayX} #{lastPos.displayY} L #{endpoint.displayX} #{endpoint.displayY}" style="fill:none;stroke:black" stroke-dasharray="5, 3" />}
            out << %{</g>}
            out
        end

        # @return [Object] Rotation parameters
        def rotateSettings
           {degrees: -currenDirection, x: lastPos.displayX, y: lastPos.displayY}
        end
    end
end
