---
title: 'Golay Encoder'
taxonomy:
    category:
        - docs
---

#### Extended Golay(24,12) code

The extended Golay(24,12) encoder uses generating polynomial g given below to generate the 11 check bits. The check bits and an additional parity bit are appended to the 12 bit data, resulting in a 24 bit codeword. The resulting code is systematic, meaning that the input data (message) is embedded in the codeword.

\(g(x) = x^{11} + x^{10} + x^6 + x^5 + x^4 + x^2 + 1\)

This is equivalent to 0xC75 in hexadecimal notation. Both the generating matrix \(G\) and parity check matrix \(H\) are shown below.

\(
\begin{align}
  G = [I_{12}|P] = \left[
    \begin{array}{cr}
    I_{12} \begin{matrix} 1&1&0&0&0&1&1&1&0&1&0&1\\
    0&1&1&0&0&0&1&1&1&0&1&1\\
    1&1&1&1&0&1&1&0&1&0&0&0\\
    0&1&1&1&1&0&1&1&0&1&0&0\\
    0&0&1&1&1&1&0&1&1&0&1&0\\
    1&1&0&1&1&0&0&1&1&0&0&1\\
    0&1&1&0&1&1&0&0&1&1&0&1\\
    0&0&1&1&0&1&1&0&0&1&1&1\\
    1&1&0&1&1&1&0&0&0&1&1&0\\
    1&0&1&0&1&0&0&1&0&1&1&1\\
    1&0&0&1&0&0&1&1&1&1&1&0\\
    1&0&0&0&1&1&1&0&1&0&1&1
    \end{matrix}
    \end{array}
\right]
\newline\newline
  H = [P^T|I_{12}] = \left[
    \begin{array}{cr}
    \begin{matrix}
    1&0&1&0&0&1&0&0&1&1&1&1\\
    1&1&1&1&0&1&1&0&1&0&0&0\\
    0&1&1&1&1&0&1&1&0&1&0&0\\
    0&0&1&1&1&1&0&1&1&0&1&0\\
    0&0&0&1&1&1&1&0&1&1&0&1\\
    1&0&1&0&1&0&1&1&1&0&0&1\\
    1&1&1&1&0&0&0&1&0&0&1&1\\
    1&1&0&1&1&1&0&0&0&1&1&0\\
    0&1&1&0&1&1&1&0&0&0&1&1\\
    1&0&0&1&0&0&1&1&1&1&1&0\\
    0&1&0&0&1&0&0&1&1&1&1&1\\
    1&1&0&0&0&1&1&1&0&1&0&1
    \end{matrix} I_{12}
    \end{array}
\right]
\end{align}
\)
 
The output of the Golay encoder is shown in the table below.

<center><span style="font-weight:bold">Table 1</span> Golay encoder details</center>
Field      | Data     | Check bits  | Parity
-----      | ----     | ----------  | ------
Position   | 23..12   | 11..1       | 0 (LSB)
Length     | 12       | 11          | 1

Four of these 24-bit blocks are used to reconstruct the LSF.

Sample MATLAB/Octave code snippet for generating \(G\) and \(H\) matrices is shown below.

```

P = hex2poly('0xC75');
[H,G] = cyclgen(23, P);

G_P = G(1:12, 1:11);
I_K = eye(12);
G = [I_K G_P P.'];
H = [transpose([G_P P.']) I_K];
```

### Issues to address...

* More details on Golay choice/performance
* Golay(24,12) matrix in C form

