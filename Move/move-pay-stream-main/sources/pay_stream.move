module base_module::pay_stream {
    use aptos_std::table::{Self, Table};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use std::signer;

    /// Error code indicating that the sender cannot be the receiver.
    const ERR_SENDER_CANNOT_BE_RECEIVER: u64 = 1;
    /// Error code indicating an invalid number.
    const ERR_NUMBER_INVALID: u64 = 2;
    /// Error code indicating that the payment does not exist.
    const ERR_PAYMENT_NOT_EXIST: u64 = 3;
    /// Error code indicating that the stream does not exist.
    const ERR_STREAM_NOT_EXIST: u64 = 4;
    /// Error code indicating that the stream is active.
    const ERR_STREAM_IS_ACTIVE: u64 = 5;
    /// Error code indicating that the signer's address is neither the sender nor the receiver.
    const ERR_SIGNER_NOT_SENDER_OR_RECEIVER: u64 = 6;

    /// Represents a payment stream with relevant attributes such as sender, receiver, duration, start time, and associated coins.
    struct Stream has store {
        /// The address of the sender.
        sender: address,
        /// The address of the receiver.
        receiver: address,
        /// The duration of the stream in seconds.
        duration_in_sec: u64, 
        /// The start time of the stream.
        start_time: u64,
        /// The coins associated with the stream.
        coins: Coin<AptosCoin>,
    }

    /// Represents a collection of payment streams organized by the sender's address.
    struct Payments has key {
        /// The table containing streams associated with the sender's address.
        streams: Table<address, Stream>
    }

    /// Checks if the sender is not the same as the receiver and asserts the result.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    fun check_sender_is_not_receiver(sender: address, receiver: address) {
        assert!(sender != receiver, ERR_SENDER_CANNOT_BE_RECEIVER)
    }

    /// Checks if a given number is greater than zero and asserts the result.
    /// @param number The number to be checked.
    fun check_number_is_valid(number: u64) {
        assert!(number > 0, ERR_NUMBER_INVALID)
    }

    /// Checks if a payment exists for a given sender address and asserts the result.
    /// @param sender_address The address of the sender.
    fun check_payment_exists(sender_address: address) {
        assert!(exists<Payments>(sender_address), ERR_PAYMENT_NOT_EXIST);
    }

    /// Checks if a stream exists in the Payments table and asserts the result.
    /// @param payments The reference to the Payments table.
    /// @param stream_address The address of the stream to be checked.
    fun check_stream_exists(payments: &Payments, stream_address: address) {
        assert!(table::contains(&payments.streams, stream_address), ERR_STREAM_NOT_EXIST);
    }

    /// Checks if a stream is not active and asserts the result.
    /// @param payments The reference to the Payments table.
    /// @param stream_address The address of the stream to be checked.
    fun check_stream_is_not_active(payments: &Payments, stream_address: address) {
        let stream = table::borrow(&payments.streams, stream_address);
        assert!(0 == stream.start_time, ERR_STREAM_IS_ACTIVE);
    }

    /// Checks if the signer's address is either the sender or the receiver and asserts the result.
    /// @param signer_address The address of the signer.
    /// @param sender_address The address of the sender.
    /// @param receiver_address The address of the receiver.
    fun check_signer_is_sender_or_receiver(
        signer_address: address,
        sender_address: address,
        receiver_address: address
    ) {
        assert!(signer_address == sender_address || 
                signer_address == receiver_address, ERR_SIGNER_NOT_SENDER_OR_RECEIVER);
    }

    /// Calculates the amount due for a given total amount, start time, and duration in seconds.
    /// @param total_amount The total amount to be calculated.
    /// @param start_time The start time of the stream.
    /// @param duration_in_sec The duration of the stream in seconds.
    /// @return The calculated amount due.
    fun calc_amount_due(total_amount: u64, start_time: u64, duration_in_sec: u64): u64 {
        if (timestamp::now_seconds() > start_time) {
            (total_amount / duration_in_sec) * (timestamp::now_seconds() - start_time)
        } else {
            0
        }
    }

    /// Initializes payments for the signer by creating a new table of streams.
    /// @param signer The signer initiating the payment.
    fun init_payments(signer : &signer) 
    {
        let streams = table::new();
        move_to<Payments>(signer, Payments{
            streams: streams
        })
    }  

    /// Creates a payment entry for the given signer, receiver address, amount, and duration in seconds.
    /// @param signer_ The signer initiating the payment.
    /// @param receiver_address The address of the receiver.
    /// @param amount The amount of the payment.
    /// @param duration_in_sec The duration of the payment in seconds.
    public entry fun create_payment(
        signer_: &signer,
        receiver_address: address,
        amount: u64,
        duration_in_sec: u64
    ) acquires Payments {
        check_sender_is_not_receiver(signer::address_of(signer_), receiver_address);
        check_number_is_valid(amount);
        if (!exists<Payments>(signer::address_of(signer_))) {
            init_payments(signer_);
        };
        let payments = borrow_global_mut<Payments>(signer::address_of(signer_));
        let coins = coin::withdraw<AptosCoin>(signer_, amount);
        table::add(&mut payments.streams, receiver_address, Stream {
            sender: signer::address_of(signer_),
            receiver: receiver_address,
            duration_in_sec: duration_in_sec,
            start_time: 0,
            coins: coins,
        });
    }

    /// Accepts a payment for the given signer and sender address.
    /// @param signer The signer accepting the payment.
    /// @param sender_address The address of the sender.
    public entry fun accept_payment(signer: &signer, sender_address: address) acquires Payments {
        check_payment_exists(sender_address);
        let payments = borrow_global_mut<Payments>(sender_address);
        check_stream_exists(payments, signer::address_of(signer));
        check_stream_is_not_active(payments, signer::address_of(signer));
        let stream = table::borrow_mut(&mut payments.streams, signer::address_of(signer));
        stream.start_time = timestamp::now_seconds();
    }

    /// Claims a payment for the given signer and sender address.
    /// @param signer The signer claiming the payment.
    /// @param sender_address The address of the sender.
    public entry fun claim_payment(signer: &signer, sender_address: address) acquires Payments {
        check_payment_exists(sender_address);
        let payments = borrow_global_mut<Payments>(sender_address);
        check_stream_exists(payments, signer::address_of(signer));
        let stream = table::borrow_mut(&mut payments.streams, signer::address_of(signer));
        let claimamount = calc_amount_due(coin::value(&stream.coins), stream.start_time, stream.duration_in_sec);
        let coin = coin::extract<AptosCoin>(&mut stream.coins, claimamount); 
        coin::deposit<AptosCoin>(signer::address_of(signer), coin);
    }

    /// Cancels a payment for the given signer, sender address, and receiver address.
    /// @param signer The signer canceling the payment.
    /// @param sender_address The address of the sender.
    /// @param receiver_address The address of the receiver.
    public entry fun cancel_payment(
        signer: &signer,
        sender_address: address,
        receiver_address: address
    ) acquires Payments {
        check_payment_exists(sender_address);
        let payments = borrow_global_mut<Payments>(sender_address);
        check_stream_exists(payments, receiver_address);
        check_signer_is_sender_or_receiver(signer::address_of(signer), sender_address, receiver_address);
        let Stream{        
            sender: _,
            receiver: _,
            duration_in_sec: _,
            start_time: _,
            coins} = table::remove(&mut payments.streams, receiver_address);
        coin::deposit(sender_address,coins);
    }

    // Retrieves payment details for the given sender and receiver addresses.
    // @param sender_address The address of the sender.
    // @param receiver_address The address of the receiver.
    // @return A tuple containing the duration in seconds, start time, and value of the coins.
    #[view]
    public fun get_payment(sender_address: address, receiver_address: address): (u64, u64, u64) acquires Payments {
        let payments = borrow_global_mut<Payments>(sender_address);
        let stream = table::borrow(&payments.streams, receiver_address);
        (stream.duration_in_sec, stream.start_time, coin::value(&stream.coins))
    }
}