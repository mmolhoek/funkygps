# FunkyGPS

FunkyGPS is a gps application, written in Ruby, available as gem.
It is created with a specific type of GPS usage in mind, namely offroad/enduro trips
but you can use it for any other trip you could think of (walking, biking, auto/motor on the road, you name it)
In this readme I will try to expain how to build it and how you can build it yourself.

Why I build it? have a look at my post on [Medium](https://medium.com/) explaining the reasons :)

To build this project I used an [Raspberry Pi Zero W](https://www.pi-supply.com/product/raspberry-pi-zero-w/), an [Adafruit Ultimate GPS](https://www.pi-supply.com/product/adafruit-ultimate-gps-breakout-66-channel-10-hz-updates/), and the 2.7 inch [PaPiRus ePaper display](https://www.pi-supply.com/product/papirus-epaper-eink-screen-hat-for-raspberry-pi/), but all other sizes should work to.

There are some other things you need, I will add a shopping list at the bottom
Lets get started

## prepping the Pi harddisk (micro sd) and connecting to it with ssh

please have a look at [PiBakery](http://www.pibakery.org/) as this is the easiest way to prep your sd-card with wifi acces point and password configured
so you can ssh right onto your pi after first boot.

## installing the dependencies (on the Raspberry Pi):
```bash
ssh pi@raspberrypi #or whatever name you gave it in PiBakery
# check which ones are needed: sudo apt-get install git python-imaging python-smbus bc i2c-tools python-dateutil fonts-freefont-ttf -y
sudo apt-get install git bc i2c-tools fonts-freefont-ttf imagemagick -y

# also enable the SPI and the I2C interfaces. and set the timezone if you did not do that in PiBakery already
sudo raspi-config

# Install fuse driver which is used by the PaPiRus display driver
sudo apt-get install libfuse-dev -y
```

After a first auto install setup of the display (don't install this one, read on) [driver](https://github.com/PiSupply/PaPiRus.git) to test if the screen was working,
I found out that both the PaPiRus and the GPS use pin 10 (gpio 16) and pin 08 (gpio 15), the UART ports luckely we can compile the PaPiRus driver,
telling it we want it to use other pins, which is not used by the PaPiRus yet and not used by the GPS. Let's do this now.

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
sudo papirus-set 2.7
```

Now that all driver stuff is done, you should test if it is all functioning correctly.

Have a look at the Ruby display driver [gem papirus](https://github.com/mmolhoek/papirus), that I created prior to this project to be able to talk to the driver from Ruby.
Try loading an image as explained [here](https://github.com/mmolhoek/papirus#playing-with-rmagic). If this works, you are ready to move on.

FunkyGPS also uses this gem internally to update the display as it goes.

After your sure the display is up and running, Lets move on to using FunkyGPS

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

* testing by using yarndoc
* zoom in/out.
* distance iand direction to track if not near the track
* intergration of actual GPS Signal
* showing info about next 3 courners to come (distance, and turning degrees)

## Copyright

Copyright (c) 2017 [FunkyForce](http://funkyforce.nl). See LICENSE.txt for further details. (MIT)

