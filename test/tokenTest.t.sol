// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {HAYEKCOP} from "../src/token.sol";
import {Test, console} from "../forge-std/Test.sol";
import "../lib/_external/SafeMathInt.sol";

contract TokenTest is Test {
    using SafeMathInt for uint256;
    HAYEKCOP hayekcop;
    address monetaryPolicy;
    /**
     * . Defining all the variables to be used in
     * testing functions
     */
    address constant USER = address(0x123);
    string constant NAME = "HAYEKCOP";
    string constant SYMBOL = "HAYEKCOP";
    uint256 constant MINTED = 1000;
    uint256 constant SENT = 100;
    uint256 constant INVALID_SENT = 1001;

    struct _address {
        address account;
        uint256 balance;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    modifier mintable() {
        /**
         *  .: Only the monetaryPolicy can mint
         *   creates new toknes echa time its called
         */
        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);
        vm.stopPrank();
        _;
    }

    function setUp() external {
        hayekcop = new HAYEKCOP();
        hayekcop.initialize(msg.sender);
        monetaryPolicy = hayekcop.monetaryPolicy();
    }
    /**
     * .: Verify all the params specified in the
     * token constructor are correct
     */
    function testInitialization() public {
        assertEq(hayekcop.owner(), msg.sender);
        assertEq(hayekcop.name(), NAME);
        assertEq(hayekcop.symbol(), SYMBOL);
        assertEq(hayekcop._totalSupply(), hayekcop.INITIAL_SUPPLY());
    }
    /**
     * . Verify total supply getter function
     *  matches the total supply state variable
     */
    function testTotalSupply() public {
        assertEq(hayekcop.totalSupply(), hayekcop._totalSupply());
    }

    /**
     * . Verify the totalsupply changes accordingly as
     * tokens are minted
     */

    function testMintSuccess() public mintable {
        assertEq(
            hayekcop.totalSupply(),
            hayekcop.INITIAL_SUPPLY() + hayekcop.balanceOf(monetaryPolicy)
        );
    }

    /**
    
    * . Verify that only the monetary policy 
    * can mint
    
    */

    function testMintFail1() public {
        vm.startPrank(USER);
        vm.expectRevert();
        hayekcop.mint(monetaryPolicy, MINTED);
        vm.stopPrank();

        assertEq(
            hayekcop.totalSupply(),
            hayekcop.INITIAL_SUPPLY() + hayekcop.balanceOf(monetaryPolicy)
        );
    }

    /**
     * . Verify only the monetarypolicy address
     * receives tokens minted
     */

    function testMintFail2() public {
        vm.startPrank(monetaryPolicy);
        vm.expectRevert();
        hayekcop.mint(USER, MINTED);
        vm.stopPrank();

        assertEq(
            hayekcop.totalSupply(),
            hayekcop.INITIAL_SUPPLY() + hayekcop.balanceOf(USER)
        );
    }
    /**
     * .
     * 1) Verify monetaryPolicy can senf tokens among different
     * accounts and balances are properly updated
     * 2) Verify that holders cand trade tokens among them
     * and account balances are properly updated
     */

    function testTransferSuccess() public {
        _address[10] memory _accounts;

        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);

        for (uint i = 2; i < _accounts.length; i++) {
            _accounts[i].account = address(uint160(i));
            hayekcop.transfer(
                _accounts[i].account,
                uint256(MINTED / _accounts.length)
            );
            assertEq(
                hayekcop.balanceOf(_accounts[i].account),
                uint256(MINTED / _accounts.length)
            );
        }
        vm.stopPrank();

        for (uint i = 2; i < _accounts.length - 1; i++) {
            vm.startPrank(address(uint160(i)));
            hayekcop.transfer(
                _accounts[i + 1].account,
                uint256(SENT / _accounts.length)
            );
            vm.stopPrank();

            assertEq(
                hayekcop.balanceOf(_accounts[i + 1].account),
                uint256(SENT + uint256(SENT / _accounts.length))
            );
        }
    }
    /**
     * . Verify that the contract address
     * does not receive any tokens
     */

    function testTranferFail1() public {
        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);
        vm.expectRevert();
        hayekcop.transfer(address(hayekcop), SENT);
        vm.stopPrank();
    }
    /**
     * . Verify the 0x0 address does not receive any tokens
     */

    function testTranferFail2() public {
        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);
        vm.expectRevert();
        hayekcop.transfer(address(0x0), SENT);
        vm.stopPrank();
    }

    /**
     * Verifiy that when transfering all tokens
     * the balance empties former owner balance
     * and updates new owner balance
     */

    function testTransferAll() public mintable {
        address bob = makeAddr("bob");
        uint256 previousBalance = hayekcop.balanceOf(monetaryPolicy);
        vm.prank(monetaryPolicy);
        hayekcop.transferAll(bob);
        assertEq(hayekcop.balanceOf(bob), previousBalance);
    }

    /**
     * . Verify that transaction is reverted
     * when sender does not have enough tokens
     */

    function testTransferFail3() public {
        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);
        vm.expectRevert();
        hayekcop.transfer(USER, INVALID_SENT);
        vm.stopPrank();
    }

    /**
     * .: Verify that the allowance
     * state variable is properly updated when
     * tokens are approved
     */

    function testAproveSuccess() public {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);
        hayekcop.transfer(bob, SENT);
        vm.stopPrank();

        vm.startPrank(bob);
        hayekcop.approve(alice, SENT);
        assertEq(hayekcop.allowance(bob, alice), SENT);
        vm.stopPrank();
    }

    /**
     * . Verify that apporvable amounts are
     * actualy held by the sender
     */

    function testApproveFailed() public {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.startPrank(monetaryPolicy);
        hayekcop.mint(monetaryPolicy, MINTED);
        hayekcop.transfer(bob, SENT);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert();
        hayekcop.approve(alice, INVALID_SENT);
        vm.stopPrank();
    }

    /**
     * . Verify allowed tokens can be transfered from
     * allowed accounts and allowances and balances are
     * properly updated
     */

    function testTransferFromSuccess() public mintable {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.prank(monetaryPolicy);
        hayekcop.transfer(bob, SENT);

        vm.prank(bob);
        hayekcop.approve(alice, SENT);
        vm.prank(alice);
        hayekcop.transferFrom(bob, USER, SENT);
        assertEq(hayekcop.balanceOf(USER), SENT);
        assertEq(hayekcop.allowance(bob, alice), 0);
    }

    /**
     * . Verify allowed tokens can be transfered from
     * allowed accounts and allowances and balances are
     * emptied and updated accordingly
     */

    function testTransferAllFromSuccess() public mintable {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.prank(monetaryPolicy);
        hayekcop.transfer(bob, SENT);

        vm.prank(bob);
        hayekcop.approve(alice, SENT);
        vm.prank(alice);
        hayekcop.transferAllFrom(bob, USER);
        assertEq(hayekcop.balanceOf(USER), SENT);
        assertEq(hayekcop.allowance(bob, alice), 0);
        assertEq(hayekcop.balanceOf(bob), 0);
    }

    /**
    * . Verify that the allowance increases by the
    * specified amount by the holder
    
     */
    function testIncreaseAllowanceSuccess() public mintable {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.prank(monetaryPolicy);
        hayekcop.transfer(bob, 2 * SENT);

        vm.startPrank(bob);

        hayekcop.approve(alice, SENT);
        hayekcop.increaseAllowance(alice, SENT);
        vm.stopPrank();

        assertEq(hayekcop.allowance(bob, alice), 2 * SENT);
    }

    /**
    * . Verify that the allowance decreases by the
    * specified amount by the holder
    
     */
    function testDecreaseAllowanceSuccess() public mintable {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.prank(monetaryPolicy);
        hayekcop.transfer(bob, 2 * SENT);

        vm.startPrank(bob);
        hayekcop.approve(alice, 2 * SENT);
        hayekcop.decreaseAllowance(alice, SENT);
        vm.stopPrank();

        assertEq(hayekcop.allowance(bob, alice), SENT);
    }

    /**
     * . Verify that the amount to be decreased
     * does not exceed the current allowance
     */

    function testDecreaseAllowanceFail() public mintable {
        address bob = makeAddr("bob");
        address alice = makeAddr("alice");

        vm.prank(monetaryPolicy);
        hayekcop.transfer(bob, 2 * SENT);

        vm.startPrank(bob);
        hayekcop.approve(alice, SENT);
        hayekcop.decreaseAllowance(alice, 2 * SENT);
        vm.stopPrank();

        assertEq(hayekcop.allowance(bob, alice), 0);
    }
    /**
     *Verify that the token supply contracts by the amount
     * specified and only possible by the monetaryPolicy adress
     * and the balance and total supply are properly adjusted
     */

    function testburnSuccess() public mintable {
        uint256 previousSupply = hayekcop.totalSupply();
        uint256 burned = MINTED / 2;

        vm.prank(monetaryPolicy);
        hayekcop.burn(monetaryPolicy, burned);

        assertEq(hayekcop.balanceOf(monetaryPolicy), burned);
        assertEq(hayekcop.totalSupply(), previousSupply - burned);
    }
}
