# Toit Library for ST LIS331 accelerometer module family

![Front and back of one version of the INA219 module](images/h3lis331dl.jpg)

## About the Device

## Quick Start Information

## Core features:

### Comparison of Sibling Models

```
Part	    Type        WHO_AM_I reg	WHO_AM_I value	Confidence
H3LIS331DL	high-g +/-400g	 0x0F	        0x32	        solid (docs + examples)
LIS331HH	high-g +/-24g    0x0F	        0x32	        de facto (libraries)
LIS331DLH	low-g 12-bit     0x0F	        0x32	        solid (datasheet + Linux)
LIS331DL	low-g 8-bit      0x0F	        0x3B	        solid (datasheet)
LIS331DLF	low-g 6-bit      0x0F	        0x52	        solid (datasheet + Linux)
LIS331DLM	low-g 8-bit      0x0F	      (unsure)	        I don’t have trustworthy values
```


# Usage

## Measuring/Operating Modes

### Continuous Mode

### Triggered Mode

### Power-Down



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
