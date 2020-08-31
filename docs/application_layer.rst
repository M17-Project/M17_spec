Application Layer
=================

PARTS 1 AND 2 REMOVED – will add this later.

Encryption Types
----------------

Encryption is optional and disabled by default. The use of it is only
allowed if local laws allow to doso.

Null Encryption
~~~~~~~~~~~~~~~

Encryption type = :math:`00_2`

No encryption is performed, payload is sent in clear text.

Scrambler
~~~~~~~~~
Encryption type = :math:`10_2`

Scrambling is an encryption by bit inversion using a bitwise
exclusive-or (XOR) operation between bit sequence of data and
pseudorandom bit sequence.

Encrypting bitstream is generated using a Fibonacci-topology
Linear-Feedback Shift Register (LFSR).  Three different LFSR sizes are
available: 8, 16 and 24-bit. Each shift register has an associated
polynomial. The polynomials are listed in Table 7. The LFSR is
initialised with a seed value of the same length as the shift
register. Seed value acts as an encryption key for the scrambler
algorithm.  Figures 5 to 8 show block diagrams of the algorithm

.. list-table::  LFSR scrambler polynomials

   * - Encryption subtype
     - LFSR polynomial
     - Seed length
     - Sequence period
   * - :math:`00_2`
     - :math:`x^8 + x^6 + x^5 + x^4 + 1`
     - 8 bits
     - 255
   * - :math:`01_2`
     - :math:`x^16 + x^15 + x^13 + x^4 + 1`
     - 16 bits
     - 65,535
   * - :math:`10_2`
     - :math:`x^24 + x^23 + x^22 + x^17 + 1`
     - 24 bits
     - 16,777,215 

.. figure:: ../images/LFSR_8.png
   
   8-bit LFSR taps

.. figure:: ../images/LFSR_16.png
   
   16-bit LFSR taps

.. figure:: ../images/LFSR_24.png
   
   24-bit LFSR taps

   
Advanced Encryption Standard (AES)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Encryption type = :math:`10_2`

This method uses AES block cipher in counter (CTR) mode. 96-bit nonce
value is extracted from the NONCE field, as the 96 most significant
bits of it. The highest 16 bits of the counter are the remaining 16
bits of the NONCE field. FN field value is then used as the
counter. The 16 bit frame counter and 40 ms frames can provide for
over 43 minutes of streaming without rolling over the counter. This
method adapts 16-bit counter to the standard 32-bit CTR for the
encryption. FN counter always start from 0 (zero).

The nonce value should be generated with a hardware random number
generator or any other method of generating non-repeating
values. Nonce values must be used only once. It is obvious that with a
finite number of nonce bits, the probability of nonce collision
approaches 1. We assume that the transmission is secure for 237 frames
using a single key. It is recommended to change keys after that
period.

To combat replay attacks, a 64-bit timestamp shall be embedded into
the NONCE field. The field structure is shown in Table 9. Timestamp is
the number of seconds that elapsed since the beginning of 1970-01-01,
00:00:00 UTC, minus leap seconds (a.k.a. “unix time”).

.. list-table:: NONCE field structure

   * - TIMESTAMP
     - NONCE
     - CTR_HIGH
   * - 64
     - 32
     - 16

**CTR_HIGH** field initializes the highest 16 bits of the CTR, with
the rest of the counter being equal to the FN counter.
