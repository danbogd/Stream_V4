// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public swapRouter = address(0);

    function setUp() public {
        bank = new Bank(swapRouter);
        
    }

   
}
