---
title: 'Data Link Layer'
taxonomy:
    category:
        - docs
media_order:
---

### Frame

A Frame shall be composed of a frame type specific [Synchronization Burst (Sync Burst)](#synchronization-burst-sync-burst) followed by 368 bits (184 symbols) of Payload.  The combination of Sync Burst plus Payload results in a constant 384 bit (192 symbol) Frame.  At the M17 data rate of 4800 symbols/s (9600 bits/s), each Frame is exactly 40ms in duration. 

There are four frame types each with their own specific Sync Burst: [Link Setup Frames (LSF)](#link-setup-frame-lsf), Bit Error Rate Test (BERT) Frames, [Stream Frames](#stream-frames), and [Packet Frames](#packet-frames).

<table style="width:75%;margin-left:auto;margin-right:auto;">
    <caption><span style="font-weight:bold">Figure 5 </span><span>Frame</span></caption>
    <tbody style="text-align:center;border:none;">
        <tr style="font-weight:bold; color:black;">
            <th style="border:3px solid black;text-align:center;width:35%;">SYNC BURST<br/>(16 bits / 8 symbols)</th>
            <th style="border:3px solid black;text-align:center;">PAYLOAD<br/>(368 bits / 184 symbols)</th>
        </tr>
    </tbody>
</table>

The Data Link Layer Contents of a specific frame are processed with techniques (forward error correction) that aid in error correction at the receiver.  It is these forward error corrected contents that are inserted into the Payload portion of the Frame.  The exact forward error correction techniques used vary by frame type. 

<center><span style="font-weight:bold">Figure 1</span> Contents to Payload</center>
[mermaid]
graph LR
  contents[Data Link Layer Contents] --> fec[Forward Error Correction] --> payload[Payload]
  style contents fill:#ffffffff,stroke:#ffffffff,stroke-width:0px
  style fec fill:#fff,stroke:#000,stroke-width:2px
  style payload fill:#ffffffff,stroke:#ffffffff,stroke-width:0px
[/mermaid]


### Modes

The Data Link layer shall operate in one of three modes during a [Transmission](../physical-layer#transmission).

* [Stream Mode](#stream-mode)  
  Data are sent in a continuous stream for an indefinite amount of time, with no break in physical layer output, until the stream ends. e.g. voice data, bulk data transfers, etc.
  Stream Mode shall start with an LSF and is followed by one or more Stream Frames.

* [Packet Mode](#packet-mode)  
   Data are sent in small bursts, up to 798 bytes at a time, after which the physical layer stops sending data. e.g. messages, beacons, etc.
   Packet Mode shall start with an LSF and is followed by one to 32 Packet Frames.

* [BERT Mode](#bert-mode)  
   PRBS9 is used to fill frames with a deterministic bit sequence.  Frames are sent in a continuous sequence.
   Bert Mode shall start with a BERT frame, and is followed by one or more BERT Frames.

**Note:** As is the convention with other networking protocols, all values and data structures are encoded in big endian byte order.

### Synchronization Burst (Sync Burst)

All frames shall be preceded by 16 bits (8 symbols) of [Sync Burst](../physical-layer#synchronization-burst-sync-burst).  The Sync Burst definition straddles both the Physical Layer and the Data Link Layer.

Only LSF and BERT Sync Bursts may immediately follow the [Preamble](../physical-layer#preamble), and each requires a different Preamble symbol pattern as shown in the table below.  

During a [Transmission](../physical-layer#transmission), only one LSF Sync Burst may be present, and if present, it shall immediately follow the Preamble.

BERT Sync Bursts, if present, may only follow the Preamble or other BERT frames.

Multiple Stream and Packet Sync Bursts may be present during a Transmission.

<center><span style="font-weight:bold">Table 2</span> Frame Specific Sync Bursts</center>
Frame Type | Preamble | Sync Burst Bytes | Sync Burst Symbols
---------- | -------- | ---------------- | ------------------
LSF        | +3, -3   | 0x55 0xF7        | +3, +3, +3, +3, -3, -3, +3, -3
BERT       | -3, +3   | 0xDF 0x55        | -3, +3, -3, -3, +3, +3, +3, +3
Stream     | None     | 0xFF 0x5D        | -3, -3, -3, -3, +3, +3, -3, +3
Packet     | None     | 0x75 0xFF        | +3, -3, +3, +3, -3, -3, -3, -3

### Link Setup Frame (LSF)

The LSF is the intial frame for both Stream and Packet Modes and contains information needed to establish a link.

<center><span style="font-weight:bold">Table 3</span> Link Setup Frame Contents</center>
Field | Length   | Description
----- | ------   | -----------
DST   | 48 bits  | Destination address - Encoded callsign or a special number (eg. a group)
SRC   | 48 bits  | Source address - Encoded callsign of the originator or a special number (eg. a group)
TYPE  | 16 bits  | Information about the incoming data stream
META  | 112 bits | Metadata field, suitable for cryptographic metadata like IVs or single-use numbers, or non-crypto metadata like the sender’s GNSS position.
CRC   | 16 bits  | CRC for the link setup data
Total: 240 bits

##### LSF DST and SRC

Destination and source addresses may be encoded amateur radio callsigns, or special numbers.  See the [Address Encoding Appendix](../../appendix/address-encoding) for details.

##### LSF TYPE

The TYPE field contains information about the frames to follow LSF.  The Packet/Stream indicator bit determines which mode (Packet or Stream) will be used during the transmission.
The remaining field meanings are defined by the specific application.

<center><span style="font-weight:bold">Table 4</span> LSF TYPE definition</center>
Bits   | Meaning
----   | -------
0      | Packet/Stream indicator, 0=Packet Mode, 1=Stream Mode
1..2   | Data type indicator
3..4   | Encryption type
5..6   | Encryption subtype
7..10  | Channel Access Number (CAN)
11..15 | Reserved (don’t care)

##### LSF META

The LSF META field is defined by the specific application.

##### <span id="lsf-crc">LSF CRC</span>

M17 uses a non-standard version of 16-bit CRC with polynomial $x^{16} + x^{14} + x^{12} + x^{11} + x^8 + x^5 + x^4 + x^2 + 1$ or 0x5935 and initial value of 0xFFFF. This polynomial allows for detecting all errors up to hamming distance of 5 with payloads up to 241 bits, which is less than the amount of data in each frame.

As M17’s native bit order is most significant bit first, neither the input nor the output of the CRC algorithm gets reflected.

The input to the CRC algorithm consists of DST, SRC (each 48 bits), 16 bits of TYPE field and 112 bits META, and then depending on whether the CRC is being computed or verified either 16 zero bits or the received CRC.

The test vectors in the following table are calculated by feeding the given message and then 16 zero bits to the CRC algorithm.

<center><span style="font-weight:bold">Table 5</span> CRC Test Vectors</center>
Message                  | CRC Output
-------                  | ----------
(empty string)           | 0xFFFF
ASCII string "A"         | 0x206E
ASCII string "123456789" | 0x772B
Bytes 0x00 to 0xFF       | 0x1c31

### Stream Mode

In Stream Mode, an *indefinite* amount of data is sent continuously without breaks in the physical layer. Stream Mode shall always start with an LSF that has the LSF TYPE Packet/Stream indicator bit set to 1 (Stream Mode).  Following the LSF, one or more Stream Frames may be sent.  

<table>
    <caption><span style="font-weight:bold">Figure 3 </span><span>Stream Mode</span></caption>
    <tbody style="text-align:center;border:none;">
        <tr style="font-weight:bold; color:black;">
            <td style="border:3px solid black;">PREAMBLE</td>
            <td style="border:3px solid black;">LSF SYNC BURST</td>
            <td style="border:3px solid black;">LSF FRAME</td>
            <td style="border:3px solid black;">STREAM SYNC BURST</td>
            <td style="border:3px solid black;">STREAM FRAME</td>
            <td style="border:3px dashed black;">&bull;&bull;&bull;</td>
            <td style="border:3px solid black;">STREAM SYNC BURST</td>
            <td style="border:3px solid black;">STREAM FRAME</td>
            <td style="border:3px solid black;">EoT</td>
        </tr>
    </tbody>
</table>

#### Stream Frames

The stream data to be sent is broken into groups of 128 bits and combined with frame signalling information contained within the [Link Information Channel (LICH)](#link-information-channel-lich). 

<center><span style="font-weight:bold">Table 6</span> Stream Frame Contents</center>
Field   | Length   | Description
-----   | ------   | -----------
LICH    | 48 bits  | LSF chunk, one of 6
FN      | 16 bits  | Frame Number
PAYLOAD | 128 bits | Payload/data, can contain arbitrary data
Total: 192 bits

The Frame Number (FN) starts from 0 and increments every frame to a maximum of 0x7fff where it will then wrap back to 0. The most significant bit in the FN is used for transmission end signalling. When transmitting the last frame, it shall be set to 1 (one), and 0 (zero) in all other frames.

##### Link Information Channel (LICH)

Each Stream Frame contains a 48-bit Link Information Channel (LICH). Each LICH within a Stream Frame includes a 40-bit chunk of the 240-bit LSF frame that was used to establish the stream.  A 3-bit modulo 6 counter (LICH_CNT) is used to indicate which chunk of the LSF is present in the current Stream Frame.  LICH_CNT starts at 0, increments to 5, then wraps back to 0. 

<center><span style="font-weight:bold">Table 7</span> Link Information Channel</center>
Bits   | Content
----   | -------
0..39  | 40-bit chunk of full LSF
40..42 | LICH_CNT
43..47 | Reserved

The 40-bit chunks start with the most significant byte of the LSF.

<center><span style="font-weight:bold">Table 8</span> LICH_CNT and LSF bits</center>
LICH_CNT | LSF bits
-------- | -------
0        | 239:200
1        | 199:160
2        | 159:120
3        | 119:80
4        | 79:40
5        | 39:0

#### Stream Superframes

Stream Frames are grouped into **Stream Superframes**, which is the group of 6 frames that contain everything needed to rebuild the original LSF packet, so that the user who starts listening in the middle of a stream (late-joiner) is eventually able to reconstruct the LSF message and understand how to receive the in-progress stream.

<center><span style="font-weight:bold">Figure 6</span> Stream Superframes</center>
![M17_stream](M17_stream.png?classes=caption "Stream consisting of one superframe")

### Packet Mode

In Packet Mode, up to 798 bytes of payload data (for example, text messages or application layer data) may be sent over the physical layer during one Transmission.  Packet Mode shall always start with an LSF that has the LSF TYPE Packet/Stream indicator bit set to 0 (Packet Mode).  Following the LSF, one or more Packet Frames may be sent.  

Packet Mode acheives a base throughput of 5 kbps, a net throughput of approximately 4.7 kbps for the largest data payload, and over 3 kbps for 100-byte payloads.  Net throughput takes into account preamble and link setup overhead.

<table>
    <caption><span style="font-weight:bold">Figure 3 </span><span>Packet Mode</span></caption>
    <tbody style="text-align:center;border:none;">
        <tr style="font-weight:bold; color:black;">
            <td style="border:3px solid black;">PREAMBLE</td>
            <td style="border:3px solid black;">LSF SYNC BURST</td>
            <td style="border:3px solid black;">LSF FRAME</td>
            <td style="border:3px solid black;">PACKET SYNC BURST</td>
            <td style="border:3px solid black;">PACKET FRAME</td>
            <td style="border:3px dashed black;">&bull;&bull;&bull;</td>
            <td style="border:3px solid black;">PACKET SYNC BURST</td>
            <td style="border:3px solid black;">PACKET FRAME</td>
            <td style="border:3px solid black;">EoT</td>
        </tr>
    </tbody>
</table>

#### Packet Superframes

A **Packet Superframe** consists of 798 packet data bytes and a 2-byte CRC checksum (800 bytes total).  The CRC used here is the same as described in [LSF CRC](#lsf-crc).

<center><span style="font-weight:bold">Table 9</span> Packet Superframe Contents</center>
Bytes  | Meaning
-----  | -------
1..798 | Packet data
2      | CRC

#### Packet Frames

Packet Frame Contents has 200 bits (25 bytes) of payload data and 6 bits of frame metadata (note that it does not terminate on a byte boundary).  

The metadata field contains a 1-bit **End of Frame (EOF) indicator**, and a 5-bit **Packet Frame/Byte Counter**.

Each Packet Frame Content payload contains up to a 25-byte chunk of the Packet Superframe.  The 25-byte chunks start with the first byte of Packet data, and finally end with the 2 CRC bytes.  If fewer than 25 bytes are able to be extracted from the Packet Superframe (i.e. for the last Packet Frame), the Packet Superframe chunk is padded with undefined bytes to reach 25 bytes total.  This results in a minimum of one to a maximum of 32 Packet Frames per Transmission.  The Packet Frame Counter is reset to zero at the start of Packet Mode.  

For each Packet Frame where there is at least 1 byte remaining in the Packet Superframe after removing a 25-byte chunk, the EOF metadata bit is set to zero, the Packet Frame Counter value is inserted into the Packet Frame/Byte Counter metadata field, and the Packet Frame Counter is incremented.

When there are no bytes remaining in the Packet Superframe after removing a 25-byte (or less) chunk, the EOF metadata bit is set to one, the Packet Byte Counter is set to the number of valid bytes extracted in the last chunk (1 to 25), inserted into the Packet Frame/Byte Counter metadata field, and Packet Mode is ended.

<center><span style="font-weight:bold">Table 10</span> Packet Frame Contents</center>
Bits   | Meaning
----   | -------
0..199 | Packet payload
1      | End of Frame (EOF) indicator
5      | Packet Frame/Byte Counter
Total: 206 bits

<br/>

<center><span style="font-weight:bold">Table 11</span> Metadata Field with EOF = 0</center>
Bits | Meaning
---- | -------
0    | Set to 0, Not end of frame
1..5 | Frame number, 0..31

<br/>

<center><span style="font-weight:bold">Table 12</span> Metadata Field with EOF = 1</center>
Bits | Meaning
---- | -------
0    | Set to 1, End of frame
1..5 | Number of bytes in frame, 1..25

### BERT Mode

BERT mode is a standardized, interoperable mode for bit error rate testing.  The preamble is 
sent, followed by an indefinite sequence of BERT frames.  Notably, a link setup frame must not
be sent in BERT mode.

<table>
    <caption><span style="font-weight:bold">Figure X </span><span>BERT Mode</span></caption>
    <tbody style="text-align:center;border:none;">
        <tr style="font-weight:bold; color:black;">
            <td style="border:3px solid black;">PREAMBLE</td>
            <td style="border:3px solid black;">BERT SYNC BURST</td>
            <td style="border:3px solid black;">BERT FRAME</td>
            <td style="border:3px dashed black;">&bull;&bull;&bull;</td>
            <td style="border:3px solid black;">BERT SYNC BURST</td>
            <td style="border:3px solid black;">BERT FRAME</td>
            <td style="border:3px solid black;">EoT</td>
        </tr>
    </tbody>
</table>

#### Purpose

The primary purpose of defining a bit error rate testing standard for M17 is to enhance
interoperability testing across M17 hardware and software implementations, and to aid in the
configuration and tuning of ad hoc communications equipment common in amateur radio.

#### BERT Frames

Each BERT frame is preceeded by the BERT sync word, 0xDF55.

The BERT frame consists of 197 bits from a [PRBS9](https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence)
generator.  This is 24 bytes and 5 bits of data.  The next frame starts with the 198th bit from the PRBS9
generator.  The same generator is used for each subsequent frame without being reset.  The number of bits
pulled from the generator, 197, is a prime number.  This will produce a reasonably large number of unique
frames even with a PRBS generator with a relatively short period.

The PRBS uses the ITU standard PRBS9 polynomial : \(x^{9}+x^{5}+1\)

This is the traditional form for a linear feedback shift register (LFSR) used
to generate a psuedorandom binary sequence.

<center><span style="font-weight:bold">Figure X</span> Traditional form LFSR</center>
![Traditional_LFSR](m17-traditional-lfsr.png?classes=caption "Traditional LFSR")

However, the M17 LFSR is a slightly different.  The M17 PRBS9 uses the
generated bit as the output bit rather than the high-bit before the shift.

<center><span style="font-weight:bold">Figure X</span> M17 LFSR</center>
![M17_LFSR](m17-prbs9.png?classes=caption "M17 LFSR")

This will result in the same sequence, just shifted by nine bits.

\({M17\_PRBS}_{n} = {PRBS9}_{n + 8}\)

The reason for this is that it allows for easier synchronization.  This is
equivalent to a multiplicative scrambler (a self-synchronizing scrambler)
fed with a stream of 0s.

<center><span style="font-weight:bold">Figure X</span> M17 PRBS9 Generator</center>
![M17_PRBS9_Generator](m17-equivalent-scrambler.png?classes=caption "M17 PRBS9 Generator")

```
  class PRBS9 {
    static constexpr uint16_t MASK = 0x1FF;
    static constexpr uint8_t TAP_1 = 8;       // Bit 9
    static constexpr uint8_t TAP_2 = 4;       // Bit 5

    uint16_t state = 1;

  public:
    bool generate()
    {
        bool result = ((state >> TAP_1) ^ (state >> TAP_2)) & 1;
        state = ((state << 1) | result) & MASK;
        return result;
    }
    ...
  };
```

The PRBS9 SHOULD be initialized with a state of 1.

<center><span style="font-weight:bold">Table X</span> BERT Frame Contents</center>
Bits  | Meaning
----  | -------
0-196 | BERT PRBS9 Payload

(..note to describe convolutional coder as appending 4 flush bits.. 4 + 197 = 201 bits)
(..section needs reworking to be consistent with other sections..)
The 201 bits are convolutionally encoded to 402 type 2 bits.

The 402 bits are punctured using the P2 puncture matrix to get 368 type 3 bits.

The 368 punctured bits are interleaved and decorrelated to get the type 4 bits
to be transmitted.

This provides the same error correction coding used for the stream payload.

<center><span style="font-weight:bold">Table X</span> BERT Frame</center>
Bits  | Meaning
----  | -------
16    | Sync word 0xDF55
368   | Payload

(..needs cleanup to here..)

#### BERT Receiver

The receiver detects the frame is a BERT frame based on the sync word
received.  If the PRBS9 generator is reset at this point, the sender and
receiver should be synchonized at the start.  This, however, is not common
nor is it required. PRBS generators can be self-synchronizing.

##### Synchronization

The receiver will synchronize the PRBS by first XORing the received bit
with the LFSR taps.  If the result of the XOR is a 1, it is an error (the
expected feedback bit and the input do not match) and the sync count is
reset.  The received bit is then also shifted into the LFSR state register.
Once a sequence of eighteen (18) consecutive good bits are recovered (twice
the length of the LFSR), the stream is considered syncronized.

<center><span style="font-weight:bold">Figure X</span> M17 PRBS9 Synchronization</center>
![M17_PRBS9_Sync](m17-prbs9-sync.png?classes=caption "M17 PRBS9 Sync")

During synchronization, bits received and bit errors are not counted towards
the overall bit error rate.

```
  class PRBS9 {
    ...
    static constexpr uint8_t LOCK_COUNT = 18;   // 18 consecutive good bits.
    ...
    // PRBS Syncronizer. Returns 0 if the bit matches the PRBS, otherwise 1.
    // When synchronizing the LFSR used in the PRBS, a single bad input bit
    // will result in 3 error bits being emitted, one for each tap in the LFSR.
    bool syncronize(bool bit)
    {
        bool result = (bit ^ (state >> TAP_1) ^ (state >> TAP_2)) & 1;
        state = ((state << 1) | bit) & MASK;
        if (result) {
            sync_count = 0; // error
        } else {
            if (++sync_count == LOCK_COUNT) {
                synced = true;
                ...
            }
        }
        return result;
    }
    ...
  };
```

##### Counting Bit Errors

After synchronization, BERT mode switches to error-counting mode, where the
received bits are compared to a free-running PRBS9 generator.  Each bit that
does not match the output of the free-running LFSR is counted as a bit error.

<center><span style="font-weight:bold">Figure X</span> M17 PRBS9 Validation</center>
![M17_PRBS9_Validation](m17-prbs9-validation.png?classes=caption "M17 PRBS9 Validation")

```
  class PRBS9 {
    ...
    // PRBS validator.  Returns 0 if the bit matches the PRBS, otherwise 1.
    // The results are only valid when sync() returns true;
    bool validate(bool bit)
    {
        bool result;
        if (!synced) {
            result = synchronize(bit);
        } else {
            // PRBS is now free-running.
            result = bit ^ generate();
            count_errors(result);
        }
        return result;
    }
    ...
  };
```

##### Resynchronization

The receiver must keep track of the number of bit errors over a period of
128 bits.  If more than 18 bit errors occur, the synchronization process
starts anew.  This is necessary in the case of missed frames or other serious
synchronization issues.

Bits received and errors which occur during resynchronization are not counted
towards the bit error rate.

#### References

 - [ITU O.150 : Digital test patterns for performance measurements on digital transmission equipment](http://www.itu.int/rec/T-REC-O.150-199210-S)
 - [PRBS (according ITU-T O.150) and Bit-Sequence Tester : VHDL-Modules](http://www.pldworld.com/_hdl/5/-thorsten-gaertner.de/vhdl/PRBS.pdf)

---

## FEC items that need work


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






### Issues to address...

* Nothing to consistently address loss of signal/fades/missing EoT
* No limit on transmission duration
* FN rollover - allowed or not?
* More details on Golay choice/performance
* Golay(24,12) matrix in C form (in appendix)


------

### Holding area


### Payload

The Payload size varies depending on the frame type, but shall be in multiples of 2 bits.

<table>
    <caption><span>Table 3</span><span>Payload Size</span></caption>
    <thead>
        <tr>
            <th>Frame Type</th>
            <th>Payload Bits</th>
            <th>Payload Symbols</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>LSF</td>
            <td>244</td>
            <td>122</td>
        </tr>
        <tr>
            <td>BERT</td>
            <td></td>
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

TAIL  | 4 bits   | Flushing bits for the convolutional encoder that do not carry any information. Only included for RF frames, not included for IP purposes.
TAIL    | 4 bits   | Flushing bits for the convolutional encoder that don’t carry any information
4      | Flush bits for convolutional coder

The fields in Table 3 (except TAIL) form initial LSF. It contains all information needed to establish M17 link. Later in the transmission, the initial LSF is divided into 6 “chunks” and transmitted beside the payload data. This allows late-joiners to reconstruct the LICH after collecting all the pieces, and start decoding the stream even though they missed the beginning of the transmission. The process of collecting full LSF takes 6 frames or 6\*40 ms = 240 ms. Four TAIL bits are needed for the convolutional coder to go back to state 0, so the ending trellis position is also known. 


<table>
    <caption><span>Sync Burst</span></caption>
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


##### Voice Coder Rates

Voice coder rate is inferred from TYPE field, bits 1 and 2.

Data Type Indicator | Voice Coder Rate
------------------- | ----------------
$00_2$              | none / reserved
$01_2$              | no voice
$10_2$              | 3200 bps
$11_2$              | 1600 bps

Bits   | Meaning
----   | -------
0      | Packet/Stream indicator, 0=Packet Mode, 1=Stream Mode
1..2   | Data type indicator, $01_2$ =data (D), $10_2$ =voice (V), $11_2$ =V+D, $00_2$ =reserved
3..4   | Encryption type, $00_2$ =none, $01_2$ =AES, $10_2$ =scrambling, $11_2$ =other/reserved
5..6   | Encryption subtype (meaning of values depends on encryption type)
7..10  | Channel Access Number (CAN)
11..15 | Reserved (don’t care)


The payload is used so that earlier data in the voice stream is sent first. For mixed voice and data payloads, the voice data is stored first, then the data.

##### Payload Example 1

`Codec2 encoded frame t + 0 | Codec2 encoded frame t + 1`

##### Payload Example 2

`Codec2 encoded frame t + 0 | Mixed data t + 0`




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







[mermaid]
graph TD
c0["conv. coder"]
p0["P_1 puncturer"]
i0["interleaver"]
w0["randomizer"]
s0["prepend LSF_SYNC"]
l0["LICH combiner"]
chunker_40["chunk 40 bits"]
golay_24_12["Golay (24, 12)"]
c1["conv. coder"]
p1["P_2 puncturer"]
i1["interleaver"]
w1["randomizer"]
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


Packet data is split into frames of 368 type 4 bits preceded by a packet-specific 16-bit sync word (0xFF5D). This is the same size frame used by stream mode.


#### Packet Frame Convolutional Coding

The entire frame is convolutionally coded, giving 420 bits of type 2 data. It is then punctured using a 7/8 puncture matrix (1,1,1,1,1,1,1,0) to give 368 type 3 bits. These are then interleaved and decorrelated to give 368 type 4 bits.

##### zzzPacket Frame

Bits     | Meaning
----     | -------
16 bits  | Sync word 0xFF5D
368 bits | Payload



