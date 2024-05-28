use ec_snark::common::{FromBytes, IntoBytes, Random};
use ec_snark::protocol::GroupParams;
use ec_snark::protocol::Protocol;
use std::error::Error;
use tonic::codegen::StdError;
use tonic::transport::Channel;

pub mod ec_auth {
    tonic::include_proto!("ec_auth");
}

use ec_auth::{
    authentication_client::AuthenticationClient, AnswerRequest, ChallengeRequest, RegisterRequest,
};

pub struct AuthClientLib {
    client: AuthenticationClient<Channel>,
}

impl AuthClientLib {
    pub async fn connect<D>(dst: D) -> Result<Self, tonic::transport::Error>
    where
        D: std::convert::TryInto<tonic::transport::Endpoint>,
        D::Error: Into<StdError>,
    {
        let client = AuthenticationClient::connect(dst).await?;
        Ok(Self { client })
    }

    pub async fn register_user(
        &mut self,
        user: String,
        y1: Vec<u8>,
        y2: Vec<u8>,
    ) -> Result<(), tonic::Status> {
        let request = RegisterRequest { user, y1, y2 };
        self.client.register_user(request).await?;
        Ok(())
    }

    pub async fn create_challenge(
        &mut self,
        user: String,
        r1: Vec<u8>,
        r2: Vec<u8>,
    ) -> Result<(Vec<u8>, String), tonic::Status> {
        let request = ChallengeRequest { user, r1, r2 };
        let response = self.client.create_challenge(request).await?;
        let inner = response.into_inner();
        Ok((inner.c, inner.auth_id))
    }

    pub async fn verify(&mut self, auth_id: String, s: Vec<u8>) -> Result<String, tonic::Status> {
        let request = AnswerRequest { auth_id, s };
        let response = self.client.verify(request).await?;
        Ok(response.into_inner().session_id)
    }
}

pub async fn run_protocol<T, P, S>(
    params: &GroupParams<P>,
    x: &T::Secret,
    user: &String,
    client: &mut AuthClientLib,
) -> Result<(), Box<dyn Error>>
where
    T: Protocol<
        GroupParameters = GroupParams<P>,
        CommitParameters = (P, P, P, P),
        Response = S,
        Challenge = S,
    >,
    P: FromBytes<P> + IntoBytes<P> + Random<P>,
    S: FromBytes<S> + IntoBytes<S> + Random<S>,
{
    let ((y1, y2, r1, r2), k) = T::commitment(params, x);

    client
        .register_user(user.clone(), P::to(&y1), P::to(&y2))
        .await?;

    let (c, auth_id) = client
        .create_challenge(user.clone(), P::to(&r1), P::to(&r2))
        .await?;

    let challenge = S::from(&c)?;

    let s = T::challenge_response(&params, &k, &challenge, &x);

    let session_id = client.verify(auth_id, S::to(&s)).await?;

    println!("Authentication successful!");
    println!("Session ID: {}", session_id);

    T::verify(&params, &s, &challenge, &(y1, y2, r1, r2));

    Ok(())
}
