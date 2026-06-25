# Sistema de Consulta e Atualização de Clientes
 
**Autora:** Milena Costa  

---

## Descrição

Aplicação online desenvolvida em COBOL CICS para consultar e atualizar dados de clientes cadastrados em um arquivo VSAM. O sistema utiliza o modelo **pseudo-conversacional** do CICS, onde o programa é carregado na memória a cada interação do usuário e encerrado logo após, preservando o estado via **COMMAREA**.

---

## Funcionalidades

- Consultar um cliente pelo código
- Exibir nome, telefone e cidade na tela
- Alterar telefone e cidade
- Salvar as alterações no VSAM

---

## Arquivos

| Arquivo | Descrição |
|---|---|
| `CLIPGM.cbl` | Programa COBOL CICS com a lógica da transação |
| `CLIMAP.bms` | Mapa BMS com o layout da tela 3270 |
| `fluxograma_pf5_pf6_clipgm.png` | Fluxograma das teclas PF5 e PF6 |

---

## Tela do Sistema

```
****************************************
*       CONSULTA DE CLIENTES          *
****************************************

Codigo Cliente: ______
Nome.........: ______________________________
Telefone.....: _______________
Cidade.......: ____________________
Mensagem.....: ______________________________

PF3=Sair
PF5=Consultar
PF6=Salvar
```

---

## Layout do Arquivo VSAM (CLIENTES)

| Campo | Tipo | Tamanho |
|---|---|---|
| CODCLI | Numérico | 6 |
| NOME | Alfanumérico | 30 |
| TELEFONE | Alfanumérico | 15 |
| CIDADE | Alfanumérico | 20 |

---

## Regras de Negócio

- **PF5**: Consulta o cliente pelo código. Exibe `CLIENTE ENCONTRADO` ou `CLIENTE NAO ENCONTRADO`.
- **PF6**: Atualiza TELEFONE e CIDADE. Exige consulta prévia. Exibe `ALTERACAO REALIZADA`.
- **PF3**: Encerra a transação.

---

## Conceitos CICS Utilizados

- `EXEC CICS SEND MAP / RECEIVE MAP` — envio e leitura do mapa BMS
- `EXEC CICS READ` — consulta ao arquivo VSAM por chave (RIDFLD)
- `EXEC CICS READ UPDATE + REWRITE` — atualização de registro VSAM
- `EXEC CICS RETURN TRANSID` — modelo pseudo-conversacional
- `COMMAREA` — preserva estado entre execuções
- `EIBAID` — identifica a tecla pressionada (PF3/PF5/PF6)
- `EIBCALEN` — detecta a primeira execução da transação

---

## Observação

O código foi desenvolvido com sintaxe CICS real, seguindo todos os requisitos do projeto. Para execução seria necessário o ambiente **CICS** ou **KICKS for TSO 1.5.0** rodando sobre MVS 3.8j / Hercules, com a transação `CLIE` registrada no PCT e o arquivo `CLIENTES` registrado no FCT.
