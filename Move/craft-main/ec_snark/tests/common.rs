use ec_snark::protocol::Protocol;

pub fn run_protocol<T>(params: &T::GroupParameters, x: &T::Secret) -> bool
where
    T: Protocol,
{
    // The client calculates the commitment using their secret and the group parameters.
    let (cp, k) = T::commitment(params, x);

    // The server (simulated here) sends a challenge to the client.
    let c = T::challenge(params);

    // The client calculates the response based on the commitment random, challenge,
    // and their secret.
    let s = T::challenge_response(params, &k, &c, &x);

    // The server (simulated here) verifies the response against the challenge and
    // commitment parameters.
    T::verify(params, &s, &c, &cp)
}
