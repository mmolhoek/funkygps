class FunkyGPS
    # The ViewBox takes care of the view of the map that is visible on the PaPiRus display
    class ViewBox
        attr_reader :map, :funkygps
        def initialize(map:, funkygps:)
            @map = map
            @funkygps = funkygps
        end
        def width
            @funkygps.screen.width
        end
        def height
            @funkygps.screen.height
        end
        def x
            @funkygps.signal.lastPos.displayX - (width/2)
        end
        def y
            @funkygps.signal.lastPos.displayY - (height/2)
        end
        def realWidth
            @map.realWidth / @map.width * width
        end
        def realHeight
            @map.realHeight / @map.height * height
        end
        def viewboxSettings
            "#{x} #{y} #{width} #{height}"
        end
    end
end
