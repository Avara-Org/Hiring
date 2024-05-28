use std::error::Error;

/// An enumeration representing the types of elliptic curves.
#[derive(PartialEq, Debug, strum::EnumString, strum::EnumVariantNames, strum::Display)]
#[strum(serialize_all = "snake_case")]
pub enum EllipticCurve {
    Pallas,
    Vesta,
}

/// Trait for converting types to and from byte representations.
pub trait IntoBytes<T> {
    fn to(t: &T) -> Vec<u8>;
}

/// Trait for converting types from byte representations.
/// Similar to `std::convert::From`
pub trait FromBytes<T> {
    fn from(bytes: &[u8]) -> Result<T, Box<dyn Error>>
    where
        Self: Sized;
}

/// Trait for generating random values of a given type.
/// /// Similar to `std::convert::Into`
pub trait Random<T> {
    fn random() -> Result<T, Box<dyn Error>>;
}
