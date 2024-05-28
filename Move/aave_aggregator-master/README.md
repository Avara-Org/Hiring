# Aave Aggregator

This is an AAVE token price aggregator written in Rust. The project is divided into two binaries: a server and a client. The server fetches streaming price data on AAVE/USD from a Chainlink price oracle on Polygon (requiring a provider API key/endpoint) as well as from Coinbase (via their public streaming endpoint). Upon request, it then forwards this price data to subscribed client(s) in real time via server-sent events. 

## Getting Started

Copy the `.env.example`:

```shell
cp .env.example .env
```

In the `.env`, be sure to fill in Alchemy (recommended) HTTP and WebSocket API endpoints configured for Polygon.

> **Optional:** Install `bunyan` for human-readable telemetry outputs: 
>
> ```shell
> cargo install bunyan
> ```

Run the server:

```shell
cargo run --bin server          # with JSON-formatted telemetry outputs
cargo run --bin server | bunyan # with human-readable telemetry outputs
```

Then, in a separate window, run the client:

```shell
cargo run --bin client
```

Note that sometimes the values from Coinbase will be slow to update (10+ seconds).