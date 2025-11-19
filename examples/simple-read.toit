// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import gpio
import i2c
import lis331 show *

/**
Simple Accel Read to demonstrate the H3LIS331 device.

*/

ESP32S3-SDA-PIN := 8
ESP32S3-SCL-PIN := 9

main:
  // Initial setup for I2C.
  frequency := 400_000
  sda := gpio.Pin ESP32S3-SDA-PIN
  scl := gpio.Pin ESP32S3-SCL-PIN
  bus := i2c.Bus --sda=sda --scl=scl --frequency=frequency
  scandevices := bus.scan

  // Try both I2C addresses to find the device.
  address/int? := null
  if (bus.test H3lis331dl.I2C-ADDRESS): address = H3lis331dl.I2C-ADDRESS
  if (bus.test H3lis331dl.I2C-ADDRESS-ALT): address = H3lis331dl.I2C-ADDRESS-ALT
  if not address:
    print "No device found."
    return

  // Load the device driver.
  device := bus.device H3lis331dl.I2C-ADDRESS
  driver := H3lis331dl device
  print " Found device 0x$(%02x address) using driver '$(driver.driver-name_)'."

  // Show current power modes.
  print " Current Power Mode: $(driver.get-power-mode)."
  driver.set-power-mode 1
  print " Current Power Mode: $(driver.get-power-mode)."

  // Get one raw reading and show the acceleration and magnitude for it.
  raw := driver.read-raw
  print " Read Raw Values: $(raw)."
  print " Read Accel Values         (g) : $(driver.read-g raw)."
  print " Read Accel Values     (m/s^2) : $(driver.read-ms2 raw)."
  print " Read Accel Magnitude      (g) : $(%0.3f driver.magnitude-g raw)."
  print " Read Accel Magnitude  (m/s^2) : $(%0.3f driver.magnitude-ms2 raw)."
