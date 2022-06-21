---
title: 'Code Puncturing'
taxonomy:
    category:
        - docs
---

Removing some of the bits from the convolutional coder’s output is called code puncturing. The nominal coding rate of the encoder used in M17 is ½. This means the encoder outputs two bits for every bit of the input data stream. To get other (higher) coding rates, a puncturing scheme has to be used.

Two different puncturing schemes are used in M17 stream mode:

1. \(P_1\) leaving 46 from 61 encoded bits
2. \(P_2\) leaving 11 from 12 encoded bits

Scheme \(P_1\) is used for the *link setup frame*, taking 488 bits of encoded data and selecting 368 bits. The \(gcd(368, 488)\) is 8 which, when used to divide, leaves 46 and 61 bits. However, a full puncture pattern requires the puncturing matrix entries count to be divisible by the number of encoding polynomials. For this case a partial puncture matrix is used. It has 61 entries with 46 of them being ones and shall be used 8 times, repeatedly. The construction of the partial puncturing pattern \(P_1\) is as follows:

\(
\begin{align}
  M = & \begin{bmatrix}
  1 & 0 & 1 & 1
  \end{bmatrix} \\
  P_{1} = & \begin{bmatrix}
  1 & M_{1} & \cdots & M_{15}
  \end{bmatrix}
\end{align}
\)

In which \(M\) is a standard 2/3 rate puncture matrix and is used 15 times, along with a leading \(1\) to form \(P_1\), an array of length 61.

The first pass of the partial puncturer discards \(G_1\) bits only, second pass discards \(G_2\), third - \(G_1\) again, and so on. This ensures that both bits are punctured out evenly.

Scheme \(P_2\) is for frames (excluding LICH chunks, which are coded differently). This takes 296 encoded bits and selects 272 of them. Every 12th bit is being punctured out, leaving 272 bits. The full matrix shall have 12 entries with 11 being ones.

The puncturing scheme \(P_2\) is defined by its partial puncturing matrix:

\(
\begin{align}
  P_2 = & \begin{bmatrix}
  1 & 1 & 1 & 1 & 1 & 1 \\
  1 & 1 & 1 & 1 & 1 & 0
  \end{bmatrix}
\end{align}
\)

The linearized representations are:

```
P1 = [1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1,
      1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1,
      0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1]

P2 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
```

One additional puncturing scheme \(P_3\) is used in the packet mode. The puncturing scheme is defined by its puncturing matrix:

\(
\begin{align}
  P_3 = & \begin{bmatrix}
  1 & 1 & 1 & 1 \\
  1 & 1 & 1 & 0
  \end{bmatrix}
\end{align}
\)

The linearized representation is:

```
P3 = [1, 1, 1, 1, 1, 1, 1, 0]
```

### Issues to address...

* More details on parameter choice/performance
