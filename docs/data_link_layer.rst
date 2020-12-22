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

Packet Mode
-----------

In *packet mode*, a finite amount of payload data (for example – text
messages or application layer data) is wrapped with a packet, sent
over the physical layer, and is completed when done. ~~Any
acknowledgement or error correction is done at the application
layer.~~

Packet Format
~~~~~~~~~~~~~

.. todo:: More detail here about endianness, etc

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


Link setup frame
~~~~~~~~~~~~~~~~

First frame of the transmission contains full LICH data. It’s called
the link setup frame, and is not part of any superframes.

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

The fields in Table 3 (except tail) form initial LICH. It contains all
information needed to establish M17 link. Later in the transmission,
the initial LICH is divided into 6 "chunks" and transmitted
interleaved with data. The purpose of that is to allow late-joiners to
receive the LICH at any point of the transmission. The process of
collecting full LICH takes 6 frames or 6*40 ms = 240 ms. Four TAIL
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
     - LICH chunk, one of 6
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

.. list-table:: LICH chunk structure
   :header-rows: 1

   * - Bits
     - Content
   * - 0..39
     - 40 bits of full LICH
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

Each frame contains a chunk of the LICH frame that was used to
establish the stream. Frames are grouped into superframes, which is
the group of 6 frames that contain everything needed to rebuild the
original LICH packet, so that the user who starts listening in the
middle of a stream (late-joiner) is eventually able to reconstruct the
LICH message and understand how to receive the in-progress stream.

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

     LICH -> c0 -> p0 -> i0 -> w0 -> s0 -> supercomb
     LICH -> chunker_48 -> golay_24_12 -> framecomb
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
