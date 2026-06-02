// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BuyMeACoffee} from "../src/BuyMeACoffee.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey;

        // Use anvil default key if not provided
        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
        } catch {
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Default anvil key
        }

        vm.startBroadcast(deployerPrivateKey);

        BuyMeACoffee buyMeACoffee = new BuyMeACoffee();

        console.log("BuyMeACoffee deployed at: ", address(buyMeACoffee));

        vm.stopBroadcast();

        // Automatic Sync
        string memory constantsDir = "./frontend/Contracts";
        vm.createDir(constantsDir, true);

        string memory filePath = string.concat(
            constantsDir,
            "/contractAddress.js"
        );
        string memory fileContent = string.concat(
            'export const contractAddress = "',
            vm.toString(address(buyMeACoffee)),
            '";\n'
        );
        vm.writeFile(filePath, fileContent);

        console.log("Contract address synced to frontend!");
    }
}
