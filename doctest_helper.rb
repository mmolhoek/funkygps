require 'lib/funkygps'

#disable some tests
YARD::Doctest.configure do |doctest|
    doctest.skip 'FunkyGPS#initialize'
    #prep some stuff before each test
    doctest.before do
        gps.map.clearTracks
    end
end
#default gps instance used for the tests
def gps
    @gps ||= FunkyGPS.new(testdisplay:{epd_path: '/tmp/epd'})
end
