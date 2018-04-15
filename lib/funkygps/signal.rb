require 'gpsd2json'
require 'date'
class FunkyGPS
    # The Signal class holds all info received from the hardware GPS
    # it will store all received GPS Coordinates in its @attr(track) list
    class Signal
        # @return [FunkyGPS] funkygps The main contoller instance
        attr_reader :funkygps
        # @return [Map] map The map area containing all tracks, points, etc
        attr_reader :map
        # @return [Map::Track] track The track received so for by the GPS
        attr_reader :track
        # @return [Integer] speed The current speed
        attr_reader :speed
        # @param [FunkyGPS] funkygps The main control center
        # @param [string] host The host the gps deamon can be found on (defaults to 'localhost')
        # @param [integer] port The port the gps deamon can be found on (defaults to 2947)
        def initialize(funkygps:, host: 'localhost', port: 2947)
            @funkygps = funkygps
            @simulationspeed = 0
            @oldtracks = []
            @speed = 0;
            @gpsdeamon = GPSD2JSON.new(host: host, port: port)
            @gpsdeamon.on_position_change do |pos|
                @track.addCoordinate(coordinate:FunkyGPS::Map::Coordinate.new(lat:pos['lat'], lng:pos['lon'], time: ts, speed:pos['speed'], altitude:pos['alt'], map: @funkygps.map))
                if @track.points.length > 2
                    @funkygps.screen.update
                end
            end
            @gpsdeamon.on_satellites_change do |sats|
                #todo
            end
            @track = Map::Track.new(map: @funkygps.map, points: [], name: 'gps')
        end

        # @param [Float] speed The minimum speed to accept a gps update
        def change_min_speed(speed:)
            @gpsdeamon.change_min_speed(speed: speed)
        end

        # Open the socket and when ready request the position flow from the gps daemon
        def start_tracking
            clearSignal
            @funkygps.screen.clear
            @gpsdeamon.start
        end

        # Stop the listening loop and close the socket
        def stop_tracking
            @gpsdeamon.stop
            @funkygps.screen.clear
        end

        # Clears the current track, returning that track
        # @return [Map::Track] The old trackdata, before the clearing
        def clearSignal
            previouspoints = @track.getpoints
            @oldtracks.push(previouspoints) if previouspoints.length > 0
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
        def simulateToGif(name: nil, delay: 100, maxsteplength: 15)
            simulate(name:name, delay: delay, maxsteplength: maxsteplength, list: Magick::ImageList.new)
        end

        # Simulate a track to either the screen when list is nil or to a gif when list is a [[Magick::ImageList.new]]
        # see helper function [[simulateToGif]].
        def simulate(delay: 100, maxsteplength: 15, name: nil, list: nil, speed: 30)
            @simulationspeed = speed
            STDERR.puts "creating gif animation of track '#{track.name}' with #{track.nr_of_points} points to #{name||track.name}.gif with #{delay} delay" if FunkyGPS::VERBOSE
            # imagelist that is used to create a gif
            @funkygps.screen.clear
            @track.resetpassedflags
            STDERR.puts "track has #{@track.points.length} points, we will add points so no point is furter than 15 meters apart" if FunkyGPS::VERBOSE
            # the points of this track, but split into chunks of max 15 meter
            points = @track.splitPoints(distance: maxsteplength)
            STDERR.puts "track now has #{points.length} points, let's start the simulation" if FunkyGPS::VERBOSE
            # Start your engines...
            startpoint = points.shift
            #create a second point close to startpoint to make the first image
            @track.addCoordinate(coordinate: startpoint)
            @track.addCoordinate(coordinate: startpoint.endpoint(heading:startpoint.bearingTo(point: points.first), distance: 5))
            startpoint.passed = true
            list ? list.read(@funkygps.screen.to_image) : @funkygps.screen.update
            (1..points.length).each_with_index do |coordinate, index|
                STDERR.puts "point #{index} of #{points.length}" if FunkyGPS::VERBOSE
                nextpoint = points.shift
                nextpoint.passed = true
                @track.addCoordinate(coordinate: nextpoint)
                list ? list.read(@funkygps.screen.to_image) : @funkygps.screen.update
            end
            if list
                # add the delay between images
                list.each {|image| image.delay = delay } if delay
                list.write("#{name||track.name.gsub(' ','_')}.gif")
            end
            @simulationspeed = 0
        end

        # Draw the GPS track as dotted line.
        # @return [String] The svg that represents track of the gps
        def trackhistory_to_svg
            @track.to_svg(rotate:rotateSettings, pathparams: FunkyGPS::GPSSIGNALTRACKLINEPARAMS)
        end

        # @return [Integer] The distance traveled after seconds:
        def distanceAfter(seconds:5)
            seconds * (@simulationspeed > 0 ? @simulationspeed : speed)
        end

        # @return [Integer] Current speed
        def speed
            @track.points.last.speed
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
