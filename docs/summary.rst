M17 RF Protocol: Summary
========================

M17 is an RF protocol that is:

* Completely open: open specification, open source code, open source
  hardware, open algorithms. Anyone must be able to build an M17 radio
  and interoperate with other M17 radios without having to pay anyone
  else for the right to do so.
* Optimized for amateur radio use.
* Simple to understand and implement.
* Capable of doing the things hams expect their digital protocols to
  do:
  
  * Voice (eg: DMR, D-Star, etc)
  * Point to point data (eg: Packet, D-Star, etc)
  * Broadcast telemetry (eg: APRS, etc)
  * Extensible, so more capabilities can be added over time.

To do this, the M17 protocol is broken down into three protocol layers, like a network:

#. Physical Layer: How to encode 1s and 0s into RF. Specifies RF
   modulation, symbol rates, bits per symbol, etc.
#. Data Link Layer: How to packetize those 1s and 0s into usable
   data. Packet vs Stream modes, headers, addressing, etc.
#. Application Layer: Accomplishing activities. Voice and data
   streams, control packets, beacons, etc.

This document attempts to document these layers.
