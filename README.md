# M17_spec

[M17 Project](http://m17project.org/) is a modern, digital radio protocol built by hams, for hams. 
This repository contains the specification describing it exhaustively, from top to bottom. It is still a work in progress, meaning that this repository is meant to be updated now and then. After a few years of development, almost all of the changes are just to supplement the specification with new functions or improve the document.

The specification can be conveniently browsed [here](https://spec.m17project.org/).

# Table of contents
**Part I - Air Interface**
* M17 RF Protocol: Summary
* Glossary
* Physical Layer
    * 4FSK generation
        * Preamble
        * Bit types
        * Error correction coding schemes and bit type conversion
* Data Link Layer
    * Stream Mode
    * Packet Mode
    * BERT Mode
* Application Layer
    * Amateur Radio Voice Application
    * Packet Application

**Part II - Internet Interface**
* M17 Internet Protocol (IP) Networking
    * Standard IP Framing
    * Control Packets

**Appendix**
* Address Encoding
    * Callsign Encoding: base40
    * Callsign Formats
* Randomizer sequence
* Convolutional Encoder
* Golay Encoder
* Code Puncturing
* Interleaving
* BERT Details
* KISS Protocol
    * References
    * Glossary
    * M17 Protocols
    * KISS Basics
    * Packet Protocols
    * Stream Protocol
    * Mixing Modes
    * Implementation Details
* File Formats
