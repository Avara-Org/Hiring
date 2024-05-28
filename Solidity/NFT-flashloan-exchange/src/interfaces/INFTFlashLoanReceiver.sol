// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title INFTFlashLoanReceiver
 * @author Cheyenne Atapour
 * @notice Defines the interface of an NFT flashloan-receiver contract
 */
interface INFTFlashLoanReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed NFT
     * @dev Ensure that the contract returns the NFT and loan fee
     * @param asset The address of the flash-borrowed NFT
     * @param assetId The id of the flash-borrowed NFT
     * @param loanFee The fee of the flash-borrowed NFT
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(address asset, uint256 assetId, address loanAsset, uint256 loanFee)
        external
        returns (bool);
}
