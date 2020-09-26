M17 Internet Protocol (IP) Networking
=====================================

Digital modes are commonly networked together through linked repeaters using IP networking.

For commercial protocols like DMR, this is meant for linking metropolitan
and state networks together and allows for easy interoperability between
radio users.
Amateur Radio uses this capability for creating global communications
networks for all imaginable purposes, and makes 'working the world' with
an HT possible.

M17 is designed with this use in mind, and has native IP framing to support it.

In competing radio protocols, a repeater or some other RF to IP bridge
is required for linking, leading to the use of hotspots (tiny simplex
RF bridges).

The TR-9 and other M17 radios may support IP networking directly, such
as through the ubiquitous ESP8266 chip or similar. This allows them to
skip the RF link that current hotspot systems require, finally bringing
to fruition the "Amateur digital radio is just VoIP" dystopian future
we were all warned about.


IP Framing
----------

M17 over IP is big endian, consistent with other IP protocols.
We have standardized on UDP port 17000 for now, so this port is recommended.

.. list-table:: Internet frame fields

   * - MAGIC
     - 32 bits
     - Magic bytes 0x4d313720 ("M17 ")
   * - StreamID (SID)
     - 16 bits
     - Random bits, changed for each PTT or stream, but consistent from frame to frame within a stream
   * - LICH
     - sizeof(LICH)*8 bits
     - A full LICH frame (dst, src, streamtype, nonce) as defined earlier
   * - FN
     - 16 bits
     - Frame number (exactly as would be transmitted as an RF stream frame, including the last frame indicator at (FN & 0x8000)
   * - Payload
     - 128 bits
     - Payload (exactly as would be transmitted in an RF stream frame)
   * - CRC16
     - 16 bits
     - CRC for the entire packet, as defined earlier (TODO: specific link)

.. 
   TODO:
   RF->IP, IP->RF bridging reassembly
   UDP NAT punching
