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
channel bandwidth. Channel spacing is 12.5 kHz. 

The symbol stream is converted (upsampled) to a series of impulses which pass through a
root-raised-cosine (alpha=0.5) shaping filter before frequency modulation
at the transmitter and again after frequency demodulation at the
receiver.

Upsampling by a factor of 10 is recommended (48000 samples/s).

The root-raised-cosine filter should span at least 8 symbols (80 samples, 81 taps).

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

Each of the 4-level frequency-shifts can be represented by dibits (2-bit values) or symbols, as shown in Table 1 below.  

In the case of dibits, the most significant bit is sent first. When four dibits are grouped into a byte, the most significant dibit of the byte is sent first. For example, the four dibits contained in the byte 0xB4 (0b 10 11 01 00) would be sent as the symbols (-1, -3, +3, +1).

<table>
    <caption><span>Table 1 </span><span>Dibit symbol mapping to 4FSK deviation</span></caption>
    <thead>
        <tr>
            <th colspan="2">Dibit</th>
            <th rowspan="2">Symbol</th>
            <th rowspan="2">4FSK deviation</th>
        </tr>
        <tr>
            <th>MSB</th>
            <th>LSB</th>
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

### Transmission

A complete transmission shall consist of a preamble, a synchronization burst, data, and an end of transmission marker.

![physical_layer_transmission](phy_layer.svg?classes=caption "Physical Layer Transmission")

### Preamble

Every transmission shall start with a preamble, which shall consist of 40 ms (192 symbols) of alternating outer symbols (+3, -3) or (-3, +3). To ensure a zero crossing prior to a synchronization burst, the last symbol transmitted within the preamble shall be opposite the first symbol transmitted in the synchronization burst.

### Synchronization Burst (Sync Burst)

A sync burst of 16 bits (8 symbols) shall be sent immediately after the preamble. The sync burst is constructed using only outer symbols, with 
codings based on [Barker codes](https://en.wikipedia.org/wiki/Barker_code). Properly chosen sync burst coding assists in symbol clocking and alignment. 
Different sync burst codes may also be used by the Data Link Layer to identify the type of data to follow.

### Data

Data shall be transmitted in multiples of 8 bits (4 symbols).

#### Randomizer

To avoid transmitting long sequences of constant symbols (e.g. +3, +3, +3, ...), a simple randomizing algorithm is used. At the transmitter, all data bits shall be XORed with a pseudorandom predefined stream before being converted to symbols.  At the receiver, the randomized data symbols are converted to bits and are
again passed through the same XOR algorithm to obtain the original data bits.   

!!! algorithm should be here !!!

### End of Transmission marker (EoT)

Every transmission ends with a distinct symbol stream, which shall consist of of 40 ms (192 symbols) of a repeating 0x55 0x5D (+3, +3, +3, +3, +3, +3, -3, +3) pattern.


