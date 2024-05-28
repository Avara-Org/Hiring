use axum::{routing::get, Router};
use lib::telemetry;
use std::sync::Arc;
use tracing::info;

mod config;
mod event;
mod routes;
mod state;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing.
    telemetry::init_tracing("aave.aggregator.server");

    // Parse the server address from the config file.
    let address = config::SERVER
        .server_address()
        .parse::<std::net::SocketAddr>()?;

    // Set up the server's shared state.
    let shared_state = Arc::new(state::Shared::new());

    // Stream AAVE/USD prices from Chainlink on Polygon.
    lib::polygon::stream_aave_prices(shared_state.clone());

    // Stream AAVE/USD prices from Coinbase.
    lib::coinbase::stream_aave_prices(shared_state.clone());

    // Configure the server with routes and shared state.
    let server = Router::new()
        .route("/event", get(routes::subscribe_to_events))
        .with_state(shared_state);

    // Let the user know where the server is running.
    info!("Aave aggregator server listening at {}", address);

    // Run the server.
    axum::Server::bind(&address)
        .serve(server.into_make_service())
        .await
        .expect("Failed to start server");

    Ok(())
}
