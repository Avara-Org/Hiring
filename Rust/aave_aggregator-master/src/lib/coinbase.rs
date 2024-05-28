use crate::AavePriceMap;
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use serde_json::json;
use std::sync::Arc;
use tokio::time::{timeout, Duration};
use tokio_tungstenite::{connect_async, tungstenite::Message};
use tracing::{info, warn};

#[derive(Deserialize)]
pub struct Ticker {
    price: String,
}

// Get streaming price updates of Coinbase's AAVE/USD pair,
// and commit them to shared state.
pub fn stream_aave_prices<T>(state: Arc<T>)
where
    T: AavePriceMap + Send + Sync + 'static,
{
    tokio::spawn(async move {
        // Run everything inside a failsafe loop since we want to reconnect
        // if an error occurs and the connection is spuriously closed.
        loop {
            // Establish a WebSocket connection with Coinbase.
            let (mut socket, _) =
                connect_async(std::env::var("COINBASE_WS").expect("COINBASE_WS must be set"))
                    .await
                    .expect("Failed to establish Coinbase WebSocket connection");

            // Create a subscription message for AAVE/USD.
            let message = json!({
                "type": "subscribe",
                "product_ids": [
                    "AAVE-USD",
                ],
                "channels": [
                    "ticker",
                ]
            });

            // Send the subscription message.
            socket
                .send(Message::Text(serde_json::to_string(&message).expect(
                    "Failed to serialize Coinbased AAVE/USD subscription message",
                )))
                .await
                .expect("Failed to send Coinbase AAVE/USD subscription message");

            // Close the connection if it hangs for more than 60 seconds.
            // The `ticker` channel we're subscribed to seems to update 'on last trade',
            // which can lead to long intervals of inactivity.
            let ws_timeout = Duration::from_secs(60);

            // Await and loop through messages from Coinbase.
            'message: loop {
                // Get the next message from Coinbase.
                let message = match timeout(ws_timeout, socket.next()).await {
                    Ok(Some(Ok(message))) => message,
                    Ok(Some(Err(error))) => {
                        warn!("Coinbase WebSocket error => {error}");
                        break 'message;
                    }
                    Ok(None) => {
                        warn!("Unexpected Coinbase WebSocket connection termination");
                        break 'message;
                    }
                    Err(_) => {
                        warn!("The Coinbase WebSocket connection timed out");
                        break 'message;
                    }
                };

                // Reply to ping messages with pong messages.
                if message.is_ping() {
                    if let Err(error) = socket.send(Message::Pong(message.into_data())).await {
                        warn!("Failed to reply to ping from Coinbase => {error}");
                    }

                    info!("Responded to Coinbase ping");
                    continue 'message;
                }

                // Ignore non-text messages.
                if !message.is_text() {
                    continue 'message;
                }

                // Parse the message as UTF-8.
                let text = match message.into_text() {
                    Ok(text) => text,
                    Err(error) => {
                        warn!("Coinbase message text conversion error => {error}");
                        continue 'message;
                    }
                };

                // Deserialize the message.
                let ticker: Ticker = match serde_json::from_str(text.as_str()) {
                    Ok(ticker) => ticker,
                    Err(error) => {
                        warn!("Coinbase ticker deserialization error => {error}");
                        continue 'message;
                    }
                };

                // Safely insert a price update into the server's shared state.
                state.insert("AAVE/USD on Coinbase", ticker.price);
            }
        }
    });
}
