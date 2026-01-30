// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {CometHarness} from "contracts/test/CometHarness.sol";

import "./0_Common.setup.t.sol";

contract Comet_Setup is Common_Setup {
    CometHarness public comet;

    function _deployComet() internal override {
        comet = new CometHarness(_configureComet());
        comet.initializeStorage();
        vm.label(address(comet), "Comet");
    }

    function _deployCometExt() internal override {
        CometConfiguration.ExtConfiguration memory extConfig =
            CometConfiguration.ExtConfiguration({name32: NAME32, symbol32: SYMBOL32});
        extensionDelegate = new CometExt(extConfig);
    }
}
