// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../CometInterface.sol";

abstract contract CometHarnessInterfaceExtendedAssetList is CometInterface {
    function accrue() external virtual;
    function getNow() external view virtual returns (uint40);
    function setNow(uint now_) external virtual;
    function setTotalsBasic(TotalsBasic memory totals) external virtual;
    function setTotalsCollateral(
        address asset,
        TotalsCollateral memory totals
    ) external virtual;
    function setBasePrincipal(
        address account,
        int104 principal
    ) external virtual;
    function setCollateralBalance(
        address account,
        address asset,
        uint128 balance
    ) external virtual;
    function updateAssetsInExternal(
        address account,
        address asset,
        uint128 initialUserBalance,
        uint128 finalUserBalance
    ) external virtual;
    function getAssetList(
        address account
    ) external view virtual returns (address[] memory);
    function assetList() external view virtual returns (address);
}
