# FunkyGPS

FunkyGPS is a gps application that can be used on a Rasberry PI with a PaPiRus display and a gps module attached.

## Before your start

You need to have the PaPiRus display up and running. please have a look at ... on how to install the drivers

## Installation

```bash
$ ssh raspberry
$ sudo gem install funkygps
```
## usage examples
### Simultate a track on the PaPiRus display
the gem has a test gpx (track) file in its tracks folder, which you can use to play with, or load your own gpx file
```bash
$ irb
gps = FunkyGPS.loadWidth(file:'./tracks/test.gpx')
gps.simulate(track:'track 1')
```
### testing on your laptop with no papirus display available

creating a animated gif of a track
```bash
$ irb
gps = FunkyGPS.loadWith(epd_path: '/tmp/epd')
gps.map.simulateToGif(track:'track 1')
```
animation is found as track.gif

other examples
```bash
gps = FunkyGPS.loadWith(epd_path: '/tmp/epd')
#gps.toggleFullscreen
#gps.screen.update
#gps.screen.to_ascii
gps.screen.to_file # create a screenshot of current display to screen.png

File.open('test.svg', 'w+') {|f| f.write gps.map.to_svg} # write the svg of the current display to a file

#other details:
STDERR.puts "the track distances in meters:\n#{gps.map.tracks.map{|tr| %{\t#{tr.name}:#{tr.distanceInMeters} meters\n}}.join('')}"
STDERR.puts "the track distances in km:\n#{gps.map.tracks.map{|tr| %{\t#{tr.name}:#{tr.distanceInKilometers} km\n}}.join('')}"
STDERR.puts "the maps square distance is #{gps.map.realWidth.round} meters by #{gps.map.realHeight.round} meters"
STDERR.puts "the maps viewBox square distance is #{gps.map.viewbox.realWidth.round} meters by #{gps.map.viewbox.realHeight.round} meters"
STDERR.puts "the current bearing of the signal is #{gps.map.signal.currenDirection} degrees"
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

