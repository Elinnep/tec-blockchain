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

    // --- ESTRUTURAS DA DAO (VOTAÇÃO DE FORMATO) ---
    struct OpcaoFormato {
        string nome;   // Ex: "Commander", "Standard"
        uint256 votos;
    }

    OpcaoFormato[] public opcoesFormato;
    mapping(address => bool) public jaVotouFormato;
    bool public votacaoEncerrada;

    // Eventos para o front-end escutar depois
    event NovaOpcaoFormato(string nome, uint256 idOpcao);
    event VotoRegistrado(address eleitor, uint256 idOpcao);
    event VotacaoEncerrada(string formatoVencedor, uint256 totalVotos);

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

    // --- FUNÇÕES DA DAO ---

    // 1. Organizador cadastra as opções de formato (ex: 0 para Commander, 1 para Standard)
    function adicionarOpcaoFormato(string memory _nome) external apenasOrganizador {
        require(!votacaoEncerrada, "A votacao ja foi encerrada");
        
        opcoesFormato.push(OpcaoFormato({
            nome: _nome,
            votos: 0
        }));
        
        emit NovaOpcaoFormato(_nome, opcoesFormato.length - 1);
    }

    // 2. Jogadores inscritos votam na sua opção favorita
    function votarFormato(uint256 _idOpcao) external {
        require(jogadores[msg.sender].cadastrado, "Apenas jogadores inscritos podem votar");
        require(!jaVotouFormato[msg.sender], "Voce ja votou em um formato");
        require(!votacaoEncerrada, "A votacao ja esta encerrada");
        require(_idOpcao < opcoesFormato.length, "Opcao de formato invalida");

        jaVotouFormato[msg.sender] = true;
        opcoesFormato[_idOpcao].votos += 1;

        emit VotoRegistrado(msg.sender, _idOpcao);
    }

    // 3. Organizador encerra a votação e o contrato calcula o vencedor
    function encerrarVotacaoFormato() external apenasOrganizador {
        require(!votacaoEncerrada, "A votacao ja esta encerrada");
        require(opcoesFormato.length > 0, "Nenhuma opcao cadastrada");

        votacaoEncerrada = true;
        
        uint256 maxVotos = 0;
        uint256 idVencedor = 0;
        
        // Percorre o array para encontrar a opção com mais votos
        for (uint256 i = 0; i < opcoesFormato.length; i++) {
            if (opcoesFormato[i].votos > maxVotos) {
                maxVotos = opcoesFormato[i].votos;
                idVencedor = i;
            }
        }
        
        emit VotacaoEncerrada(opcoesFormato[idVencedor].nome, maxVotos);
    }

    // 4. Função de leitura auxiliar para o Front-end
    function obterOpcoesDeFormato() external view returns (OpcaoFormato[] memory) {
        return opcoesFormato;
    }
}