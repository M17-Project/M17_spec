Application Layer
=================

PARTS 1 AND 2 REMOVED – will add this later.

.. _packet-superframes:

Packet Superframes
------------------

Packet superframes are composed of a 1..n byte data type specifier, 0..797 bytes of
payload data.  The data type specifier is encoded in the same way as UTF-8.  It provides
efficient coding of common data types.  And it can be extended to include a very large
number of distinct packet data type codes.

The data type specifier can also be used as a protocol specifier.  For example,
the following protocol identifers are reserved in the M17 packet spec:

.. list-table::  Reserved Protocols
   :header-rows: 1

   * - Identifer
     - Protocol
   * - 0x00
     - RAW
   * - 0x01
     - AX.25
   * - 0x02
     - APRS
   * - 0x03
     - 6LoWPAN
   * - 0x04
     - IPv4
   * - 0x05
     - SMS
   * - 0x06
     - WinLink

 
The data type specifier is used to compute the CRC, along with the payload.

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

Encryption type = :math:`01_2`

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
   :header-rows: 1

   * - Encryption subtype
     - LFSR polynomial
     - Seed length
     - Sequence period
   * - :math:`00_2`
     - :math:`x^8 + x^6 + x^5 + x^4 + 1`
     - 8 bits
     - 255
   * - :math:`01_2`
     - :math:`x^{16} + x^{15} + x^{13} + x^4 + 1`
     - 16 bits
     - 65,535
   * - :math:`10_2`
     - :math:`x^{24} + x^{23} + x^{22} + x^{17} + 1`
     - 24 bits
     - 16,777,215

.. figure:: ../images/LFSR_8.*
   :scale: 22%

   8-bit LFSR taps

.. figure:: ../images/LFSR_16.*
   :scale: 22%

   16-bit LFSR taps

.. figure:: ../images/LFSR_24.*
   :scale: 22%

   24-bit LFSR taps


Advanced Encryption Standard (AES)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Encryption type = :math:`10_2`

This method uses AES block cipher in counter (CTR) mode. 96-bit nonce
value is extracted from the NONCE field, as the 96 most significant
bits of it. The highest 16 bits of the counter are the remaining 16
bits of the NONCE field. FN field value is then used as the
counter. The 16 bit frame counter and 40 ms frames can provide for
over 20 minutes of streaming without rolling over the counter [#fn_roll]_. This
method adapts 16-bit counter to the standard 32-bit CTR for the
encryption. FN counter always start from 0 (zero).

.. [#fn_roll] The effective capacity of the counter is 15 bits, as the
              MSB is used for transmission end signalling

The nonce value should be generated with a hardware random number
generator or any other method of generating non-repeating
values. Nonce values must be used only once. It is obvious that with a
finite number of nonce bits, the probability of nonce collision
approaches 1. We assume that the transmission is secure for 237 frames
using a single key. It is recommended to change keys after that
period.

To combat replay attacks, a 32-bit timestamp shall be embedded into
the NONCE field. The field structure is shown in Table 9. Timestamp is 32 LSB portion of
the number of seconds that elapsed since the beginning of 1970-01-01,
00:00:00 UTC, minus leap seconds (a.k.a. “unix time”).

.. list-table:: NONCE field structure
   :header-rows: 1

   * - TIMESTAMP
     - NONCE
     - CTR_HIGH
   * - 32
     - 64
     - 16

**CTR_HIGH** field initializes the highest 16 bits of the CTR, with
the rest of the counter being equal to the FN counter.
