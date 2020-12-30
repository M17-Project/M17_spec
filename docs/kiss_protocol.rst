*************
KISS Protocol
*************

The purpose of this appendix is to document conventions for adapting KISS TNCs
to M17 packet and streaming modes.  M17 is a more complex protocol, both at
the baseband level and at the data link layer than is typical for HDLC-based
protocols commonly used on KISS TNCs.  However, it is well suited for modern
packet data links, and can even be used to stream digital audio between a host
and a radio.

This appendix assumes the reader is familiar with the streaming and packet
modes defined in the M17 spec, and with KISS TNCs and the KISS protocol.

In all cases, the TNC expects to get the data payload to be sent and is
responsible for frame construction, FEC encoding, puncturing, interleaving
and decorrelation.  It is also responsible for baseband modulation.

For streaming modes, all voice encoding (Codec2) is done on the host and
not on the TNC.  The host is also responsible for constructing the LICH.


References
==========

 - http://www.ax25.net/kiss.aspx
 - https://packet-radio.net/wp-content/uploads/2017/04/multi-kiss.pdf
 - https://en.wikipedia.org/wiki/OSI_model


Glossary
========

.. glossary::

   TNC
     Terminal node controller -- a baseband network interface device to allow
     host computers to send data over a radio network, similar to a modem. It
     connects a computer to a radio and handles the baseband portion of the
     physical layer and the data link layer of network protocol stack.

   KISS
     Short for "Keep it simple, stupid".  A simplified TNC protocol designed
     to move everything except for the physical layer and the data link layer
     out of the TNC.  Early TNCs could include everything up through the
     application layer of the OSI network model.

   SLIP
     `Serial Line Internet Protocol <https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol>`_ --
     the base protocol used by the KISS protocol, extended by adding a single
     :term:`type indicator` byte at the start of a frame.

   type indicator
     A one byte code at the beginning of a KISS frame which indicates the TNC
     :term:`port` and KISS :term:`command`.
     
   port
     A logical port on a TNC. This allowed a single TNC to connect to multiple
     radios.  Its specific use is loosely defined in the KISS spec.  The high
     nibble of the KISS :term:`type indicator`.  Port 0xF is reserved.

   command
     A KISS command. This tells the TNC or host how to interpret the KISS
     frame contents.  The low nibble of the KISS :term:`type indicator`.
     Command 0xF is reserved.

   CSMA
     `Carrier-sense multiple access <https://en.wikipedia.org/wiki/Carrier-sense_multiple_access>`_ --
     a protocol used by network devices to minimize collisions on a shared
     communications channel.

   HDLC
     `High-Level Data Link Control <https://en.wikipedia.org/wiki/High-Level_Data_Link_Control>`_ --
     a data link layer framing protocol used in many AX.25 packet radio
     networks.  Many existing protocol documents, including KISS, reference
     HDLC because of its ubiquity when the protocols were invented.  However,
     HDLC is not a requirement for higher level protocols like KISS which
     are agnostic to the framing used at the data link layer.

   EOS
     End of stream -- an indicator bit in the frame number field of a stream
     data frame.
   
   LICH
     Link information channel -- a secondary data channel in the stream data
     frame containing supplemental information, including a copy of the link
     setup frame.


M17 Protocols
=============

This specification defines KISS TNC modes for M17 packet and streaming modes,
allowing the KISS protocol to be used to send and receive M17 packet and voice
data. Both are bidirectional.  There are two packet modes defined. This is done
to provide complete access to the M17 protocol while maintaining the greatest
degree of backwards compatibility with existing packet applications.

These protocols map to specific KISS :term:`port`.  The host tells the TNC what
type of data to transmit based on the port used in host to TNC transfers. And
the TNC tells the host what data it has received by the port set on TNC to
host transfers.

This document outlines first the two packet protocols, followed by the
streaming protocol.

KISS Basics
===========

TX Delay
--------

If a KISS **TX delay** :math:`T_d` greater than 0 is specified, the transmitter
is keyed for :math:`T_d * 10 ms` with only a DC signal present.

The :math:`T_d` value should be adjusted to the minimum required by the
transmitter in order to transmit the full preamble reliably.

Only a single 40ms preamble frame is ever sent.

.. note::

   A TX delay may be necessary because many radios require some time between
   when PTT is engaged and the transmitter can begin transmitting a modulated
   signal.


Packet Protocols
================

In order to provide backward compatibility with the widest range of existing
ham radio software, and to make use of features in the the M17 protocol
itself, we will define two distint packet interfaces *BASIC* and *FULL*.

The KISS protocol allows us to target specific modems using the port
identifier in the control byte.

We first define basic packet mode as this is initially likely to be the
most commonly used mode over KISS.

M17 Basic Packet Mode
---------------------

Basic packet mode uses only the standard KISS protocol on **TNC port** 0.
This is the default port for all TNCs.  Packets are sent using command 0.
Again, this is normal behavior for KISS client applications.

Sending Data
^^^^^^^^^^^^

In basic mode, the TNC only expects to receive packets from the host, as it
would for any other mode supported AFSK, G3RUH, etc.

If the TNC is configured for half-duplex, the TNC will do P-persistence CSMA
using a 40ms slot time and obey the P value set via the KISS interface.  CSMA
is disabled in full-duplex mode.

The **TX Tail** value is deprecated and is ignored.

The TNC sends the preamble burst.

The TNC is responsible for constructing the link setup frame, identifying the
content as a raw mode packet.  The source field is an encoded TNC identifier,
similar to the APRS TOCALL, but it can be an arbitrary text string up to 9
characters in length.  The destination is set to the broadcast address.

In basic packet mode, it is expected that the sender callsign is embedded within
the packet payload.

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
using **KISS port** 0.

M17 Full Packet Mode
---------------------

The purpose of full packet mode is to provide access to the entire M17 packet
protocol to the host.  This allows the host to set the source and destination
fields, filter received packets based on the content these fields, enable
encryption, and send and receive type-coded frames.

Use M17 full packet mode by sending to **KISS port** 1.  In this mode the host
is responsible for sending both the link setup frame and the packet data.  It
does this by prepending the 30-byte link setup frame to the packet data,
sending this to the TNC in a single KISS frame.  The TNC uses the first 30
bytes as the link setup frame verbatim, then splits the remaining data into
M17 packet frames.

As with basic mode, the TNC uses the **Duplex** setting to enable/disable CSMA,
and uses the **P value** for CSMA, with a fixes slot time of "4" (40 ms).

Receiving Data
^^^^^^^^^^^^^^

For TNC to host transfers, the same occurs.  The TNC combines the link setup
frame with the packet frame and sends both in one KISS frame to the host using
**KISS port** 1.

Stream Protocol
===============

The streaming protocol is fairly trivial to describe.  It is used by sending
first a link setup frame followed by a stream of 26-byte data frames to
**KISS port** 2.

Stream Format
-------------

.. list-table:: M17 KISS Stream Protocol
   :header-rows: 1

   * - Frame Size
     - Contents
   * - 30
     - Link Setup Frame
   * - 26
     - LICH + Payload
   * - 26
     - LICH + Pyaload
   * - ...
     - ...
   * - 26
     - LICH + Payload with EOS bit set.

The host must not send any frame to any other KISS port while a stream is
active (a frame with the EOS bit has not been sent).

It is a protocol violation to send anything other than a link setup frame with
the stream mode bit set in the first field as the first frame in a stream
transfer to KISS port 2.  Any such frame is ignored.

It is a protocol violation to send anything to any other KISS port while a
stream is active.  If that happens the stream is terminated and the packet
that caused the protocol violation is dropped.


Data Frames
-----------

The data frames contain a 6-byte (48-bit) LICH segment followed by a 20 byte
payload segment consisting of frame number, 16-byte data payload and CRC. The
TNC is responsible for parsing the frame number and detecting the end-of-stream
bit to stop transmitting.

.. list-table:: KISS Stream Data Frame
   :header-rows: 1

   * - Frame Size
     - Contents
   * - 6
     - LICH (48 bits)
   * - 2
     - Frame number and EOS flag
   * - 16
     - Payload
   * - 2
     - M17 CRC of frame number and payload

The TNC is responsible for FEC-encoding both the LICH the payload, as well
as interleaving, decorrelation, and baseband modulation.

Timing Constraints
------------------

Streaming mode provides additional timing constraints on both host to TNC
transfers and on TNC to host transfers.  Payload frames must arrive every
40ms and must have a jitter below 40ms.  In general, it is expected that the
TNC has up to 2 frames buffered (buffering occurs while sending the preamble
and link setup frames), it should be able to keep the transmit buffers filled
with packet jitter of 40ms.

The TNC must stop transmitting if the transmit buffers are empty.  The TNC
communicates that it has stopped transmitting early (before seeing a frame
with the **end of stream** indicator set) by sending an empty data frame to
the host.

TNC to Host Transfers
---------------------

TNC to host transfers are similar in that the TNC first sends the 30-byte
link setup frame received to the host, followed by a stream of 26-byte data
frames as described above.  These are sent using **KISS port** 2.

The TNC must send the link setup frame first.  This means that tne TNC must
be able to decode LICH segments and assemble a valid link setup frame before
it sends the first data frame.  The TNC will only send a link setup frame
with a valid CRC to the host.  After the link setup frame is sent, the TNC
ignores the CRC and sends all valid frames (those received after a valid
sync word) to the host.  If the stream is lost before seeing an end-of-stream
flag, the TNC sends a 0-byte data frame to indicate loss of signal.

The TNC must then re-acquire the signal by decoding a valid link setup frame
from the LICH in order to resume sending to the host.

Busy Channel Lockout
--------------------

The TNC implements **busy channel lockout** by enabling half-duplex mode on
the TNC, and disables **busy channel lockout** by enabling full-duplex mode.
When busy channel lockout occurs, the TNC keeps the link setup frame and
discards all data frames until the channel is available.  It then sends the
preamble, link setup frame, and starts sending the data frames as they are
received.

Note: BCL will be apparent to a receiver as the first frame received after
the link setup frame will not start with frame number 0.

Limitations
-----------

Information is lost by having the TNC decode the LICH.  It is not possible to
communicate to the host that the LICH bytes are known to be invalid.

Should we have the TNC signal the host by dropping known invalid LICH segments?
The host can tell that the LICH is missing by looking at the frame size.

Mixing Modes
============

An M17 KISS TNC need not keep track of state across distinct TNC ports.  Packet
transfers are sent one packet at a time.  It is OK to send to port 0 and port 1
in subsequent transfers.  It is also OK to send a packet followed immediately
by a voice streams.  As mentioned earlier, it is a protocol violation to sent
a KISS frame to any other port while a stream is active.  However, a packet
can be sent immediately following a voice stream (after EOS is sent).

Back-to-back Transfers
----------------------

The TNC is expected to detect back-to-back transfers from the host, even across
different KISS ports, and suppress the generation of the preamble.

For example, a packet containing APRS data sent immediately on PTT key-up
should be sent immediately after the EOS frame.

Back-to-back transfers are common for packet communication where the
**window size** determines the number of unacknowledged frames which may be
outstanding (unacknowledged). Packet applications will frequently send
back-to-back packets (up to **window size** packets) before waiting for
the remote end to send ACKs for each of the packets.

Implementation Details
======================

Polarity
--------

One of the issues that must be addressed by the TNC designer, and one which
the KISS protocol offers no ready solution for, is the issue of polarity.

A TNC must interface with a RF transceiver for a complete M17 physical layer
implementation.  RF transceivers may have different polarity for their
TX and RX paths.

M17 defines that the +3 symbol is transmitted with a +2.4 kHz deviation
(2.4 kHz above the carrier).  **Normal polarity** in a transceiver results
in a positive voltage driving the frequency higher and a lower voltage
driving the frequency lower.  **Reverse polarity** is the opposite.  A
higher voltage drives the frequency lower.

On the receive side the same issue exists.  **Normal polarity** results
in a positive voltage output when the received signal is above the carrier
frequency. **Reverse polarity** results in a positive voltage when the
frequency is below the carrier.

Just as with transmitter deviation levels and received signal levels, the
polarity of the transmit and receive path must be adjustable on a 4-FSK
modem.  The way these adjustments are made to the TNC are not addressed
by the KISS specification.

