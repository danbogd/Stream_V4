// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public swapRouter = a0xE592427A0AEce92De3Edee1F18E0157C05861564;

    function setUp() public {
        bank = new Bank(swapRouter);
        
    }

   
}
