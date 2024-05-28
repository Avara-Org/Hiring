use lazy_static::lazy_static;
use serde::Deserialize;
use tracing::{debug, warn};

lazy_static! {
    pub static ref SERVER: Server = Server::new().expect("Failed to initialize shared config");
}

#[derive(Deserialize)]
pub struct Server {
    server_address: String,
    server_broadcast_channel_capacity: usize,
}

impl Server {
    pub fn new() -> Result<Self, config::ConfigError> {
        match dotenvy::dotenv() {
            Ok(_) => {
                debug!("Loaded .env");
            }
            Err(_) => {
                warn!("Could not find .env (this may cause the app to panic in development)");
            }
        }

        let conf = config::Config::builder()
            .add_source(config::File::with_name(
                std::env::var("SERVER_CONFIG_PATH")
                    .expect("SERVER_CONFIG_PATH must be set")
                    .as_str(),
            ))
            .build()?;

        conf.try_deserialize()
    }

    pub fn server_address(&self) -> &str {
        self.server_address.as_str()
    }

    pub fn server_broadcast_capacity(&self) -> usize {
        self.server_broadcast_channel_capacity
    }
}
