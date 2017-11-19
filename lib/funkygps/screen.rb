require 'papirus'
require 'papirus/rmagick'
# used to embed svg's
require 'tempfile'

class FunkyGPS

    # Layout is used to configure different layouts of the screen elements like map, menu, info
    # @todo Implement different layouts
    class Layout
        # @return [Array<label>] All parts of the screen that can be build
        attr_reader :subscreens

        # @param [FunkyGPS] funkygps The main control center
        # @param [Label] currentlayout (:fullscreen) The currently active screen layout. defaults to :fullscreen
        def initialize(funkygps:, currentlayout: :fullscreen)
            @funkygps = funkygps
            @current_layout = currentlayout
            @subscreens = [:map, :menu, :info]
        end

        # Creates all possible layouts
        def layouts
            #Struct.new :hi, :there
            return @layouts if @layouts
            @layouts = {}
            @layouts[:fullscreen] = {}
            @layouts[:fullscreen][:map] = {}
            @layouts[:fullscreen][:map][:x] = 0
            @layouts[:fullscreen][:map][:y] = 0
            @layouts[:fullscreen][:map][:width] = @funkygps.screen.width
            @layouts[:fullscreen][:map][:height] = @funkygps.screen.height
            @layouts
        end

        # @return [Integer] The x of the specified screen
        # @param [Label] of The subscreen that you want to know the :x of
        def x(of:)
            layouts[@current_layout][of][:x]
        end

        # @return [Integer] The y of the specified screen
        # @param [Label] of The subscreen that you want to know the :y of
        def y(of:)
            layouts[@current_layout][of][:y]
        end

        # @return [Integer] The width of the specified screen
        # @param [Label] of The subscreen that you want to know the :width of
        def width(of:)
            layouts[@current_layout][of][:width]
        end

        # @return [Integer] The height of the specified screen
        # @param [Label] of The subscreen that you want to know the :height of
        def height(of:)
            layouts[@current_layout][of][:height]
        end

        # @return [Boolean] Is the subscreen screen: visible in the current layout?
        # @param [Label] screen The subscreen that you want to check
        def is_visible(screen:)
            not layouts[@current_layout][screen].nil?
        end

        # @return [Boolean] Is only the :map visible at this moment?
        def fullscreenmap
            (@subscreens - [:map]).all?{|subscreen| layouts[@current_layout][subscreen].nil?}
        end
    end

    # Base class for the display output. it's {to_svg} function will create the image that it will send to the papirus display. It holds the reference to the PaPiRus display and can send the image to it.
    class Screen
        # @return [::PaPiRus::Display] display The reference to the PaPiRus driver
        attr_reader :display
        # @return [FunkyGPS] funkygps The main contoller instance
        attr_reader :funkygps
        # @return [Boolean] fullscreen Is the map fullscreen or do we have other interface items
        attr_accessor :fullscreen
        # @return [Boolean] landscape Is the PaPiRus display in landscape or portrait mode installed
        attr_accessor :landscape

        # @param [FunkyGPS] funkygps The main contoller instance
        # @param [Boolean] fullscreen Is the map fullscreen or do we have other interface items
        # @param [Boolean] landscape Is the PaPiRus display in landscape or portrait mode installed
        # @param [::PaPiRus::Display] testdisplay Can be used to send options to the initialize of {::PaPiRus::Display}, only used when you need a fake display for testing
        def initialize(funkygps:, fullscreen:, landscape:, testdisplay:nil)
            @funkygps = funkygps
            @fullscreen = fullscreen
            @landscape = true
            if testdisplay
                @display = ::PaPiRus::Display.new(options: testdisplay)
            else
                @display = ::PaPiRus::Display.new()
            end
            @layout = Layout.new(funkygps: funkygps)
        end

        # Builds and sends the current state of the map/gps data to the display
        def update
            raise NoMapFound, "your have to load a gps track first" unless funkygps.map
            #show it on the PaPiRus display
            @display.show(data:to_bit_stream, command: 'F')
        end

        # Tells the PaPiRus display to clear its screen
        def clear
            @display.clear
        end

        # @return [Integer] The PaPiRus display's width
        def width
            @display.width
        end

        # @return [Integer] The PaPiRus display's height
        def height
            @display.height
        end

        # @return [String] The svg converted to image, converted to 1-bit 2-color image data packed to String
        def to_bit_stream
            Magick::Image::from_blob(to_svg).first.to_bit_stream(width, height)
        end

        # toggle the maps fullscreen state
        def toggleFullscreen
            @fullscreen = !@fullscreen
        end

        # Used to create all separate parts of the display like menu, and map. We do this by creating separate SVGs of all elements and dumping them as images at a certain x,y,w,h on the screen
        # @param [Float] x The x position to put the SVG
        # @param [Float] y The x position to put the SVG
        # @param [Float] width The width to use when creating the SVG
        # @param [Float] height The height to use when creating the SVG
        # @param [String] svg The SVG
        def add_svg(x:, y:, width:, height:, svg:)
            %{<image x="#{x}" y="#{y}" width="#{width}" height="#{height}" xlink:href='#{embed_svg(svg: svg)}' />\n}
        end

        # Helper for add_svg, as we don't have the possibility to pass
        # the svg as blob (href="data:... svg as it is not (yet) supported by image magick)
        # The created tempfile is automaticaly removed at garbage collection moment.
        # @param [String] svg The SVG to put in the tempfile
        # @return [String] path to the tempfile that hold the SVG
        def embed_svg(svg:)
            t  = Tempfile.new(['embed','.svg'])
            t.write svg
            t.close
            t.path
        end

        # Create an image of the screen, used to create an gif animation of a route,
        # adding an image to the gif for each point.
        # @return [String] path to the tempfile that hold the SVG of the screen
        def to_image()
            embed_svg(svg: to_svg)
        end

        # Create ASCII art or a PNG image of display for debugging purpose
        # @param [String] name The name to use for the image, if name is 'ascii', ASCII art will be dumped to the terminal, otherwise it will be the name of the image, can be anything ImageMagick can write to and defaulting to screen.png
        def to_file(name: 'screen.png')
            if name === 'ascii'
                system "clear" #clear the terminal screen
                Magick::Image::from_blob(to_svg).first.inspect_bitstream(width, height)
            else
                Magick::Image::from_blob(to_svg).first.write(name)
            end
        end

        # will request the svg of all visible screen parts (map, menu and info)
        # and put them in a an svg if needed and send it to the display.
        def to_svg
            if (@fullscreen or @layout.fullscreenmap)
                #then we can skip the subscreen rendering with tempfiles and dump the map's svg
                funkygps.map.to_svg
            else
                out = %{<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n}
                out << %{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n}
                out << %{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="#{width}px" height="#{height}px">\n}
                @layout.subscreens.each do |subscreen|
                    out << add_svg(x: @layout.x(of:subscreen), y: @layout.y(of:subscreen), width: @layout.width(of:subscreen), height: @layout.height(of: subscreen), svg: funkygps.instance_variable_get(subscreen).to_svg) if @layout.is_visible(screen: subscreen)
                end
                out << %{</svg>}
                out
            end
        end
    end
end
