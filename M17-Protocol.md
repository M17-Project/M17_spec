**TODO**:
* Better formatting and spell checking.

# M17 RF Protocol: Summary
M17 is an RF protocol that is:
* Completely open: open specification, open source code, open source hardware, open algorithms. Anyone must be able to build an M17 radio and interoperate with other M17 radios without having to pay anyone else for the right to do so.
* Optimized for amateur radio use.
* Simple to understand and implement.
* Capable of doing the things hams expect their digital protocols to do:
  * Voice (eg: DMR, D-Star, etc)
  * Point to point data (eg: Packet, D-Star, etc)
  * Broadcast telemetry (eg: APRS, LoRa, etc)
* Extensible, so we can add more capabilities over time.

To do this, the M17 protocol is broken down into three protocol layers, like a network:
1. Physical Layer: How to encode 1s and 0s into RF. Specifies RF modulation, symbol rates, bits per symbol, etc.
1. Data Link Layer: How to packetize those 1s and 0s into usable data.  Packet vs Stream modes, headers, addressing, etc.
1. Application Layer: Accomplishing activities. Voice and data streams, control packets, beacons, etc.

This document attempts to document these layers.

# Physical Layer
**TODO**: Flesh this out.
4GFSK, 4800 baud, 9600 bps.

# Data Link Layer
The Data Link layer is split into two modes:
1. Packet Mode: Data are sent in small bursts, on the order of 100s to 1000s of bytes at a time, after which the Physical layer stops sending data.  eg: Link Controll messages, beacons, etc.
1. Stream Mode: Data are sent in a continuous stream for an indefinite amount of time, with no break in Physical layer output, until the stream ends.  eg: Voice data, bulk data transfers, etc.

When the Physical Layer is idle (no RF being transmitted or received), the Data Link defaults to Packet mode.  To switch to Stream mode, a Link Control packet (detailed later) is sent, immediately followed by the switch to Stream mode; the Stream of data immediately follows the Link Control packet without disabling the Physical layer.  To switch out of Stream mode, the stream simply ends and returns the Physical layer to the idle state, and the Data Link defaults back to Packet mode.

## Data Link Layer: Packet Mode
In Packet Mode, a finite amount of payload data (eg: Link Control messages, or Application Layer data) is wrapped with a packet, sent over the Physical Layer, and is completed when done.  Any acknowlement or error correction is done at the application layer.

### Packet Format:
The M17 Packet format borrows heavily from Ethernet, except the Preamble and Sync:
* Preamble: 8 bytes
  * **TODO** Depends on Physical Layer. ADF7021 datasheet suggests 0xAAAAAA for 2FSK, but 0x0202 for 4FSK.
* Sync: 3 bytes
  * **TODO** Something long and arbitrary, like e or Pi.
* Packet Indicator: 1 byte
  * A value to indicate this is a Packet, not a Stream.
* Destination address: 6 bytes  (See below for address encoding.)
* Source address: 6 bytes  (See below for address encoding.)
* Length: 2 bytes (Number of bytes in payload)
* Payload: N bytes
* CRC: 4 bytes (32-bit CRC of the entire frame, not including the preamble or sync byte. Includes Destination, Source, Lengh, and Payload.)

**Note:** The Preamble and Sync are different than Ethernet. These are constants that depend more on the Physical layer than the Data Link. The values used here are chosen for the M17 Physical layer.  When bridging M17 packets to Ethernet, the Preamble and Sync are replaced with Ethernet values.

**TODO** More detail here about endianness, etc.  Use Ethernet definitions unless we have a specific reason not to.

## Data Link Layer: Stream Mode
In Stream Mode, an indefinite amount of payload data is sent continuously without breaks in the Physical layer.  The Stream is broken up into parts, called Frames to not confuse them with Packets sent in Packet mode.  Frames contain payload data wrapped with framing (similar to packets).

A portion of each Frame contains a portion of the Link Control packet that was used to establish the Stream.  Frames are grouped into Super Frames, which is the group of Frames that contain everything needed to rebuild the original Link Control packet, so that a receiver who starts listening in the middle of a stream is eventually able to reconstruct the Link Control message and understand how to receive the in-progress stream.

### Frame Format:
Stream frames are 60 bytes, formatted like this:
* Sync: 3 bytes  (Same Sync from Packet mode)
* Stream Indicator: 1 byte
* Payload: 48 bytes
* CRC: 4 bytes
* Preamble/Link Control: 4 bytes
  * Every frame of the Super Frame except the last, this contains 4 bytes of the Link Control message that established this stream.
  * The last frame of the Super Frame, this contains 4 bytes of Preamble.  Combined with the immediately following Sync header of the next frame, these two will wake-up a receiver in progress.
 
Assuming a 9600bps Physical layer, this Stream Frame format gives 7680bps of payload throughput.  All ECC is done at the application layer.

# Application Layer
This section describes the actual Packet and Stream payloads.

## Packet Formats
### Link Control Packet

### Identity Beacon Packet

## Stream Formats
These formats must fit in the 48 byte payload of the Stream Mode Frame specified above.

A Frame will be sent 20 times a second, or one frame every 50ms.  The application is responsible for padding any unneeded space.

### Voice Streams
#### CODEC2 3200
CODEC2 3200 needs to send a 64 bit, 4 byte, CODEC frame every 20ms.  Stream frames are sent every 50ms, so Stream frames will alternate between 2 CODEC frames and 3 CODEC frames.



### File Transfer Stream

# Address Encoding
M17 addresses are 48 bits, 6 bytes long.  Callsigns (and other addresses) are encoded into these 6 bytes in the following ways:
* An address of 0 is invalid.
  * **TODO** Do we want to use zero as a flag value of some kind?
* Address values between 1 and 262143999999999 (which is (40^9)-1), up to 9 characters of text are encoded using base40, described below.
* Address values between 262144000000000 (40^9) and 281474976710655 ((2^48)-1) are invalid
  * **TODO** Can we think of something to do with these 19330976710655 addresses?
* An address of 0xFFFFFFFFFFFF is a broadcast.  All stations should receive and listen to this message.

## Callsign Encoding: base40
9 characters from an alphabet of 40 possible characters can be encoded into 48 bits, 6 bytes.  The base40 alphabet is:
* 0: An invalid character, something not in the alphabet was provided.
* 1-26: 'A' through 'Z'
* 27-36: '0' through '9'
* 37: '-'
* 38: '/'
* 39: TBD

Encoding is little endian.  That is, the right most characters in the encoded string are the most significant bits in the resulting encoding.

### Example code: encode_base40() 
```
uint64_t encode_callsign_base40(const char *callsign) {
   uint64_t encoded = 0;
   for (const char *p = (callsign + strlen(callsign) - 1); p >= callsign; p-- ) {
      encoded *= 40;
      // If speed is more important than code space, you can replace this with a lookup into a 256 byte array.
      if (*p >= 'A' && *p <= 'Z')  // 1-26
         encoded += *p - 'A' + 1;
      else if (*p >= '0' && *p <= '9')  // 27-36
         encoded += *p - '0' + 27;
      else if (*p == '-')  // 37
         encoded += 37;
      // These are just place holders. If other characters make more sense, change these.
      // Be sure to change them in the decode array below too.
      else if (*p == '/')  // 38
         encoded += 38;
      else if (*p == '.')  // 39
         encoded += 39;
      else
         // Invalid character, represented by 0.
         //encoded += 0;
         ;
   }
   return encoded;
}
```
### Example code: decode_base40()
```
char *decode_callsign_base40(uint64_t encoded, char *callsign) {
   if (encoded >= 262144000000000) {   // 40^9
      *callsign = 0;
      return callsign;
   }

   char *p = callsign;
   for (; encoded > 0; p++) {
      *p = "xABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-/."[encoded % 40];
      encoded /= 40;
   }
   *p = 0;
   return callsign;
}
```

### Why base40?
The longest commonly assigned callsign from the FCC is 6 characters. The minimum alphabet of A-Z, 0-9, and a "done" character mean the most compact encoding of an American callsign could be: log2(37^6)=31.26 bits, or 4 bytes.

But I'm not convinced that 6 character is a global maximum.  Also, we want to extend our callsigns (see below).  So we want more than 6 characters.  How many bits do we need to represent more characters:
* 7 characters: log2(37^7)=36.47 bits, 5 bytes
* 8 characters: log2(37^8)=41.67 bits, 6 bytes
* 9 characters: log2(37^9)=46.89 bits, 6 bytes
* 10 characters: log2(37^10)=52.09 bits, 7 bytes.

Of these, 9 characters into 6 bytes seems the sweet spot.  Given 9 characters, how large can we make the alphabet without using more than 6 bytes?
* 37 alphabet: log2(37^9)=46.89 bits, 6 bytes
* 38 alphabet: log2(38^9)=47.23 bits, 6 bytes
* 39 alphabet: log2(39^9)=47.57 bits, 6 bytes
* 40 alphabet: log2(40^9)=47.90 bits, 6 bytes
* 41 alphabet: log2(41^9)=48.22 bits, 7 bytes

Given this, 9 characters from an alphabet of 40 possible characters, makes maximal use of 6 bytes.

## Callsign Formats
Government issued callsigns should be able to encode directly with no changes.

### Multiple Stations
To allow for multiple stations by the same operator, we borrow the use of the '-' character from AX.25.  A callsign  such as "KR6ZY-1" is considered a different station than "KR6ZY-2" or even "KR6ZY", but it is understood that these all belong to the same operator, "KR6ZY."

### Temporary Modifiers
Similarly, suffixes are often added to callsign to indicate temporary changes of status, such as "KR6ZY/M" for a mobile station, or "KR6ZY/AE" to signify that I have Amateur Extra operating privileges even though the FCC database may not yet be updated.  So the '/' is included in the base40 alphabet.

The difference between '-' and '/' is that '-' are considered different stations, but '/' are NOT.  They are considered to be a temporary modification to the same station.  **TODO** I'm not sure what impact this actually has.

### Interoperability
It may be desirable to bridge information between M17 and other networks.  The 9 character base40 encoding allows for this:

**TODO** Define more interoperability standards here.  System Fusion? P25? IRLP? AllStar?

#### DMR
DMR unfortunately doesn't have a guaranteed single name space.  Individual IDs are reasonably well recognized to be managed by https://www.radioid.net/database/search#! but Talk Groups are much less well managed.  Talk Group XYZ on Brandmeister may be (and often is) different than Talk Group XYZ on a private cBridge system.

* DMR IDs are encoded as: `D<number>`  eg: `D3106728` for KR6ZY
* DMR Talk Groups are encoded by their network.  Currently, the following networks are defined:
  * Brandmeister: `BM<number>`  eg:  `BM31075`
  * More networks to be defined here.

#### D-Star
D-Star reflectors have well defined names: REFxxxY which are encoded directly into base40.

**TODO** Individuals?  Just callsigns?


#### Interoperability Challenges
* We'll need to provide a source ID on the other network.  Not sure how to do that, and it'll probably be unique for each network we want to interoperate with.  Maybe write the DMR/BM gateway to automatically lookup a callsign in the DMR database and map it to a DMR ID?  Just thinking out loud.
* We will have to transcode CODEC2 to whatever the other network uses (pretty much AMBE of one flavor or another.)  I'd be curious to see how that sounds.
