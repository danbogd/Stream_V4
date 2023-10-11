// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {SwapRouter} from "../lib/v3-periphery/contracts/SwapRouter.sol";

contract BankTest is Test {
    Bank public bank;
    SwapRouter public swaprouter;

    function setUp() public {
        swaprouter = new SwapRouter;

        address sr = address(swaprouter);
        bank = new Bank(sr);
        
    }

   
}
