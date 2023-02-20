---
title: 'Address Encoding'
taxonomy:
    category:
        - docs
---

M17 uses 48-bit (6-byte) addresses. Callsigns and special purpose addresses are encoded into these 6 bytes in the following ways:

* An address of 0 is reserved for future use.
* Address values between 1 and 262143999999999 ($40^{9}−1$), contain up to 9 characters of text encoded using base-40 as described below.
* Address values between 262144000000000 ($40^{9}$) and 281474976710654 ($2^{48}−2$) are reserved for future use.
* An address of 0xFFFFFFFFFFFF is a broadcast.

### Address Scheme

<center><span style="font-weight:bold">Table 1</span> M17 Addresses</center>
Address Range (base-16)         | Category  | Number of Addresses | Remarks
-------------                   | --------  | ------------------- | -------
0x000000000000                  | INVALID   | 1                   | 
0x000000000001 - 0xEE6B27FFFFFF | Unit ID   | 262143999999999     | 
0xEE6B28000000 - 0xFFFFFFFFFFFE | RESERVED  | 19330976710655      | For future use
0xFFFFFFFFFFFF                  | Broadcast | 1                   | Valid only for destination

### Callsign Encoding: base-40

9 characters from an alphabet of 40 possible characters can be encoded into 48 bits (6 bytes). The base-40 alphabet is:

<center><span style="font-weight:bold">Table 2</span> M17 Callsign Alphabet</center>
Value (base-10) | Character | Note
--------------- | --------- | ----
0               | ' '       | A space, ASCII 32 (0x20). Invalid characters will be replaced with this.
1 - 26          | 'A' - 'Z' | Upper case letters, ASCII 65 - 90 (0x41 - 0x5A).
27 - 36         | '0' - '9' | Numerals, ASCII 48 - 57 (0x30 - 0x39).
37              | '-'       | Hyphen, ASCII 45 (0x2D).
38              | '/'       | Forward Slash, ASCII 47 (0x2F).
39              | '.'       | Dot, ASCII 46 (0x2E).

When computing the base-40 value of the callsign, the left most character of the callsign is the least significant value.  Callsigns must be
left justified. Leading spaces are not permitted.

After the base-40 value is calculated, the final 6-byte address is the big endian encoded (most significant byte first) representation of the base-40 value. 

For example, for the callsign AB1CD, the base-40 representation would be DC1BA, and would be calculated as:

('D': $4 \times 40^4$) + ('C': $3 \times 40^3$) + ('1': $28 \times 40^2$) + ('B': $2 \times 40^1$) + ('A': $1 \times 40^0$)

DC1BA (base-40), 0x0000009fdd51 (base-16), 10476881 (base-10)

The final address encoded into the 6-byte LSF/LICH field would be 0x0000009fdd51 

#### Example Encoder

```python
def encodeM17(call):
	"""Encode a text string into an M17 address value"""
	
	charMap = ' ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-/.'

	# convert to upper case
	call = call.upper()

	# generate an assert error if more than 9 characters long
	assert len(call) <= 9, 'Error: <callsign> must be 9 characters or less'

	if call == 'ALL':
		# handle the special case for Broadcast
		encoded = 0xFFFFFFFFFFFF
	else:
		encoded = 0
		# loop through the characters starting from the end (right most character)
		for c in call[::-1]:
			# find the position of the character in the map
			value = charMap.find(c)

			# if value < 0, the character was not found
			# invalid characters are forced to 0
			if value < 0:
				value = 0

			# shift the current value by one base-40 character (40 decimal)
			# and add the current value
			encoded = encoded*40 + value

	return encoded
```

#### Example Decoder

```python
def decodeM17(encoded):
	"""Decode an M17 address value to a text string"""

	charMap = ' ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-/.'

	# check for unique values
	if encoded == 0xFFFFFFFFFFFF:
		# BROADCAST
		call = 'ALL'
	elif encoded == 0:
		call = 'RESERVED'
	elif encoded >= 0xEE6B28000000:
		call = 'RESERVED'
	else:
		call = ''
		while (encoded > 0):
			call = call + charMap[encoded % 40]
			encoded = encoded // 40

	return call
```

#### Why base-40?

##### Callsign Formats

The [International Telecommunication Union (ITU)](https://www.itu.int/) coordinates radio callsign formats worldwide, with format details specified in ITU [Radio Regulations](https://www.itu.int/pub/R-REG-RR/en) Articles 19.67 through 19.69.  A very extensive [Wikipedia entry for Amateur Radio Call Signs](https://en.wikipedia.org/wiki/Amateur_radio_call_signs) includes implementation details on callsign use around the world.

From the ITU Articles, the longest standard callsign may consist of up to seven characters, with longer temporary special occasion callsigns allowed.  The allowed callsign characters, or "callsign alphabet", are the 26 letters of the English alphabet ('A' through 'Z') and the ten digits ('0' through '9').

##### Secondary Operating Suffixes

Secondary operating suffixes are often added to callsign to indicate temporary changes of status, such as "AB1CD/M" for a mobile station, or "AB1CD/AE" to signify the station has additional operating privileges, etc. The '/' character will be included in callsign alphabet. 

##### Bits per Characters

The minimum number of allowed callsign characters in the callsign alphabet is 37 ('A' through 'Z', '0' through '9', and '/').  The following table shows how many bytes are required to encoded a callsign using an alphabet size of 37.

<center><span style="font-weight:bold">Table 3</span> Storage required for number of callsign characters</center>
Callsign Characters | Bits                  | Bytes
------------------- | ----                  | -----
7                   | $log_2(37^7)=36.47$    | 5
8                   | $log_2(37^8)=41.67$    | 6
9                   | $log_2(37^9)=46.89$    | 6
10                  | $log_2(37^{10})=52.09$ | 7
11                  | $log_2(37^{11})=57.30$ | 8
12                  | $log_2(37^{12})=62.51$ | 8
13                  | $log_2(37^{13})=67.72$ | 9

Of these, 9 characters into 6 bytes, or 12 characters into 8 bytes are the most efficient. Given that 9 callsign characters and 6 bytes should be suitable for the majority of use cases, can the callsign alphabet be increased without using more than 6 bytes?

##### Alphabet Size vs. Bytes

The following table shows how many bytes are required to encode a 9 character callsign using callsign alphabet sizes of 37 through 41.

<center><span style="font-weight:bold">Table 4</span> Storage required for alphabet size</center>
Alphabet Size | Bits               | Bytes
------------- | ----               | -----
37            | $log_2(37^9)=46.89$ | 6
38            | $log_2(38^9)=47.23$ | 6
39            | $log_2(39^9)=47.57$ | 6
40            | $log_2(40^9)=47.90$ | 6
41            | $log_2(41^9)=48.22$ | 7

The largest callsign alphabet size able to encode 9 characters into 6 bytes is 40.  This means the minimal callsign alphabet of 37 can be extended with three additional characters.

##### Multiple Stations

To indicate multiple stations by the same operator, the '-' character can be used. A callsign such as "AB1CD-1" is considered a different station than "AB1CD-2" or even "AB1CD", but it is understood that these all belong to the same operator, "AB1CD".  The '-' character will be included in callsign alphabet.

##### Fill

A space ' ' character is included in the callsign alphabet as a fill character or as a substitute for characters that are not part of the callsign alphabet.

##### Dot

A dot '.' character is included in the callsign alphabet as ... TBD ...

##### M17 base-40 Callsign Alphabet

These final additions complete the 40 character M17 callsign alphabet as ' ' (space), 'A' through 'Z', '0' through '9', '-' (hyphen), '/' (forward slash), and '.' (dot).
