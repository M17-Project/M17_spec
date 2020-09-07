M17 Internet Protocol (IP) Networking
=====================================


Digital modes are commonly networked together through linked repeaters
and hotspots (portable simplex RF patches to the network). For commercial
protocols like DMR, this is meant for linking metropolitan and state
networks together and allows for easy interoperability between radio users.

Amateur Radio uses this capability for creating
global communications networks for all imaginable purposes.

M17 is designed with this in mind, and has native IP framing for native
IP communications, or RF to IP bridging.

The TR-9 and other M17 radios may support IP networking directly, such
as through the ubiquitous ESP8266 chip or similar. This allows them to
skip the show RF link that current hotspot systems require, finally
bringing to fruition the "digital radio is just VoIP" dystopian future
we were all warned about.

.. list-table:: Internet frame fields

   * - MAGIC
     - 32 bits
     - Magic bytes 0x4d313720 ("M17 ")
   * - StreamID (SID)
     - 16 bits
     - Random bits, changed for each PTT or stream, but consistent from frame to frame within a stream.
   * - LICH
     - sizeof(LICH)*8 bits
     - A full LICH frame (dst, src, streamtype, nonce)
   * - FN
     - 16 bits
     - Frame number (exactly as would be transmitted as an RF stream frame)
   * - Payload
     - 128 bits
     - Payload (exactly as would be transmitted in an RF stream frame)
   * - CRC16
     - 16 bits
     - CRC for the entire packet, as defined earlier (TODO: specific link)


Todo:
-----
Big endian
RF->IP, IP->RF bridging reassembly
Official port number udp:17000
UDP NAT punching
magic bytes + streamid
last frame indication
