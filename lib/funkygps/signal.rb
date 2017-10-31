class FunkyGPS
    # The Signal class holds all info received from the hardware GPS
    # it will store all received GPS Coordinates in its @attr(track) list
    class Signal
        # @return [Map] map The map area containing all tracks, waypoints, etc
        # @return [Map::Track] track The track received so for by the GPS
        attr_reader :funkygps, :map, :track
        # @param [FunkyGPS] funkygps The main control center
        def initialize(funkygps:)
            @funkygps = funkygps
            @map = @funkygps.map
            @track = Map::Track.new(trackpoints: [], name: 'gps')
        end
        # Add the track
        def loadTrack(track:)
            @track = track
        end
        # Clears the current track, returning that track
        # @return [Map::Track] The old trackdata, before the clearing
        def clearTrack
            previousTrack = @track.clone
            @track.clearTrack
            previousTrack
        end
        # Returns The amount of meters traveled at the current speed in seconds: time
        # @return [Integer] meters traveled
        def distanceAfter(seconds:5)
            seconds * speed
        end
        # Current speed, coming directly from GPS signal
        # @todo getting the signal from the GPS hw
        # @return [Integer] Current speed
        def speed
            15
        end
        # The last know position
        # @return [Map::Coordinate] the last Coordinate of the signal's track
        def lastPos
            @track.trackpoints.last
        end
        # The angle of the last know movement. This is either coming directly from the GPS
        # or is calculated with the last two coordinates of the signals's track
        # @todo getting the direction from the GPS hw
        # @return [Integer] degrees (0-365)
        def currenDirection
            @track.trackpoints[-2].bearingTo(other:@track.trackpoints[-1])
        end

        # Simulate a track by moving from start to end trackpoints
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
            STDERR.puts "creating gif animation of track '#{track.name}' with #{track.nrOfTrackpoints} trackpoints to #{name} with #{delay} delay" if FunkyGPS::VERBOSE
            list = Magick::ImageList.new
            # tempTrack is used to restore the track when the simulation is finished
            tempTrack = clearTrack
            # our track to simultae
            simTrack = tempTrack.clone
            # Start your engines...
            startpoint = simTrack.trackpoints.shift
            @track.addCoordinate(coordinate: startpoint)
            @track.addCoordinate(coordinate: startpoint.endpoint(heading:startpoint.bearingTo(other: simTrack.trackpoints.first), distance: 5))
            list.read @funkygps.screen.to_image
            simTrack.trackpoints.each do |coordinate|
                @track.addCoordinate(coordinate: simTrack.trackpoints.shift)
                list.read @funkygps.screen.to_image
            end
            # add the delay between images
            list.each {|image| image.delay = delay } if delay
            list.write(name)
            # Restore track
            @track.replaceTrackpoints(trackpoints: tempTrack.trackpoints) if tempTrack.trackpoints
        end

        # Simulate a track by moving from start to end trackpoints
        # on the PaPiRus display, as fast as possible
        # @example Simulate to PaPiRus display
        #   gps.map.loadGPSFile(file:'./tracks/track1.gpx')
        #   gps.map.setActiveTrack(name:'name of track')
        #   gps.signal.simulate(track:'track 1')
        def simulate(track:)
            # tempTrack is used to restore the track when the simulation is finished
            tempTrack = clearTrack
            # our track to simultae
            simTrack = tempTrack.clone
            # Start your engines...
            @track.addCoordinate(coordinate: simTrack.trackpoints.shift)
            simTrack.trackpoints.each do |coordinate|
                @track.addCoordinate(coordinate: simTrack.trackpoints.shift)
                @funkygps.screen.update
            end
            # Restore track
            @track.replaceTrackpoints(trackpoints: tempTrack.trackpoints) if tempTrack.trackpoints
        end

        # Draw the GPS track as dotted line.
        # @return [String] The svg that represents track of the gps
        def trackhistory_to_svg
            @track.to_svg(rotate:{degrees:-currenDirection, x: lastPos.displayX, y: lastPos.displayY}, pathparams: FunkyGPS::GPSSIGNALTRACKLINEPARAMS)
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
    end
end
