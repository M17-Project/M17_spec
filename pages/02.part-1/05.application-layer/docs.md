---
title: 'Application Layer'
taxonomy:
    category:
        - docs
media_order: 'LFSR_8.svg,LFSR_16.svg,LFSR_24.svg'
---

### M17 Voice Application

This section defines the application layer parameters for an audio stream containing low bit rate speech encoded using the open source [Codec 2](http://rowetel.com/codec2.html) codec.

[Data Link Layer Stream Mode](../04.data-link-layer/#stream-mode) is used for this application.  

#### M17 Voice Application LSF Parameters

A Stream Mode Transmission begins with an [LSF](../04.data-link-layer/#link-setup-frame-lsf).  

<center><span style="font-weight:bold">Table 3</span> Link Setup Frame Contents</center>
Field | Length   | Description
----- | ------   | -----------
DST   | 48 bits  | Destination address - Encoded callsign or a special number (eg. a group)
SRC   | 48 bits  | Source address - Encoded callsign of the originator or a special number (eg. a group)
TYPE  | 16 bits  | Information about the incoming data stream
META  | 112 bits | Metadata field, suitable for cryptographic metadata like IVs or single-use numbers, or non-crypto metadata like the sender’s GNSS position.

Destination (DST) and source (SRC) addresses may be encoded amateur radio callsigns, or special numbers.  See the [Address Encoding Appendix](../../appendix/address-encoding) for details.

The TYPE field contains information about the frames to follow LSF. 

<center><span style="font-weight:bold">Table 4</span> LSF TYPE definition</center>
Bits   | Meaning
----   | -------
0      | Packet/Stream indicator
<nbsp> | 1 = Stream Mode
1..2   | Data type indicator
<nbsp> | $10_2$ = Voice only (3200 bps)
3..4   | Encryption type
<nbsp> | $00_2$ = None 
<nbsp> | $01_2$ = Scrambling
<nbps> | $10_2$ = AES
5..6   | Encryption subtype
<nbsp> | foo
7..10  | Channel Access Number (CAN)
<nbsp> | foo
11..15 | Reserved (don’t care)

This application requires Stream Mode.

The Voice only Data type indicator specifies voice data encoded at 3200 bps using Codec 2.

#### Encryption Types

Encryption is **optional**. The use of it may be restricted within some radio services and countries, and should only be used if legally permissible.

##### Null Encryption

Encryption type = $00_2$

The “Encryption SubType” bits in the Stream Type field then indicate what data is stored in the 112 bits of the LSF META field.

Encryption SubType bits | LSF META data contents
----------------------- | ----------------------
$00_2$                  | UTF-8 Text
$01_2$                  | GNSS Position Data
$10_2$                  | Reserved
$11_2$                  | Reserved

All LSF META data must be stored in big endian byte order.

GNSS Position Data stores the 112 bit META field as follows:

Size in bits | Format                  | Contents
------------ | ------                  | --------
8            | 8-bit signed integer    | Latitude  - degrees, integer part (-90..+90, positive values for northern hemisphere)
16           | 16-bit unsigned integer | Latitude - degrees, fractional part (eg. 0.5 -> 32,768)
16           | 16-bit unsigned integer | Longitude - degrees, integer part (-180..+180, positive values for eastern hemisphere)
16           | 16-bit unsigned integer | Longitude Longitude - degrees, fractional part (eg. 0.5 -> 32,768)
16           | unsigned integer | Altitude, in feet MSL. Stored +1500, so a stored value of 0 represents -1500 MSL. Subtract 1500 feet when parsing.
10           | unsigned integer | Course in degrees true North
10           | unsigned integer | Speed in miles per hour
20           | reserved values | Transmitter/Object description field

##### Scrambling

Encryption type = $01_2$

Scrambling is an encryption by bit inversion using a bitwise exclusive-or (XOR) operation between the bit sequence of data and a pseudorandom bit sequence.

Pseudorandom bit sequence is generated using a Fibonacci-topology Linear-Feedback Shift Register (LFSR). Three different LFSR sizes are available: 8, 16 and 24-bit. Each shift register has an associated polynomial. The polynomials are listed in Table 7. The LFSR is initialised with a seed value of the same length as the shift register. The seed value acts as an encryption key for the scrambler algorithm. Figures 5 to 8 show block diagrams of the algorithm

Encryption subtype | LFSR polynomial                         | Seed length | Sequence period
------------------ | ---------------                         | ----------- | ---------------
$00_2$             | $x^8 + x^6 + x^5 + x^4 + 1$             | 8 bits      | 255
$01_2$             | $x^{16} + x^{15} + x^{13} + x^4 + 1$    | 16 bits | 65,535
$10_2$             | $x^{24} + x^{23} + x^{22} + x^{17} + 1$ | 24 bits | 16,777,215


![LSFR_8](LFSR_8.svg?classes=caption "8-bit LSFR taps")

---

![LSFR_16](LFSR_16.svg?classes=caption "16-bit LSFR taps")

---

![LSFR_24](LFSR_24.svg?classes=caption "24-bit LSFR taps")

---

#### Advanced Encryption Standard (AES)

Encryption type = $10_2$

This method uses AES block cipher in counter (CTR) mode, with a 96-bit nonce that should never be used for more than one separate stream and a 32 bit CTR.

The 96-bit AES nonce value is extracted from the 96 most significant bits of the META field, and the remaining 16 bits of the META field form the highest 16 bits of the 32 bit counter.  The FN (Frame Number) field value is then used to fill out the lower 16 bits of the counter, and always starts from 0 (zero) in a new voice stream.

The 16 bit frame number and 40 ms frames can provide for over 20 minutes of streaming without rolling over the counter.

> The effective capacity of the counter is 15 bits, as the MSB is used for transmission end signalling. At 40ms per frame, or 25 frames per second, and 2\*\*15 frames, we get 2\*\*15 frames / 25 frames per second = 1310 seconds, or 21 minutes and some change.

The random part of the nonce value should be generated with a hardware random number generator or any other method of generating non-repeating values. 

To combat replay attacks, a 32-bit timestamp shall be embedded into the cryptographic nonce field. The field structure of the 96 bit nonce is shown in Table 9. Timestamp is 32 LSB portion of the number of seconds that elapsed since the beginning of 1970-01-01, 00:00:00 UTC, minus leap seconds (a.k.a. “unix time”).

##### 96 bit nonce field structure

| Timestamp | Random Data | CTR_HIGH |
| --------- | ----------- | -------- |
| 32        | 64          | 16       |

**CTR_HIGH** field initializes the highest 16 bits of the CTR, with the rest of the counter being equal to the FN counter.

!! In CTR mode, AES encryption is malleable. That is, an attacker can change the contents of the encrypted message without decrypting it. This means that recipients of AES-encrypted data must not trust that the data is authentic. Users who require that received messages are proven to be exactly as-sent by the sender should add application-layer authentication, such as HMAC. In the future, use of a different mode, such as Galois/Counter Mode, could alleviate this issue.


##### LSF META

The LSF META field is defined by the specific application.

### Packet Application

Packet superframes are composed of a 1..n byte data type specifier, 0..797 bytes of payload data. The data type specifier is encoded in the same way as UTF-8. It provides efficient coding of common data types. And it can be extended to include a very large number of distinct packet data type codes.

The data type specifier can also be used as a protocol specifier. For example, the following protocol identifers are reserved in the M17 packet spec:

##### Reserved Protocols

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

