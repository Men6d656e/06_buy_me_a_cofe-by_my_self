// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BuyMeACoffee} from "../src/BuyMeACoffee.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();

        BuyMeACoffee buyMeACoffee = new BuyMeACoffee();

        console.log("BuyMeACoffee deployed at: ", address(buyMeACoffee));

        vm.stopBroadcast();

        // Automatic Sync
        string memory constantsDir = "./frontend/constants";
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
