// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IFlexableAuth {
    function isAdmin(address account) external view returns (bool);

    function isOperator(address account) external view returns (bool);

    function isMinter(address account) external view returns (bool);

    function getPayoutAddress() external view returns (address);
}
