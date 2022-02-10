Application Layer
=================

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

Encryption is optional. The use of it may be restricted within some radio
services and countries, and should only be used if legally permissible.

Null Encryption
~~~~~~~~~~~~~~~

Encryption type = :math:`00_2`

No encryption is performed, payload is sent in clear text.

The "Encryption SubType" bits in the Stream Type field then indicate
what data is stored in the 112 bits of the LSF META field.

.. list-table::  
   :header-rows: 1

   * - Encryption SubType bits
     - LSF META data contents
   * - :math:`00_2`
     - UTF-8 Text
   * - :math:`01_2`
     - GNSS Position Data
   * - :math:`10_2`
     - Reserved
   * - :math:`11_2`
     - Reserved

All LSF META data must be stored in big endian byte order, as throughout
the rest of this specification.

GNSS Position Data stores the 112 bit META field as follows:

.. list-table::  
   :header-rows: 1

   * - Size, in bits
     - Format
     - Contents
   * - 32
     - 32-bit fixed point degrees and decimal minutes (TBD)
     - Latitude
   * - 32
     - 32-bit fixed point degrees and decimal minutes (TBD)
     - Longitude
   * - 16
     - unsigned integer
     - Altitude, in feet MSL. Stored +1500, so a stored value of 0 represents -1500 MSL. Subtract 1500 feet when parsing.
   * - 10
     - unsigned integer
     - Course in degrees true North
   * - 10
     - unsigned integer
     - Speed in miles per hour.
   * - 12
     - Reserved values
     - Transmitter/Object description field


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

This method uses AES block cipher in counter (CTR) mode, with a 96-bit
nonce that should never be used for more than one separate stream and a 32 bit CTR.

The 96-bit AES nonce value is extracted from the 96 most significant
bits of the META field, and the remaining 16 bits of the META field
form the highest 16 bits of the 32 bit counter.  The FN (Frame Number)
field value is then used to fill out the lower 16 bits of the counter,
and always starts from 0 (zero) in a new voice stream.

The 16 bit frame number and 40 ms frames can provide for over 20 minutes
of streaming without rolling over the counter [#fn_roll]_.

.. [#fn_roll] The effective capacity of the counter is 15 bits, as the
              MSB is used for transmission end signalling. At 40ms per
              frame, or 25 frames per second, and 2**15 frames, we get
              2**15 frames / 25 frames per second = 1310 seconds, or 21
              minutes and some change.

The random part of the nonce value should be generated with a hardware
random number generator or any other method of generating non-repeating
values. 

To combat replay attacks, a 32-bit timestamp shall be embedded into the
cryptographic nonce field. The field structure of the 96 bit nonce is
shown in Table 9. Timestamp is 32 LSB portion of the number of seconds
that elapsed since the beginning of 1970-01-01, 00:00:00 UTC, minus leap
seconds (a.k.a. “unix time”).

.. list-table:: 96 bit nonce field structure
   :header-rows: 1

   * - TIMESTAMP
     - RANDOM DATA
     - CTR_HIGH
   * - 32
     - 64
     - 16

**CTR_HIGH** field initializes the highest 16 bits of the CTR, with
the rest of the counter being equal to the FN counter.

.. warning::
    In CTR mode, AES encryption is malleable [CTR]_ [CRYPTO]_.
    That is, an attacker can change the contents of the encrypted message
    without decrypting it. This means that recipients of AES-encrypted data
    must not trust that the data is authentic.
    Users who require that received messages are proven to be exactly as-sent by
    the sender should add application-layer authentication, such as HMAC.
    In the future, use of a different mode, such as Galois/Counter Mode, could
    alleviate this issue [CRYPTO]_.

.. [CTR] McGrew, David A. "Counter mode security: Analysis and recommendations." Cisco Systems, November 2, no. 4 (2002).

.. [CRYPTO] Rogaway, Phillip. "Evaluation of some blockcipher modes of operation." Cryptography Research and Evaluation Committees (CRYPTREC) for the Government of Japan (2011).
