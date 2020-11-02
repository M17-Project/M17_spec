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

.. todo:: RF->IP & IP->RF bridging reassembly, UDP NAT punching, callsign routing lookup

.. points_of_contact N7TAE, W2FBI

Control Packets
----------------------

Reflectors use a few different types of control frames, identified by their magic:

* *CONN* - Connect to a reflector
* *ACKN* - acknowledge connection
* *PING/PONG* - keepalives for the connection
* *DISC* - Disconnect (client->reflector or reflector->client)

CONN
~~~~~~~~~~~~~~~

.. table :: Bytes of a CONN packet

  +-------+----------------------------------------------------------------------------------------------------------------+
  | Bytes | Purpose                                                                                                        |
  +=======+================================================================================================================+
  | 0-3   | Magic - ASCII "CONN"                                                                                           |
  +-------+----------------------------------------------------------------------------------------------------------------+
  | 4-9   | 6-byte 'From' callsign including module in last character (e.g. "A1BCD   D") encoded as per `Address Encoding` |
  +-------+----------------------------------------------------------------------------------------------------------------+
  | 10    | Module to connect to - single ASCII byte A-Z                                                                   |
  +-------+----------------------------------------------------------------------------------------------------------------+

.. todo:: it would ne nice to include the destination callsign in full rather than just the module - it's only an extra 5 bytes, and it would allow hosting multiple reflectors on one instance and maybe some other use cases where you want to be explicit about what you're connecting to

A client sends this to a reflector to initiate a connection. The reflector replies with ACKN on successful linking, or NACK on failure.

ACKN
~~~~~~~~~~~~~~~~~

.. table :: Bytes of ACKN packet

  +-------+----------------------------------------------------------------------------------------------------------------+
  | Bytes | Purpose                                                                                                        |
  +=======+================================================================================================================+
  | 0-3   | Magic - ASCII "ACKN"                                                                                           |
  +-------+----------------------------------------------------------------------------------------------------------------+
  | 4-9   | 6-byte callsign including module in last character (e.g. "A1BCD   D") encoded as per `Address Encoding`        |
  +-------+----------------------------------------------------------------------------------------------------------------+

NACK
~~~~~~~~~~~~~~~~~

.. table :: Bytes of NACK packet

  +-------+--------------------------------------------------------------------------------------------------------------------------+
  | Bytes | Purpose                                                                                                                  |
  +=======+==========================================================================================================================+
  | 0-3   | Magic - ASCII "NACK"                                                                                                     |
  +-------+--------------------------------------------------------------------------------------------------------------------------+

PONG
~~~~~~~~~~~~~~~~~

.. table :: Bytes of PONG packet

  +-------+----------------------------------------------------------------------------------------------------------------+
  | Bytes | Purpose                                                                                                        |
  +=======+================================================================================================================+
  | 0-3   | Magic - ASCII "PONG"                                                                                           |
  +-------+----------------------------------------------------------------------------------------------------------------+
  | 4-9   | 6-byte 'From' callsign including module in last character (e.g. "A1BCD   D") encoded as per `Address Encoding` |
  +-------+----------------------------------------------------------------------------------------------------------------+

Upon receing a PING, the client replies with a PONG

DISC
~~~~~~~~~~~~~~~~~

.. table :: Bytes of DISC packet

  +-------+----------------------------------------------------------------------------------------------------------------+
  | Bytes | Purpose                                                                                                        |
  +=======+================================================================================================================+
  | 0-3   | Magic - ASCII "DISC"                                                                                           |
  +-------+----------------------------------------------------------------------------------------------------------------+
  | 4-9   | 6-byte 'From' callsign including module in last character (e.g. "A1BCD   D") encoded as per `Address Encoding` |
  +-------+----------------------------------------------------------------------------------------------------------------+

Sent by either end to force a disconnection. Acknowledged with 4-byte packet "DISC" (without the callsign field)
