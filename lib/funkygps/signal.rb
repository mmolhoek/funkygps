class FunkyGPS
    class Signal
        attr_reader :funkygps, :map, :track
        def initialize(funkygps:)
            @funkygps = funkygps
            @map = @funkygps.map
            @track = []
        end
        # When loading a map, you can add waypoint with the name me, me1, me2, me[\d]*
        # this way you can mimic a gps signal
        def addTrackpoint(trackpoint:, at:nil)
            if at
                @track.insert(at, trackpoint)
            else
                @track.push(trackpoint)
            end
        end
        # clears the current track, returning that track
        def clearSignal
            out = Marshal.load(Marshal.dump(@track))
            @track = []
            out
        end
        #retores a track as the current signal track
        def restoreTrack(track:)
            @track = track
        end
        # draws a dot on the last location and a line from that location
        # in the last know direction with a length representing the speed
        def to_svg
            endpoint = lastPos.endpoint(heading:0, distance:speed)
            out = %{<g>}
            out << %{<circle cx="#{lastPos.displayX}" cy="#{lastPos.displayY}" r="4" style="fill:none;stroke:black"/>}
            out << %{<path d="M #{lastPos.displayX} #{lastPos.displayY} L #{endpoint.displayX} #{endpoint.displayY}" style="fill:none;stroke:black"/>}
            out << %{</g>}
            out
        end
        # returns the current speed in meters
        def speed
            50
        end
        # The last know position
        def lastPos
            @track.last
        end
        # The angle of the last know movement (last two positions)
        def currenDirection
            @track[-2].bearingTo(other:@track[-1])
        end
    end
end
