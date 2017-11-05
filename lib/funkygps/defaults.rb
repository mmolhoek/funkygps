class FunkyGPS
    # @return [:meters, :kms, :miles, :nms] DEFAULTMETRICS Sets the default metrics unit
    DEFAULTMETRICS = :meters

    # @return [String] DEFAULTMETRICSLABEL Sets the default metrics unit
    DEFAULTMETRICSLABEL = 'm'  # Sets the default metrics label

    # @return [String] DEFAULTTRACKFOLDER Sets the default folder, where FunkyGPS will load and store tracks from and to
    DEFAULTTRACKFOLDER = './tracks/'

    # @return [Boolean] VERBOSE Set to true when you want to see some extra STDERR.puts info when debugging
    VERBOSE = false

    # @return [String] ACTIVETRACKLINEPARAMS Active track line. Empty means black
    # @see FunkyGPS::ACTIVETRACKDIRECTIONLINE for other configuration example
    ACTIVETRACKLINEPARAMS=''

    # @return [String] ACTIVETRACKDIRECTIONLINE Active track direction pointer. the first number represents the dash length, the second the gap length
    ACTIVETRACKDIRECTIONLINE='stroke-dasharray="3, 3"'

    # @return [String] GPS signals track line cofiguration
    # @see FunkyGPS::ACTIVETRACKLINEPARAMS for other configuration example
    GPSSIGNALTRACKLINEPARAMS='stroke-dasharray="2, 6"'

    # @return [Integer] ACTIVETRACKDIRECTIONLINE How many degrees left and right of 0 and 180 off we have to be before short arrow kicks in
    ACTIVETRACKDIRECTIONDEGREEOFFSET=35

    # FunkyGPS base error
    class FunkyException < ::StandardError
        # FunkyGPS error that is raised when the gps file type is not supported
        class ExtentionNotSupported < FunkyException; end
        # FunkyGPS error that is raised when loader funtions are not implemented
        class NotImplemented < FunkyException; end
        # FunkyGPS error when the is no map available
        class NoMapFound < FunkyException; end
        # FunkyGPS error when the is no track available
        class NoTrackFound < FunkyException; end
        # FunkyGPS error when the is no active track set
        class NoActiveTrackFound < FunkyException; end
    end
end
