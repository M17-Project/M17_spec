*************
KISS Protocol
*************

The purpose of this appendix is to document convetions for adapting KISS TNCs
to M17 packet and streaming modes.  M17 is a more complex protocol, both at
the baseband level and at the data link layer than is typical for HDLC-based
protocols commonly used on KISS TNCs.  However, it is well suited for modern
packet data links, and can even be used to stream audio between a host and
a radio.

This appendix assumes the reader is familiar with the streaming and packet
modes defined in the M17 spec.

In all cases, the TNC expects to get the data payload to be sent and is
responsible for frame construction, FEC encoding, puncturing, interleaving
and decorrelation.  It is also responsible for baseband modulation.

For streaming modes, all voice encoding (Codec2) is done on the host and
not on the TNC.

References
==========

 - http://www.ax25.net/kiss.aspx
 - https://packet-radio.net/wp-content/uploads/2017/04/multi-kiss.pdf
 
M17 Protocols
=============

The specification defines KISS TNC modes for M17 packet modes, both RAW
and ENCAPSULATED.  And it defines a bidirectional streaming mode, allowing
KISS protocol to be used to send and receive M17 voice data.

These protocols map to specific KISS TNC ports.  The host tells the TNC what
type of data to transmit based on the TNC port used in host to TNC transfers.
And the TNC tells the host what data it has received by the TNC port set on
TNC to host transfers.

Packet Protocols
================

In order to provide backward compatibility with the widest range of existing
ham radio software, and to make use of features in the the M17 protocol
itself, we will define two distint packet interfaces *RAW* and *ENCAPSULATED*.

The KISS protocol allows us to target specific modems using the modem
identifier in the command byte.  The KISS protocol defines this as an
**HDLC port**.

We will also be extending the KISS protocol, using undefined command codes
to set things like SOURCE and DESTINATION addresses.

M17 Raw Packet Mode
-------------------

Raw packet mode uses only the standard KISS protocol on **HDLC port** 0.  This
is the default port for all TNCs.  Packets are sent using command 0.  Again,
this is normal behavior for KISS client applications.

Sending Data
^^^^^^^^^^^^

In raw mode, the TNC only expects to receive packets from the host, as it
would for any other mode supported AFSK, G3RUH, etc.

If the TNC is configured for half-duplex, the TNC will do P-persistence CSMA
using a 40ms slot time and obey the P value set via the KISS interface.  CSMA
is disabled in full-duplex mode.

The **TX Delay** and **TX Tail** values are ignored as the M17 preamble length is
pre-defined.

The TNC sends the preamble burst.

The TNC is responsible for constructing the link setup frame, identifying the
content as a raw mode packet.  The source field is an encoded TNC identifier,
similar to the APRS TOCALL, but it can be an arbitrary text string up to 9
characters in length.  The destination is set to the broadcast address.

The TNC sends the link setup frame.

The TNC then computes the CRC for the full packet, splits the packet into data
frames encode and modulate each frame back-to-back until the packet is
completely transmitted.

If there is another packet to be sent, the preamble can be skipped and the
TNC will construct the next link setup frame (it can re-use the same link
setup frame as it does not change) and send the next set of packet frames.

Limitations
^^^^^^^^^^^

The KISS specification defines no limitation to the packet size allowed.  Nor
does it specify any means of returning error conditions back to the host.
M17 packet protocol limits the raw packet payload size to 798 bytes.  The
TNC must drop any packets larger than this.

Receiving Data
^^^^^^^^^^^^^^

When receiving M17 data, the TNC must receive and parse the link setup frame
and verify that the following frames contain raw packet data.

The TNC is responsible for decoding each packet, assembling the packet from
the sequence of frames received, and verifying the packet checksum.  If the
checksum is valid, the TNC transfers the packet, excluding the CRC to the host
using **HDLC port** 0.

M17 Encapsulated Packet Mode
----------------------------

The purpose of encapsulated packet mode is to provide access to the entire
M17 protocol stream to the host.  This allows the host to set the source and
destination fields, filter received packets based on the content these fields,
and send and receive type-coded frames.

To communicate the source and destination between the host and TNC, we are
extending the KISS protocol.  We are chosing command words that are not
currently known to be in use.

One of the design goals for the KISS protocols is a symmetric protocol between
host and TNC.
