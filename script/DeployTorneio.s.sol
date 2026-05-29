// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TorneioMTG.sol";

contract DeployTorneio is Script {
    function run() external {
        // Pega a chave privada do seu arquivo .env
        uint256 deployerPrivateKey = vm.parseUint(vm.envString("PRIVATE_KEY"));        
        vm.startBroadcast(deployerPrivateKey);

        // Antes: new TorneioMTG(0.01 ether);
        new TorneioMTG(0.01 ether, 16);

        vm.stopBroadcast();
    }
}