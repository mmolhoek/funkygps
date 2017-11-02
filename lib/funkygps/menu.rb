class FunkyGPS
    # The menu is used to control all actions and states of the FunkyGPS app. Also it deals with all external inputs like buttons.
    # @todo Reading button input from hw
    class Menu
        # @return [Boolean] fullscreen Is the app running in fullscreen map mode?
        attr_reader :fullscreen
        def initialize(fullscreen: true)
            @fullscreen = fullscreen
        end
    end
end

