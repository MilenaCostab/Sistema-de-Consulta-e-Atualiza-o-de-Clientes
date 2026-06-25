*****************************************************************
      * CLIPGM.CBL
      * Programa  : CLIPGM
      * Transacao : CLIE
      * Arquivo   : CLIENTES (VSAM KSDS)
      * Autor     : MILENA COSTA
      *
      * OBSERVACAO SOBRE O AMBIENTE DE DESENVOLVIMENTO:
      *   Este programa foi desenvolvido com sintaxe CICS real,
      *   seguindo todos os requisitos do projeto:
      *
      *   - EXEC CICS SEND MAP / RECEIVE MAP (mapa BMS CLIMAPST)
      *   - EXEC CICS READ FILE('CLIENTES') RIDFLD (consulta VSAM)
      *   - EXEC CICS READ UPDATE + REWRITE  (atualizacao VSAM)
      *   - EXEC CICS RETURN TRANSID('CLIE') (pseudo-conversacional)
      *   - COMMAREA para preservar estado entre execucoes
      *   - EIBAID para identificar a tecla pressionada (PF3/PF5/PF6)
      *   - EIBCALEN para detectar a primeira execucao da transacao
      *
      *   Para execucao seria necessario o ambiente CICS ou KICKS
      *   (KICKS for TSO 1.5.0) rodando sobre MVS 3.8j / Hercules,
      *   com a transacao CLIE registrada no PCT e o arquivo
      *   CLIENTES registrado no FCT do CICS/KICKS.
      *
      * ENTREGAVEIS:
      *   1. CLIMAP.BMS  - Mapa BMS com layout da tela
      *   2. Fluxograma  - Fluxo das teclas PF5 e PF6
      *   3. CLIPGM.CBL  - Este programa (logica da transacao)
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CLIPGM.
       AUTHOR. MILENA COSTA.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      
       01  CLIMAPI.
           05 FILLER            PIC X(12).
           05 WCODCLIL          PIC S9(4) COMP.
           05 WCODCLIA          PIC X.
           05 WCODCLIO          PIC 9(6).
           05 WNOMEL            PIC S9(4) COMP.
           05 WNOMEA            PIC X.
           05 WNOMEO            PIC X(30).
           05 WTELEFONEL        PIC S9(4) COMP.
           05 WTELEFONE-A       PIC X.
           05 WTELEFONE-O       PIC X(15).
           05 WCIDADEL          PIC S9(4) COMP.
           05 WCIDADEA          PIC X.
           05 WCIDADE-O         PIC X(20).
           05 WMENSAGEML        PIC S9(4) COMP.
           05 WMENSAGEMA        PIC X.
           05 WMENSAGEM-O       PIC X(30).

      
       01  WS-COMMAREA.
           05 WCA-CODIGO        PIC 9(6).
           05 WCA-STATUS        PIC X(1).
               88 WCA-CONSULTADO    VALUE 'C'.
               88 WCA-NOVO          VALUE 'N'.

      
       01  WS-REGISTRO-CLIENTE.
           05 WS-CODCLI         PIC 9(6).
           05 WS-NOME           PIC X(30).
           05 WS-TELEFONE       PIC X(15).
           05 WS-CIDADE         PIC X(20).

      
       01  WS-RESP              PIC S9(8) COMP.
       01  WS-COMM-LENGTH       PIC S9(4) COMP VALUE 7.

       01  WS-TECLAS.
           05 WS-PF3            PIC X VALUE X'6C'.
           05 WS-PF5            PIC X VALUE X'7E'.
           05 WS-PF6            PIC X VALUE X'6B'.

      
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05 LK-CODIGO         PIC 9(6).
           05 LK-STATUS         PIC X(1).

       PROCEDURE DIVISION.

      
       0000-PRINCIPAL.
           IF EIBCALEN = ZERO
               PERFORM 1000-PRIMEIRA-EXECUCAO
           ELSE
               MOVE DFHCOMMAREA TO WS-COMMAREA
               PERFORM 2000-PROCESSAR-TECLA
           END-IF
           STOP RUN.

      
       1000-PRIMEIRA-EXECUCAO.
           MOVE SPACES TO CLIMAPI
           MOVE SPACES TO WS-COMMAREA
           MOVE 'N'    TO WCA-STATUS
           MOVE 'INFORME O CODIGO E PRESSIONE PF5'
               TO WMENSAGEM-O

           EXEC CICS SEND MAP('CLIMAP')
                          MAPSET('CLIMAPST')
                          ERASE
                          FREEKB
           END-EXEC

           EXEC CICS RETURN
                          TRANSID('CLIE')
                          COMMAREA(WS-COMMAREA)
                          LENGTH(WS-COMM-LENGTH)
           END-EXEC.

      
       2000-PROCESSAR-TECLA.
           MOVE EIBAID TO WS-EIBAID

           EVALUATE TRUE
               WHEN WS-EIBAID = WS-PF3
                   PERFORM 3000-PF3-SAIR
               WHEN WS-EIBAID = WS-PF5
                   PERFORM 4000-PF5-CONSULTAR
               WHEN WS-EIBAID = WS-PF6
                   PERFORM 5000-PF6-SALVAR
               WHEN OTHER
                   MOVE 'USE PF3 PF5 OU PF6' TO WMENSAGEM-O
                   PERFORM 9000-ENVIAR-MAPA
           END-EVALUATE.

    
       3000-PF3-SAIR.
           EXEC CICS SEND TEXT
                          FROM('TRANSACAO CLIE ENCERRADA.')
                          ERASE
                          FREEKB
           END-EXEC

           EXEC CICS RETURN
           END-EXEC.

     
       4000-PF5-CONSULTAR.
           EXEC CICS RECEIVE MAP('CLIMAP')
                             MAPSET('CLIMAPST')
           END-EXEC

           MOVE WCODCLIO TO WS-CODCLI

           EXEC CICS READ FILE('CLIENTES')
                          INTO(WS-REGISTRO-CLIENTE)
                          LENGTH(71)
                          RIDFLD(WS-CODCLI)
                          RESP(WS-RESP)
           END-EXEC

           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                   MOVE WS-NOME     TO WNOMEO
                   MOVE WS-TELEFONE TO WTELEFONE-O
                   MOVE WS-CIDADE   TO WCIDADE-O
                   MOVE 'CLIENTE ENCONTRADO'
                       TO WMENSAGEM-O
                   MOVE WS-CODCLI TO WCA-CODIGO
                   MOVE 'C'       TO WCA-STATUS

               WHEN DFHRESP(NOTFND)
                   MOVE SPACES TO WNOMEO
                                  WTELEFONE-O
                                  WCIDADE-O
                   MOVE 'CLIENTE NAO ENCONTRADO'
                       TO WMENSAGEM-O
                   MOVE 'N' TO WCA-STATUS

               WHEN OTHER
                   MOVE 'ERRO AO ACESSAR ARQUIVO'
                       TO WMENSAGEM-O
           END-EVALUATE

           PERFORM 9000-ENVIAR-MAPA.

     
       5000-PF6-SALVAR.
           IF NOT WCA-CONSULTADO
               MOVE 'CONSULTE UM CLIENTE ANTES DE SALVAR'
                   TO WMENSAGEM-O
               PERFORM 9000-ENVIAR-MAPA
               GO TO 5000-PF6-SALVAR-FIM
           END-IF

           EXEC CICS RECEIVE MAP('CLIMAP')
                             MAPSET('CLIMAPST')
           END-EXEC

           MOVE WCA-CODIGO TO WS-CODCLI

           EXEC CICS READ FILE('CLIENTES')
                          INTO(WS-REGISTRO-CLIENTE)
                          LENGTH(71)
                          RIDFLD(WS-CODCLI)
                          UPDATE
                          RESP(WS-RESP)
           END-EXEC

           IF WS-RESP = DFHRESP(NORMAL)
               MOVE WTELEFONE-O TO WS-TELEFONE
               MOVE WCIDADE-O   TO WS-CIDADE

               EXEC CICS REWRITE FILE('CLIENTES')
                                  FROM(WS-REGISTRO-CLIENTE)
                                  LENGTH(71)
               END-EXEC

               MOVE WS-NOME     TO WNOMEO
               MOVE WS-TELEFONE TO WTELEFONE-O
               MOVE WS-CIDADE   TO WCIDADE-O
               MOVE 'ALTERACAO REALIZADA' TO WMENSAGEM-O
           ELSE
               MOVE 'ERRO AO SALVAR REGISTRO' TO WMENSAGEM-O
           END-IF

           PERFORM 9000-ENVIAR-MAPA.

       5000-PF6-SALVAR-FIM.
           EXIT.

      
           EXEC CICS SEND MAP('CLIMAP')
                          MAPSET('CLIMAPST')
                          DATAONLY
                          FREEKB
           END-EXEC

           EXEC CICS RETURN
                          TRANSID('CLIE')
                          COMMAREA(WS-COMMAREA)
                          LENGTH(WS-COMM-LENGTH)
           END-EXEC.