
<a name="0x4321_pay_stream"></a>

# Module `0x4321::pay_stream`



-  [Struct `Stream`](#0x4321_pay_stream_Stream)
-  [Resource `Payments`](#0x4321_pay_stream_Payments)
-  [Constants](#@Constants_0)
-  [Function `create_payment`](#0x4321_pay_stream_create_payment)
-  [Function `accept_payment`](#0x4321_pay_stream_accept_payment)
-  [Function `claim_payment`](#0x4321_pay_stream_claim_payment)
-  [Function `cancel_payment`](#0x4321_pay_stream_cancel_payment)
-  [Function `get_payment`](#0x4321_pay_stream_get_payment)


<pre><code><b>use</b> <a href="">0x1::aptos_coin</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::table</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
</code></pre>



<a name="0x4321_pay_stream_Stream"></a>

## Struct `Stream`

Represents a payment stream with relevant attributes such as sender, receiver, duration, start time, and associated coins.


<pre><code><b>struct</b> <a href="pay_stream.md#0x4321_pay_stream_Stream">Stream</a> <b>has</b> store
</code></pre>



<a name="0x4321_pay_stream_Payments"></a>

## Resource `Payments`

Represents a collection of payment streams organized by the sender's address.


<pre><code><b>struct</b> <a href="pay_stream.md#0x4321_pay_stream_Payments">Payments</a> <b>has</b> key
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="0x4321_pay_stream_ERR_NUMBER_INVALID"></a>

Error code indicating an invalid number.


<pre><code><b>const</b> <a href="pay_stream.md#0x4321_pay_stream_ERR_NUMBER_INVALID">ERR_NUMBER_INVALID</a>: u64 = 2;
</code></pre>



<a name="0x4321_pay_stream_ERR_PAYMENT_NOT_EXIST"></a>

Error code indicating that the payment does not exist.


<pre><code><b>const</b> <a href="pay_stream.md#0x4321_pay_stream_ERR_PAYMENT_NOT_EXIST">ERR_PAYMENT_NOT_EXIST</a>: u64 = 3;
</code></pre>



<a name="0x4321_pay_stream_ERR_SENDER_CANNOT_BE_RECEIVER"></a>

Error code indicating that the sender cannot be the receiver.


<pre><code><b>const</b> <a href="pay_stream.md#0x4321_pay_stream_ERR_SENDER_CANNOT_BE_RECEIVER">ERR_SENDER_CANNOT_BE_RECEIVER</a>: u64 = 1;
</code></pre>



<a name="0x4321_pay_stream_ERR_SIGNER_NOT_SENDER_OR_RECEIVER"></a>

Error code indicating that the signer's address is neither the sender nor the receiver.


<pre><code><b>const</b> <a href="pay_stream.md#0x4321_pay_stream_ERR_SIGNER_NOT_SENDER_OR_RECEIVER">ERR_SIGNER_NOT_SENDER_OR_RECEIVER</a>: u64 = 6;
</code></pre>



<a name="0x4321_pay_stream_ERR_STREAM_IS_ACTIVE"></a>

Error code indicating that the stream is active.


<pre><code><b>const</b> <a href="pay_stream.md#0x4321_pay_stream_ERR_STREAM_IS_ACTIVE">ERR_STREAM_IS_ACTIVE</a>: u64 = 5;
</code></pre>



<a name="0x4321_pay_stream_ERR_STREAM_NOT_EXIST"></a>

Error code indicating that the stream does not exist.


<pre><code><b>const</b> <a href="pay_stream.md#0x4321_pay_stream_ERR_STREAM_NOT_EXIST">ERR_STREAM_NOT_EXIST</a>: u64 = 4;
</code></pre>



<a name="0x4321_pay_stream_create_payment"></a>

## Function `create_payment`

Creates a payment entry for the given signer, receiver address, amount, and duration in seconds.
@param signer_ The signer initiating the payment.
@param receiver_address The address of the receiver.
@param amount The amount of the payment.
@param duration_in_sec The duration of the payment in seconds.


<pre><code><b>public</b> entry <b>fun</b> <a href="pay_stream.md#0x4321_pay_stream_create_payment">create_payment</a>(signer_: &<a href="">signer</a>, receiver_address: <b>address</b>, amount: u64, duration_in_sec: u64)
</code></pre>



<a name="0x4321_pay_stream_accept_payment"></a>

## Function `accept_payment`

Accepts a payment for the given signer and sender address.
@param signer The signer accepting the payment.
@param sender_address The address of the sender.


<pre><code><b>public</b> entry <b>fun</b> <a href="pay_stream.md#0x4321_pay_stream_accept_payment">accept_payment</a>(<a href="">signer</a>: &<a href="">signer</a>, sender_address: <b>address</b>)
</code></pre>



<a name="0x4321_pay_stream_claim_payment"></a>

## Function `claim_payment`

Claims a payment for the given signer and sender address.
@param signer The signer claiming the payment.
@param sender_address The address of the sender.


<pre><code><b>public</b> entry <b>fun</b> <a href="pay_stream.md#0x4321_pay_stream_claim_payment">claim_payment</a>(<a href="">signer</a>: &<a href="">signer</a>, sender_address: <b>address</b>)
</code></pre>



<a name="0x4321_pay_stream_cancel_payment"></a>

## Function `cancel_payment`

Cancels a payment for the given signer, sender address, and receiver address.
@param signer The signer canceling the payment.
@param sender_address The address of the sender.
@param receiver_address The address of the receiver.


<pre><code><b>public</b> entry <b>fun</b> <a href="pay_stream.md#0x4321_pay_stream_cancel_payment">cancel_payment</a>(<a href="">signer</a>: &<a href="">signer</a>, sender_address: <b>address</b>, receiver_address: <b>address</b>)
</code></pre>



<a name="0x4321_pay_stream_get_payment"></a>

## Function `get_payment`



<pre><code><b>public</b> <b>fun</b> <a href="pay_stream.md#0x4321_pay_stream_get_payment">get_payment</a>(sender_address: <b>address</b>, receiver_address: <b>address</b>): (u64, u64, u64)
</code></pre>
