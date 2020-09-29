Recommendation for the codeplug structure
*****************************************
 
Introduction
############

Codeplugs are ordinary text files with *.m17* extension. They provide an information on:

 * channel banks
 * channel frequencies
 * destination IDs
 * transmission mode
 * payload type
 * encryption mode

Codeplugs should be human-readable and easily editable with common text editors.

Codeplug file structure
#######################

We recommend using YAML for the codeplug files.

Keywords
--------

**codeplug:**
  **author:**
    String - Codeplug author, max 16 characters
  **version:**
    Date and time in YYYY-MM-DDTHH:MM:SS format    

**bank:**
  **name:**
    String - Channel bank name, 16 characters maximum

**channel:** 
  **name:**
    String - Channel name, 16 characters maximum
  **descr:**
    String - Channel Description, 16 characters maximum
  **freq_rx:**
    Integer - Channel RX Frequency in Hz
  **freq_tx:**
    Integer - Channel TX Frequency in Hz
  **mode:**
    Integer - Channel mode. Valid modes are: 0 - Analog, 1 - Digital Voice, 2 - Digital Data, 3 - Digital Voice and Data
  **encr:**
    Integer - Is encryption enabled? 0 for no encryption, 1 - AES256, 2 - scrambler etc. (refer to M17_spec for details)
  **nonce:**
    String - 14-byte hex value without leading 0x. nonce for ciphers or initial LFSR value for scrambler
  **gps:**
    Boolean - If true, and mode value enables digital data, gps data will be transferred along with payload

Example Codeplug
################

::

  codeplug:
    author: SP5WWP
    version: 2020-28-09T13:20:49
    - bank:
      name: M17
      - channel:
        name: M17_DMO
        descr: 
        freq_rx: 439575000
        freq_tx: 439575000
        mode: 2
        encr: 0
        nonce: 0
        gps: false
      - channel:
        name: M17_DMO_2
        descr: 
        freq_rx: 439975000
        freq_tx: 439975000
        mode: 2
        encr: 0
        nonce: 0
        gps: false
    - bank:
      name: Repeaters
      - channel:
        name: SR5MS
        descr: 
        freq_rx: 439425000
        freq_tx: 431825000
        mode: 2
        encr: 0
        nonce: 0
        gps: false
  #codeplug end
