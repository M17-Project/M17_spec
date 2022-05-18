---
title: 'BERT Details'
taxonomy:
    category:
        - docs
---

#### PRBS Generation

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

#### PRBS Receiver

The receiver detects the frame is a BERT Frame based on the Sync Burst
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

