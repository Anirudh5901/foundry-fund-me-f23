// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint constant SEND_VALUE = 0.1 ether;
    uint constant STARTING_BALANCE = 10 ether;
    uint constant GAS_PRICE = 1;

    //set up is the first fn in all tests
    //this is where we deploy our smart contract
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        //assertEq is a function from forge-std/Test.sol that checks equality
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //what can we do towork with addresses outside our system?
    //1.unit
    //  -Testing a specific part of our code
    //2.Integration
    //  -Testing how our code works with other parts of our code
    //3.Forked
    //  -testing our code on a simulated real environment
    //Staging
    //  -testing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public {
        uint version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line should revert
        //assert(This txn fails/reverts)
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // vm.prank(USER); //The next Txn will be sent by USER
        // fundMe.fund{value: SEND_VALUE}();
        uint amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();
        vm.expectRevert(); //v.expectRevert() ignores vm pranks. so the next line is fundMe.withdraw()
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint gasStart = gasleft();
        // vm.txGasPrice(1);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint gasEnd = gasleft();
        // uint gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("Gas used: ", gasUsed);

        //Assert
        uint endingOwnerBalance = fundMe.getOwner().balance;
        uint endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultiplefunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank
            //vm.deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //  uint256 endingOwnerBalance = fundMe.getOwner().balance;
        // uint256 endingFundMeBalance = address(fundMe).balance;

        assert(address(fundMe).balance == 0);
        assert(
            fundMe.getOwner().balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultiplefundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank
            //vm.deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //  uint256 endingOwnerBalance = fundMe.getOwner().balance;
        // uint256 endingFundMeBalance = address(fundMe).balance;

        assert(address(fundMe).balance == 0);
        assert(
            fundMe.getOwner().balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }
}
