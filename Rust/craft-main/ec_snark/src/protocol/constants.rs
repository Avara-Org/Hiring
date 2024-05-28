use crate::common::FromBytes;
use crate::protocol::GroupParams;
use lazy_static::lazy_static;
#[allow(unused_imports)]
use num_traits::FromBytes as NumFromBytes;
use pasta_curves::pallas::Point as PallasPoint;
use pasta_curves::vesta::Point as VestaPoint;
use std::str::FromStr;

lazy_static! {
    pub static ref PALLAS_GROUP_PARAMS: GroupParams<PallasPoint> = {
        GroupParams::<PallasPoint> {
            g: <PallasPoint as FromBytes<PallasPoint>>::from(
                convert(
                    &hex::decode(
                        "f9abd1b1a37af310baa363ed031ef5613fb474f1780dc8fc767c2b1480da582b",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
            h: <PallasPoint as FromBytes<PallasPoint>>::from(
                convert(
                    &hex::decode(
                        "8f1339a6e025db7854f67838a42764b870e85e991e7b2e6570c5e5fee6e5c30c",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
            p: <PallasPoint as FromBytes<PallasPoint>>::from(
                convert(
                    &hex::decode(
                        "0000000000000000000000000000000000000000000000000000000000000000",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
            q: <PallasPoint as FromBytes<PallasPoint>>::from(
                convert(
                    &hex::decode(
                        "0000000000000000000000000000000000000000000000000000000000000000",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
        }
    };
    pub static ref VESTA_GROUP_PARAMS: GroupParams<VestaPoint> = {
        GroupParams::<VestaPoint> {
            g: <VestaPoint as FromBytes<VestaPoint>>::from(
                convert(
                    &hex::decode(
                        "227b13b3f09fbc6312ea3a7d150e9879fc5debc5f19e0433a0d774e7485e7ea3",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
            h: <VestaPoint as FromBytes<VestaPoint>>::from(
                convert(
                    &hex::decode(
                        "33fc580619f0b5fa23a88cb6be070033cfdb0ed10aef7491d2400ea6dd45f5a6",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
            p: <VestaPoint as FromBytes<VestaPoint>>::from(
                convert(
                    &hex::decode(
                        "0000000000000000000000000000000000000000000000000000000000000000",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
            q: <VestaPoint as FromBytes<VestaPoint>>::from(
                convert(
                    &hex::decode(
                        "0000000000000000000000000000000000000000000000000000000000000000",
                    )
                    .unwrap(),
                )
                .unwrap(),
            )
            .unwrap(),
        }
    };
}

fn convert(vec: &Vec<u8>) -> Result<&[u8; 32], &'static str> {
    if vec.len() == 32 {
        let slice: &[u8; 32] = vec
            .as_slice()
            .try_into()
            .expect("Slice with incorrect length");
        Ok(slice)
    } else {
        Err("Vector does not have exactly 32 elements")
    }
}

impl FromStr for GroupParams<PallasPoint> {
    type Err = (); // Defining the error type as a unit type.

    // Implementing the from_str method which takes a string slice and returns a Result.
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "pallas" => Ok(PALLAS_GROUP_PARAMS.to_owned()),
            _ => Err(()), // Returning an error for unrecognized strings.
        }
    }
}

impl FromStr for GroupParams<VestaPoint> {
    type Err = (); // Defining the error type as a unit type.

    // Implementing the from_str method which takes a string slice and returns a Result.
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            // Matching the string "ec25519" and returning the corresponding group parameters.
            "vesta" => Ok(VESTA_GROUP_PARAMS.to_owned()),
            _ => Err(()), // Returning an error for unrecognized strings.
        }
    }
}
