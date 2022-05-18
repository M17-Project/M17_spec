---
title: 'Convolutional Encoder'
taxonomy:
    category:
        - docs
---

The convolutional code shall encode the input bit sequence after appending 4 tail bits at the end of the sequence. Rate of the coder is R=½ with constraint length K=5. The encoder diagram and generating polynomials are shown below.

\(
\begin{align}
  G_1(D) =& 1 + D^3 + D^4 \\
  G_2(D) =& 1+ D + D^2 + D^4
\end{align}
\)

The output from the encoder must be read alternately.

![convolutional](convolutional.svg?classes=caption "Convolutional coder diagram")

### Issues to address...

* More details on parameter choice/performance
