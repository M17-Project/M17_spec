---
title: 'File Formats'
taxonomy:
    category:
        - docs
---

This appendix documents the file formats used for testing various M17 layers.

### Glossary

#### Bit numbering, Bit order, Most significant bit (MSB), Least significant bit (LSB)
[Bit numbering](https://en.wikipedia.org/wiki/Bit_numbering) is how bit positions are identified in a binary number.  The least significant bit (LSB) is the bit position respresenting a value of 1.  The most significant bit (MSB) is the bit position representing the highest value position.  Bit order refers to the order in which bits are extracted from a binary number.  This is important especially when sending binary values one bit at a time, or when constructing multiple-bit symbols.  LSB first means the extraction happens from the least significant position first.  MSB first means extraction happens from the most significant position first.

#### Deviation, Frequency Deviation
In this context, how far from the center frequency a carrier is shifted.  This can be positive or negative.  For M17, the frequency deviation of the four symbols are shown in [Physical Layer](https://spec.m17project.org/part-1/physical-layer) Table 1.

#### Deviation Function (Transmit)
A function used to convert symbol values to frequency deviation in RF hardware.  This can be used to set hardware registers, create voltages, etc. depending on the hardware used.

#### Deviation Function (Receive)
A function used to convert frequency deviation in RF hardware to symbol values.  This can be used when reading hardware registers, sampling voltages, etc. depending on the hardware used.

#### Dibit
Two bits used to represent a symbol, as shown in [Physical Layer](https://spec.m17project.org/part-1/physical-layer) Table 1.

#### Endianness, Byte order, Big-endian (BE), Little-endian (LE)
[Endianness](https://en.wikipedia.org/wiki/Endianness) is the order of the bytes in a word of digital data.  In this document, we will refer to big-endian (BE) and little-endian (LE).
BE means that the most significant byte of a word is at the lowest memory location, while LE means that the least significant byte is at the lowest memory location.

#### RF Sample Rate
The rate at which deviation values are updated.  This will vary depending on the hardware.   M17 test software commonly uses 48000 samples per second.

#### Root-raised-cosine (RRC) Filter
A filter used to in digital communications to help reduce intersymbol interference. The M17 [Physical Layer](https://spec.m17project.org/part-1/physical-layer) specifies a root-raised-cosine (RRC) filter with alpha = 0.5  [Root Raised Cosine](https://en.wikipedia.org/wiki/Root-raised-cosine_filter)

#### Symbol
An M17 [Physical Layer](https://spec.m17project.org/part-1/physical-layer) symbol of +3, +1, -1, and -3.

#### Symbol Rate
The rate at which new symbols are generated.  For M17, this is 4800 symbols per second.

### File Extensions
Multiple files are used when testing the different elements of the M17 protocol.  File extensions (the three characters after a period in a complete file name) are defined to standardize formats and usage.

Extension | Description | Data Format | Data Rate
--------- | ----------- | ----------- | ---------
aud       | mono audio  | Signed 16-bit LE | 8000 samples per second
sym       | M17 symbols | Signed 8-bit | 4800 symbols per second
bin       | Packed M17 Dibits | MSB first, Unsigned 8-bit | 4800 symbols per second (1200 bytes per second)
rrc       | RRC filtered and Scaled M17 symbols | Signed 16-bit LE | 48000 samples per second
rf        | RF deviation values | Varies | Varies   

#### aud
Mono audio of signed 16-bit LE at a rate of 8000 samples per second.  This is often referred to as a "raw" audio file and contains no embedded header information.

#### sym
M17 symbols (+3, +1, -1, -3) encoded as signed 8-bit values at rate of 4800 symbols per second.

#### bin
M17 symbols packed 2 bits per symbol (dibits), 4 symbols per byte (+3 = 01, +1 = 00, -1 = 10, -3 = 11) with the MSB first.  These are unsigned 8-bit values at 4800 symbols per second, which is 4 symbols per byte at 1200 bytes per second.

#### rrc
RRC filtered and scaled M17 symbols.  In order to generate a reasonable RRC waveform, the symbol rate (4800 symbols per second) is upsampled by a factor of 10 to an RRC sample rate of 48000 samples per second.  Then the upsampled symbols are passed through the RRC filter.  The output samples of the RRC filter are multiplied by 7168 to fit within a signed 16-bit LE representation (e.g. a +3 value would be +21504).

#### rf
RF hardware specific deviation values.  These would be obtained by passing RRC filtered values through a deviation function.  Since these are device specific, it is recommended to use an underscore plus device type as part of the filename.  For example, the Semtech SX1276 uses a deviation step size of 61 Hz per bit.  An M17 1600 Hz frequency step is equivalent to an SX1276 deviation value change of 26.  Since the SX1276 only accepts positive deviation steps, the deviation function for the SX1276 would be (rrc value + 3.0) x 13.  The .rf file specific for the SX1276 would contain those values, and could have a name such as m17test_sx1276.rf       

### Example file flows
These show the file types in order of processing for transmit and receive flows.  Each "->" symbolizes processing required to move from one file type to the next.

#### Transmit

aud -> sym -> rrc -> rf

aud -> bin -> rrc -> rf

#### Receive

rf -> rrc -> sym -> aud

rf -> rrc -> bin -> aud

### To-DO
File formats for packet and voice + data streams.
