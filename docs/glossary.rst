Glossary
========

.. glossary::

   ECC
     Error Correcting Code

   FEC
      Forward Error Correction

   Frame
      The individual components of a stream, each of which contains payload data interleaved with frame signalling.

   Link Information Frame
      The first frame of any transmission. It contains full LICH data.

   LICH
      Link Information Channel. The LICH contains all information needed to establish an M17 link. The first frame of a transmission contains full LICH data, and subsequent frames each contain one sixth of the LICH data so that late-joiners can obtain the LICH.
	  
   Packet
      A single burst of transmitted data containing 100s to 1000s of bytes, after which the physical layer stops sending data.
   
   Superframe
      A set of six consecutive frames which collectively contain full LICH data are grouped into a superframe.
