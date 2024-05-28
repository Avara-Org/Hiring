# Pay Stream Module

This module is a response to AAVE's Craft Task, the project implements a basic payment streaming system on the Aptos blockchain, i.e. it allows any payer to create a streaming payment, and pays to the recipient every second until the streaming is cancelled. It allows users to create, accept, and cancel payment streams between two parties. The module is written with MOVE programming language.

## Features

- Creation of payment streams
- Acceptance of payment streams
- Claiming payments from active streams
- Canceling payment streams by its creator, streams will be cut off till that amount

## Test

Test cases are in a separate test file, run ```aptos move test``` to test the code.

## Installation

To use this module, you will need to install to the Aptos blockchain and the MOVE development environment. [Click here](https://aptos.dev/tutorials/first-move-module/) for a detailed tutorial.

## Usage

1. Clone the repository.
    ```
    git clone <repository_URL>
    ```
2. Navigate to the repository directory.
    ```
    cd <repository_directory>
    ```
3. Compile the MOVE code.
    ```

    aptos move compile
    ```


    ```
    aptos move compile
    Compiling, may take a little while to download git dependencies...
    INCLUDING DEPENDENCY AptosFramework
    INCLUDING DEPENDENCY AptosStdlib
    INCLUDING DEPENDENCY MoveStdlib
    BUILDING pay_stream
    {
    "Result": [
        "0000000000000000000000000000000000000000000000000000000000004321::pay_stream_tests",
        "0000000000000000000000000000000000000000000000000000000000004321::pay_stream"
    ]
    }

    ```

4. Verify the MOVE code.
    ```
    aptos move prove
    ```

    ```
    aptos move prove
    [INFO] preparing module 0x4321::pay_stream_tests
    [INFO] preparing module 0x4321::pay_stream
    [INFO] transforming bytecode
    [INFO] generating verification conditions
    [INFO] 13 verification conditions
    [INFO] running solver
    [INFO] 0.221s build, 0.618s trafo, 0.011s gen, 0.849s verify, total 1.700s
    {
    "Result": "Success"
    }
    ```

5. Run the MOVE tests.
    ```
    aptos move test
    ```

    ```
    aptos move test
    INCLUDING DEPENDENCY AptosFramework
    INCLUDING DEPENDENCY AptosStdlib
    INCLUDING DEPENDENCY MoveStdlib
    BUILDING pay_stream
    Running Move unit tests
    [ PASS    ] 0x4321::pay_stream_tests::test_accept_as_sender
    [ PASS    ] 0x4321::pay_stream_tests::test_claim_as_sender
    [ PASS    ] 0x4321::pay_stream_tests::test_create_accept_and_claim
    [ PASS    ] 0x4321::pay_stream_tests::test_create_and_cancel
    Test result: OK. Total tests: 4; passed: 4; failed: 0
    {
    "Result": "Success"
    }
    ```
6. Generate MOVE code documentation.
    ```
    aptos move document
    ```
    
    ```
    aptos move document
    Compiling, may take a little while to download git dependencies...
    INCLUDING DEPENDENCY AptosFramework
    INCLUDING DEPENDENCY AptosStdlib
    INCLUDING DEPENDENCY MoveStdlib
    BUILDING pay_stream
    {
    "Result": "succeeded"
    }
    ```

## Error Codes

The module utilizes specific error codes for various situations, including:

- ERR_SENDER_CANNOT_BE_RECEIVER
- ERR_NUMBER_INVALID
- ERR_PAYMENT_NOT_EXIST
- ERR_STREAM_NOT_EXIST
- ERR_STREAM_IS_ACTIVE
- ERR_SIGNER_NOT_SENDER_OR_RECEIVER

Please refer to the code for more details on the specific scenarios where these error codes are used.



## License

This module is available under the [MIT License](https://opensource.org/licenses/MIT).
