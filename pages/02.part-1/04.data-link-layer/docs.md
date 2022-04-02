---
title: 'Data Link Layer'
taxonomy:
    category:
        - docs
media_order: 'M17_stream.png,convolutional.svg,frame_encoding.svg,link_setup_frame_encoding.svg,packet_frame_encoding.svg'
---

The Data Link layer is split into three modes:

* Packet mode
   Data are sent in small bursts, on the order of 100s to 1000s of bytes at a time, after which the physical layer stops sending data. e.g. messages, beacons, etc.

* Stream mode
   Data are sent in a continuous stream for an indefinite amount of time, with no break in physical layer output, until the stream ends. e.g. voice data, bulk data transfers, etc.

* BERT mode
   PRBS9 is used to fill frames with a deterministic bit sequence.  Frames are sent in a continuous sequence.

When the physical layer is idle (no RF being transmitted or received), the data link defaults to packet mode.

As is the convention with other networking protocols, all values are
encoded in big endian byte order.

### Stream Mode

In Stream Mode, an *indefinite* amount of payload data is sent continuously without breaks in the physical layer. The *stream* is broken up into parts, called *frames* to not confuse them with *packets* sent in packet mode. Frames contain payload data interleaved with frame signalling (similar to packets). Frame signalling is contained within the **Link Information Channel (LICH)**.


#### Link setup frame

First frame of the transmission contains full LSF data. It’s called the **Link Setup Frame (LSF)**, and is not part of any superframes.

##### LSF Fields

Field | Length   | Description
----- | ------   | -----------
DST   | 48 bits  | Destination address - Encoded callsign or a special number (eg. a group)
SRC   | 48 bits  | Source address - Encoded callsign of the originator or a special number (eg. a group)
TYPE  | 16 bits  | Information about the incoming data stream
META  | 112 bits | Metadata field, suitable for cryptographic metadata like IVs or single-use numbers, or non-crypto metadata like the sender’s GNSS position.
CRC   | 16 bits  | CRC for the link setup data
TAIL  | 4 bits   | Flushing bits for the convolutional encoder that do not carry any information. Only included for RF frames, not included for IP purposes.

##### Bitfields of Type Field

Bits   | Meaning
----   | -------
0      | Packet/stream indicator, 0=packet, 1=stream
1..2   | Data type indicator, $01_2$ =data (D), $10_2$ =voice (V), $11_2$ =V+D, $00_2$ =reserved
3..4   | Encryption type, $00_2$ =none, $01_2$ =AES, $10_2$ =scrambling, $11_2$ =other/reserved
5..6   | Encryption subtype (meaning of values depends on encryption type)
7..10  | Channel Access Number (CAN)
11..15 | Reserved (don’t care)

The fields in Table 3 (except TAIL) form initial LSF. It contains all information needed to establish M17 link. Later in the transmission, the initial LSF is divided into 6 “chunks” and transmitted beside the payload data. This allows late-joiners to reconstruct the LICH after collecting all the pieces, and start decoding the stream even though they missed the beginning of the transmission. The process of collecting full LSF takes 6 frames or 6\*40 ms = 240 ms. Four TAIL bits are needed for the convolutional coder to go back to state 0, so the ending trellis position is also known. 

Voice coder rate is inferred from TYPE field, bits 1 and 2.

##### Voice Coder Rates

Data Type Indicator | Voice Coder Rate
------------------- | ----------------
$00_2$              | none / reserved
$01_2$              | no voice
$10_2$              | 3200 bps
$11_2$              | 1600 bps

#### Subsequent Frames

##### Fields for Frames other than LSF

Field   | Length   | Description
-----   | ------   | -----------
LICH    | 48 bits  | LSF chunk, one of 6
FN      | 16 bits  | Frame number, starts from 0 and increments every frame to a max of 0x7fff where it will then wrap back to 0. High bit set indicates this frame is the last of the stream
PAYLOAD | 128 bits | Payload/data, can contain arbitrary data
TAIL    | 4 bits   | Flushing bits for the convolutional encoder that don’t carry any information

The most significant bit in the FN counter is used for transmission end signalling. When transmitting the last frame, it shall be set to 1 (one), and 0 (zero) in all other frames.

The payload is used so that earlier data in the voice stream is sent first. For mixed voice and data payloads, the voice data is stored first, then the data.

##### LSF Chunk Structure

Bits   | Content
----   | -------
0..39  | 40 bits of full LSF
40..42 | A modulo 6 counter (LICH_CNT) for LSF re-assembly
43..47 | Reserved

##### Payload Example 1

`Codec2 encoded frame t + 0 | Codec2 encoded frame t + 1`

##### Payload Example 2

`Codec2 encoded frame t + 0 | Mixed data t + 0`

#### Superframes

Each frame contains a chunk of the LSF frame that was used to establish the stream. Frames are grouped into superframes, which is the group of 6 frames that contain everything needed to rebuild the original LSF packet, so that the user who starts listening in the middle of a stream (late-joiner) is eventually able to reconstruct the LSF message and understand how to receive the in-progress stream.

![M17_stream](M17_stream.png?classes=caption "Stream consisting of one superframe")

[mermaid]
graph TD
c0["conv. coder"]
p0["P_1 puncturer"]
i0["interleaver"]
w0["decorrelator"]
s0["prepend LSF_SYNC"]
l0["LICH combiner"]
chunker_40["chunk 40 bits"]
golay_24_12["Golay (24, 12)"]
c1["conv. coder"]
p1["P_2 puncturer"]
i1["interleaver"]
w1["decorrelator"]
s1["prepend FRAME_SYNC"]
fn["add FN"]
chunker_128["chunk 128 bits"]
framecomb["Frame Combiner"]
supercomb["Superframe Combiner"]

counter --> l0
LSF --> c0 --> p0 --> i0 --> w0 --> s0 --> supercomb
LSF --> chunker_40 --> l0 --> golay_24_12 --> framecomb
data --> chunker_128 --> fn --> c1 --> p1 --> framecomb
framecomb --> i1 --> w1 --> s1 --> supercomb
preamble --> supercomb
[/mermaid]
<center>An overview of the forward dataflow</center>

#### CRC

M17 uses a non-standard version of 16-bit CRC with polynomial $x^{16} + x^{14} + x^{12} + x^{11} + x^8 + x^5 + x^4 + x^2 + 1$ or 0x5935 and initial value of 0xFFFF. This polynomial allows for detecting all errors up to hamming distance of 5 with payloads up to 241 bits, which is less than the amount of data in each frame.

As M17’s native bit order is most significant bit first, neither the input nor the output of the CRC algorithm gets reflected.

The input to the CRC algorithm consists of DST, SRC (each 48 bits), 16 bits of TYPE field and 112 bits META, and then depending on whether the CRC is being computed or verified either 16 zero bits or the received CRC.

The test vectors in the following table are calculated by feeding the given message and then 16 zero bits to the CRC algorithm.

Message                  | CRC Output
-------                  | ----------
(empty string)           | 0xFFFF
ASCII string "A"         | 0x206E
ASCII string "123456789" | 0x772B
Bytes 0x00 to 0xFF       | 0x1c31

### Packet Mode

In *packet mode*, a finite amount of payload data (for example – text messages or application layer data) is wrapped with a packet, sent over the physical layer, and is completed when done. ~~Any acknowledgement or retransmission is done at the application layer.~~

#### Link Setup Frame

Packet mode uses the same link setup frame that has been defined for stream mode above. The packet/stream indicator is set to 0 in the type field.

##### Bitfields of Type Field

Bits   | Meaning
----   | -------
0      | Packet/stream indicator, 0=packet, 1=stream
1..2   | Data type indicator, $01_2$ =data (D), $10_2$ =voice (V), $11_2$ =V+D, $00_2$ =reserved
3..4   | Encryption type, $00_2$ =none, $01_2$ =AES, $10_2$ =scrambling, $11_2$ =other/reserved
5..6   | Encryption subtype (meaning of values depends on encryption type)
7..10  | Channel Access Number (CAN)
11..15 | Reserved (don’t care)

Raw packet frames have no packet type metadata associated with them. Encapsulated packet format is discussed in Packet Superframes in the Application Layer section. This provides data type information and is the preferred format for use on M17.

When encryption type is $00_2$, meaning no encryption, the encryption subtype bits are used to indicate the contents of the META field in the LSF. Since that space would otherwise go be unused, we can store small bits of data in that field such as free text or the sender’s GNSS position.

Encryption type and subtype bits, including the plaintext data formats when not using encryption, are described in more detail in the Application Layer section of this document.

Currently the contents of the source and destination fields are arbitrary as no behavior is defined which depends on the content of these fields. The only requirement is that the content is base-40 encoded.

#### Packet Format

M17 packet mode can transmit up to 798 bytes of payload data within one transmission. It acheives a base throughput of 5 kbps, and a net throughput of about 4.7 kbps for the largest data payload, and over 3 kbps for 100-byte payloads. [^1]
[^1]: Net throughput takes into account preamble and link setup overhead.

The packet superframe consists of 798 payload data bytes and a 2-byte CCITT CRC-16 checksum.

##### Byte Fields of Packet Superframe

Bytes  | Meaning
-----  | -------
1..798 | Packet payload
2      | CRC-16

The CRC used here is the same as described in [Chapter 2.4](https://spec.m17project.org/part-1/data-link-layer#crc).

Packet data is split into frames of 368 type 4 bits preceded by a packet-specific 16-bit sync word (0xFF5D). This is the same size frame used by stream mode.

The packet frame starts with a 210 bit frame of type 1 data. It is noteworthy that it does not terminate on a byte boundary.

The frame has 200 bits (25 bytes) of payload data, 6 bits of frame metadata, and 4 bits to flush the convolutional coder.

##### Bit Fields of Packet Frame

Bits   | Meaning
----   | -------
0..199 | Packet payload
1      | EOF indicator
5      | Frame / Byte count
4      | Flush bits for convolutional coder

The metadata field contains a 1 bit **end of frame (EOF)** indicator, and a 5-bit frame/byte counter.

The **EOF** bit is 1 only on the last frame. The **counter** field is used to indicate the frame number when **EOF** is 0, and the number of bytes in the last frame when **EOF** is 1. This encodes the exact packet size, up to 800 bytes, in a 6-bit field.

##### Metadata Field with EOF = 0

Bits | Meaning
---- | -------
0    | Set to 0, Not end of frame
1..5 | Frame number, 0..31

##### Metadata Field with EOF = 1

Bits | Meaning
---- | -------
0    | Set to 1, End of frame
1..5 | Number of bytes in frame, 1..25

Note that it is non-conforming to send a last frame with a length of 0 bytes. The number of bytes **includes** 2-byte CRC.

#### Convolutional Coding

The entire frame is convolutionally coded, giving 420 bits of type 2 data. It is then punctured using a 7/8 puncture matrix (1,1,1,1,1,1,1,0) to give 368 type 3 bits. These are then interleaved and decorrelated to give 368 type 4 bits.

##### Packet Frame

Bits     | Meaning
----     | -------
16 bits  | Sync word 0xFF5D
368 bits | Payload




### Bit types

The bits at different stages of the error correction coding are referred to with bit types, given in the following table.

Type   | Description
----   | -----------
Type 1 | Data link layer bits
Type 2 | Bits after appropriate encoding
Type 3 | Bits after puncturing (only for convolutionally coded data, for other ECC schemes type 3 bits are the same as type 2 bits)
Type 4 | Decorrelated and interleaved (re-ordered) type 3 bits

Type 4 bits are used for transmission over the RF. Incoming type 4 bits shall be decoded to type 1 bits, which are then used to extract all the frame fields.

### Error correction coding schemes and bit type conversion

Two distinct ECC/FEC schemes are used for different parts of the transmission.

#### Link setup frame (LSF)

![link_setup_frame_encoding](link_setup_frame_encoding.svg?classes=caption "ECC Link Setup Frame Encoding")

240 DST, SRC, TYPE, META and CRC type 1 bits are convolutionally coded using rate 1/2 coder with constraint K=5. 4 tail bits are used to flush the encoder’s state register, giving a total of 244 bits being encoded. Resulting 488 type 2 bits are retained for type 3 bits computation. Type 3 bits are computed by puncturing type 2 bits using a scheme shown in chapter 4.4. This results in 368 bits, which in conjunction with the synchronization burst gives 384 bits (384 bits / 9600bps = 40 ms).

Interleaving type 3 bits produce type 4 bits that are ready to be transmitted. Interleaving is used to combat error bursts.

#### Subsequent frames

![frame_encoding](frame_encoding.svg?classes=caption "ECC stages of subsequent frames")

A 40-bit (type 1) chunk of the LSF along with a 3-bit modulo 6 counter (LICH_CNT) and 5 reserved bits (see Table 7) is partitioned into 4 12-bit parts and encoded using Golay (24, 12) code. This produces 96 encoded bits of type 2. These bits are used in the Link Information Channel (LICH).

16-bit FN and 128 bits of payload (144 bits total) are convolutionally encoded in a manner analogous to that of the link setup frame. A total of 148 bits is being encoded resulting in 296 type 2 bits. These bits are punctured to generate 272 type 3 bits.

96 type 2 bits of LICH are concatenated with 272 type 3 bits and re-ordered to form type 4 bits for transmission. This, along with 16-bit sync in the beginning of frame, gives a total of 384 bits

The LICH chunks allow for late listening and indepedent decoding to check destination address. The goal is to require less complexity to decode just the LICH and check if the full message should be decoded.

#### Packet Frame Encoding

![packet_frame_encoding](packet_frame_encoding.svg?classes=caption "Packet Frame Encoding")


All data fields utilize big-endian order of bytes unless specified otherwise.


#### Extended Golay(24,12) code

The extended Golay(24,12) encoder uses generating polynomial g given below to generate the 11 check bits. The check bits and an additional parity bit are appended to the 12 bit data, resulting in a 24 bit codeword. The resulting code is systematic, meaning that the input data (message) is embedded in the codeword.

\(g(x) = x^{11} + x^{10} + x^6 + x^5 + x^4 + x^2 + 1\)

This is equivalent to 0xC75 in hexadecimal notation. Both the generating matrix \(G\) and parity check matrix \(H\) are shown below.

\(
\begin{align}
  G = \begin{bmatrix} I_k | P \end{bmatrix} = & \begin{bmatrix}
  1&0&0&0&0&0&0&0&0&0&0&0&1&1&0&0&0&1&1&1&0&1&0&1\\
  0&1&0&0&0&0&0&0&0&0&0&0&0&1&1&0&0&0&1&1&1&0&1&1\\
  0&0&1&0&0&0&0&0&0&0&0&0&1&1&1&1&0&1&1&0&1&0&0&0\\
  0&0&0&1&0&0&0&0&0&0&0&0&0&1&1&1&1&0&1&1&0&1&0&0\\
  0&0&0&0&1&0&0&0&0&0&0&0&0&0&1&1&1&1&0&1&1&0&1&0\\
  0&0&0&0&0&1&0&0&0&0&0&0&1&1&0&1&1&0&0&1&1&0&0&1\\
  0&0&0&0&0&0&1&0&0&0&0&0&0&1&1&0&1&1&0&0&1&1&0&1\\
  0&0&0&0&0&0&0&1&0&0&0&0&0&0&1&1&0&1&1&0&0&1&1&1\\
  0&0&0&0&0&0&0&0&1&0&0&0&1&1&0&1&1&1&0&0&0&1&1&0\\
  0&0&0&0&0&0&0&0&0&1&0&0&1&0&1&0&1&0&0&1&0&1&1&1\\
  0&0&0&0&0&0&0&0&0&0&1&0&1&0&0&1&0&0&1&1&1&1&1&0\\
  0&0&0&0&0&0&0&0&0&0&0&1&1&0&0&0&1&1&1&0&1&0&1&1\\
  \end{bmatrix}
\newline\newline
  H = \begin{bmatrix} P^T | I_k \end{bmatrix} = & \begin{bmatrix}
  1&0&1&0&0&1&0&0&1&1&1&1&1&0&0&0&0&0&0&0&0&0&0&0\\
  1&1&1&1&0&1&1&0&1&0&0&0&0&1&0&0&0&0&0&0&0&0&0&0\\
  0&1&1&1&1&0&1&1&0&1&0&0&0&0&1&0&0&0&0&0&0&0&0&0\\
  0&0&1&1&1&1&0&1&1&0&1&0&0&0&0&1&0&0&0&0&0&0&0&0\\
  0&0&0&1&1&1&1&0&1&1&0&1&0&0&0&0&1&0&0&0&0&0&0&0\\
  1&0&1&0&1&0&1&1&1&0&0&1&0&0&0&0&0&1&0&0&0&0&0&0\\
  1&1&1&1&0&0&0&1&0&0&1&1&0&0&0&0&0&0&1&0&0&0&0&0\\
  1&1&0&1&1&1&0&0&0&1&1&0&0&0&0&0&0&0&0&1&0&0&0&0\\
  0&1&1&0&1&1&1&0&0&0&1&1&0&0&0&0&0&0&0&0&1&0&0&0\\
  1&0&0&1&0&0&1&1&1&1&1&0&0&0&0&0&0&0&0&0&0&1&0&0\\
  0&1&0&0&1&0&0&1&1&1&1&1&0&0&0&0&0&0&0&0&0&0&1&0\\
  1&1&0&0&0&1&1&1&0&1&0&1&0&0&0&0&0&0&0&0&0&0&0&1\\
  \end{bmatrix}
\end{align}
\)
 
The output of the Golay encoder is shown in the table below.
 
Field      | Data     | Check bits  | Parity
-----      | ----     | ----------  | ------
Position   | 23..12   | 11..1       | 0 (LSB)
Length     | 12       | 11          | 1

Four of these 24-bit blocks are used to reconstruct the LSF.

Sample MATLAB/Octave code snippet for generating \(G\) and \(H\) matrices is shown below.

```

P = hex2poly('0xC75');
[H,G] = cyclgen(23, P);

G_P = G(1:12, 1:11);
I_K = eye(12);
G = [I_K G_P P.'];
H = [transpose([G_P P.']) I_K];
```

### Convolutional encoder

The convolutional code shall encode the input bit sequence after appending 4 tail bits at the end of the sequence. Rate of the coder is R=½ with constraint length K=5. The encoder diagram and generating polynomials are shown below.

\(
\begin{align}
  G_1(D) =& 1 + D^3 + D^4 \\
  G_2(D) =& 1+ D + D^2 + D^4
\end{align}
\)

The output from the encoder must be read alternately.

![convolutional](convolutional.svg?classes=caption "Convolutional coder diagram")

### Code puncturing

Removing some of the bits from the convolutional coder’s output is called code puncturing. The nominal coding rate of the encoder used in M17 is ½. This means the encoder outputs two bits for every bit of the input data stream. To get other (higher) coding rates, a puncturing scheme has to be used.

Two different puncturing schemes are used in M17 stream mode:

1. \(P_1\) leaving 46 from 61 encoded bits
2. \(P_2\) leaving 11 from 12 encoded bits

Scheme \(P_1\) is used for the *link setup frame*, taking 488 bits of encoded data and selecting 368 bits. The \(gcd(368, 488)\) is 8 which, when used to divide, leaves 46 and 61 bits. However, a full puncture pattern requires the puncturing matrix entries count to be divisible by the number of encoding polynomials. For this case a partial puncture matrix is used. It has 61 entries with 46 of them being ones and shall be used 8 times, repeatedly. The construction of the partial puncturing pattern \(P_1\) is as follows:

\(
\begin{align}
  M = & \begin{bmatrix}
  1 & 0 & 1 & 1
  \end{bmatrix} \\
  P_{1} = & \begin{bmatrix}
  1 & M_{1} & \cdots & M_{15}
  \end{bmatrix}
\end{align}
\)

In which \(M\) is a standard 2/3 rate puncture matrix and is used 15 times, along with a leading \(1\) to form \(P_1\), an array of length 61.

The first pass of the partial puncturer discards \(G_1\) bits only, second pass discards \(G_2\), third - \(G_1\) again, and so on. This ensures that both bits are punctured out evenly.

Scheme \(P_2\) is for frames (excluding LICH chunks, which are coded differently). This takes 296 encoded bits and selects 272 of them. Every 12th bit is being punctured out, leaving 272 bits. The full matrix shall have 12 entries with 11 being ones.

The puncturing scheme \(P_2\) is defined by its partial puncturing matrix:

\(
\begin{align}
  P_2 = & \begin{bmatrix}
  1 & 1 & 1 & 1 & 1 & 1 \\
  1 & 1 & 1 & 1 & 1 & 0
  \end{bmatrix}
\end{align}
\)

The linearized representations are:

```
P1 = [1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1,
      1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1,
      0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1]

P2 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
```

One additional puncturing scheme \(P_3\) is used in the packet mode. The puncturing scheme is defined by its puncturing matrix:

\(
\begin{align}
  P_3 = & \begin{bmatrix}
  1 & 1 & 1 & 1 \\
  1 & 1 & 1 & 0
  \end{bmatrix}
\end{align}
\)

The linearized representation is:

```
P3 = [1, 1, 1, 1, 1, 1, 1, 0]
```

### Interleaving

For interleaving a Quadratic Permutation Polynomial (QPP) is used. The polynomial \(\pi(x)=(45x+92x^2)\mod 368\) is used for a 368 bit interleaving pattern QPP. See appendix sec-interleaver for pattern.





### Frame

A frame shall be composed of a frame type specific Synchronization Burst followed by a Payload.  There are four frame types: Link Setup Frames (LSF), Bit Error Rate Test (BERT) frames, Stream Frames, and Packet Frames.

Only LSF and BERT frames may immediately follow the preamble.

### Synchronization Burst (Sync Burst)

All frames shall be preceded by 16 bits (8 symbols) of *synchronization burst*.

The Sync Burst codings are based on [Barker codes](https://en.wikipedia.org/wiki/Barker_code).

<table>
    <caption><span>Table 2</span><span>Sync Burst</span></caption>
    <thead>
        <tr>
            <th>Frame Type</th>
            <th>Preamble</th>
            <th>Sync Burst Bytes</th>
            <th>Sync Burst Symbols</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>LSF</td>
            <td>+3, -3</td>
            <td>0x55 0xF7</td>
            <td>+3, +3, +3, +3, -3, -3, +3, -3</td>
        </tr>
        <tr>
            <td>BERT</td>
            <td>-3, +3</td>
            <td>0xDF 0x55</td>
            <td>-3, +3, -3, -3, +3, +3, +3, +3</td>
        </tr>
        <tr>
            <td>Stream</td>
            <td>None</td>
            <td>0xFF 0x5D</td>
            <td>-3, -3, -3, -3, +3, +3, -3, +3</td>
        </tr>
        <tr>
            <td>Packet</td>
            <td>None</td>
            <td>0x75 0xFF</td>
            <td>+3, -3, +3, +3, -3, -3, -3, -3</td>
        </tr>
    </tbody>
</table>


### Payload

The Payload consists of 368 bits (192 symbols).
