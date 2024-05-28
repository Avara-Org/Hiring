use ec_snark::protocol::constants::PALLAS_GROUP_PARAMS;
use ec_snark::protocol::elliptic_curves::pallas::PallasEllipticCurve;
use ec_snark::protocol::Protocol;
use pasta_curves::group::ff::Field;
use pasta_curves::group::GroupEncoding;
use pasta_curves::pallas::{Point, Scalar};
use rand_core::OsRng;

mod common;

use common::run_protocol;

/// Test verification using standard protocol execution.
#[test]
fn pallas_success_verification() {
    let mut rng = OsRng;
    let x = <Scalar as Field>::random(&mut rng);
    let params = PALLAS_GROUP_PARAMS.to_owned();
    // Testing the correctness of the serialization and deserialization of group parameters.
    let gb = params.g.to_bytes();
    let restored_g = Point::from_bytes(&gb).unwrap();
    assert_eq!(params.g, restored_g);
    let hb = params.h.to_bytes();
    let restored_h = Point::from_bytes(&hb).unwrap();
    assert_eq!(params.h, restored_h);
    // Further tests omitted for brevity...
    // Asserting the successful execution of the protocol.
    assert!(run_protocol::<PallasEllipticCurve>(&params, &x));
}

/// Test verification fails with an incorrect response.
#[test]
fn pallas_fail_verification() {
    let mut rng = OsRng;
    let x = <Scalar as Field>::random(&mut rng);
    let params = PALLAS_GROUP_PARAMS.to_owned();
    // Generating commitment and a challenge to simulate an authentication attempt.
    let (cp, _) = PallasEllipticCurve::commitment(&params, &x);
    let c = PallasEllipticCurve::challenge(&params);
    // Simulating a fake response to force a failed verification.
    let fake_response = <Scalar as Field>::random(&mut rng);
    // Asserting that the verification should fail with the fake response.
    let verified = PallasEllipticCurve::verify(&params, &fake_response, &c, &cp);
    assert!(!verified);
}
