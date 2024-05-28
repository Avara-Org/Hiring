use crossterm::{cursor, style::Stylize, terminal, ExecutableCommand};
use serde::Deserialize;
use sse_client::EventSource;
use std::{collections::HashMap, io::stdout};

mod config;

#[derive(Deserialize)]
struct Event {
    pub source: String,
    pub value: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Parse the server address from the config file.
    let endpoint = format!("{}/event", config::CLIENT.server_address());

    // Create the event source.
    let source = EventSource::new(endpoint.as_str()).expect("Failed to build event source");

    // Let the user know that we're connected to the server.
    println!("Connected to {} \u{1F47B}\n", endpoint.bold());

    // Create a hashmap of current prices.
    let mut prices = HashMap::<String, String>::new();
    let mut lines = 0;

    // Lock stdout.
    let mut stdout = stdout();

    // Await and loop through messages from the server.
    for event in source.receiver().iter() {
        // Deserialize the event.
        let event: Event = match serde_json::from_str(event.data.as_str()) {
            Ok(event) => event,
            Err(error) => {
                println!("Failed to deserialize event => {error}");
                break;
            }
        };

        // Update the `prices` hashmap.
        _ = prices.insert(event.source, event.value);

        // Clear the terminal.
        stdout
            .execute(cursor::MoveUp(lines))
            .expect("Terminal cursor error");
        stdout
            .execute(terminal::Clear(terminal::ClearType::FromCursorDown))
            .expect("Terminal clear error");

        lines = 0;

        // Write the price data to the terminal.
        for (source, price) in prices.iter() {
            println!(
                "{} ${}",
                source.clone().blue(),
                price.clone().green().bold()
            );

            // Update the number of lines written to the terminal.
            lines += 1;
        }
    }

    Ok(())
}
