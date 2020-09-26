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


Standard IP Framing
-------------------

M17 over IP is big endian, consistent with other IP protocols.
We have standardized on UDP port 17000, this port is recommended but not required.
Later specifications may require this port.

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


The CRC checksum must be recomputed after modification or re-assembly
of the packet, such as when translating from RF to IP framing.

Example packet dissection
-------------------------
.. raw:: html
    <embed>
      <style>
      .m17_magic{
         background-color: grey;
         border: 1px dashed #055;
      .m17_streamid{
         background-color: #055;
         border: 1px dashed grey;
      }
      }
      .m17_addr{
      }
      .m17_dst{
      }
      .m17_src{
      }
      .m17_streamtype{
      }
      .m17_nonce{
      }
      .m17_frame_number{
      }
      .m17_payload{
      }
      .m17_crc{
      }
      </style>
      <span class="m17_magic">
      4d 31 37 20 
      </span>
      <span class="m17_streamid">
      cc cc 
      </span>
      <span class="m17_dst m17_addr">
      00 99 6a 41 93 f8 
      </span>
      <span class="m17_src m17_addr">
      00 00 01 61 
      <br>
      ae 1f 
      </span>
      <span class="m17_streamtype">
      00 05 
      </span>
      <span class="m17_nonce">
      41 41 41 41 41 41 41 41 41 41 41 41 
      <br>
      41 41 
      </span>
      <span class="m17_frame_number">
      00 0d 
      </span>
      <span class="m17_payload">
      42 42 42 42 42 42 42 42 42 42 42 42 
      <br>
      42 42 42 42 
      <span class="m17_crc">
      ff ff 
      </span>
      <br>
    </embed>

.. todo:: RF->IP & IP->RF bridging reassembly, UDP NAT punching, callsign routing lookup

.. points_of_contact:: N7TAE, W2FBI
