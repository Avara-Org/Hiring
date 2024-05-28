use crate::AavePriceMap;
use ethers::{
    contract::{abigen, Contract},
    core::types::ValueOrArray,
    middleware::Middleware,
    providers::{Http, Provider, StreamExt, Ws},
    utils::format_units,
};
use std::sync::Arc;
use tracing::error;

abigen!(
    AggregatorInterface,
    r#"[
        event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt)
    ]"#,
);

// Get streaming price updates of the AAVE/USD pair from the
// Chainlink Oracle on Ethereum, and commit them to shared state.
pub fn stream_aave_prices<T>(state: Arc<T>)
where
    T: AavePriceMap + Send + Sync + 'static,
{
    tokio::spawn(async move {
        // Create an `http_provider`` for the initial `get_block` call.
        let http_provider = Provider::<Http>::try_from(
            std::env::var("POLYGON_HTTP")
                .expect("POLYGON_HTTP must be set")
                .as_str(),
        )
        .expect("Failed to initialize HTTP provider");

        // Get the latest block number from the `http provider`.
        let latest_block = http_provider
            .get_block_number()
            .await
            .expect("Failed to fetch block number");

        // Initialize a `ws_provider` for streaming price updates.
        let ws_provider = Provider::<Ws>::connect(
            std::env::var("POLYGON_WS")
                .expect("POLYGON_WS must be set")
                .as_str(),
        )
        .await
        .expect("Failed to initialize WS provider");

        // Define the event type we are interested in.
        let event = Contract::event_of_type::<AnswerUpdatedFilter>(Arc::new(ws_provider))
            .from_block(latest_block)
            .address(ValueOrArray::Value(
                std::env::var("POLYGON_AAVE_ADDRESS")
                    .expect("POLYGON_AAVE_ADDRESS must be set")
                    .parse()
                    .expect("Failed to parse POLYGON_AAVE_ADDRESS"),
            ));

        // Create the stream.
        let mut stream = event
            .subscribe_with_meta()
            .await
            .expect("Failed to subscribe to events");

        // Await and process each stream event.
        loop {
            match stream.next().await {
                Some(Ok((log, _))) => {
                    // Parse the price from the log data.
                    let price = format_units(log.current, 8).unwrap_or_else(|_| "0".to_string());

                    // Safely insert a price update into the server's shared state.
                    state.insert("AAVE/USD on Chainlink/Polygon", price);
                }
                _ => {
                    error!("Stream returned an error");
                }
            }
        }
    });
}
