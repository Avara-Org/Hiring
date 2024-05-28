pub mod logic;

use sha2::{Digest, Sha512};
use std::str::FromStr;
use structopt::StructOpt;
use strum::VariantNames;

use ec_snark::common::{FromBytes, IntoBytes};

use ec_snark::common::EllipticCurve;
use ec_snark::common::Random;
use ec_snark::protocol::{
    elliptic_curves::pallas::PallasEllipticCurve, elliptic_curves::vesta::VestaEllipticCurve,
    GroupParams,
};
use logic::run_protocol;
use logic::AuthClientLib;
use pasta_curves::pallas::Point as PallasPoint;
use pasta_curves::vesta::Point as VestaPoint;
use std::error::Error;

#[derive(Debug, StructOpt)]
struct Cli {
    #[structopt(short, long, default_value = "[::1]")]
    host: String,

    #[structopt(short, long, default_value = "50051")]
    port: u32,

    #[structopt(short, long)]
    secret: Option<String>,

    #[structopt(short, long, default_value = "peggy")]
    user: String,

    #[structopt(short, long, possible_values = EllipticCurve::VARIANTS, default_value = "pallas")]
    curve: EllipticCurve,
}

fn hash_or_randomize_secret<T: FromBytes<T> + IntoBytes<T> + Random<T>>(
    secret: Option<&String>,
) -> T {
    match secret {
        Some(s) => {
            let mut hasher = Sha512::new();
            hasher.update(s);
            let result = hasher.finalize();
            T::from(&result).expect("Hash convertion error")
        }
        None => T::random().expect("Random value generation error"),
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let opt = Cli::from_args();

    println!(" Starting client ");
    println!("      host: {}", opt.host);
    println!("      port: {}", opt.port);
    println!("      elliptic curve: {}", opt.curve);
    println!("      user: {}", opt.user);

    let mut client = AuthClientLib::connect(format!("http://{}:{}", opt.host, opt.port)).await?;
    match opt.curve {
        EllipticCurve::Pallas => {
            let ec_params = GroupParams::<PallasPoint>::from_str(&opt.curve.to_string())
                .map_err(|_| "Invalid group parameters value".to_string())?;
            run_protocol::<PallasEllipticCurve, _, _>(
                &ec_params,
                &hash_or_randomize_secret(opt.secret.as_ref()),
                &opt.user,
                &mut client,
            )
            .await?
        }

        EllipticCurve::Vesta => {
            let ec_params = GroupParams::<VestaPoint>::from_str(&opt.curve.to_string())
                .map_err(|_| "Invalid group parameters value".to_string())?;
            run_protocol::<VestaEllipticCurve, _, _>(
                &ec_params,
                &hash_or_randomize_secret(opt.secret.as_ref()),
                &opt.user,
                &mut client,
            )
            .await?
        }
    }
    Ok(())
}
