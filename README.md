# GeigerCounter
This is a sample iOS app that shows how to access to bluetooth 
peripherals using Core Bluetooth `CBCentralManager`

The app sets itself as central and tries to connect to 
peripherals that are advertising a custom battery and geiger counter
services. Each of this services provide characteristics that show the example
of reading, subscribing to notifications and writing to the peripheral.

## Getting started

Just import the project to Xcode and run. The peripheral implementation is
a sample [MacApp](https://github.com/pablocaif/GeigerMeterSimulator)

Bluetooth doesn't work on the simulator so to test this you will need to 
use an actual device.
