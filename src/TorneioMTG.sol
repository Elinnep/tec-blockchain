// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TorneioMTG {
    address public organizador;
    uint256 public taxaInscricao;
    uint256 public maxJogadores;
    bool public inscricoesAbertas;

    struct Jogador {
        string nome;
        uint256 pontuacao;
        bool cadastrado;
    }

    mapping(address => Jogador) public jogadores;
    address[] public listaJogadores;

    event InscricaoRealizada(address participante, string nome);

    modifier apenasOrganizador() {
        require(msg.sender == organizador, "Apenas o organizador pode executar isto");
        _;
    }

    constructor(uint256 _taxaInscricao, uint256 _maxJogadores) {
        organizador = msg.sender;
        taxaInscricao = _taxaInscricao;
        maxJogadores = _maxJogadores;
        inscricoesAbertas = true;
    }

    function inscrever(string memory _nome) external payable {
        require(inscricoesAbertas, "As inscricoes ja estao encerradas");
        require(listaJogadores.length < maxJogadores, "O torneio atingiu o limite de vagas");
        require(msg.value == taxaInscricao, "Valor de inscricao incorreto");
        require(!jogadores[msg.sender].cadastrado, "Esta carteira ja esta inscrita");

        jogadores[msg.sender] = Jogador({
            nome: _nome,
            pontuacao: 0,
            cadastrado: true
        });
        
        listaJogadores.push(msg.sender);

        emit InscricaoRealizada(msg.sender, _nome);
    }

    function fecharInscricoes() external apenasOrganizador {
        inscricoesAbertas = false;
    }
    
    function premiar(address payable _vencedor) external apenasOrganizador {
        require(_vencedor != address(0), "Endereco invalido (zero address)");
        require(address(this).balance > 0, "O contrato nao tem saldo para premiar");
        
        _vencedor.transfer(address(this).balance);
    }

    function pontuar(address j, uint256 p) external apenasOrganizador {
        jogadores[j].pontuacao += p;
    }
}