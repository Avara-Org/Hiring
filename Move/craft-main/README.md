# `Craft`

## Overview
Craft gRPC server is a command-line application that facilitates a secret verification service based on elliptic curve zkSNARK protocol. It allows to authenticate securely, without revealing the password at any point.

## Protocol Overview

The protocol I chose is a basic zkSNARk on elliptic curves. Current version of `Craft` is implemented for `pasta` (`pallas` and `vesta`) elliptic curves, which are quite popular. Other implemenentations can be added easily if needed.

### Steps of the protocol

We want to prove that the discrete logarithms of points `P` and `Q` on the elliptic curve to the bases `G` and `H`, respectively, are equal, i.e., `G^x = P` and `H^x = Q` for some `x`, without revealing it. `x` will be the password of our user.

1. **Setup**: 
   - Public input: Points `G`, `H`, `P`, `Q` on the elliptic curve.
   - Prover's secret: The value `x`, such that `G^x = P` and `H^x = Q`.

2. **Commitment**:
   - The prover selects a random scalar `r` and computes `A = G^r` and `B = H^r`.
   - The prover sends `A` and `B` to the verifier.

3. **Challenge**:
   - The verifier sends a random scalar `c` as a challenge to the prover.

4. **Response**:
   - The prover computes `s = r + cx` (where the addition and multiplication are in the scalar field).
   - The prover sends `s` to the verifier.

5. **Verification**:
   - The verifier checks if `G^s = A * P^c` and `H^s = B * Q^c`. This uses the property that `G^(r+cx) = G^r * G^{cx}`.
   - If both equations hold, the verifier accepts the proof; otherwise, it is rejected.


## Usage

0. **Install Prerequesites**
   `protoc` and `Rust` need to be installed, details depend on your OS and CPU architecture.

1. **Run the build**
   Open a terminal and run:

   ```bash
   cd path/to/craft
   cargo build --release
   ```
2. **Start the server with default parameters**
   ```bash
   ❯ ./target/release/server
    Starting server 
          host: [::1]
          port: 50051
          elliptic curve: pasta
   ```

3. **In the second terminal send a request with the client using default parameters**
   ```bash
   ❯ ./target/release/client
    Starting client
          host: [::1]
          port: 50051
          elliptic curve: pasta
          user: peggy
    Authentication successful! 
   Session ID: c8d58285-4486-4da0-ba4f-aa8548fa6d4d
   ```
## Usage

**Run the tests**
   Open a terminal and run:

   ```bash
   cd path/to/craft/ec_snark
   cargo test
   ```