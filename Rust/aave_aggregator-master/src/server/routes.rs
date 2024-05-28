use crate::state::Shared as SharedState;
use async_stream::try_stream;
use axum::{
    extract::State,
    response::sse::{Event, KeepAlive, Sse},
};
use futures::Stream;
use std::{convert::Infallible, sync::Arc};
use tracing::error;

#[allow(clippy::unused_async)]
/// This route returns an http stream of server-sent events (e.g. price updates in JSON format).
pub async fn subscribe_to_events(
    State(state): State<Arc<SharedState>>,
) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let mut rx = state.subscribe();

    Sse::new(try_stream! {
        loop {
            match rx.recv().await {
                Ok(server_event) => {
                    let event = Event::default().data(server_event);

                    yield event;
                }
                Err(error) => {
                    error!("Failed to receive broadcast server event => {}", error);
                }
            }
        }
    })
    .keep_alive(KeepAlive::default())
}
