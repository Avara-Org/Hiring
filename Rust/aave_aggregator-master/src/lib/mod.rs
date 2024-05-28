pub mod coinbase;
pub mod polygon;
pub mod telemetry;

/// Define a simple trait for all price setters/getters to call in to.
pub trait AavePriceMap {
    /// Insert a new `source` with price `value` into the map.
    fn insert(&self, source: &'static str, value: String);
    /// Select the latest `value` of the AAVE token price from `source`.
    fn select(&self, source: &'static str) -> Option<String>;
}
