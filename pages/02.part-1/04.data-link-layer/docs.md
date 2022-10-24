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

#### Forward Error Correction (FEC)
The Data Link Layer Contents of a specific frame are modified using various Error Correction Code (ECC) methods. Applying these codes at the transmitter allows the receiver to correct some amount of induced errors in a Forward Error Correction (FEC) process.  It is this ECC/FEC data that is inserted into the Payload portion of the Frame.  The exact ECC/FEC techniques used vary by frame type. 

Applying ECC/FEC may be a multi-step process.  To distinguish data bits at the various stages of the process, Bit Types are defined as shown in the following table.  It is important to note that not all ECC/FEC processes utilize both Type 2 and Type 3 bits.  Prior to decoding Data Link Layer contents, a receiver would need to convert incoming bits from Type 4 back to Type 1 bits, which may also include conversion through Type 3 and/or Type 2 bits.  The exact ECC/FEC methods and Bit Types utilized will be indicated for each frame type.

<center><span style="font-weight:bold">Table 2</span> Bit Types</center>
Type   | Description
----   | -----------
Type 1 | Data link layer content bits
Type 2 | Bits after appropriate encoding
Type 3 | Bits after puncturing
Type 4 | Interleaved (re-ordered) bits

<center><span style="font-weight:bold">Figure 6</span> Transmit Contents to Payload</center>
[mermaid]
graph LR
  contents[Data Link Layer Contents] -- Type 1 bits --> fec[ECC/FEC Encode] -- Type 4 bits--> payload[Payload]
  style contents fill:#ffffffff,stroke:#ffffffff,stroke-width:0px
  style fec fill:#fff,stroke:#000,stroke-width:2px
  style payload fill:#ffffffff,stroke:#ffffffff,stroke-width:0px
[/mermaid]

<center><span style="font-weight:bold">Figure 7</span> Receive Payload to Contents</center>
[mermaid]
graph LR
  payload[Payoad] -- Type 4 bits --> fec[ECC/FEC Decode] -- Type 1 bits--> contents[Data Link Layer Contents]
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

Multiple Stream or Packet Sync Bursts may be present during a Transmission, depending on the mode.

<center><span style="font-weight:bold">Table 3</span> Frame Specific Sync Bursts</center>
Frame Type | Preamble | Sync Burst Bytes | Sync Burst Symbols
---------- | -------- | ---------------- | ------------------
LSF        | +3, -3   | 0x55 0xF7        | +3, +3, +3, +3, -3, -3, +3, -3
BERT       | -3, +3   | 0xDF 0x55        | -3, +3, -3, -3, +3, +3, +3, +3
Stream     | None     | 0xFF 0x5D        | -3, -3, -3, -3, +3, +3, -3, +3
Packet     | None     | 0x75 0xFF        | +3, -3, +3, +3, -3, -3, -3, -3

### Link Setup Frame (LSF)

The LSF is the intial frame for both Stream and Packet Modes and contains information needed to establish a link.

<center><span style="font-weight:bold">Table 4</span> Link Setup Frame Contents</center>
Field | Length   | Description
----- | ------   | -----------
DST   | 48 bits  | Destination address - Encoded callsign or a special number (eg. a group)
SRC   | 48 bits  | Source address - Encoded callsign of the originator or a special number (eg. a group)
TYPE  | 16 bits  | Information about the incoming data stream
META  | 112 bits | Metadata field, suitable for cryptographic metadata like IVs or single-use numbers, or non-crypto metadata like the sender’s GNSS position.
CRC   | 16 bits  | CRC for the link setup data
Total: 240 Type 1 bits

##### LSF DST and SRC

Destination and source addresses may be encoded amateur radio callsigns, or special numbers.  See the [Address Encoding Appendix](../../appendix/address-encoding) for details.

##### LSF TYPE

The TYPE field contains information about the frames to follow LSF.  The Packet/Stream indicator bit determines which mode (Packet or Stream) will be used during the transmission.
The remaining field meanings are defined by the specific mode and application.

<center><span style="font-weight:bold">Table 5</span> LSF TYPE definition</center>
Bits   | Content
----   | -------
0      | Packet/Stream indicator
1..2   | Data type indicator
3..4   | Encryption type
5..6   | Encryption subtype
7..10  | Channel Access Number (CAN)
11..15 | Reserved (don’t care)

<center><span style="font-weight:bold">Table 5a</span> Packet/Stream indicator</center>
Value  | Content
----   | -------
0      | Packet mode
1      | Stream mode

<center><span style="font-weight:bold">Table 5b</span> Data type</center>
Value    | Content
----     | -------
\(00_2\) | Reserved
\(01_2\) | Data
\(10_2\) | Voice
\(11_2\) | Voice+Data

<center><span style="font-weight:bold">Table 5c</span> Encryption type</center>
Value    | Content
----     | -------
\(00_2\) | None
\(01_2\) | AES
\(10_2\) | Scrambler
\(11_2\) | Other/reserved

For the encryption subtype, meaning of values depends on encryption type.

##### LSF META

The LSF META field is defined by the specific application.

##### <span id="lsf-crc">LSF CRC</span>

M17 uses a non-standard version of 16-bit CRC with polynomial $x^{16} + x^{14} + x^{12} + x^{11} + x^8 + x^5 + x^4 + x^2 + 1$ or 0x5935 and initial value of 0xFFFF. This polynomial allows for detecting all errors up to hamming distance of 5 with payloads up to 241 bits, which is less than the amount of data in each frame.

As M17’s native bit order is most significant bit first, neither the input nor the output of the CRC algorithm gets reflected.

The input to the CRC algorithm consists of DST, SRC (each 48 bits), 16 bits of TYPE field and 112 bits META, and then depending on whether the CRC is being computed or verified either 16 zero bits or the received CRC.

The test vectors in the following table are calculated by feeding the given message and then 16 zero bits to the CRC algorithm.

<center><span style="font-weight:bold">Table 6</span> CRC Test Vectors</center>
Message                  | CRC Output
-------                  | ----------
(empty string)           | 0xFFFF
ASCII string "A"         | 0x206E
ASCII string "123456789" | 0x772B
Bytes 0x00 to 0xFF       | 0x1C31

#### LSF Contents ECC/FEC

The 240 Type 1 bits of the Link Setup Frame Contents along with 4 flush bits are [convolutionally coded](../../04.appendix/03.convolutional-encoder) using a rate 1/2 coder with constraint K=5.  244 bits total are encoded resulting in 488 Type 2 bits.

Type 3 bits are computed by [\(P_1\) puncturing](../../04.appendix/05.code-puncturing) the Type 2 bits, resulting in 368 Type 3 bits.

[Interleaving](../../04.appendix/06.interleaving/) the Type 3 bits produces 368 Type 4 bits that are ready to be passed to the Physical Layer.

Within the Physical Layer, the 368 Type 4 bits are randomized and combined with the 16-bit LSF Sync Burst, which results in a complete frame of 384 bits (384 bits / 9600bps = 40 ms).

<center><span style="font-weight:bold">Figure 8</span> LSF Construction</center>
[mermaid]
graph TD

lsf_conv_coder["convolutional encoder"]
lsf_p1_puncturer["P<sub>1</sub> puncturer"]
lsf_interleaver["interleaver"]
lsf_randomizer["randomizer"]
lsf_sync["prepend LSF Sync Burst"]
lsf_flush["add 4 flush bits"]

phy_cont["Physical Layer Continues..."]

classDef default fill:#fff,stroke:#000,stroke-width:2px

subgraph phy["Physical Layer"]
    lsf_randomizer --> lsf_sync -- 384-bit Frame -->phy_cont
end

subgraph data_link["Data Link Layer"]
    LSF[LSF Contents] -- 240 Type 1 bits--> lsf_flush --> lsf_conv_coder -- 488 Type 2 bits --> lsf_p1_puncturer -- 368 Type 3 bits --> lsf_interleaver -- 368 Type 4 bits --> lsf_randomizer
end

[/mermaid]


### Stream Mode

In Stream Mode, an *indefinite* amount of data is sent continuously without breaks in the physical layer. Stream Mode shall always start with an LSF that has the LSF TYPE Packet/Stream indicator bit set to 1 (Stream Mode). Other valid LSF TYPE parameters are selected per application.

Following the LSF, one or more Stream Frames may be sent.  

<table>
    <caption><span style="font-weight:bold">Figure 9 </span><span>Stream Mode</span></caption>
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

Stream Frames are composed of frame signalling information contained within the [Link Information Channel (LICH)](#link-information-channel-lich) combined with [Stream Contents](#stream-contents).  Both the LICH and Stream Contents utilize different ECC/FEC mechanisms, and are combined at the bit level in a [Frame Combiner](#frame-combiner).


##### Link Information Channel (LICH)

The LICH allows for late listening and indepedent decoding to check destination address if the LSF for the current transmission was missed.

Each Stream Frame contains a 48-bit Link Information Channel (LICH). Each LICH within a Stream Frame includes a 40-bit chunk of the 240-bit LSF frame that was used to establish the stream.  A 3-bit modulo 6 counter (LICH_CNT) is used to indicate which chunk of the LSF is present in the current Stream Frame.  LICH_CNT starts at 0, increments to 5, then wraps back to 0. 

<center><span style="font-weight:bold">Table 7</span> Link Information Channel Contents</center>
Bits   | Content
----   | -------
0..39  | 40-bit chunk of full LSF Contents (Type 1 bits)
40..42 | LICH_CNT
43..47 | Reserved
Total: 48 bits

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

##### LICH Contents ECC/FEC

The 48-bit LICH Contents is partitioned into 4 12-bit parts and encoded using [Golay (24, 12) code](../../appendix/golay-encoder). This produces 96 encoded Type 2 bits that are fed into the [Frame Combiner](#frame-combiner).

##### Stream Contents

<center><span style="font-weight:bold">Table 9</span> Stream Contents</center>
Field   | Length   | Description
-----   | ------   | -----------
FN      | 16 bits  | Frame Number
STREAM  | 128 bits | Stream data, can contain arbitrary data
Total: 144 Type 1 bits

The Frame Number (FN) starts from 0 and increments every frame to a maximum of 0x7fff where it will then wrap back to 0. The most significant bit in the FN is used for transmission end signalling. When transmitting the last frame, it shall be set to 1 (one), and 0 (zero) in all other frames.

Stream data (STREAM) is obtained by extracting 128 bits at a time from the continuous stream of application layer data. If the last frame will contain less than 128 bits of valid data, the remaining bits should be set to zero.  

##### Stream Contents ECC/FEC

The 144 Type 1 bits of Stream Contents along with 4 flush bits are [convolutionally coded](#../../04.appendix/03.convolutional-encoder) using a rate 1/2 coder with constraint K=5.  148 bits total are encoded resulting in 296 Type 2 bits. 

These bits are [\(P_2\) punctured](../../04.appendix/05.code-puncturing) to generate 272 Type 3 bits that are fed into the [Frame Combiner](#frame-combiner).

##### Frame Combiner

The 96 Type 2 bits of the ECC/FEC LICH Contents are concatenated with 272 Type 3 bits of the ECC/FEC Stream Contents resuting in 368 of combined Type 2/3 bits.

<center><span style="font-weight:bold">Table 10</span> LICH and Stream Combined</center>
Field  | Length   | Description
------ | ------   | -----------
LICH   | 96 bits  | ECC/FEC LICH Contents Type 2 bits
STREAM | 272 bits | ECC/FEC STREAM Contents Type 3 bits
Total: 368 Type 2/3 bits

[Interleaving](../../04.appendix/06.interleaving/) the Combined Type 2/3 bits produces 368 Type 4 bits that are ready to be passed to the Physical Layer.

Within the Physical Layer, the 368 Type 4 bits are randomized and combined with the 16-bit Stream Sync Burst, which results in a complete frame of 384 bits (384 bits / 9600bps = 40 ms).

<center><span style="font-weight:bold">Figure 10</span> Stream Frame Construction</center>
[mermaid]
graph TD

lich_chunk_40["chunk 40 bits"]
lich_golay_24_12["Golay (24, 12)"]
lich_counter["add LICH counter"]

stream_data["Stream Data"]
stream_chunk_128["chunk 128 bits"]
stream_frame_number["prepend frame number"]
stream_flush["add 4 flush bits"]
stream_conv_coder["convolutional encoder"]
stream_p2_puncturer["P<sub>2</sub> puncturer"]

lich_stream_frame_combiner["Frame Combiner"]

stream_interleaver["interleaver"]
stream_randomizer["randomizer"]
stream_sync["prepend Stream Sync Burst"]

phy_cont["Physical Layer Continues..."]

classDef default fill:#fff,stroke:#000,stroke-width:2px

subgraph phy ["Physical Layer"]
    stream_randomizer --> stream_sync -- 384-bit Frame --> phy_cont
end

subgraph data_link["Data Link Layer"]
    LSF[LSF Contents] --> lich_chunk_40 -- 40 Type 1 bits --> lich_counter --> lich_golay_24_12 -- 96 Type 2 bits --> lich_stream_frame_combiner
    stream_chunk_128 --> stream_frame_number -- 144 Type 1 bits --> stream_flush --> stream_conv_coder -- 296 Type 2 bits --> stream_p2_puncturer -- 272 Type 3 bits --> lich_stream_frame_combiner
    lich_stream_frame_combiner -- 96 Type 2 bits + 372 Type 3 bits = 368 Type 2/3 bits --> stream_interleaver -- 368 Type 4 bits --> stream_randomizer
end

subgraph application_layer["Application Layer"]
    stream_data -- Continuous data --> stream_chunk_128
end

[/mermaid]

#### Stream Superframes

Stream Frames are grouped into Stream Superframes, which is the group of 6 frames that contain everything needed to rebuild the original LSF packet, so that the user who starts listening in the middle of a stream (late-joiner) is eventually able to reconstruct the LSF message and understand how to receive the in-progress stream.

<center><span style="font-weight:bold">Figure 11</span> Stream Superframes</center>
![M17_stream](M17_stream.png?classes=caption "Stream consisting of one superframe")

### Packet Mode

In Packet Mode, a Single Packet with up to 798 bytes of Application Packet Data along with an appended two byte CRC may be sent over the physical layer during one Transmission.  

<center><span style="font-weight:bold">Table 11</span> Single Packet</center>
Bytes  | Meaning
-----  | -------
1..798 | Application Packet Data
2      | CRC
Total: 800 bytes (maximum)

The CRC used here is the same as described in [LSF CRC](#lsf-crc).

Packet Mode shall always start with an LSF that has the LSF TYPE Packet/Stream indicator bit set to 0 (Packet Mode).  Following the LSF, one to 32 Packet Frames may be sent.  

Packet Mode acheives a base throughput of 5 kbps, a net throughput of approximately 4.7 kbps for the largest data payload, and over 3 kbps for 100-byte payloads.  Net throughput takes into account preamble and link setup overhead.

<table>
    <caption><span style="font-weight:bold">Figure 12 </span><span>Packet Mode</span></caption>
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

#### Packet Frames

Packet Frames contain Packet Contents after ECC/FEC is applied. 

#### Packet Contents

<center><span style="font-weight:bold">Table 12</span> Packet Contents</center>
Bits   | Meaning
----   | -------
0..199 | 200-bit chunk of Single Packet 
1      | End of Frame (EOF) indicator
5      | Packet Frame/Byte Counter
Total: 206 Type 1 bits

The metadata field contains the 1-bit End of Frame (EOF) indicator, and the 5-bit Packet Frame/Byte Counter.

Each Packet Frame Content payload contains up to a 25-byte chunk of the Single Packet.  The 25-byte chunks start with the first byte of the Application Packet data, and finally end with the 2 CRC bytes.  If fewer than 25 bytes are able to be extracted from the Single Packet (i.e. for the last Packet Frame), the Single Packet chunk is padded with undefined bytes to reach 25 bytes total.  This results in a minimum of one to a maximum of 32 Packet Frames per Transmission.  The Packet Frame Counter is reset to zero at the start of Packet Mode.  

For each Packet Frame where there is at least 1 byte remaining in the Single Packet after removing a 25-byte chunk, the EOF metadata bit is set to zero, the Packet Frame Counter value is inserted into the Packet Frame/Byte Counter metadata field, and the Packet Frame Counter is incremented.

When there are no bytes remaining in the Single Packet after removing a 25-byte (or less) chunk, the EOF metadata bit is set to one, the Packet Byte Counter is set to the number of valid bytes extracted in the last chunk (1 to 25), inserted into the Packet Frame/Byte Counter metadata field, and Packet Mode is ended.

<br/>

<center><span style="font-weight:bold">Table 13</span> Metadata Field with EOF = 0</center>
Bits | Meaning
---- | -------
0    | Set to 0, Not end of frame
1..5 | Frame number, 0..31

<br/>

<center><span style="font-weight:bold">Table 14</span> Metadata Field with EOF = 1</center>
Bits | Meaning
---- | -------
0    | Set to 1, End of frame
1..5 | Number of bytes in frame, 1..25

##### Packet Contents ECC/FEC

The 206 Type 1 bits of the Packet Contents along with 4 flush bits are [convolutionally coded](#../../04.appendix/03.convolutional-encoder) using a rate 1/2 coder with constraint K=5.  210 bits total are encoded resulting in 410 Type 2 bits. 

These bits are [\(P_3\) punctured](../../04.appendix/05.code-puncturing) to generate 368 Type 3 bits.

[Interleaving](../../04.appendix/06.interleaving/) the Type 3 bits produces 368 Type 4 bits that are ready to be passed to the Physical Layer.

Within the Physical Layer, the 368 Type 4 bits are randomized and combined with the 16-bit Packet Sync Burst, which results in a complete frame of 384 bits (384 bits / 9600bps = 40 ms).

<center><span style="font-weight:bold">Figure 13</span> Packet Frame Construction</center>
[mermaid]
graph TD

packet_data["Packet Data"]
packet_crc["add CRC"]
packet_chunk_200["chunk 200 bits"]
packet_frame_number["add metadata"]
packet_flush["add 4 flush bits"]
packet_conv_coder["convolutional encoder"]
packet_p3_puncturer["P<sub>3</sub> puncturer"]
packet_interleaver["interleaver"]
packet_randomizer["randomizer"]
packet_sync["prepend Packet Sync Burst"]

phy_cont["Physical Layer Continues..."]

classDef default fill:#fff,stroke:#000,stroke-width:2px

subgraph phy ["Physical Layer"]
    packet_randomizer -->packet_sync --> phy_cont
end

subgraph data_link["Data Link Layer"]
    packet_crc --> packet_chunk_200 --> packet_frame_number -- 206 Type 1 bits --> packet_flush --> packet_conv_coder -- 420 Type 2 bits --> packet_p3_puncturer --  368 Type 3 bits --> packet_interleaver -- 368 Type 4 bits --> packet_randomizer
end

subgraph application_layer["Application Layer"]
    packet_data -- 798 bytes max per packet --> packet_crc
end
[/mermaid]

#### Packet Superframes

A Packet Superframe consists of up to the 32 Packet Frames used to reconstruct the original Single Packet.

### BERT Mode

BERT mode is a standardized, interoperable mode for bit error rate testing.  The preamble is 
sent, followed by an indefinite sequence of BERT frames.  Notably, an LSF is not sent in BERT mode.

The primary purpose of defining a bit error rate testing standard for M17 is to enhance
interoperability testing across M17 hardware and software implementations, and to aid in the
configuration and tuning of ad hoc communications equipment common in amateur radio.

<table>
    <caption><span style="font-weight:bold">Figure 14 </span><span>BERT Mode</span></caption>
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

#### BERT Frames

BERT Frames contain BERT Contents after ECC/FEC is applied.

##### BERT Contents

The BERT Contents consists of 197 bits from a [PRBS9](https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence)
generator.  This is 24 bytes and 5 bits of data.  The next BERT Contents starts with the 198th bit from the PRBS9
generator.  The same generator is used for each subsequent BERT Contents without being reset.  The number of bits
pulled from the generator, 197, is a prime number.  This will produce a reasonably large number of unique
frames even with a PRBS generator with a relatively short period.  

See the Appendix for [BERT generation and reception details](../../04.appendix/07.bert-details).

<center><span style="font-weight:bold">Table 15</span> BERT Contents</center>
Bits  | Meaning
----  | -------
0-196 | BERT PRBS9 Payload
Total: 197 Type 1 bits

##### BERT Contents ECC/FEC

The 197 Type 1 bits of the Packet Contents along with 4 flush bits are [convolutionally coded](#../../04.appendix/03.convolutional-encoder) using a rate 1/2 coder with constraint K=5.  201 bits total are encoded resulting in 402 Type 2 bits. 

These bits are [\(P_2\) punctured](../../04.appendix/05.code-puncturing) to generate 368 Type 3 bits.

[Interleaving](../../04.appendix/06.interleaving/) the Type 3 bits produces 368 Type 4 bits that are ready to be passed to the Physical Layer.

This provides the same error ECC/FEC used for Stream Frames.

Within the Physical Layer, the 368 Type 4 bits are randomized and combined with the 16-bit BERT Sync Burst, which results in a complete frame of 384 bits (384 bits / 9600bps = 40 ms).

<center><span style="font-weight:bold">Figure 15</span> BERT Frame Construction</center>
[mermaid]
graph TD

bert_data["BERT PRBS9 Data"]
bert_chunk_197["chunk 197 bits"]
bert_flush["add 4 flush bits"]
bert_conv_coder["convolutional encoder"]
bert_p2_puncturer["P_2 puncturer"]
bert_interleaver["interleaver"]
bert_randomizer["randomizer"]
bert_sync["prepend BERT Sync Burst"]

phy_cont["Physical Layer Continues..."]

classDef default fill:#fff,stroke:#000,stroke-width:2px

subgraph phy ["Physical Layer"]
    bert_randomizer --> bert_sync --> phy_cont
end

subgraph data_link["Data Link Layer"]
    bert_data --> bert_chunk_197 -- 197 Type 1 bits --> bert_flush --> bert_conv_coder -- 402 Type 2 bits --> bert_p2_puncturer -- 368 Type 3 bits --> bert_interleaver -- 368 Type 4 bits --> bert_randomizer
end
[/mermaid]


### Issues to address...

* Stream FN rollover - allowed or not?
 

