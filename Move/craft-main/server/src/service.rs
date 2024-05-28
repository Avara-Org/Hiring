use crate::apis::user_impl::in_memory::InMemoryUserAPI;
use crate::apis::{user::User, user::UserAPI};
use ec_snark::common::{FromBytes, IntoBytes};
use ec_snark::protocol::{GroupParams, Protocol};
use log::{debug, error, info, trace};
use tokio::sync::Mutex;
use tonic::{Request, Response, Status};
use uuid::Uuid;

// Protobuf generated module
pub mod ec_auth {
    tonic::include_proto!("ec_auth");
}

// Protobuf imports
use ec_auth::{
    authentication_server::Authentication, AnswerRequest, AnswerResponse,
    ChallengeRequest, ChallengeResponse, RegisterRequest,
    RegisterResponse,
};

pub struct ECAuthentication<C, T, S> {
    params: GroupParams<T>,
    api: Mutex<Box<dyn UserAPI<T, S> + Send + Sync>>,
    _type_phantom: std::marker::PhantomData<C>,
    _scalar_phantom: std::marker::PhantomData<S>,
}

impl<
        C,
        T: std::marker::Send
            + std::marker::Sync
            + std::clone::Clone
            + FromBytes<T>
            + IntoBytes<T>
            + 'static,
        S: std::marker::Send
            + std::marker::Sync
            + std::clone::Clone
            + FromBytes<S>
            + IntoBytes<S>
            + 'static,
    > ECAuthentication<C, T, S>
{
    pub fn new(params: GroupParams<T>) -> Self {
        let api = Mutex::new(
            Box::new(InMemoryUserAPI::<T, S>::new()) as Box<dyn UserAPI<T, S> + Send + Sync>
        );
        Self {
            params,
            api,
            _type_phantom: std::marker::PhantomData,
            _scalar_phantom: std::marker::PhantomData,
        }
    }
}

#[tonic::async_trait]
impl<C, T, S> Authentication for ECAuthentication<C, T, S>
where
    T: Send + Sync + 'static + Clone + FromBytes<T> + IntoBytes<T>,
    S: Send + Sync + 'static + Clone + FromBytes<S> + IntoBytes<S>,
    C: Protocol<
            Response = S,
            CommitmentRandom = S,
            Challenge = S,
            Secret = S,
            GroupParameters = GroupParams<T>,
            CommitParameters = (T, T, T, T),
        >
        + 'static
        + std::marker::Sync
        + std::marker::Send,
{
    async fn register_user(
        &self,
        request: Request<RegisterRequest>,
    ) -> Result<Response<RegisterResponse>, Status> {
        trace!("register_user: {:?}", request);
        let req = request.into_inner();

        let y1 = T::from(&req.y1).or_else(|_| Err(Status::invalid_argument("Invalid y1")))?;
        let y2 = T::from(&req.y2).or_else(|_| Err(Status::invalid_argument("Invalid y2")))?;

        let user = User {
            username: req.user.clone(),
            y1,
            y2,
            r1: None,
            r2: None,
        };

        let mut api = self.api.lock().await;
        api.create(user);

        let reply = RegisterResponse {};
        trace!("register reply: {:?}", reply);
        Ok(Response::new(reply))
    }

    async fn create_challenge(
        &self,
        request: Request<ChallengeRequest>,
    ) -> Result<Response<ChallengeResponse>, Status> {
        trace!("create_challenge request: {:?}", request);
        let req = request.into_inner();
        let challenge = C::challenge(&self.params);

        let user = {
            let mut api = self.api.lock().await;
            let mut user = api
                .read(&req.user)
                .ok_or_else(|| Status::not_found("User not found"))?;
            user.r1 =
                Some(T::from(&req.r1).or_else(|_| Err(Status::invalid_argument("Invalid r1")))?);
            user.r2 =
                Some(T::from(&req.r2).or_else(|_| Err(Status::invalid_argument("Invalid r2")))?);
            user.clone()
        };

        let auth_id = {
            let mut api = self.api.lock().await;
            api.update(&user.username, user.clone());
            api.create_challenge(&req.user, &challenge)
        };

        let reply = ChallengeResponse {
            auth_id,
            c: S::to(&challenge),
        };
        trace!("create_authentication_challenge reply: {:?}", reply);
        Ok(Response::new(reply))
    }

    async fn verify(
        &self,
        request: Request<AnswerRequest>,
    ) -> Result<Response<AnswerResponse>, Status> {
        trace!("verify: {:?}", request);
        let req = request.into_inner();

        let challenge = {
            let mut api = self.api.lock().await;
            api.get_challenge(&req.auth_id)
                .ok_or_else(|| Status::not_found("Challenge not found"))?
        };

        let user = {
            let mut api = self.api.lock().await;
            api.read(&challenge.user)
                .ok_or_else(|| Status::not_found("User not found"))?
        };

        let s = S::from(&req.s).or_else(|_| Err(Status::invalid_argument("Invalid s")))?;
        let params = self.params.clone();
        let verified = C::verify(
            &params,
            &s,
            &challenge.c,
            &(user.y1, user.y2, user.r1.unwrap(), user.r2.unwrap()),
        );

        debug!("User: {} verified", user.username);
        if !verified {
            error!("Invalid authentication for user: {}", user.username);
            return Err(Status::invalid_argument("Invalid authentication"));
        }
        let session_id = Uuid::new_v4().to_string();
        let reply = AnswerResponse { session_id };

        let mut api = self.api.lock().await;
        api.delete_challenge(&req.auth_id);

        info!(
            " User: {} authenticated, session id: {}",
            user.username, req.auth_id
        );
        trace!("verify_authentication reply: {:?}", reply);
        Ok(Response::new(reply))
    }
}
