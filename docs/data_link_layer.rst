Data Link Layer
===============
The Data Link layer is split into two modes:

#. Packet mode: data are sent in small bursts, on the order of 100s to 1000s of bytes at a time, after
which the physical layer stops sending data. eg: messages, beacons, etc.
#. Stream mode: data are sent in a continuous stream for an indefinite amount of time, with no
break in physical layer output, until the stream ends. eg: voice data, bulk data transfers, etc.

When the physical layer is idle (no RF being transmitted or received),
the data link defaults to packet mode. ~~To switch to stream mode, a
start stream packet (detailed later) is sent, immediately followed by
the switch to stream mode; the Stream of data immediately follows the
Start Stream packet without disabling the Physical layer. To switch
out of Stream mode, the stream simply ends and returns the Physical
layer to the idle state, and the Data Link defaults back to Packet
mode.~~

As is the convention with networking protocols, all quantities
larger than 8 bits are encoded in bigendian.

Stream Mode
-----------

In Stream Mode, an *indefinite* amount of payload data is sent continuously without breaks in the
physical layer. The *stream* is broken up into parts, called *frames* to not confuse them with *packets* sent
in packet mode. Frames contain payload data interleaved with frame signalling (similar to packets).
Frame signalling is contained within the **Link Information Channel (LICH)**.

Sync Burst
~~~~~~~~~~

All frames are preceded by a 16-bit *synchronization burst*.

    * Link setup frames shall be preceded with 0x55F7.
    * Stream frames shall be preceeded with 0xFF5D.
    * Packet frames shall be preceeded with 0x75FF.

All syncwords are type 4 bits.

These sync words are based on `Barker codes`_.  The sequence 0xDF55 (symbols -3 +3 -3 -3 +3 +3 +3 +3) is reserved.

.. _`Barker codes`: https://en.wikipedia.org/wiki/Barker_code


Link setup frame
~~~~~~~~~~~~~~~~

First frame of the transmission contains full LSF data. It’s called
the **Link Setup Frame (LSF)**, and is not part of any superframes.

.. list-table:: Link setup frame fields

   * - DST
     - 48 bits
     -  Destination address - Encoded callsign or a special number (eg. a group)
   * - SRC
     - 48 bits
     - Source address - Encoded callsign of the originator or a
       special number (eg. a group)
   * - TYPE
     - 16 bits
     - Information about the incoming data stream
   * - NONCE
     - 112 bits
     - Nonce for encryption
   * - CRC
     - 16 bits
     - CRC for the link setup data
   * - TAIL
     - 4 bits
     - Flushing bits for the convolutional encoder that do not carry any information


.. list-table:: Bitfields of type field
   :header-rows: 1

   * - Bits
     - Meaning
   * - 0
     - Packet/stream indicator, 0=packet, 1=stream
   * - 1-2
     - Data type indicator, :math:`01_2` =data (D), :math:`10_2` =voice
       (V), :math:`11_2` =V+D, :math:`00_2` =reserved
   * - 3-4
     - Encryption type, :math:`00_2` =none, :math:`01_2` =AES,
       :math:`10_2` =scrambling, :math:`11_2` =other/reserved
   * - 5-6
     - Encryption subtype (meaning of values depends on encryption type)
   * - 7-15
     - Reserved (don't care)

The fields in Table 3 (except tail) form initial LSF. It contains all
information needed to establish M17 link. Later in the transmission,
the initial LSF is divided into 6 "chunks" and transmitted
interleaved with data. The purpose of that is to allow late-joiners to
receive the LICH at any point of the transmission. The process of
collecting full LSF takes 6 frames or 6*40 ms = 240 ms. Four TAIL
bits are needed for the convolutional coder to go back to state 0, so
also the ending trellis position is known.

Voice coder rate is inferred from TYPE field, bits 1 and 2.

.. list-table:: Voice coder rates for different data type indicators
   :header-rows: 1

   * - Data type indicator
     - Voice coder rate
   * - :math:`00_2`
     - none/reserved
   * - :math:`01_2`
     - no voice
   * - :math:`10_2`
     - 3200 bps
   * - :math:`11_2`
     - 1600 bps

Subsequent frames
~~~~~~~~~~~~~~~~~

.. list-table:: Fields for frames other than the link setup frame

   * - LICH
     - 48 bits
     - LSF chunk, one of 6
   * - FN
     - 16 bits
     - Frame number, starts from 0 and increments every frame to a max of 0x7fff where it will then wrap back to 0. High bit set indicates this frame is the last of the stream.
   * - PAYLOAD
     - 128 bits
     - Payload/data, can contain arbitrary data
   * - CRC
     - 16 bits
     - This field contains 16-bit value used to check data integrity, see section 2.4 for details
   * - TAIL
     - 4 bits
     - Flushing bits for the convolutional encoder that don't carry any information

The most significant bit in the FN counter is used for transmission
end signalling. When transmitting the last frame, it shall be set to 1
(one). 

The payload is used so that earlier data in the voice stream is sent first.
For mixed voice and data payloads, the voice data is stored first, then the data.

.. list-table:: LSF chunk structure
   :header-rows: 1

   * - Bits
     - Content
   * - 0..39
     - 40 bits of full LSF
   * - 40..42
     - A modulo 6 counter (LICH_CNT) for LICH re-assembly
   * - 43..47
     - 5-bit Color Code (CC)

.. table:: Payload example 1

   +-------------------------------+---------------+---------------+
   |    Codec2 encoded frame t + 0 |   Codec2 encoded frame t + 1  |
   +---------------+---------------+---------------+---------------+

.. table:: Payload Example 2

   +-------------------------------+---------------+---------------+
   |    Codec2 encoded frame t + 0 |       Mixed data t + 0        |
   +---------------+---------------+---------------+---------------+

Superframes
~~~~~~~~~~~

Each frame contains a chunk of the LSF frame that was used to
establish the stream. Frames are grouped into superframes, which is
the group of 6 frames that contain everything needed to rebuild the
original LSF packet, so that the user who starts listening in the
middle of a stream (late-joiner) is eventually able to reconstruct the
LSF message and understand how to receive the in-progress stream.

.. figure:: ../images/M17_stream.png

   Stream consisting of one superframe

.. graphviz::
   :caption: An overview of the forward dataflow

   digraph D{
     size="4,6";
     node [shape=record];
     {rank=same c0 c1 golay_24_12}
     {rank=same p0 p1}
     {rank=same i0 i1}

     c0[label="conv coder"]
     p0[label="Puncture P1"]
     i0[label="interleave"]
     w0[label="decorrelator"]
     s0[label="add sync"]
     chunker_48[label="chunk 48 bits"]
     golay_24_12[label="golay(24, 12)"]

     c1[label="conv coder"]
     p1[label="Puncture P2"]
     i1[label="interleave"]
     w1[label="decorrelator"]
     s1[label="add sync"]
     fn[label="Add FN"]
     chunker_128[label="chunk 128 bits"]

     framecomb[label="Frame Combiner"]
     supercomb[label="Superframe Combiner"]

     LSF -> c0 -> p0 -> i0 -> w0 -> s0 -> supercomb
     LSF -> chunker_48 -> golay_24_12 -> framecomb
     data -> chunker_128 -> fn -> CRC -> c1 -> p1 -> framecomb
     framecomb -> i1 -> w1 -> s1 -> supercomb
     Preamble -> supercomb
   }

CRC
~~~

M17 uses a non-standard version of 16-bit CRC with polynomial
:math:`x^{16} + x^{14} + x^{12} + x^{11} + x^8 + x^5 + x^4 + x^2 + 1` or
0x5935 and initial value of 0xFFFF. This polynomial allows for
detecting all errors up to hamming distance of 5 with payloads up to
241 bits [#koopman]_, which is less than the amount of data in each frame.

.. [#koopman] https://users.ece.cmu.edu/~koopman/crc/ has this listed
              as 0xAC9A, which is the reversed reciprocal notation

As M17’s native bit order is most significant bit first, neither the
input nor the output of the CRC algorithm gets reflected.

The input to the CRC algorithm consists of the 16 bits of FN and 128
bits of payload, and then depending on whether the CRC is being computed
or verified either 16 zero bits or the received CRC.

The test vectors in Table 6 are calculated by feeding the given
message and then 16 zero bits to the CRC algorithm.

.. list-table:: CRC test vectors
   :header-rows: 1

   * - Message
     - CRC output
   * - (empty string)
     - 0xFFFF
   * - ASCII string "A"
     - 0x206E
   * - ASCII string "123456789"
     - 0x772B
   * - Bytes from 0x00 to 0xFF
     - 0x1C31

Packet Mode
-----------

In *packet mode*, a finite amount of payload data (for example – text
messages or application layer data) is wrapped with a packet, sent
over the physical layer, and is completed when done. ~~Any
acknowledgement or retransmission is done at the application
layer.~~

Link Setup Frame
~~~~~~~~~~~~~~~~

Packet mode uses the same link setup frame that has been defined for stream mode above.
The packet/stream indicator is set to 0 in the type field.

.. list-table:: Bitfields of type field
   :header-rows: 1

   * - Bits
     - Meaning
   * - 0
     - Packet/stream indicator, 0=packet, 1=stream
   * - 1-2
     - Data type indicator, :math:`01_2` =raw (D), :math:`10_2` =encapsulated
       (V), :math:`11_2` =reserved, :math:`00_2` =reserved
   * - 3-4
     - Encryption type, :math:`00_2` =none, :math:`01_2` =AES,
       :math:`10_2` =scrambling, :math:`11_2` =other/reserved
   * - 5-6
     - Encryption subtype (meaning of values depends on encryption type)
   * - 7-15
     - Reserved (don't care)

Raw packet frames have no packet type metadata associated with them.  Encapsulated packet
format is discussed in :ref:`packet-superframes` in the Application Layer section.  This
provides data type information and is the preferred format for use on M17.

Currently the contents of the source and destination fields are arbitrary as no behavior
is defined which depends on the content of these fields.  The only requirement is that
the content is base-40 encoded.

Packet Format
~~~~~~~~~~~~~

M17 packet mode can transmit up to 798 bytes of payload data.  It acheives a base throughput
of 5kbps, and a net throughput of about 4.7kbps for the largest data payload, and over 3kbps
for 100-byte payloads.  (Net throughput takes into account preamble and link setup overhead.)

The packet superframe consists of 798 payload data bytes and a 2-byte CCITT CRC-16 checksum.

.. list-table:: Byte fields of packet superframe
   :header-rows: 1

   * - Bytes
     - Meaning
   * - 1-798
     - Packet payload
   * - 2
     - CCITT CRC-16


Packet data is split into frames of 368 type 4 bits preceded by a packet-specific 16-bit sync
word (0xFF5D).  This is the same size frame used by stream mode.

The packet frame starts with a 210 byte frame of type 1 data.  It is noteworthy that it does
not terminate on a byte boundary.

The frame has 200 bits (25 bytes) of payload data, 6 bits of frame metadata, and 4 bits to
flush the convolutional coder.

.. list-table:: Bit fields of packet frame
   :header-rows: 1

   * - Bits
     - Meaning
   * - 0-199
     - Packet payload
   * - 1
     - EOF indicator
   * - 5
     - Frame/byte count
   * - 4
     - Flush bits for convolutional coder

   
The metadata field contains a 1 bit **end of frame** (**EOF**) indicator, and a 5-bit frame/byte counter.

The **EOF** bit is 1 only on the last frame.  The **counter** field is used to indicate the frame number
when **EOF** is 0, and the number of bytes in the last frame when **EOF** is 1.  This encodes the
exact packet size, up to 800 bytes, in a 6-bit field.

.. list-table:: Metadata field with EOF = 0
   :header-rows: 1

   * - Bits
     - Meaning
   * - 0
     - Set to 0, Not end of frame
   * - 1-5
     - Frame number, 0..31

.. list-table:: Metadata field with EOF = 1
   :header-rows: 1

   * - Bits
     - Meaning
   * - 0
     - Set to 1, End of frame
   * - 1-5
     - Number of bytes in frame, 1..25

Note that it is non-conforming to send a last frame with a length of 0 bytes.

Convolutional Coding
~~~~~~~~~~~~~~~~~~~~

The entire frame is convolutionally coded, giving 420 bits of type 2 data.  It is then punctured using
a 7/8 puncture matrix (1,1,1,1,1,1,1,0) to give 368 type 3 bits.  These are then interleaved and
decorrelated to give 368 type 4 bits.

.. list-table:: Packet frame
   :header-rows: 1

   * - Bits
     - Meaning
   * - 16 bits
     - Sync word 0xFF5D
   * - 368 bits
     - Payload


Carrier-sense Multiple Access
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When sending packets, the sender is reponsible for ensuring the channel is clear before transmitting.
`CSMA <https://en.wikipedia.org/wiki/Carrier-sense_multiple_access>`_ is used to minimize collisions on
a shared network.  Specifically, P-persistent access is used.  Each time slot is 40ms (one packet length)
and the probability SHOULD default to 25%.  In terms of the values used by the KISS protocol, these
equate to a slot time of 4 and a P-persistence value of 63.

The benefit of this method is that it imposes no penalty on uncontested networks.

