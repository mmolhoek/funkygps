require 'papirus'
require 'papirus/rmagick'
# used to embed svg's
require 'tempfile'

module FunkyGPS
    class Layout
        attr_reader :screen
        def initialize(controlcenter:, screen:)
            @screen = screen
            @controlcenter = controlcenter
        end
        def mapX
            0
        end
        def mapY
            0
        end
        def mapWidth
            #@controlcenter.settings.map.fullscreen ? @screen.width : @screen.width
            @screen.width
        end
        def mapHeight
            @screen.height
        end
    end
    class Screen
        attr_reader :display, :controlcenter
        attr_accessor :fullscreen, :landscape
        def initialize(controlcenter:, fullscreen:, landscape:, epd_path:)
            @controlcenter = controlcenter
            @fullscreen = fullscreen
            @landscape = true
            @display = ::PaPiRus::Display.new(epd_path: epd_path)
            @layout = Layout.new(controlcenter: controlcenter, screen:self)
        end
        def update
            raise NoMapFound, "your have to load a gps track first" unless controlcenter.map
            #show it on the PaPiRus display
            @display.show(to_bit_stream)
        end
        def width
            @display.width
        end
        def height
            @display.height
        end
        def to_bit_stream
            Magick::Image::from_blob(to_svg).first.to_bit_stream(width, height)
        end
        # toggle the map fullscreen state dhow the whole map or
        # together with all instuments
        def toggleFullscreen
            @fullscreen = !@fullscreen
        end
        # will request the svg of all screen parts (map, menu and info)
        # and merge them in the active layout and send it to the display
        def to_svg
            if (@fullscreen)
                map.to_svg
            else
                out = %{<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n}
                out << %{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n}
                out << %{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="#{width}px" height="#{height}px">\n}
                out << add_svg(x: @layout.mapX, y: @layout.mapY, width: @layout.mapWidth, height: @layout.mapHeight, svg: controlcenter.map.to_svg)
                out << %{</svg>}
                out
            end
        end
        # Used to create all separate parts of the display like menu, and map
        def add_svg(x:, y:, width:, height:, svg:)
            %{<image x="#{x}" y="#{y}" width="#{width}" height="#{height}" xlink:href='#{embed_svg(svg: svg)}' />\n}
        end
        # helper for add_svg, as we dont have the possibility to pass
        # the svg as blob (href="data:... svg is not supported by image magick yet)
        def embed_svg(svg:)
            t  = Tempfile.new(['embed','.svg'])
            t.write svg
            t.close
            t.path
        end

        # Create ascii art or image of display for debugging purpose
        def to_file(name: 'display.png')
            if name === 'ascii'
                system "clear"
                Magick::Image::from_blob(to_svg).first.inspect_bitstream(width, height)
            else
                Magick::Image::from_blob(to_svg).first.write(name)
            end
        end
    end
end