// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/TorneioMTG.sol";

contract TorneioMTGTest is Test {
    TorneioMTG public torneio;
    address public organizador = address(1);
    address public jogador1 = address(2);
    address public naoInscrito = address(3);

    uint256 public taxaInscricao = 0.01 ether;

    function setUp() public {
        // Define o organizador e faz o deploy do contrato
        vm.prank(organizador);
        torneio = new TorneioMTG(taxaInscricao, 16);
    }

    function testFluxoVotacaoFormato() public {
        // 1. O organizador adiciona as opções de formato de Magic
        vm.startPrank(organizador);
        torneio.adicionarOpcaoFormato("Commander");
        torneio.adicionarOpcaoFormato("Standard");
        vm.stopPrank();

        // 2. O jogador 1 inscreve-se no torneio pagando a taxa
        vm.deal(jogador1, taxaInscricao);
        vm.prank(jogador1);
        torneio.inscrever{value: taxaInscricao}("Participante 1");

        // 3. O jogador 1 vota na opção 0 (Commander)
        vm.prank(jogador1);
        torneio.votarFormato(0);

        // 4. Valida se o voto foi devidamente contabilizado
        (string memory nome, uint256 votos) = torneio.opcoesFormato(0);
        assertEq(votos, 1);
        assertEq(nome, "Commander");
    }

    function testFalhaVotoNaoInscrito() public {
        // O organizador adiciona uma opção
        vm.prank(organizador);
        torneio.adicionarOpcaoFormato("Pauper");

        // Tenta votar com uma conta não inscrita (deve falhar)
        vm.prank(naoInscrito);
        vm.expectRevert("Apenas jogadores inscritos podem votar");
        torneio.votarFormato(0);
    }
}