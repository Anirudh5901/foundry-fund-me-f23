// SPDX-License-Identifier: MIT

//1.deploy mocks when we are on a local anvil chain
//2.Keep track of contract addresses across different chains
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //if we are on a local anvil, we deploy mocks
    //otherwise, grab the existing address on the live netwroks
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    NetwrokConfig public activeNetwrokConfig;

    struct NetwrokConfig {
        address priceFeed; //ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetwrokConfig = getSepoliaEthConfig();
        } else {
            activeNetwrokConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetwrokConfig memory) {
        //price feed address
        NetwrokConfig memory sepoliaConfig = NetwrokConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetwrokConfig memory) {
        //if we've already deployed a mockPriceFeed, we dont need to redeploy a new one hence the following check
        if (activeNetwrokConfig.priceFeed != address(0)) {
            return activeNetwrokConfig;
        }
        //1.Deploy the mocks(mock = fake/dummy contract)
        //2.return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetwrokConfig memory anvilConfig = NetwrokConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
