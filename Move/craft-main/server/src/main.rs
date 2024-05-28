pub mod service;

/// CRUD APIs to work with storage.
pub mod apis;

use ec_snark::common::EllipticCurve;
use ec_snark::protocol::elliptic_curves::pallas::PallasEllipticCurve;
use ec_snark::protocol::elliptic_curves::vesta::VestaEllipticCurve;
use ec_snark::protocol::GroupParams;
use pasta_curves::pallas::Point as PallasPoint;
use pasta_curves::vesta::Point as VestaPoint;
use service::ec_auth::authentication_server::AuthenticationServer;
use service::ECAuthentication;
use std::str::FromStr;
use structopt::StructOpt;
use strum::VariantNames;
use tonic::transport::Server;

#[derive(StructOpt, Debug)]
struct Cli {
    #[structopt(short, long, default_value = "[::1]")]
    host: String,

    #[structopt(short, long, default_value = "50051")]
    port: u32,

    #[structopt(short, long, possible_values = EllipticCurve::VARIANTS, default_value = "pallas")]
    curve: EllipticCurve,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let Cli {
        host, port, curve, ..
    } = Cli::from_args();

    println!(" Starting server ");
    println!("       host: {}", host);
    println!("       port: {}", port);
    println!("       elliptic curve: {}", curve);

    let addr = format!("{}:{}", host, port)
        .parse()
        .map_err(|_| "Address parcing error")?;

    match curve {
        EllipticCurve::Pallas => {
            let params = GroupParams::<PallasPoint>::from_str(&curve.to_string())
                .map_err(|_| "Invalid group parameters value".to_string())?;
            let auth = ECAuthentication::<PallasEllipticCurve, _, _>::new(params);
            Server::builder()
                .add_service(AuthenticationServer::new(auth))
                .serve(addr)
                .await?;
        }

        EllipticCurve::Vesta => {
            let params = GroupParams::<VestaPoint>::from_str(&curve.to_string())
                .map_err(|_| "Invalid elliptic curve values".to_string())?;
            let auth = ECAuthentication::<VestaEllipticCurve, _, _>::new(params);
            Server::builder()
                .add_service(AuthenticationServer::new(auth))
                .serve(addr)
                .await?;
        }
    }

    Ok(())
}
