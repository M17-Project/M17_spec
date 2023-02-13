---
title: 'Application Layer'
taxonomy:
    category:
        - docs
media_order: 'LFSR_8.svg,LFSR_16.svg,LFSR_24.svg'
---
### M17 Amateur Radio Voice Application

This section defines the application layer parameters for an audio stream containing low bit rate speech encoded using the open source [Codec 2](http://rowetel.com/codec2.html) codec.  It is intended to be used over the air by amateur radio operators worldwide.  Implementation details for M17 clients, repeaters, and gateways ensure that an M17 Amateur Radio Voice Application is legal under all licensing regimes.

Definitions
- M17 Client - an end station that transmits and receives M17 voice
- M17 Repeater - a station that receives and retransmits (repeats) M17 voice
- M17 Gateway - a station that receives and transmits M17 voice, converting to and from different formats (e.g. D-Star, DMR, EchoLink, etc.)

Credit to Jonathan Naylor (G4KLX) for [documenting and implementing](#references-acknowledgements) the details included here.

[Data Link Layer Stream Mode](../04.data-link-layer/#stream-mode) is used for this application.  

A Stream Mode Transmission begins with an [LSF](../04.data-link-layer/#link-setup-frame-lsf).  

#### LSF/LICH

<center><span style="font-weight:bold">Table 16</span> Link Setup Frame Contents</center>
Field | Length   | Description
----- | ------   | -----------
DST   | 48 bits  | Destination address
SRC   | 48 bits  | Source address
TYPE  | 16 bits  | Information about the incoming data stream
META  | 112 bits | Metadata field

##### Address fields

Destination (DST) and source (SRC) addresses may be encoded amateur radio callsigns, or special identifiers.  See the [Address Encoding Appendix](../../appendix/address-encoding) for details on how up to 9 characters of text can be encoded into the 6-byte address value.  

The source address is always the callsign of the station transmitting, be it a client, repeater, or gateway. This is not a problem for a client, but for a repeater/gateway this raises issues about identifying the original source of a transmission.  Having a repeater/gateway always use its own callsign for the source field does ensure that there are no issues with licensing authorities.  To retain identification of the original source for a repeater/gateway, an extended callsign data field will be encoded in the LSF META field.

The destination address used by a client may simply be a callsign for a point to point contact, or may be one of the following special identifiers in the table below.

<center><span style="font-weight:bold">Table 17</span> Client destination address</center>
Identifier       | Address Value  | Description
---------------- | -------------- | -----------
(Callsign)       | varies         | Destination callsign for a point to point contact
ALL              | 0xFFFFFFFFFFFF | Broadcast and any transmission is relayed to any connected reflector
ECHO             | 0x0000000ED87D | Enable the local echo function in a repeater/gateway
INFO             | 0x0000000ECDB9 | Trigger a voice and text announcement of the current linked status of the repeater/gateway 
UNLINK           | 0x0000454F7745 | Unlink from a reflector and trigger an INFO response
(Reflector Name) | varies         | Link to a reflector and trigger an INFO response (if valid and not already linked)

The destination address of locally repeated radio transmission retains its original destination address, and the originator's callsign is encoded in the extended callsign data.  For other transmissions, one of the following special identifiers may be used.

<center><span style="font-weight:bold">Table 18</span> Repeater/gateway destination address</center>
Identifier       | Address Value  | Description
---------------- | -------------- | -----------
(Callsign)       | varies         | Destination callsign for a locally repeated radio transmission
ALL              | 0xFFFFFFFFFFFF | All transmitted reflector traffic, originator's callsign and the currently linked reflector are encoded in the extended callsign data
ECHO             | 0x0000000ED87D | Reply of the built-in echo function, originator's callsign is encoded in the extended callsign data
INFO             | 0x0000000ECDB9 | Voice and text announcement of the current linked status of the repeater/gateway 

##### TYPE field

The TYPE field contains information about the frames to follow LSF. 

<center><span style="font-weight:bold">Table 18</span> M17 Voice LSF TYPE definition</center>
Bits   | Meaning
----   | -------
0      | Packet/Stream indicator
<nbsp> | 1 = Stream Mode
1..2   | Data type indicator
<nbsp> | $10_2$ = Voice only (3200 bps)
3..4   | Encryption type
<nbsp> | $00_2$ = None 
<nbsp> | $01_2$ = Scrambling
<nbsp> | $10_2$ = AES
5..6   | Encryption subtype
7..10  | Channel Access Number (CAN)
11..15 | Reserved (don’t care)

This application requires Stream Mode.

The Voice only Data type indicator specifies voice data encoded at 3200 bps using Codec 2.

#### Encryption Types

Encryption is **optional**. The use of it may be restricted within some radio services and countries, and should only be used if legally permissible.

##### Null Encryption

Encryption type = $00_2$

When no encryption is used, the 14-byte (112-bit) META field of the LSF and corresponding LICH of the stream can be used for transmitting relatively small amounts of extended data without affecting the bandwidth available for the audio. The full 14 bytes of META extended data is potentially decodable every six stream frames, at a 240 ms update rate. The extended data is transmitted in a simple round robin manner, with the only exception being GPS data which should be transmitted as soon as possible after the GPS data is received from its source.

The "Encryption SubType" bits in the Stream Type field indicate what extended data is stored in the META field.

<center><span style="font-weight:bold">Table 19</span> Null encryption subtype bits</center>
Encryption subtype bits | LSF META data contents
----------------------- | ----------------------
$00_2$                  | Text Data
$01_2$                  | GNSS Position Data
$10_2$                  | Extended Callsign Data
$11_2$                  | Reserved

##### Text Data

The first byte of the Text Data is a Control Byte. To maintain backward compatibility, a Control Byte of 0x00 indicates that no Text Data is included.

Up to four Text Data blocks compose a complete message with a maximum length of 52 bytes.  Each block may contain up to 13 bytes of UTF-8 encoded text, and is padded with space characters to fill any unused space at the end of the last used Text Data block. 

The Control Byte is split into two 4-bit fields. The most significant four bits are a bit map of the message length indicating how many Text Data blocks are required for a complete message. There is one bit per used Text Data block, with $0001_2$ used for one block, $0011_2$ for the two, $0111_2$ for three, and $1111_2$ for four.

The least significant four bits indicate which of the Text Data blocks this text corresponds to. It is $0001_2$ for the first, $0010_2$ for the second, $0100_2$ for the third, and $1000_2$ for the fourth. Any received Control Byte is OR-ed together by the receiving station, and once the most significant and least significant four bits are the same, a complete message has been received.

It is up to the receiver to decide how to display this message. It may choose to wait for all of the Text Data to be received, or display the parts as they are received. It is not expected that the data in the text field changes during the course of a transmission.

##### GNSS Data

Unlike Text and Extended Callsign Data, GNSS data is expected to be dynamic during the course of a transmission and to be transmitted quickly after the GNSS data becomes available. To stop the LSF/LICH data stream from being overrun with GNSS data relative to other data types, a throttle on the amount of GNSS data transmitted is needed. It is recommended that GNSS data be sent at an update rate no faster than once every five seconds.

The GNSS data fits within one 14-byte META field, which equates to six audio frames, and takes 240ms to transmit.  This is a simple format of the GNSS data which does not require too much work to convert into, and provides enough flexibility for most cases. This has been tested on-air and successfully gated to APRS-IS, showing a location very close to the position reported by the GPS receiver.

GNSS Position Data stores the 112 bit META field as follows:

<center><span style="font-weight:bold">Table 20</span> GNSS Data encoding</center>
Size in bits | Format            | Contents
------------ | ------            | --------
8            | unsigned integer  | Data Source
<nbsp>       | <nbsp>            | Used to modify the message added to the APRS message sent to APRS-IS
<nbsp>       | <nbsp>            | 0x00 : M17 Client
<nbsp>       | <nbsp>            | 0x01 : OpenRTX
<nbsp>       | <nbsp>            | 0x02..0xFE : reserved
<nbsp>       | <nbsp>            | 0xFF : other data source
8            | unsigned integer  | Station Type
<nbsp>       | <nbsp>            | Translated into suitable APRS symbols when gated to APRS-IS
<nbsp>       | <nbsp>            | 0x00 : Fixed Station
<nbsp>       | <nbsp>            | 0x01 : Mobile Station
<nbsp>       | <nbsp>            | 0x02 : Handheld
8            | unsigned integer  | Whole number absolute value of degrees latitude
16           | unsigned integer  | Decimal degrees of latitude multiplied by 65535, MSB first
8            | unsigned integer  | Whole number absolute value of degrees longitude
16           | unsigned integer  | Decimal degrees of longitude multiplied by 65535, MSB first
8            | unsigned integer  | Latitude N/S, Longitude E/W, Altitude, Speed and Bearing bit fields
<nbsp>       | <nbsp>            | $xxxxxxx0_2$ North Latitude
<nbsp>       | <nbsp>            | $xxxxxxx1_2$ South Latitude
<nbsp>       | <nbsp>            | $xxxxxx0x_2$ East Longitude
<nbsp>       | <nbsp>            | $xxxxxx1x_2$ West Longitude
<nbsp>       | <nbsp>            | $xxxxx0xx_2$ Altitude data invalid
<nbsp>       | <nbsp>            | $xxxxx1xx_2$ Altitude data valid
<nbsp>       | <nbsp>            | $xxxx0xxx_2$ Speed and Bearing data invalid
<nbsp>       | <nbsp>            | $xxxx1xxx_2$ Speed and Bearing data valid
16           | unsigned integer  | Altitude above sea level in feet + 1500 (if valid), MSB first
16           | unsigned integer  | Whole number of bearing in degrees between 0 and 360 (if valid), MSB first 
8            | unsigned integer  | Whole number of speed in miles per hour (if valid)

##### Extended Callsign Data

This is only transmitted from repeaters/gateways and not from clients, who only receive and display this data. These fields should not appear over M17 Internet links as they should only be used over the air from a repeater/gateway.

The META field is split into two callsign fields. The first is always present, and the second is optional. The callsign data is encoded using the standard M17 callsign [Address Encoding](../../appendix/address-encoding) which takes six bytes to encode a nine character callsign. Any unused space in the META field contains 0x00 bytes. The first callsign field starts at offset zero in the META field, and the second callsign if present starts immediately after the first. There are two unused bytes at the end of the META field.

The use of these two callsign fields is as follows:

<center><span style="font-weight:bold">Table 21</span> Extended Callsign Data encoding</center>
Source              | Callsign Field 1 | Callsign Field 2
------------------- | ---------------- | ----------------
Locally Repeated RF | Originator       | Unused
ECHO Reply          | Originator       | Unused
Reflector Traffic   | Originator       | Reflector Name

The extended callsign data is not used under any other circumstances than the above currently.

It is not expected that the data in the extra callsign fields change during the course of a transmission.

##### Scrambling

Encryption type = $01_2$

Scrambling is an encryption by bit inversion using a bitwise exclusive-or (XOR) operation between the bit sequence of data and a pseudorandom bit sequence.

Pseudorandom bit sequence is generated using a Fibonacci-topology Linear-Feedback Shift Register (LFSR). Three different LFSR sizes are available: 8, 16 and 24-bit. Each shift register has an associated polynomial. The polynomials are listed in Table 7. The LFSR is initialized with a seed value of the same length as the shift register. The seed value acts as an encryption key for the scrambler algorithm. Figures 16 to 18 show block diagrams of the algorithm.

<center><span style="font-weight:bold">Table 22</span> Scrambling</center>
Encryption subtype | LFSR polynomial                         | Seed length | Sequence period
------------------ | ---------------                         | ----------- | ---------------
$00_2$             | $x^8 + x^6 + x^5 + x^4 + 1$             | 8 bits      | 255
$01_2$             | $x^{16} + x^{15} + x^{13} + x^4 + 1$    | 16 bits | 65,535
$10_2$             | $x^{24} + x^{23} + x^{22} + x^{17} + 1$ | 24 bits | 16,777,215

---
<center><span style="font-weight:bold">Figure 16</span> 8-bit LFSR taps</center>
![LFSR_8](LFSR_8.svg?classes=caption "8-bit LFSR taps")
---
<center><span style="font-weight:bold">Figure 17</span> 16-bit LFSR taps</center>
![LFSR_16](LFSR_16.svg?classes=caption "16-bit LFSR taps")
---
<center><span style="font-weight:bold">Figure 18</span> 24-bit LFSR taps</center>
![LFSR_24](LFSR_24.svg?classes=caption "24-bit LFSR taps")

##### Advanced Encryption Standard (AES)

Encryption type = $10_2$

This method uses AES block cipher in counter (CTR) mode, with a 96-bit nonce that should never be used for more than one separate stream and a 32-bit CTR.

The 96-bit AES nonce value is extracted from the 96 most significant bits of the META field, and the remaining 16 bits of the META field form the highest 16 bits of the 32-bit counter.  The FN (Frame Number) field value is then used to fill out the lower 16 bits of the counter, and always starts from 0 (zero) in a new voice stream.

The 16-bit frame number and 40 ms frames can provide for over 20 minutes of streaming without rolling over the counter.

> The effective capacity of the counter is 15 bits, as the MSB is used for transmission end signalling. At 40ms per frame, or 25 frames per second, and $2^{15}$ frames, we get $2^{15}$ frames / 25 frames per second = 1310 seconds, or almost 22 minutes.

The random part of the nonce value should be generated with a hardware random number generator or any other method of generating non-repeating values. 

To combat replay attacks, a 32-bit timestamp shall be embedded into the cryptographic nonce field. The field structure of the 96 bit nonce is shown in Table 9. Timestamp is 32 LSB portion of the number of seconds that elapsed since the beginning of 1970-01-01, 00:00:00 UTC, minus leap seconds (a.k.a. “unix time”).

##### 96 bit nonce field structure

<center><span style="font-weight:bold">Table 23</span> Nonce field</center>
| Timestamp | Random Data | CTR_HIGH |
| --------- | ----------- | -------- |
| 32        | 64          | 16       |

**CTR_HIGH** field initializes the highest 16 bits of the CTR, with the rest of the counter being equal to the FN counter. Encryption subtypes are not applicable for this encryption scheme. All parties are assumed to know the key length used for each transmission.

!! In CTR mode, AES encryption is malleable. That is, an attacker can change the contents of the encrypted message without decrypting it. This means that recipients of AES-encrypted data must not trust that the data is authentic. Users who require that received messages are proven to be exactly as-sent by the sender should add application-layer authentication, such as HMAC. In the future, use of a different mode, such as Galois/Counter Mode, could alleviate this issue.

##### Channel Access Number (CAN)

The Channel Access Number (CAN) is a four bit code that may be used to filter received audio, text, and GNSS data. A receiver may optionally allow reception from sources only if their transmitted CAN value matches the receiver's own specified CAN value. 

#### Stream Frames

[Stream Frames](../data-link-layer#stream-frames) will contain the appropriate LICH data (described above). The Stream Contents will include the incrementing 16-bit Frame Number, and 128 bits of Codec 2 data (unencrypted or encrypted).

#### References / Acknowledgements

 - [Jonathan Naylor (G4KLX) Source/Destination and META fields in the M17 Voice Application](https://discourse.m17project.org/t/callsigns-and-extended-use-of-the-meta-field-in-m17/103)
 - [Jonathan Naylor (G4KLX) GPS Encoding in META field](https://discourse.m17project.org/t/the-format-of-the-m17-gps-data/107/3)
 - [Jonathan Naylor (G4KLX) Multi-Mode Digital Voice Modem (MMVDM)](https://github.com/g4klx/MMDVM)


### Packet Application

**!!! Incomplete !!! This is work in progress.**

A single packet of up to 798 bytes of data may be sent in one transmission.

Packets are sent using [Packet Mode](../data-link-layer#packet-mode).

A Stream Mode Transmission begins with an [LSF](../04.data-link-layer/#link-setup-frame-lsf).

Packet superframes are composed of a 1..n byte data type specifier, 0..797 bytes of payload data. The data type specifier is encoded in the same way as UTF-8. It provides efficient coding of common data types. And it can be extended to include a very large number of distinct packet data type codes.

The data type specifier can also be used as a protocol specifier. For example, the following protocol identifiers are reserved in the M17 packet spec:

##### Reserved Protocols

<center><span style="font-weight:bold">Table 24</span> Packet protocol identifiers</center>
Identifier | Protocol
---------- | --------
0x00       | RAW
0x01       | AX.25
0x02       | APRS
0x03       | 6LoWPAN
0x04       | IPv4
0x05       | SMS
0x06       | Winlink

The data type specifier is used to compute the CRC, along with the payload.

