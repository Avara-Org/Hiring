use serde::Serialize;

pub type Serialized = String;

#[derive(Serialize, Debug)]
#[serde(untagged)]
/// Define server-sent events here.
pub enum Server<'v> {
    PriceUpdated(Price<'v>),
}

impl<'v> Server<'v> {
    pub fn price_updated(source: &'static str, value: &'v str) -> Self {
        Self::PriceUpdated(Price { source, value })
    }
}

#[derive(Serialize, Debug)]
pub struct Price<'v> {
    source: &'static str,
    value: &'v str,
}
