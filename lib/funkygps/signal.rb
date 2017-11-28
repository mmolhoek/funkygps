require 'socket'
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
        def initialize(funkygps:, host: 'localhost', port: 2947)
            @funkygps = funkygps
            @oldtracks = []
            @speed = 0;
            @socket = nil
            @socket_ready = false
            @host = host
            @port = port
            @trackthread = nil
            @min_speed = 0.8 # speed needs to be higher than this to make the gps info count
            @last = nil #last gps info
            @sats = nil # last satellites info
            @track = Map::Track.new(map: @funkygps.map, points: [], name: 'gps')
        end

        # Change the minimum speed to accept a gps update
        def change_min_speed(speed:)
            @min_speed = speed
        end

        # Start requesting the position from the gps daemon
        # and add it to the @track. It also update the speed property
        def start_tracking
            clearSignal
            @funkygps.screen.clear

            # background thread that is used to open the socket and wait for it to be ready
            @socket_init_thread = Thread.start do
                #open the socket
                init_socket
                while not @socket_ready
                    #wait for it to be ready
                    sleep 1
                end
                # it's ready, tell it to start watching and passing
                puts "socket ready, start watching" if FunkyGPS::VERBOSE
                @socket.puts '?WATCH={"enable":true,"json":true}'
            end

            # background thead that is used to read info from the socket and use it
            @trackthread = Thread.start do
                while true do
                    begin
                        read_from_socket
                    rescue
                        "error while reading socket: #{$!}" if FunkyGPS::VERBOSE
                    end
                end
            end
        end

        # Stop the listening loop and close the socket
        def stop_tracking
            Thread.kill(@socket_init_thread) if @socket_init_thread
            Thread.kill(@trackthread) if @trackthread
            @socket_ready = false
            close_socket
            @funkygps.screen.clear
        end

        # initialize pgsd socket
        def init_socket
            begin
                puts "init_socket" if FunkyGPS::VERBOSE
                close_socket if @socket
                @socket = TCPSocket.new(@host, @port)
                @socket.puts("w+")
                puts "reading socket..." if FunkyGPS::VERBOSE
                welkom = JSON.parse(@socket.gets) rescue nil
                puts "welkom: #{welkom.inspect}" if FunkyGPS::VERBOSE
                @socket_ready = (welkom and welkom['class'] and welkom['class'] == 'VERSION')
                puts "@socket_ready: #{@socket_ready.inspect}" if FunkyGPS::VERBOSE
            rescue
                @socket_ready = false
                puts "#$!" if FunkyGPS::VERBOSE
            end
        end


        def oldstuff
            if pos = get_gps_position
                $stderr.print "new gps coordinate: lat:#{pos[:lat]}, lng:#{pos[:lon]} alt:#{pos[:alt]}, time: #{pos[:time]}, speed: #{pos[:speed]} \n" if FunkyGPS::VERBOSE
                if @track.points.length > 1
                    @funkygps.screen.update
                end
            end
        end

        # Read from socket. this should happen in a Thread as a continues loop. It should try to read data from the socket but nothing might happen if the gps deamon might not be ready. If ready it will send packets that we read and proces
        def read_from_socket
            if @socket_ready
                begin
                    parse_socket_json(json: JSON.parse(@socket.gets.chomp))
                rescue
                    puts "error reading from socket: #{$!}" if FunkyGPS::VERBOSE
                end
            else
                sleep 1
            end
        end

        # Proceses json object returned by gpsd daemon. The TPV and SKY object
        # are used the most as they give info about satellites used and gps locations
        # @param [JSON] json The object returned by the daemon
        def parse_socket_json(json:)
            case json['class']
            when 'DEVICE', 'DEVICES'
                # devices that are found, not needed
            when 'WATCH'
                # gps deamon is ready and will send other packets, not needed yet
            when 'TPV'
                # gps position
                #  "tag"=>"RMC",
                #  "device"=>"/dev/ttyS0",
                #  "mode"=>3,
                #  "time"=>"2017-11-28T12:54:54.000Z",
                #  "ept"=>0.005,
                #  "lat"=>52.368576667,
                #  "lon"=>4.901715,
                #  "alt"=>-6.2,
                #  "epx"=>2.738,
                #  "epy"=>3.5,
                #  "epv"=>5.06,
                #  "track"=>198.53,
                #  "speed"=>0.19,
                #  "climb"=>0.0,
                #  "eps"=>7.0,
                #  "epc"=>10.12
                if json['mode'] > 1
                   #we have a 2d or 3d fix
                    if is_new_measurement(json: json)
                        ts = DateTime.parse(json['time'])
                        puts "lat: #{json['lat']}, lng: #{json['lon']}, alt: #{json['alt']}, speed: #{json['speed']} at #{ts.to_s}, which is #{Time.now - ts.to_time} s old" if FunkyGPS::VERBOSE
                        @track.addCoordinate(coordinate:FunkyGPS::Map::Coordinate.new(lat:json['lat'], lng:json['lon'], time: ts, speed:json['speed'], altitude:json['alt'], map: @funkygps.map))
                        if @track.points.length > 2
                            @funkygps.screen.update
                        end
                    end
                end
            when 'SKY'
                # report on found satellites
                sats = json['satellites']
                if satellites_changed(sats: sats)
                    puts "found #{sats.length} satellites, of which #{sats.count{|sat| sat['used']}} are used" if FunkyGPS::VERBOSE
                end
            else
                puts "hey...found unknow tag: #{json.inspect}" if FunkyGPS::VERBOSE
            end
        end

        # checks if the new satellites object return by the deamon is different enough compared
        # to the last one, to use it
        def satellites_changed(sats:)
            if @sats.nil? or (@sats.length != sats.length or @sats.count{|sat| sat['used']} != sats.count{|sat| sat['used']})
                @sats = sats
                return true
            end
            return false
        end

        # checks if the new location object return by the deamon is different enough compared
        # to the last one, to use it. it could be disregarded for example because the speed is to low, and you don't want to have the location jumping around when you stand still
        def is_new_measurement(json:)
            if @last.nil? or (@last['lat'] != json['lat'] and @last['lon'] != json['lon'] and json['speed'] > @min_speed)
                @last = json
                return true
            end
            return false
        end

        # This will tell the gps daemon we want to get the coordinates of
        # any gps connected. when calling this we have to start reading
        # the socket and keep reading it as otherwise the socket will overflow
        # get closed by the daemon
        def start_to_listen_socket
            begin
                if @socket_ready
                    @socket.puts '?WATCH={"enable":true,"json":true}'
                    return true
                end
            rescue
                puts "#$!" if FunkyGPS::VERBOSE
                return false
            end
        end

        # Close the gps deamon socket
        def close_socket
            begin
                if @socket
                    @socket.puts '?WATCH={"enable":false}'
                    @socket.close
                end
                @socket = nil
            rescue
                puts "#$!" if FunkyGPS::VERBOSE
            end
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
        def simulateToGif(name: nil, delay: 100)
            STDERR.puts "creating gif animation of track '#{track.name}' with #{track.nr_of_points} points to #{name||track.name}.gif with #{delay} delay" if FunkyGPS::VERBOSE
            # imagelist that is used to create a gif
            @funkygps.screen.clear
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
