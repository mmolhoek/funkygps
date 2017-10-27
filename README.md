# FunkyGPS

FunkyGPS is a gps application that can be used on a Rasberry PI with a PaPiRus display and a gps module attached.

## Before your start

Before you start playing make sure you got the display driver installed (gratis/edp-fuse)

```bash
sudo apt-get install libfuse-dev -y

git clone https://github.com/repaper/gratis.git
cd gratis
make rpi EPD_IO=epd_io.h PANEL_VERSION='V231_G2'
make rpi-install EPD_IO=epd_io.h PANEL_VERSION='V231_G2'
systemctl enable epd-fuse.service
systemctl start epd-fuse
```

You can find more detailed instructions and updates at the [gratis](https://github.com/repaper/gratis) repo

## Installation

```bash
$ ssh raspberry
$ sudo gem install funkygps
```
## usage examples

you can also find examples in the bin folder of the gem

### Simultate a track on the PaPiRus display
the gem has a test gpx (track) file in its tracks folder, which you can use to play with, or load your own gpx file
```ruby
$ irb
require 'funkygps'
gps = FunkyGPS.loadWidth(file:'./tracks/test.gpx')
gps.map.simulate(track:'track 1')
```
### testing on your laptop with no papirus display available

creating a animated gif of a track
```ruby
$ irb
require 'funkygps'
gps = FunkyGPS.initWith(epd_path: '/tmp/epd', file: '/path/to/gpx/file.gpx')
gps.map.simulateToGif(track:'track 1', name: 'out.gif')
```

other examples
```ruby
require 'funkygps'
gps = FunkyGPS.initWith(epd_path: '/tmp/epd')
gps.screen.update # send current display to screen
gps.screen.to_ascii # send current display as ascii art to terminal (put your terminal font small)
gps.screen.to_file # create a screenshot of current display to screen.png
File.open('test.svg', 'w+') {|f| f.write gps.map.to_svg} # write the svg of the current display to a file

#other details:
puts "the track distances in meters:\n#{gps.map.tracks.map{|tr| %{\t#{tr.name}:#{tr.distanceInMeters} meters\n}}.join('')}"
puts "the track distances in km:\n#{gps.map.tracks.map{|tr| %{\t#{tr.name}:#{tr.distanceInKilometers} km\n}}.join('')}"
puts "the maps square distance is #{gps.map.realWidth.round} meters by #{gps.map.realHeight.round} meters"
puts "the maps viewBox square distance is #{gps.map.viewbox.realWidth.round} meters by #{gps.map.viewbox.realHeight.round} meters"
puts "the current bearing of the signal is #{gps.map.signal.currenDirection} degrees"
```
## Contributing to funkygps

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Create a PR

## Todo's
* zoom
* distance to track
* intergration of actual GPS Signal

## Copyright

Copyright (c) 2017 FunkyForce. See LICENSE.txt for further details. (MIT)

