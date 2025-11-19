# Toit Library for ST LIS331 accelerometer module family

## About the Device
ST have a series of devices that are small and low power, with a number of
different ranges/sensitivities.  Given they all have roughly the same register
map/layout, this driver/code has been developed with an H3LIS331DL, but
designed to work with as many of them as possible.

## Quick Start Information
See the examples folder.

## Model Comparison
The following models have had code created for them.  Their driver packages are
extensions of the base class `Lis331Base` which on its own, cannot be used.
| Part | Bits/Max g | Notes | Driver Class Name | Notes |
| - | - | - | - | - |
| H3LIS331DL | 12-bit ±400g | Implemented and Tested | `H3lis331dl` | Device designed to be a crash sensor, so not extremely accurate for fine IMU work. (±1g Accuracy at rest!) |
| LIS331HH | 12-bit ±24g | Implemented | `Lis331hh` |
| LIS331DLH | 12-bit ±8g 	| Implemented | `Lis331dlh` |
| LIS331DL | 8-bit | Not Implemented | - |
| LIS331DLF | 6-bit ±8g | Implemented | `Lis331dlf` |

Data rates for these devices can be configured between 0.5Hz and 1kHz

### Implementing other models
By taking a copy of an implemented class, renaming and adjusting the LSB numbers
etc, it would be possible to add any sibling device with the same register map.

Based on the existing patterns, it seems likely that this package could be used
for the newer suite/generation of IC's, such as the LIS2* and IIS2* product
ranges.  [Raise an issue](https://github.com/milkmansson/toit-lis331/issues) or
get in touch for help with those.

## Issues
If there are any issues, changes, or any other kind of feedback, please
[raise an issue](https://github.com/milkmansson/toit-lis331/issues). Feedback is
welcome and appreciated!

## Disclaimer
- This driver has been written and tested with the Sparkfun H3LIS331 module.
- All trademarks belong to their respective owners.
- No warranties for this work, express or implied.

## Credits
- [Florian](https://github.com/floitsch) for the tireless help and encouragement
- The wider Toit developer team (past and present) for a truly excellent product
- AI has been used for code and text reviews, analysing and compiling data and
  results, and assisting with ensuring accuracy.

## About Toit
One would assume you are here because you know what Toit is.  If you dont:
> Toit is a high-level, memory-safe language, with container/VM technology built
> specifically for microcontrollers (not a desktop language port). It gives fast
> iteration (live reloads over Wi-Fi in seconds), robust serviceability, and
> performance that’s far closer to C than typical scripting options on the
> ESP32. [[link](https://toitlang.org/)]
- [Review on Soracom](https://soracom.io/blog/internet-of-microcontrollers-made-easy-with-toit-x-soracom/)
- [Review on eeJournal](https://www.eejournal.com/article/its-time-to-get-toit)
