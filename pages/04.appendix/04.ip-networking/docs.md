---
title: 'IP Networking'
taxonomy:
    category:
        - docs
---

Digital modes are commonly networked together through linked repeaters using IP networking.  
  
For commercial protocols like DMR, this is meant for linking metropolitan and state networks together and allows for easy interoperability between radio users. Amateur Radio uses this capability for creating global communications networks for all imaginable purposes, and makes ‘working the world’ with an HT possible.  
  
M17 is designed with this use in mind, and has native IP framing to support it.  
  
In competing radio protocols, a repeater or some other RF to IP bridge is required for linking, leading to the use of hotspots (tiny simplex RF bridges).  
  
The TR-9 and other M17 radios may support IP networking directly, such as through the ubiquitous ESP8266 chip or similar. This allows them to skip the RF link that current hotspot systems require, finally bringing to fruition the “Amateur digital radio is just VoIP” dystopian future we were all warned about.

## Standard IP Framing

M17 over IP is big endian, consistent with other IP protocols. We have standardized on UDP port 17000, this port is recommended but not required. Later specifications may require this port.

##### Internet Frame Fields

Field          | Size     | Description
-----          | ----     | -----------
MAGIC          | 32 bits  | Magic bytes 0x4d313720 (“M17 “)
StreamID (SID) | 16 bits  | Random bits, changed for each PTT or stream, but consistent from frame to frame within a stream
LICH           | 224 bits | The meaningful contents of a LICH frame (dst, src, streamtype, META field) as defined earlier.
FN             | 16 bits  | Frame number (exactly as would be transmitted as an RF stream frame, including the last frame indicator at (FN & 0x8000)
Payload        | 128 bits | Payload (exactly as would be transmitted in an RF stream frame)
CRC16          | 16 bits  | CRC for the entire packet, as defined earlier [CRC definition](https://spec.m17project.org/part-1/data-link-layer#crc)

The CRC checksum must be recomputed after modification or re-assembly of the packet, such as when translating from RF to IP framing.

## Control Packets

Reflectors use a few different types of control frames, identified by their magic:

* CONN - Connect to a reflector
* ACKN - acknowledge connection
* NACK - deny connection
* PING - keepalive for the connection from the reflector to the client
* PONG - keepalive response from the client to the reflector
* DISC - Disconnect (client->reflector or reflector->client)

#### CONN

##### Bytes of CONN Packet

Bytes | Purpose
----- | -------
0..3  | Magic - ASCII "CONN"
4..9  | 6-byte ‘From’ callsign including module in last character (e.g. “A1BCD D”) encoded as per Address Encoding
10    | Module to connect to - single ASCII byte A-Z

A client sends this to a reflector to initiate a connection. The reflector replies with ACKN on successful linking, or NACK on failure.

#### ACKN

##### Bytes of ACKN Packet

Bytes | Purpose
----- | -------
0..3  | Magic - ASCII "ACKN"

#### NACK

##### Bytes of NACK Packet

Bytes | Purpose
----- | -------
0..3  | Magic - ASCII "NACK"

#### PING

##### Bytes of PING Packet

Bytes | Purpose
----- | -------
0..3  | Magic - ASCII "PING"
4..9  | 6-byte ‘From’ callsign including module in last character (e.g. “A1BCD D”) encoded as per Address Encoding

#### PONG

##### Bytes of PONG Packet

Bytes | Purpose
----- | -------
0..3  | Magic - ASCII "PONG"
4..9  | 6-byte ‘From’ callsign including module in last character (e.g. “A1BCD D”) encoded as per Address Encoding

#### DISC

##### Bytes of DISC Packet

Bytes | Purpose
----- | -------
0..3  | Magic - ASCII "DISC"
4..9  | 6-byte ‘From’ callsign including module in last character (e.g. “A1BCD D”) encoded as per Address Encoding
