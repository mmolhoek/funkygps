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
            @oldtracks = []
            @track = Map::Track.new(map: @funkygps.map, points: [], name: 'gps')
        end

        # Clears the current track, returning that track
        # @return [Map::Track] The old trackdata, before the clearing
        def clearSignal
            @oldtracks.push(@track.getpoints)
            @track.clearTrack
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

        # You can use this to use any track as a fake gps signal.
        # @param [String] name The name of the track to use as fake signal
        def copyTrackPointsToSignal(name:)
            @track.setpoints(points:@funkygps.map.getTrack(name: name).getpoints)
        end

        # Simulate a track by moving from start to end points
        # at a x ms interval, creating an animated gif of the result
        # @example Simulate to an animated gif name_of_track.gif
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(track:'name of track')
        #   gps.signal.simulateToGif()
        # @example Simulate to an animated gif name hi.gif
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(track:'name of track')
        #   gps.signal.simulateToGif(name: 'hi')
        # @example Simulate to an animated gif with delay of 500 ms between each move
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(track:'name of track')
        #   gps.signal.simulateToGif(delay: 500)
        def simulateToGif(name: nil, delay: 100)
            STDERR.puts "creating gif animation of track '#{track.name}' with #{track.nr_of_points} points to #{name||track.name}.gif with #{delay} delay" if FunkyGPS::VERBOSE
            # imagelist that is used to create a gif
            list = Magick::ImageList.new
            # tempTrack is used to restore the track when the simulation is finished
            STDERR.puts "track has #{@track.points.length} points, we will add points so no point is furter than 15 meters apart" if FunkyGPS::VERBOSE
            #reset all passed points
            @track.resetpassedflags
            # the points of this track, but split into chunks of max 15 meter
            points = @track.splitPoints(distance: 15)
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
            list.write("#{name||track.name.gsub(' ','_')}.gif")
        end
        def simulate(delay: 100)
            STDERR.puts "creating gif animation of track '#{track.name}' with #{track.nr_of_points} points to PaPiRus display with #{delay} delay" if FunkyGPS::VERBOSE
            # tempTrack is used to restore the track when the simulation is finished
            STDERR.puts "track has #{@track.points.length} points, we will add points so no point is furter than 15 meters apart" if FunkyGPS::VERBOSE
            #reset all passed points
            @track.resetpassedflags
            # the points of this track, but split into chunks of max 15 meter
            points = @track.splitPoints(distance: 15)
            STDERR.puts "track now has #{points.length} points, let's start the simulation" if FunkyGPS::VERBOSE
            # Start your engines...
            startpoint = points.shift
            #create a second point close to startpoint to make the first image
            @track.addCoordinate(coordinate: startpoint)
            @track.addCoordinate(coordinate: startpoint.endpoint(heading:startpoint.bearingTo(point: points.first), distance: 5))
            @funkygps.screen.update
            (1..points.length).each_with_index do |coordinate, index|
                STDERR.puts "point #{index} of #{points.length}" if FunkyGPS::VERBOSE
                @track.addCoordinate(coordinate: points.shift)
                @funkygps.screen.update
            end
        end

        # Draw the GPS track as dotted line.
        # @return [String] The svg that represents track of the gps
        def trackhistory_to_svg
            @track.to_svg(rotate:rotateSettings, pathparams: FunkyGPS::GPSSIGNALTRACKLINEPARAMS)
        end

        # @return [Integer] The distance traveled after seconds:
        def distanceAfter(seconds:5)
            seconds * speed
        end

        # @todo getting the speed from the GPS hw
        # @return [Integer] Current speed
        def speed
            5
        end
        # Set the track. This is used to fake a track as the signal. As if you received all track's points as gps signals
        def setTrack(track:)
            @track = track.deep_clone
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
