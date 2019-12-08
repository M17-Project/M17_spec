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
* Destination address: 6 bytes
* Source address: 6 bytes
* Length: 2 bytes (Number of bytes in payload)
* Payload: N bytes
* CRC: 4 bytes (32-bit CRC of the entire frame, not including the preamble or sync byte. Includes Destination, Source, Lengh, and Payload.)

**Note:** The Preamble and Sync are different than Ethernet. These are constants that depend more on the Physical layer than the Data Link. The values used here are chosen for the M17 Physical layer.  When bridging M17 packets to Ethernet, the Preamble and Sync are replaced with Ethernet values.

**TODO** More detail here about endianness, etc.  Use Ethernet definitions unless we have a specific reason not to.

### Link Control Packets
**TODO** Define a packet that switches from Packet mode to Stream mode.

## Data Link Layer: Stream Mode
In Stream Mode, an indefinite amount of payload data is sent continuously without breaks in the Physical layer.  The Stream is broken up into parts, called Frames to not confuse them with Packets sent in Packet mode.  Frames contain payload data wrapped with framing (similar to packets).

A portion of each Frame contains a portion of the Link Control packet that was used to establish the Stream.  Frames are grouped into Super Frames, which is the group of Frames that contain everything needed to rebuild the original Link Control packet, so that a receiver who starts listening in the middle of a stream is eventually able to reconstruct the Link Control message and understand how to receive the in-progress stream.

### Frame Format:
Stream frames are 64 bytes, formatted like this:
* Sync: 3 bytes  (Same Sync from Packet mode)
* Stream Indicator: 1 byte
* Payload: 52 bytes
* CRC: 4 bytes
* Preamble/Link Control: 4 bytes
  * Every frame of the Super Frame except the last, this contains 4 bytes of the Link Control message that established this stream.
  * The last frame of the Super Frame, this contains 4 bytes of Preamble.  Combined with the immediately following Sync header of the next frame, these two will wake-up a receiver in progress.
 
Assuming a 9600bps Physical layer, this Stream Frame format gives 7800bps of payload throughput.  All ECC is done at the application layer.

# Application Layer
This section describes the actual Packet and Stream payloads.
