/// Represents a user within the system.
///
/// # Fields
/// - `username`: A `String` representing the username of the user.
/// - `y1`: A generic field of type `T`.
/// - `y2`: Another generic field of type `T`.
/// - `r1`: An `Option<T>` representing an optional field of type `T`.
/// - `r2`: Another `Option<T>` representing an optional field of type `T`.
#[derive(Debug, Clone)]
pub struct User<T> {
    pub username: String,
    pub y1: T,
    pub y2: T,
    pub r1: Option<T>,
    pub r2: Option<T>,
}

/// Represents an challenge for a user.
///
/// # Fields
/// - `id`: A `String` representing the unique identifier of the challenge.
/// - `user`: A `String` representing the username of the user this challenge is associated with.
/// - `c`: A generic field of type `S` representing the challenge data.
#[derive(Debug, Clone)]
pub struct Challenge<S> {
    pub id: String,
    pub user: String,
    pub c: S,
}

/// This trait abstracts the CRUD (Create, Read, Update, Delete) operations
/// and authentication challenge related operations for user data.
///
/// Basic implementation uses in-memory HashMap.
///
/// # Type Parameters
/// - `T`: Type parameter for User related data.
/// - `S`: Type parameter for Authentication Challenge related data.
pub trait UserAPI<T, S> {
    fn create(&mut self, user: User<T>);

    fn read(&mut self, username: &str) -> Option<User<T>>;

    fn update(&mut self, name: &String, user: User<T>) -> Option<()>;

    fn delete(&mut self, name: &String) -> Option<User<T>>;

    fn create_challenge(&mut self, user: &String, c: &S) -> String;

    fn get_challenge(&mut self, id: &String) -> Option<Challenge<S>>;

    fn delete_challenge(&mut self, id: &String);
}
