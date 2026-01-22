// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {CometExtAssetList} from "contracts/CometExtAssetList.sol";
import {AssetListFactory} from "contracts/AssetListFactory.sol";
import {CometHarnessExtendedAssetList} from "contracts/test/CometHarnessExtendedAssetList.sol";

import "./0_Common.setup.t.sol";

contract CometWithExtendedAssetList_Setup is Common_Setup {
    CometHarnessExtendedAssetList public cometExtAsset;

    function _deployComet() internal override {
        cometExtAsset = new CometHarnessExtendedAssetList(_configureComet());
        cometExtAsset.initializeStorage();
        vm.label(address(cometExtAsset), "Comet");
    }

    function _deployCometExt() internal override {
        CometConfiguration.ExtConfiguration memory extConfig =
            CometConfiguration.ExtConfiguration({name32: NAME32, symbol32: SYMBOL32});
        extensionDelegate = new CometExtAssetList(extConfig, address(new AssetListFactory()));
    }
}
