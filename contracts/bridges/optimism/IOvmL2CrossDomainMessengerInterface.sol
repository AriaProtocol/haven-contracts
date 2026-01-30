// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IOvmL2CrossDomainMessengerInterface {
    function xDomainMessageSender() external returns (address);
}
