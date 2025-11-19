// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.   See README.md.

import log
import binary
import serial.device as serial
import serial.registers as registers
import math show *

/**
Toit driver library for the LIS331 accelerometer module family.

To use this library, consult the README.md and examples.
*/

class Lis331Base:
  static I2C-ADDRESS     := 0x19 // 0b0011001 - SDO/SA0 pin tied to 3v3 - 0x19
  static I2C-ADDRESS-ALT := 0x18 // 0b0011000 - SDO/SA0 pin tied to GND - 0x18
  static DEFAULT-REGISTER-WIDTH_ := 8

  static REG-WHO-AM-I_    := 0x0F //R
  static REG-CTRL-1_      := 0x20 //RW
  static REG-CTRL-2_      := 0x21 //RW
  static REG-CTRL-3_      := 0x22 //RW
  static REG-CTRL-4_      := 0x23 //RW
  static REG-CTRL-5_      := 0x24 //RW
  static REG-HP-FILT-RST_ := 0x25 //R
  static REG-REFERENCE_   := 0x26 //RW
  static REG-STATUS_      := 0x27 //R


  static REG-INTRPT-1-CFG_ := 0x30 //RW
  static REG-INTRPT-1-SRC_ := 0x31 //R
  static REG-INTRPT-1-THS_ := 0x32 //RW
  static REG-INTRPT-1-DUR_ := 0x33 //RW

  static REG-INTRPT-2-CFG_ := 0x34 //RW
  static REG-INTRPT-2-SRC_ := 0x35 //R
  static REG-INTRPT-2-THS_ := 0x36 //RW
  static REG-INTRPT-2-DUR_ := 0x37 //RW

  // REG-CTRL-1_
  static CTRL-1-PWR-MASK_ := 0b11100000 // Power mode selection. Default value: 000 (000: power-down; others: refer to Table 15)
  static CTRL-1-DR-MASK_  := 0b00011000 // Data rate selection. Default value: 00 (00: 50 Hz; others: refer Table 16)
  static CTRL-1-Z-EN_     := 0b00000100 // Enables Z-axis. Default value: 1
  static CTRL-1-Y-EN_     := 0b00000010 // Enables Y-axis. Default value: 1
  static CTRL-1-X-EN_     := 0b00000001 // Enables X-axis. Default value: 1

  // REG-CTRL-2_
  static CTRL-2-BOOT-MASK_  := 0b10000000 // BOOT Reboot memory content. Default value: 0 (0: normal mode; 1: reboot memory content)
  static CTRL-2-HPM-MASK_   := 0b01100000 // High-pass filter mode selection. Default value: 00 (00: normal mode; others: refer to Table 17)
  static CTRL-2-FDS-MASK_   := 0b00010000 // Filtered data selection. Default value: 0 (0: internal filter bypassed; 1: data from internal filter sent to output register)
  static CTRL-2-HPEN2-MASK_ := 0b00001000 // HPen2 High-pass filter enabled for interrupt 2 source. Default value: 0 (0: filter bypassed; 1: filter enabled)
  static CTRL-2-HPEN1-MASK_ := 0b00000100 // HPen1 High-pass filter enabled for interrupt 1 source. Default value: 0 (0: filter bypassed; 1: filter enabled)
  static CTRL-2-HPCF-MASK_  := 0b00000011 // High-pass filter cutoff frequency configuration. Default value: 00 (00: HPc=8; 01: HPc=16; 10: HPc=32; 11: HPc=64

  // REG-CTRL-3_
  static CTRL-3-INTRPT-PIN-ACT-LOW-MASK_ := 0b10000000 // When 0, interupt pins are active high.
  static CTRL-3-PP-OPEN-MASK_            := 0b01000000 // When 0, pins are push/pull, when 1, open drain.
  static CTRL-3-INTRPT2-LATCH-MASK_      := 0b00100000 // When 0, not latched. 1 is latched.
  static CTRL-3-INTRPT2-DATA-SIG-MASK_   := 0b00011000
  static CTRL-3-INTRPT1-LATCH-MASK_      := 0b00000100 // When 0, not latched. 1 is latched.
  static CTRL-3-INTRPT1-DATA-SIG-MASK_   := 0b00000011

  // REG-CTRL-4_
  static CTRL-4-BDU-MASK_   := 0b10000000  // Block data update. Default value: 0 (0: continuous update; 1: output registers not updated between read of MSB and LSB)
  static CTRL-4-B-L-E-MASK_ := 0b01000000  // Big/little endian data selection. Default value: 0 (0: data LSB @ lower address; 1: data MSB @ lower address)
  static CTRL-4-FS-MASK_    := 0b00110000  // Full scale selection. Default value: 00 (00: ±100 g; 01: ±200 g; 11: ±400 g)
  static CTRL-4-SIM-MASK_   := 0b00000001  // SPI serial interface mode selection. Default value: 0 (0: 4-wire interface; 1: 3-wire interface)

  // REG-CTRL-5_
  // 00 Sleep-to-wake function is disabled
  // 11 urned on: The device is in low-power mode (the ODR is defined in CTRL_REG1)
  static CTRL-4-TURN-ON-1-MASK_ := 0b00000010
  static CTRL-4-TURN-ON-0-MASK_ := 0b00000001

  // REG-INTx-CFG_ and REG-INTx-SRC_
  static INTRPT-AND-OR-MASK_ := 0b10000000
  static INTRPT-ACTIVE-MASK_ := 0b01000000 // REG-INTx-SRC_ only.
  static INTRPT-HIGH-Z-MASK_ := 0b00100000
  static INTRPT-LOW-Z-MASK_  := 0b00010000
  static INTRPT-HIGH-Y-MASK_ := 0b00001000
  static INTRPT-LOW-Y-MASK_  := 0b00000100
  static INTRPT-HIGH-X-MASK_ := 0b00000010
  static INTRPT-LOW-X-MASK_  := 0b00000001

  // REG-STATUS_
  static STATUS-ZYXOR-MASK_ := 0b10000000
  static STATUS-ZOR-MASK_   := 0b01000000
  static STATUS-YOR-MASK_   := 0b00100000
  static STATUS-XOR-MASK_   := 0b00010000
  static STATUS-ZYXDA-MASK_ := 0b00001000
  static STATUS-ZDA-MASK_   := 0b00000100
  static STATUS-YDA-MASK_   := 0b00000010
  static STATUS-XDA-MASK_   := 0b00000001

  // Constants.
  static G/float ::= 9.80665

  // Private variables.
  reg_/registers.Registers := ?
  logger_/log.Logger := ?

  constructor.private_ dev/serial.Device --logger/log.Logger:
    reg_ = dev.registers
    logger_ = logger       // Name comes from subclass.

    // Do what is possible to ensure the chosen driver matches the IC present.
    who := read-who-am-i_
    if who != expected-who-am-i_:
      logger_.error "Device is a $who, expecting a $expected-who-am-i_"
        --tags={ "expected": expected-who-am-i_, "found": who}
      throw "Device is not expected. Expected 0x$(%02x expected-who-am-i_) got 0x$(%02x who)"

    // Driver Loaded
    logger_.info "Driver Loaded" --tags={"driver":"$driver-name_"}

    // Setting this by default due to the likelihood of error if not set.
    block-data-updates-while-reading

    // Setting fs range to default (per class).
    set-fs-selection-raw default-full-scale

  // Base versions to ensure a throw if an override not in place
  expected-who-am-i_ -> int:
    throw "expected-who-am-i_ not implemented"

  full-scale-table-g-per-lsb -> Map:
    throw "full-scale-table not implemented"

  default-full-scale -> int:
    throw "default-full-scale not implemented"

  driver-name_ -> string:
    throw "driver-name_ not implemented"

  /**
  Measurement registers.

  A feature exists to ensure that values/readings will not update in the time
    between reading of high and low registers.  If this is a risk, see
    $Lis331Base.CTRL-4-BDU-MASK_.
  */
  read-raw -> Point3i:
    throw "read-raw not implemented"

  configure-defaults_ -> none:
    // e.g. write CTRL_REG1, full-scale bits based on default-full-scale-setting

  /**
  Device ID register.
  */
  read-who-am-i_ -> int:
    return read-register_ REG-WHO-AM-I_

  /**
  Resets the High Pass Filter.

  Instantaneously zero's the content of the internal high-pass filter. If the
    high-pass filter is enabled, all three axes are instantaneously set to 0 g.
    This allows the settling time of the high-pass filter to be overcome.
  */
  high-pass-filter-reset -> none:
    read-register_ REG-HP-FILT-RST_

  /**
  Get the Reference Filter value.

  This register sets the acceleration value taken as a reference for the
    high-pass filter output.  When the filter is turned on (at least one of the
    FDS, HPen2, or HPen1 bits is equal to 1) and the HPM bits are set to 01, a
    filter-out is generated, taking this value as a reference.
  */
  get-reference-filter-value -> int:
    return read-register_ REG-REFERENCE_

  /**
  Set the Reference Filter value.

  This register sets the acceleration value taken as a reference for the
    high-pass filter output.  When the filter is turned on (at least one of the
    FDS, HPen2, or HPen1 bits is equal to 1) and the HPM bits are set to 01, a
    filter-out is generated, taking this value as a reference.
  */
  set-reference-filter-value value/int -> none:
    assert: 0 <= value <= 255
    write-register_ REG-REFERENCE_ value

  /**
  Set Power Mode

  Sets the power mode of the module.  The various 'Low Power' modes affect the
    data rate, as shown in the table in README.md.
  */
  set-power-mode value/int -> none:
    assert: 0 <= value <= 7
    write-register_ REG-CTRL-1_ value  --mask=CTRL-1-PWR-MASK_

  /**
  Get Power Mode

  Sets the power mode of the module.  The various 'Low Power' modes affect the
    data rate, as shown in the table in README.md.
  */
  get-power-mode -> int:
    return (read-register_ REG-CTRL-1_ --mask=CTRL-1-PWR-MASK_)

  /**
  Set Data Rate and Low Pass frequencies.

  The Data Rate configuration, in normal mode operation, selects the data rate
    at which acceleration samples are produced. In low-power modes they define
    the output data resolution. See the table in README.md.
  */
  set-data-rate value/int -> none:
    assert: 0 <= value <= 3
    write-register_ REG-CTRL-1_ value --mask=CTRL-1-DR-MASK_

  is-z-axis-enabled -> bool:
    return (read-register_ REG-CTRL-1_ --mask=CTRL-1-Z-EN_) != 0

  enable-z-axis -> none:
    write-register_ REG-CTRL-1_ 1 --mask=CTRL-1-Z-EN_

  disable-z-axis -> none:
    write-register_ REG-CTRL-1_ 0 --mask=CTRL-1-Z-EN_

  is-y-axis-enabled -> bool:
    return (read-register_ REG-CTRL-1_ --mask=CTRL-1-Y-EN_) != 0

  enable-y-axis -> none:
    write-register_ REG-CTRL-1_ 1 --mask=CTRL-1-Y-EN_

  disable-y-axis -> none:
    write-register_ REG-CTRL-1_ 0 --mask=CTRL-1-Y-EN_

  is-x-axis-enabled -> bool:
    return (read-register_ REG-CTRL-1_ --mask=CTRL-1-X-EN_) != 0

  enable-x-axis -> none:
    write-register_ REG-CTRL-1_ 1 --mask=CTRL-1-X-EN_

  disable-x-axis -> none:
    write-register_ REG-CTRL-1_ 0 --mask=CTRL-1-X-EN_

  read-g raw/Point3i=read-raw -> Point3f:
    scale := full-scale-table-g-per-lsb[get-fs-selection-raw]
    return Point3f (raw.x * scale) (raw.y * scale) (raw.z * scale)

  read-ms2 raw/Point3i=read-raw -> Point3f:
    scale := full-scale-table-g-per-lsb[get-fs-selection-raw]
    return Point3f (raw.x * scale * G) (raw.y * scale * G) (raw.z * scale * G)

  magnitude-g raw/Point3i=read-raw -> float:
    scale := full-scale-table-g-per-lsb[get-fs-selection-raw]
    x := raw.x * scale
    y := raw.y * scale
    z := raw.z * scale
    return sqrt (x*x + y*y + z*z)

  magnitude-ms2 raw/Point3i=read-raw -> float:
    scale := full-scale-table-g-per-lsb[get-fs-selection-raw]
    x := raw.x * scale * G
    y := raw.y * scale * G
    z := raw.z * scale * G
    return sqrt (x*x + y*y + z*z)

  interrupt-pins-active-low -> none:
    write-register_ REG-CTRL-3_ 1 --mask=CTRL-3-INTRPT-PIN-ACT-LOW-MASK_

  interrupt-pins-active-high -> none:
    write-register_ REG-CTRL-3_ 0 --mask=CTRL-3-INTRPT-PIN-ACT-LOW-MASK_

  interrupt-pins-push-pull -> none:
    write-register_ REG-CTRL-3_ 0 --mask=CTRL-3-PP-OPEN-MASK_

  interrupt-pins-open-drain -> none:
    write-register_ REG-CTRL-3_ 1 --mask=CTRL-3-PP-OPEN-MASK_

  interrupt-configure interrupt/int --config/int -> none:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: write-register_ REG-INTRPT-1-CFG_ config
    else if interrupt == 2: write-register_ REG-INTRPT-2-CFG_ config

  interrupt-threshold interrupt/int --threshold/int -> none:
    assert: 1 <= interrupt <= 2
    assert: 0 <= threshold <= 127
    if interrupt == 1: write-register_ REG-INTRPT-1-THS_ threshold
    else if interrupt == 2: write-register_ REG-INTRPT-2-THS_ threshold

  interrupt-duration interrupt/int --duration/int -> none:
    assert: 1 <= interrupt <= 2
    assert: 0 <= duration <= 127
    if interrupt == 1: write-register_ REG-INTRPT-1-DUR_ duration
    else if interrupt == 2: write-register_ REG-INTRPT-2-DUR_ duration

  interrupt-source-clear interrupt/int -> int:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: return read-register_ REG-INTRPT-1-SRC_
    else if interrupt == 2: return read-register_ REG-INTRPT-2-SRC_
    throw "interrupt-source-clear failed."

  interrupt-disable-latching interrupt/int -> none:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: write-register_ REG-CTRL-3_ 0 --mask=CTRL-3-INTRPT1-LATCH-MASK_
    else if interrupt == 2: write-register_ REG-CTRL-3_ 0 --mask=CTRL-3-INTRPT2-LATCH-MASK_

  interrupt-enable-latching interrupt/int -> none:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: write-register_ REG-CTRL-3_ 1 --mask=CTRL-3-INTRPT1-LATCH-MASK_
    else if interrupt == 2: write-register_ REG-CTRL-3_ 1 --mask=CTRL-3-INTRPT2-LATCH-MASK_

  is-interrupt-latching-enabled interrupt/int -> bool:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: return (read-register_ REG-CTRL-3_ --mask=CTRL-3-INTRPT1-LATCH-MASK_) != 0
    else if interrupt == 2: return (read-register_ REG-CTRL-3_ --mask=CTRL-3-INTRPT2-LATCH-MASK_) != 0
    throw "interrupt-enable-latching failed."

  interrupt-data-sig interrupt/int --value/int -> none:
    assert: 1 <= interrupt <= 2
    assert: 0 <= value <= 3
    if interrupt == 1: write-register_ REG-CTRL-3_ value --mask=CTRL-3-INTRPT1-DATA-SIG-MASK_
    else if interrupt == 2: write-register_ REG-CTRL-3_ value --mask=CTRL-3-INTRPT2-DATA-SIG-MASK_

  interrupt-enable-hp-filter interrupt/int -> none:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: write-register_ REG-CTRL-2_ 1 --mask=CTRL-2-HPEN1-MASK_
    else if interrupt == 2: write-register_ REG-CTRL-2_ 1 --mask=CTRL-2-HPEN2-MASK_

  interrupt-disable-hp-filter interrupt/int -> none:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: write-register_ REG-CTRL-2_ 0 --mask=CTRL-2-HPEN1-MASK_
    else if interrupt == 2: write-register_ REG-CTRL-2_ 0 --mask=CTRL-2-HPEN2-MASK_

  is-interrupt-hp-filter-enabled interrupt/int -> bool:
    assert: 1 <= interrupt <= 2
    if interrupt == 1: return (read-register_ REG-CTRL-2_ --mask=CTRL-2-HPEN1-MASK_) != 0
    else if interrupt == 2: return (read-register_ REG-CTRL-2_ --mask=CTRL-2-HPEN2-MASK_) != 0
    throw "interrupt-is-hp-filter-enabled failed."

  /**
  Configures data registers to be little endian.

  FYI:  This driver is configured for Big Endian.  Use of $set-little-endian or
    $set-big-endian may create unusable results.
  */
  set-little-endian -> none:
    write-register_ REG-CTRL-4_ 1 --mask=CTRL-4-B-L-E-MASK_

  /**
  Configures data registers to be big endian.

  FYI:  This driver is configured for Big Endian.  Use of $set-little-endian or
    $set-big-endian may create unusable results.
  */
  set-big-endian -> none:
    write-register_ REG-CTRL-4_ 0 --mask=CTRL-4-B-L-E-MASK_

  /**
  Blocks updates between reads of MSB and LSB. (If >8 bit reads.)
  */
  block-data-updates-while-reading -> none:
    write-register_ REG-CTRL-4_ 1 --mask=CTRL-4-BDU-MASK_

  /**
  Allow updates between reads of MSB and LSB. (If >8 bit reads.)
  */
  allow-data-updates-while-reading -> none:
    write-register_ REG-CTRL-4_ 0 --mask=CTRL-4-BDU-MASK_

  /**
  Sets Full Scale selection

  Values are dependent on the device being used.  See descendant device classes.
  */
  set-fs-selection-raw fs/int -> none:
    assert: 0 <= fs <= 3
    write-register_ REG-CTRL-4_ fs --mask=CTRL-4-FS-MASK_

  /**
  Gets Full Scale selection

  Values are dependent on the device being used.  See descendant device classes.
  */
  get-fs-selection-raw -> int:
    value := read-register_ REG-CTRL-4_ --mask=CTRL-4-FS-MASK_
    //logger_.debug "FS Selection" --tags={"fs":"$(%02b value)"}
    return value

  /**
  Configures SPI to 3-wire mode.
  */
  set-spi-3-wire -> none:
    write-register_ REG-CTRL-4_ 1 --mask=CTRL-4-SIM-MASK_

  /**
  Configures SPI to 4-wire mode.
  */
  set-spi-4-wire -> none:
    write-register_ REG-CTRL-4_ 0 --mask=CTRL-4-SIM-MASK_


  is-zyz-overload -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-ZYXOR-MASK_) != 0

  is-z-overload -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-ZOR-MASK_) != 0

  is-y-overload -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-YOR-MASK_) != 0

  is-x-overload -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-ZOR-MASK_) != 0

  is-zyz-data-ready -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-ZYXDA-MASK_) != 0

  is-z-data-ready -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-ZDA-MASK_) != 0

  is-y-data-ready -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-YDA-MASK_) != 0

  is-x-data-ready -> bool:
    return (read-register_ REG-STATUS_ --mask=STATUS-XDA-MASK_) != 0

  /**
  Parse big-endian 16bit from two separate bytes.
  */
  from-i16-be_ high-byte/int low-byte/int --signed/bool=false -> int:
    high := high-byte & 0xFF
    low := low-byte & 0xFF
    value := (high << 8) | low
    if signed:
      return (value >= 0x8000) ? (value - 0x10000) : value
    else:
      return value

  /**
  Parse little-endian 16bit from two separate bytes.
  */
  from-i16-le_ high-byte/int low-byte/int --signed/bool=false -> int:
    high := high-byte & 0xFF
    low := low-byte & 0xFF
    value := (low << 8) | low
    if signed:
      return (value >= 0x8000) ? (value - 0x10000) : value
    else:
      return value

  /**
  Clamps the supplied value to specified limit.
  */
  clamp-value_ value/any --upper/any?=null --lower/any?=null -> any:
    if (upper != null) and (lower != null):
      assert: upper > lower
    if upper != null: if value > upper:  return upper
    if lower != null: if value < lower:  return lower
    return value

  /**
  Reads and optionally masks/parses register data
  */
  read-register_
      register/int
      --mask/int?=null
      --offset/int?=null
      --width/int=DEFAULT-REGISTER-WIDTH_
      --signed/bool=false -> any:
    assert: (width == 8) or (width == 16) or (width == 32)
    if mask == null:
      if      width == 8:  mask = 0xFF
      else if width == 16: mask = 0xFFFF
      else:                mask = 0xFFFFFFFF
    if offset == null:
      offset = mask.count-trailing-zeros

    register-value/int? := null
    if width == 8:
      if signed:
        register-value = reg_.read-i8 register
      else:
        register-value = reg_.read-u8 register
    if width == 16:
      if signed:
        register-value = reg_.read-i16-be register
      else:
        register-value = reg_.read-u16-be register
    if width == 32:
      if signed:
        register-value = reg_.read-i32-be register
      else:
        register-value = reg_.read-u32-be register

    if register-value == null:
      logger_.error "read-register_: Read failed."
      throw "read-register_: Read failed."

    if ((mask == 0xFFFF) or (mask == 0xFF) or (mask == 0xFFFFFFFF)) and (offset == 0):
      return register-value
    else:
      masked-value := (register-value & mask) >> offset
      return masked-value

  /**
  Writes register data (masked or full register writes)
  */
  write-register_
      register/int
      value/any
      --mask/int?=null
      --offset/int?=null
      --width/int=DEFAULT-REGISTER-WIDTH_
      --signed/bool=false -> none:
    assert: (width == 8) or (width == 16) or (width == 32)
    if mask == null:
      if      width == 8:  mask = 0xFF
      else if width == 16: mask = 0xFFFF
      else:                mask = 0xFFFFFFFF
    if offset == null:
      offset = mask.count-trailing-zeros

    field-mask/int := (mask >> offset)
    assert: ((value & ~field-mask) == 0)  // fit check
    bit-32-ba := ?

    // Full-width direct write
    if ((width == 8)  and (mask == 0xFF)  and (offset == 0)) or
      ((width == 16) and (mask == 0xFFFF) and (offset == 0)) or
      ((width == 32) and (mask == 0xFFFFFFFF) and (offset == 0)):
      if width == 8:
        signed ? reg_.write-i8 register (value & 0xFF) : reg_.write-u8 register (value & 0xFF)
      else if width == 16:
        signed ? reg_.write-i16-be register (value & 0xFFFF) : reg_.write-u16-be register (value & 0xFFFF)
      else:
        bit-32-ba = to-bytes32 (value & 0xFFFFFFFF)
        signed ? reg_.write-i32-be register (value & 0xFFFFFFFF) : reg_.write-bytes register bit-32-ba
      return

    // Read Reg for modification
    old-value/int? := null
    if width == 8:
      if signed :
        old-value = reg_.read-i8 register
      else:
        old-value = reg_.read-u8 register
    else if width == 16:
      if signed :
        old-value = reg_.read-i16-be register
      else:
        old-value = reg_.read-u16-be register
    else:
      if signed :
        old-value = reg_.read-i32-be register
      else:
        old-value = reg_.read-u32-be register


    if old-value == null:
      logger_.error "write-register_: Read existing value (for modification) failed."
      throw "write-register_: Read failed."

    new-value/int := (old-value & ~mask) | ((value & field-mask) << offset)

    if width == 8:
      signed ? reg_.write-i8 register new-value : reg_.write-u8 register new-value
      return
    else if width == 16:
      signed ? reg_.write-i16-be register new-value : reg_.write-u16-be register new-value
      return
    else if width == 32:
      bit-32-ba = to-bytes32 new-value
      signed ? reg_.write-i32-be register new-value : reg_.write-bytes register bit-32-ba
      return
    throw "write-register_: Unhandled Circumstance."

  /**
  Provides strings to display bitmasks nicely when testing.
  */
  bits-grouped_ x/int
      --min-display-bits/int=0
      --group-size/int=4
      --sep/string="."
      -> string:

    assert: x >= 0
    assert: group-size > 0

    // raw binary
    bin := "$(%b x)"

    // choose target width: at least min-display-bits, then round up to a full group
    groups := 0
    leftover := 0
    width := bin.size
    if min-display-bits > width:
      width = min-display-bits
    if group-size > width:
      width = group-size
    leftover = width % group-size
    if leftover > 0:
      width = width + (group-size - leftover)

    // left-pad to target width
    bin = bin.pad --left width '0'

    // group left->right
    out := ""
    i := 0
    while i < bin.size:
      if i > 0: out = "$(out)$(sep)"
      j := i + group-size
      if j > bin.size: j = bin.size
      out = "$(out)$(bin[i..j])"
      i = j

    return out

  /**
  Turns a 32 bit value into a 4xbyte byte array
  */
  to-bytes32 value/int -> ByteArray:
    return #[
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8)  & 0xFF,
      value & 0xFF
    ]

/**
Small class as an integer version of Point3f.
*/
class Point3i:
  x/int? := null
  y/int? := null
  z/int? := null

  constructor .x/int? .y/int? .z/int?:

  constructor --.x/int? --.y/int? --.z/int?:

  stringify -> string:
    return "x=$x y=$y z=$z"



// LIS331HH (high-g, 12 bit)
class Lis331hh extends Lis331Base:
  // Private variables.
  reg_/registers.Registers := ?
  logger_/log.Logger := ?

  static REG-OUT-X-L_     := 0x28 //R
  static REG-OUT-X-H_     := 0x29 //R
  static REG-OUT-Y-L_     := 0x2a //R
  static REG-OUT-Y-H_     := 0x2b //R
  static REG-OUT-Z-L_     := 0x2c //R
  static REG-OUT-Z-H_     := 0x2d //R

  // Public constructor that calls the base private one
  constructor
      dev/serial.Device
      --logger/log.Logger = log.default:
    logger_ = logger.with-name "lis331hh"
    reg_ = dev.registers
    super.private_ dev --logger=logger_

  expected-who-am-i_ -> int:
    return 0x32

  full-scale-table-mg-per-lsb -> Map:
    // fs bits -> mg/LSB
    return {
      0b00: 0.003,  // ±6 g
      0b01: 0.006,  // ±12 g
      0b11: 0.012,  // ±24 g
    }

  default-full-scale-setting -> int:
    return 0b00  // say ±100 g

  read-raw -> Point3i:
    x-low := read-register_ REG-OUT-X-L_
    x-hi := read-register_ REG-OUT-X-H_
    y-low := read-register_ REG-OUT-Y-L_
    y-hi := read-register_ REG-OUT-Y-H_
    z-low := read-register_ REG-OUT-Z-L_
    z-hi := read-register_ REG-OUT-Z-H_
    return Point3i
      ((from-i16-be_ x-hi x-low --signed) >> 4)
      ((from-i16-be_ y-hi y-low --signed) >> 4)
      ((from-i16-be_ z-hi z-low --signed) >> 4)


// LIS331DLH (low-g 12-bit)
// WARNING: DigiKey says "Obsolete – no longer manufactured".
class Lis331dlh extends Lis331Base:
  // Private variables.
  reg_/registers.Registers := ?
  logger_/log.Logger := ?

  static REG-OUT-X-L_     := 0x28 //R
  static REG-OUT-X-H_     := 0x29 //R
  static REG-OUT-Y-L_     := 0x2a //R
  static REG-OUT-Y-H_     := 0x2b //R
  static REG-OUT-Z-L_     := 0x2c //R
  static REG-OUT-Z-H_     := 0x2d //R

  constructor
      dev/serial.Device
      --logger/log.Logger = log.default:
    logger_ = logger.with-name "lis331dlh"
    reg_ = dev.registers
    super.private_ dev --logger=logger_

  expected-who-am-i -> int:
    return 0x32

  full-scale-table-mg-per-lsb -> Map:
    return {
      0b00: 0.001,  // ±2 g
      0b01: 0.002,  // ±4 g
      0b11: 0.0039,  // ±8 g
    }

  default-full-scale-setting -> int:
    return 0b00   // ±2 g

  read-raw -> Point3i:
    x-low := read-register_ REG-OUT-X-L_
    x-hi := read-register_ REG-OUT-X-H_
    y-low := read-register_ REG-OUT-Y-L_
    y-hi := read-register_ REG-OUT-Y-H_
    z-low := read-register_ REG-OUT-Z-L_
    z-hi := read-register_ REG-OUT-Z-H_
    return Point3i
      ((from-i16-be_ x-hi x-low --signed) >> 4)
      ((from-i16-be_ y-hi y-low --signed) >> 4)
      ((from-i16-be_ z-hi z-low --signed) >> 4)



// LIS331DLF (low-g, 8-bit)
// WARNING: Likely obsolete
class Lis331dlf extends Lis331Base:
  // Private variables.
  reg_/registers.Registers := ?
  logger_/log.Logger := ?

  static REG-OUT-X_     := 0x29 //R
  static REG-OUT-Y_     := 0x2b //R
  static REG-OUT-Z_     := 0x2d //R

  constructor
      dev/serial.Device
      --logger/log.Logger = log.default:
    logger_ = logger.with-name "lis331dlf"
    reg_ = dev.registers
    super.private_ dev --logger=logger_

  expected-who-am-i -> int:
    return 0x52

  full-scale-table-g-per-lsb -> Map:
    return {
      0b00: 0.001,  // ±2 g
      0b01: 0.002,  // ±4 g
      0b11: 0.004,  // ±8 g
    }

  default-full-scale-setting -> int:
    return 0b00   // ±2 g

  read-raw -> Point3i:
    x := read-register_ REG-OUT-X_ --signed
    y := read-register_ REG-OUT-Y_ --signed
    z := read-register_ REG-OUT-Z_ --signed
    return Point3i x y z

// H3LIS331DL (high-g, 12 bit)
class H3lis331dl extends Lis331Base:
  static I2C-ADDRESS     := 0x19 // 0b0011001 - SDO/SA0 pin tied to 3v3 - 0x19
  static I2C-ADDRESS-ALT := 0x18 // 0b0011000 - SDO/SA0 pin tied to GND - 0x18

  // Private variables.
  reg_/registers.Registers := ?
  logger_/log.Logger := ?

  static REG-OUT-X-L_     := 0x28 //R
  static REG-OUT-X-H_     := 0x29 //R
  static REG-OUT-Y-L_     := 0x2a //R
  static REG-OUT-Y-H_     := 0x2b //R
  static REG-OUT-Z-L_     := 0x2c //R
  static REG-OUT-Z-H_     := 0x2d //R

  // Public constructor that calls the base private one
  constructor
      dev/serial.Device
      --logger/log.Logger = log.default:
    logger_ = logger.with-name "h3lis331dl"
    reg_ = dev.registers
    super.private_ dev --logger=logger_

  expected-who-am-i_ -> int: return 0x32

  driver-name_ -> string: return "H3Lis331dl"

  full-scale-table-g-per-lsb -> Map:
    // fs bits -> g/LSB
    return {
      0b00: 0.049,  // ±100 g
      0b01: 0.098,  // ±200 g
      0b11: 0.195,  // ±400 g
    }

  default-full-scale -> int:
    return 0b00     // ±100 g

  read-raw -> Point3i:
    x-low := read-register_ REG-OUT-X-L_
    x-hi := read-register_ REG-OUT-X-H_
    y-low := read-register_ REG-OUT-Y-L_
    y-hi := read-register_ REG-OUT-Y-H_
    z-low := read-register_ REG-OUT-Z-L_
    z-hi := read-register_ REG-OUT-Z-H_
    return Point3i
      ((from-i16-be_ x-hi x-low --signed) >> 4)
      ((from-i16-be_ y-hi y-low --signed) >> 4)
      ((from-i16-be_ z-hi z-low --signed) >> 4)
