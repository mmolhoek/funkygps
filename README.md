# FunkyGPS

FunkyGPS is a gps application, written in Ruby, available as gem.
It is created with a specific type of GPS usage in mind, namely offroad/enduro trips
but you can use it for any other trip you could think of (walking, biking, auto/motor on the road, you name it)
In this readme I will try to expain how I build it and how you can build it yourself.

Why I build it? have a look at my post on [Medium](https://medium.com/) explaining the reasons :)

To build this project I used an [Raspberry Pi Zero W](https://www.pi-supply.com/product/raspberry-pi-zero-w/), an [Adafruit Ultimate GPS](https://www.pi-supply.com/product/adafruit-ultimate-gps-breakout-66-channel-10-hz-updates/), and the 2.7 inch [PaPiRus ePaper display](https://www.pi-supply.com/product/papirus-epaper-eink-screen-hat-for-raspberry-pi/), but all other sizes should work to.

There are some other things you need, I will add a shopping list at the bottom.

Lets get started

## prepping the Pi harddisk (micro sd) and connecting to it with ssh

please have a look at [PiBakery](http://www.pibakery.org/) as this is the easiest way to prep your sd-card with wifi acces point and password configured
so you can ssh right onto your pi after first boot.

## installing the dependencies (on the Pi):
```bash
ssh pi@raspberrypi #or whatever name you gave it in PiBakery
# start with updating all packages (keep your system up to date and security holes closed). takes about 5 mins, so get a coffee
$ sudo apt-get update && sudo apt-get dist-upgrade
$ sudo dpkg-reconfigure locales
# now reboot to activate the new kernel if it got upgraded and ssh to you pi again
$ sudo reboot
```
- check which ones are needed: sudo apt-get install git python-imaging python-smbus bc i2c-tools python-dateutil fonts-freefont-ttf -y
Install some apps we need. **git** to get and recompile the display driver (we will explain later how and why), **imagemagick, libmagickcore-dev and libmagickwand-dev** as funkygps uses imagemagick to convert svg into images and with the help of a gem called papirus (we will install it later) to send this image to the display.  **ruby** as funkygps is written in ruby. **libfuse-dev** as that is used by the display. **ruby-dev** is needed for the rmagick gem that we will install later on.
```bash
sudo apt-get install git imagemagick libmagickcore-dev libmagickwand-dev ruby ruby-dev libfuse-dev -y

# also enable the SPI and the I2C interfaces. and set the timezone if you did not do that in PiBakery already
sudo raspi-config
# set the following options
# Boot Options > Wait for Network at Boot > No
# Localisation Options > Change Timezone > <your timezone>
# Interfacing Options > SPI > Yes
# Interfacing Options > I2C > Yes
# Interfacing Options > Serial > No and Yes
```

I found out that both the PaPiRus and the GPS use pin 10 (gpio 16) and pin 08 (gpio 15), Luckely we can compile the PaPiRus driver,
telling it we want it to use other pins, which are not used by the PaPiRus yet and also not used by the GPS. Let's do this now.

## build the PaPiRus driver from source
```bash
#get the source
git clone https://github.com/repaper/gratis.git
cd gratis
```

before we compile and install the driver we have to make some changes
as (GPIO_P1_07 and GPIO_P1_15 are not used by both the gps and the PaPiRus,
we will tell PaPiRus to use these instead of GPIO_P1_08 and GPIO_P1_10

edit PlatformWithOS/RaspberryPi/epd_io.h in your fav editor (vi for me)

```vi PlatformWithOS/RaspberryPi/epd_io.h```

* change the border_pin GPIO_P1_08 to GPIO_P1_07
* change the discharge pin GPIO_P1_10 to GPIO_P1_15

Do not remove the # hash in front of the lines, they belong there :)
save the file and exit

```bash
#now we build the driver
make rpi EPD_IO=epd_io.h PANEL_VERSION='V231_G2'
#and install it
sudo make rpi-install PANEL_VERSION='V231_G2'

# enable and start the service
sudo systemctl enable epd-fuse.service
sudo systemctl start epd-fuse
```

set the screen size (1.44 | 1.9 | 2.0 | 2.6 | 2.7) (2.7 in my case)
```bash
# stop the fuse driver
sudo systemctl stop epd-fuse
# edit the drivers config file in you fav editor (vi in my case), remove the # from the line that start with #EPD_SIZE and add your display size.
sudo vi /etc/default/epd-fuse
# start the driver again
sudo systemctl start epd-fuse
```

Now that all driver stuff is done, you should test if it is all functioning correctly. To do this we install a little ruby gem that can talk to the display. we need the gem anyway for our the funkygps to work, and we can use it to test the screen. let's go:

```bash
# Install the gem's rmagick to talk to imagemagick from ruby and papirus to talk to the display from ruby
NOKOGIRI_USE_SYSTEM_LIBRARIES=true sudo gem install rmagick papirus geokit nokogiri --no-doc
# Start an interactive ruby session
irb
require 'papirus'
display = PaPiRus::Display.new()
display.clear
```

This should clear the screen by making it black and then white again. If that happens, your set to continue with installing funkygps

## Setting up the GPS on your py zero using the uart, not the serial
edit /boot/config.txt and add/change the line enable_uart=0 to enable_uart=1 (make sure it does not have the # infront...)
sudo systemctl stop gpsd.socket
sudo systemctl disable gpsd.socket
reboot
#alway have to start like this when rebooted
sudo gpsd /dev/ttyS0 -F /var/run/gpsd.sock
cgps -s

gem install nmea_plus



FunkyGPS also uses this gem internally to update the display as it goes.

After your sure the display is up and running, Lets move on to using FunkyGPS

## Installation

```bash
$ ssh raspberry
$ sudo gem install papirus rmagick funkygps --no-doc
```
## usage examples

you can also find examples in the bin folder of the gem

### Simultate a track on the PaPiRus display
the gem has a test gpx (track) file in its tracks folder, which you can use to play with, or load your own gpx file
```ruby
$ irb
require 'funkygps'
gps = FunkyGPS.new(file:'./tracks/test.gpx')
gps.map.simulate(track:'track 1')
```
### testing on your laptop with no papirus display available

When you pass the `epd_path` parameter you can tell the papirus gem to use a fake display folder. Make sure the path is writable as FunkyGPS will ask the papirus gem to create a fake display structure there

creating a animated gif of a track
```ruby
$ irb
require 'funkygps'
# To get the 2.0 panel display you would only have to pass the fake folder as the 2.0 is the default display:
gps = FunkyGPS.new(testdisplay: { epd_path: '/tmp/epd'}, file: './tracks/test.gpx')
# but for the 2.7 display, your would also have to pass the width, height and panel info
gps = FunkyGPS.new(testdisplay: { epd_path: '/tmp/epd', width: 264, height: 176, panel: 'EPD 2.7'}, file: './tracks/test.gpx')

gps.map.simulateToGif(track:'track 1', name: 'out.gif')
```

other examples
```ruby
require 'funkygps'
gps = FunkyGPS.new(testdisplay: { epd_path: '/tmp/epd', width: 264, height: 176, panel: 'EPD 2.7' }, file: './tracks/test.gpx')

gps.screen.update # send current display to screen
gps.screen.to_ascii # send current display as ascii art to terminal (put your terminal font small)
gps.screen.to_file # create a screenshot of current display to screen.png
File.open('test.svg', 'w+') {|f| f.write gps.map.to_svg} # write the svg of the current display to a file

#other details:
puts "the track distances in meters:\n#{ gps.map.tracks.map{|tr| %{\t#{ tr.name }:#{ tr.distanceInMeters } meters\n}}.join('') }"
puts "the track distances in km:\n#{ gps.map.tracks.map{|tr| %{\t#{ tr.name }:#{ tr.distanceInKilometers } km\n}}.join('') }"
puts "the maps square distance is #{ gps.map.realWidth.round } meters by #{ gps.map.realHeight.round } meters"
puts "the maps viewBox square distance is #{ gps.map.viewbox.realWidth.round } meters by #{ gps.map.viewbox.realHeight.round } meters"
puts "the current bearing of the signal is #{ gps.map.signal.currenDirection } degrees"
```
## Development
```bash
# Install enviroment with bundler
$ (sudo) gem install bundler # If you did not already
$ bundle # Installs all gems
# Activate yard doctest plugin
$ bundle exec yard config load_plugins true
$ bundle exec yard config -a autoload_plugins yard-doctest
# Run the unit tests right from the doumentation
bundle exec rake yarn:doctest
# Create the documentation with
bundle exec rake yarn
# Start a irb session
bundle exec irb -r ./lib/funkygps
# or, for example, create a animated gif of a track with
$ echo "gps = FunkyGPS.new(testdisplay: { epd_path: '/tmp/epd', width: 264, height: 176, panel: 'EPD 2.7' }, file: './tracks/track1.gpx'); gps.map.setActiveTrack(name: 'track 1');gps.signal.copyTrackPointsToSignal(name:'track 1'); gps.signal.simulateToGif; STDOUT.puts 'done'" |bundle exec irb -r ./lib/funkygps
# where you first select the track, then copy the same track to use as fake gps signal and then simulate that signal
# gps = FunkyGPS.new(file: './tracks/track_direction_test.gpx'); gps.map.setActiveTrack(name: 'track'); gps.signal.simulate
```
## Contributing to funkygps

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Create a PR

## Todo's

* testing by using yarndoc
* zoom in/out.
* distance iand direction to track if not near the track
* intergration of actual GPS Signal
* showing info about next 3 courners to come (distance, and turning degrees)

## Copyright

Copyright (c) 2017 [FunkyForce](http://funkyforce.nl). See LICENSE.txt for further details. (MIT)

