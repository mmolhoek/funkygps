require 'lib/funkygps'

YARD::Doctest.configure do |doctest|
    #skip tests that are just documentation
    doctest.skip 'FunkyGPS#initialize'
    doctest.skip 'FunkyGPS::Map#simulate'
    doctest.skip 'FunkyGPS::Map#simulateToGif'
    doctest.skip 'FunkyGPS::Map#simulateToAscii'
    #clear the tracks before each test
    doctest.before do
        gps.map.clearTracks
    end
end

#default gps instance used for the tests
def gps
    @gps ||= FunkyGPS.new(testdisplay:{epd_path: '/tmp/epd'})
end
