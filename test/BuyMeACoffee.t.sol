// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BuyMeACoffee} from "../src/BuyMeACoffee.sol";

contract BuyMeACoffeeTest is Test {
    BuyMeACoffee public buyMeACoffee;

    address public owner = makeAddr("owner");
    address public tipper = makeAddr("tipper");

    function setUp() public {
        vm.prank(owner);
        buyMeACoffee = new BuyMeACoffee();

        vm.deal(tipper, 10 ether);
    }

    function test_InitialOwner() public view {
        assertEq(buyMeACoffee.owner(), owner);
    }

    function test_BuyMeACoffee_InsufficientEth() public {
        vm.prank(tipper);
        vm.expectRevert(BuyMeACoffee.InsufficientEth.selector);
        buyMeACoffee.buyCoffee{value: 0.0009 ether}("Alice", "Not enough");
    }

    function test_BuyCoffee_Success() public {
        vm.prank(tipper);
        buyMeACoffee.buyCoffee{value: 0.001 ether}("Alice", "Great work!");

        BuyMeACoffee.Memo[] memory memos = buyMeACoffee.getMemos();
        assertEq(memos.length, 1);
        assertEq(memos[0].from, tipper);
        assertEq(memos[0].name, "Alice");
        assertEq(memos[0].message, "Great work!");
        assertEq(address(buyMeACoffee).balance, 0.001 ether);
    }

    function test_BuyMeACoffee_EmptyMessage() public {
        vm.prank(tipper);
        buyMeACoffee.buyCoffee{value: 0.001 ether}("", "");

        BuyMeACoffee.Memo[] memory memos = buyMeACoffee.getMemos();
        assertEq(memos.length, 1);
        assertEq(memos[0].from, tipper);
        assertEq(memos[0].name, "");
        assertEq(memos[0].message, "");
    }

    function test_WithdrawTips_NotOwner() public {
        vm.prank(tipper);
        buyMeACoffee.buyCoffee{value: 0.001 ether}("Alice", "Great work!");

        vm.prank(tipper);
        vm.expectRevert(BuyMeACoffee.NotOwner.selector);
        buyMeACoffee.withdrawTips();
    }

    function test_WithdrawTips_Success() public {
        vm.prank(tipper);
        buyMeACoffee.buyCoffee{value: 1 ether}("Alice", "Generous tip");

        uint256 initialOwnerBalance = owner.balance;

        vm.prank(owner);
        buyMeACoffee.withdrawTips();

        assertEq(owner.balance, initialOwnerBalance + 1 ether);
        assertEq(address(buyMeACoffee).balance, 0);
    }
}
