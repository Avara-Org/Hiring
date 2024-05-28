use crate::{
    config::SERVER,
    event::{Serialized as SerializedEvent, Server as ServerEvent},
};
use lib::AavePriceMap;
use parking_lot::{Mutex, RwLock};
use std::collections::HashMap;
use tokio::sync::broadcast;
use tracing::{debug, error, warn};

/// Define shared server state here.
pub struct Shared {
    price_map: RwLock<HashMap<&'static str, Mutex<String>>>,
    tx: broadcast::Sender<SerializedEvent>,
}

/// Define shared server state methods here.
impl Shared {
    /// Create a new shared state for storing and updating AAVE token price info.
    pub fn new() -> Self {
        let price_map = RwLock::new(HashMap::new());
        let (tx, _) = broadcast::channel(SERVER.server_broadcast_capacity());

        Self { price_map, tx }
    }

    /// Broadcast a server event to all receivers.
    pub fn broadcast(&self, event: ServerEvent) {
        // Serialize the event into JSON.
        let serialized_event = match serde_json::to_string(&event) {
            Ok(serialized_event) => serialized_event,
            Err(error) => {
                error!("Failed to serialize server event => {error}");
                return;
            }
        };

        // Broadcast the serialized event to all receivers.
        match self.tx.send(serialized_event) {
            Ok(active_readers) => {
                debug!("Event sent to {active_readers:?} readers");
            }
            Err(error) => {
                warn!("Failed to send event => {error}");
            }
        }
    }

    /// Get a receiver of broadcast server events.
    pub fn subscribe(&self) -> broadcast::Receiver<SerializedEvent> {
        self.tx.subscribe()
    }
}

/// Implement the `AavePriceMap` trait so that the price fetching tasks can call
/// into the shared state directly without knowing anything else about it.
impl AavePriceMap for Shared {
    fn insert(&self, source: &'static str, value: String) {
        // Broadcast this event to all receivers.
        self.broadcast(ServerEvent::price_updated(source, value.as_str()));

        // Use a read-lock to check if an entry exists for this `source`.
        if let Some(guard) = self.price_map.read().get(source) {
            // Update the existing entry.
            let mut price = guard.lock();

            *price = value;

            return;
        }

        // Get a write lock to the price map and insert a new entry.
        self.price_map.write().insert(source, Mutex::new(value));
    }

    fn select(&self, source: &'static str) -> Option<String> {
        // Use a read-lock to check if an entry exists for this `source`,
        // and return `Some(Decimal)` if it exists or `None` if not.
        self.price_map.read().get(source).map(|g| g.lock().clone())
    }
}
