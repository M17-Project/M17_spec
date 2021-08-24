Address Encoding
================

M17 uses 48 bits (6 bytes) long addresses. Callsigns (and other
addresses) are encoded into these 6 bytes in the following ways:

*  An address of 0 is invalid.

* Address values between 1 and 262143999999999 (which is
  :math:`40^9-1`), up to 9 characters of text are encoded using
  base40, described below.
* Address values between 262144000000000 (:math:`40^9`) and
  281474976710654 (:math:`2^{48}-2`) are invalid

.. todo:: Can we think of something to do with these 19330976710655 addresses?

* An address of 0xFFFFFFFFFFFF is a broadcast. All stations should
  receive and listen to this message.

.. table:: Address scheme

   +------------------------------+---------------+-------------------+-------------------+
   |Address Range                 |Category       |Number of addresses|Remarks            |
   +==============================+===============+===================+===================+
   |0x000000000000                |RESERVED       |1                  |For future use     |
   +------------------------------+---------------+-------------------+-------------------+
   |0x000000000001-0xee6b27ffffff |Unit ID        |262143999999999    |                   |
   +------------------------------+---------------+-------------------+-------------------+
   |0xee6b28000000-0xfffffffffffe |RESERVED       |19330976710655     |For future use     |
   +------------------------------+---------------+-------------------+-------------------+
   |0xffffffffffff                |Broadcast      |1                  |Valid only for     |
   |                              |               |                   |destination field  |
   +------------------------------+---------------+-------------------+-------------------+


Callsign Encoding: base40
-------------------------

9 characters from an alphabet of 40 possible characters can be encoded into 48 bits, 6 bytes. The
base40 alphabet is:

* 0: A space. Invalid characters will be replaced with this.
* 1-26: "A" through "Z"
* 27-36: "0" through "9"
* 37: "-" (hyphen)
* 38: "/" (slash)
* 39: "." (dot)

Encoding is little endian. That is, the right most characters in the
encoded string are the most significant bits in the resulting
encoding.

Example code: encode_base40()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   uint64_t encode_callsign_base40(const char *callsign) {
     uint64_t encoded = 0;
     for (const char *p = (callsign + strlen(callsign) - 1); p >= callsign; p-- ) {
       encoded *= 40;
       // If speed is more important than code space, 
       // you can replace this with a lookup into a 256 byte array.
       if (*p >= 'A' && *p <= 'Z') // 1-26
         encoded += *p - 'A' + 1;
       else if (*p >= '0' && *p <= '9') // 27-36
         encoded += *p - '0' + 27;
       else if (*p == '-') // 37
         encoded += 37;
       // These are just place holders. If other characters make more sense,
       // change these. Be sure to change them in the decode array below too.
       else if (*p == '/') // 38
         encoded += 38;
       else if (*p == '.') // 39
         encoded += 39;
       else
         // Invalid character or space, represented by 0, decoded as a space.
         //encoded += 0;
     }
     return encoded;
   }

Example code: decode_base40()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   char *decode_callsign_base40(uint64_t encoded, char *callsign) {
     if (encoded >= 262144000000000) { // 40^9
       *callsign = 0;
       return callsign;
     }
     char *p = callsign;
     for (; encoded > 0; p++) {
       *p = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-/."[encoded % 40];
       encoded /= 40;
     }
     *p = 0;

     return callsign;
   }

Why base40?
~~~~~~~~~~~

The longest commonly assigned callsign from the FCC is 6 characters. The minimum alphabet of A-Z,
0-9, and a "done" character mean the most compact encoding of an American callsign could be:
:math:`log2(37^6)=31.26` bits, or 4 bytes.

Some countries use longer callsigns, and the US sometimes issues
longer special event callsigns. Also, we want to extend our callsigns
(see below). So we want more than 6 characters. How many bits do we
need to represent more characters:

.. list-table:: bits per characters
   :header-rows: 1

   * - characters
     - bits
     - bytes
   * - 7
     - :math:`log2(37^7)=36.47`
     - 5
   * - 8
     - :math:`log2(37^8)=41.67`
     - 6
   * - 9
     - :math:`log2(37^9)=46.89`
     - 6
   * - 10
     - :math:`log2(37^{10})=52.09`
     - 7

Of these, 9 characters into 6 bytes seems the sweet spot. Given 9
characters, how large can we make the alphabet without using more than
6 bytes?

.. list-table:: alphabet size vs bytes
   :header-rows: 1

   * - alphabet size
     - bits
     - bytes
   * - 37
     - :math:`log2(37^9)=46.89`
     - 6
   * - 38
     - :math:`log2(38^9)=47.23`
     - 6
   * - 39
     - :math:`log2(39^9)=47.57`
     - 6
   * - 40
     - :math:`log2(40^9)=47.90`
     - 6
   * - 41
     - :math:`log2(41^9)=48.22`
     - 7

Given this, 9 characters from an alphabet of 40 possible characters,
makes maximal use of 6 bytes.

Callsign Formats
----------------

Government issued callsigns should be able to encode directly with no
changes.

Multiple Stations
~~~~~~~~~~~~~~~~~

To allow for multiple stations by the same operator, we borrow the use
of the '-' character from AX.25 and the SSID field. A callsign such as
"AB1CD-1" is considered a different station than "AB1CD-2" or even
"AB1CD", but it is understood that these all belong to the same
operator, "AB1CD"

Temporary Modifiers
~~~~~~~~~~~~~~~~~~~

Similarly, suffixes are often added to callsign to indicate temporary
changes of status, such as "AB1CD/M" for a mobile station, or
"AB1CD/AE" to signify that I have Amateur Extra operating privileges
even though the FCC database may not yet be updated. So the '/' is
included in the base40 alphabet.  The difference between '-' and '/'
is that '-' are considered different stations, but '/' are NOT. They
are considered to be a temporary modification to the same
station.

Interoperability
~~~~~~~~~~~~~~~~

It may be desirable to bridge information between M17 and other
networks. The 9 character base40 encoding allows for this:

DMR
+++

DMR unfortunately doesn't have a guaranteed single name
space. Individual IDs are reasonably well recognized to be managed by
https://www.radioid.net/database/search#! but Talk Groups are much
less well managed. Talk Group XYZ on Brandmeister may be (and often
is) different than Talk Group XYZ on a private cBridge system.

* DMR IDs are encoded as: D<number> eg: D3106728 for KR6ZY
* DMR Talk Groups are encoded by their network. Currently, the
  following networks are defined:
* Brandmeister: BM<number> eg: BM31075
* DMRPlus: DP<number> eg: DP262
* More networks to be defined here.

D-Star
++++++

D-Star reflectors have well defined names: REFxxxY which are encoded directly into base40.
