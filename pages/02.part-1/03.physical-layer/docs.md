---
title: 'Physical Layer'
taxonomy:
    category:
        - docs
simple-responsive-tables:
    active: true
media_order: 
---

### 4-level Frequency-shift Keying Modulation (4FSK)

M17 standard uses 4FSK running at 4800 symbols/s (9600
bits/s) with a deviation index h=0.33 for transmission in 9 kHz
channel bandwidth. Channel spacing is 12.5 kHz. The symbol stream is
converted (upsampled) to a series of impulses which pass through a
root-raised-cosine (alpha=0.5) shaping filter before frequency modulation
at the transmitter and again after frequency demodulation at the
receiver.

!!! Do we need to specify minimal/recommended upsampling rates and minimal/recommended number of RRC taps? !!!

[mermaid]
graph LR
  id1[Dibits Input] --> id2[Upsampler] --> id3[RRC Filter] --> id4[Frequency Modulation] --> id5[4FSK Output]
  style id1 fill:#ffffffff,stroke:#ffffffff,stroke-width:0px
  style id2 fill:#fff,stroke:#000,stroke-width:2px
  style id3 fill:#fff,stroke:#000,stroke-width:2px
  style id4 fill:#fff,stroke:#000,stroke-width:2px
  style id5 fill:#ffffffff,stroke:#ffffffff,stroke-width:0px
[/mermaid]

### Dibit, Symbol, and Frequency-shift

Each of the 4-level frequency-shifts can be represented by dibits (2-bit values) or symbols, as shown in the table below.  

In the case of dibits, the most significant bits are sent first. For example, the four dibits contained in the byte 0xB4 (0b 10 11 01 00) would be sent as the symbols (-1, -3, +3, +1).

<table>
    <caption><span>Table 1 </span><span>Dibit symbol mapping to 4FSK deviation</span></caption>
    <thead>
        <tr>
            <th colspan="2">Information bits</th>
            <th rowspan="2">Symbol</th>
            <th rowspan="2">4FSK deviation</th>
        </tr>
        <tr>
            <th>Bit 1</th>
            <th>Bit 0</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>0</td>
            <td>1</td>
            <td>+3</td>
            <td>+2.4 kHz</td>
        </tr>
        <tr>
            <td>0</td>
            <td>0</td>
            <td>+1</td>
            <td>+0.8 kHz</td>
        </tr>
        <tr>
            <td>1</td>
            <td>0</td>
            <td>-1</td>
            <td>-0.8 kHz</td>
        </tr>
        <tr>
            <td>1</td>
            <td>1</td>
            <td>-3</td>
            <td>-2.4 kHz</td>
        </tr>
    </tbody>
</table>

### Preamble

Every transmission shall start with a preamble, which shall consist of at least 40 ms of alternating outer symbols (+3, -3)  !!! maximum duration recommendation? !!!. This is equivalent to 40 milliseconds of a 2400 Hz tone. The last symbol transmitted within the preamble shall be -3 for all modes except BERT. !!! check?  don't understand !!! This is to avoid unnecessary long constant symbol runs and increase zero-crossing rate.

### Frame

A frame shall be composed of a Sync Burst followed by a Payload.  There are four frame types: Link Setup Frames (LSF), Stream Frames, Packet Frames, and
Bit Error Rate Test (BERT) frames. 

### Synchronization Burst (Sync Burst)

All frames shall be preceded by 16 bits (8 symbols) of *synchronization burst*.

* LSF shall be preceded with 0x55F7 (+3, +3, +3, +3, -3, -3, +3, -3)
* Stream frames shall be preceeded with 0xFF5D (-3, -3, -3, -3, +3, +3, -3, +3)
* Packet frames shall be preceeded with 0x75FF (+3, -3, +3, +3, -3, -3, -3, -3)
* BERT frames shall be preceeded with 0xDF55 (-3, +3, -3, -3, +3, +3, +3, +3)

The Sync Burst codings are based on [Barker codes](https://en.wikipedia.org/wiki/Barker_code). !!! need reference for 4-level Barker Sequences !!!

### Payload

The Payload consists of 368 bits (192 symbols).

#### Randomizer

To avoid transmitting long sequences of constant symbols (e.g. +3, +3, +3, ...), a simple randomizing algorithm is used. At the transmitter, all 368 payload bits shall be XORed with a pseudorandom predefined stream before being converted to symbols.  At the receiver, payload symbols are converted to bits and are
again passed through the same XOR algorithm to obtain the original payload bits.   

!!! algorithm should be here !!!

### End of Transmission marker (EoT)

Every transmission ends with a distinct symbol stream, which shall consist of at least 40 ms !!! but not longer than??? !!! of a repeating 0x555D (+3, +3, +3, +3, +3, +3, -3, +3) pattern.


