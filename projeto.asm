; ******************************************************
; **** PROJETO 1 - INT. ARQUITETURA DE COMPUTADORES ****
; * Vitor Nunes, Afonso Samora, Joao Moniz			   *
; ******************************************************
; Informacoes importantes
; R7 - guardara permanentemente o valor do cursor no ecra
; R6 - posicao do passaro
;
;
;
; 
; Configuracoes Gerais
CR              EQU     0Ah
FIM_TEXTO       EQU     '@'
IO_READ         EQU     FFFFh
IO_WRITE        EQU     FFFEh
IO_STATUS       EQU     FFFDh
SP_INICIAL      EQU     FDFFh
XY_SCREEN		EQU		FFFCh
INT_MASK	    EQU     1000000000000111b
INT_MASK_ADDR	EQU		FFFAh
MASK_RANDOM		EQU		1000000000010110b
DISPLAY1		EQU		FFF0h
DISPLAY2		EQU		FFF1h
DISPLAY3		EQU		FFF2h
DISPLAY4		EQU		FFF3h
VAL_CONT		EQU		FFF6h
CONT_CT			EQU		FFF7h
LED_ADD			EQU		FFF8h
LCD_CONTROLO	EQU		FFF4h
LCD				EQU		FFF5h
N_COLUNAS		EQU		78 ;numero de colunas da matriz que representa o ecra
N_LINHAS		EQU		24
DIM_TABS		EQU		9 ; dimensao das tabelas que contem a posicao e o valor dos obstaculos
MAX_OBST		EQU		10 ; numero maximo de obstaculos em simultaneo
POWER_TEMP		EQU		1 ; indica se o temporizador está ativo
CONT_MS			EQU		1 ;n de milisegundos configurado no temporizador
LIMITES_ALEAT	EQU		19 ;limites do valor aleatório (entre 0 e LIMITES_ALEAT)
LED_FACIL		EQU		1000000000000000b ;Máscara que será utilizada para mostrar o nível na representação dos leds
LED_MEDIO		EQU		1100000000000000b
LED_DIFICIL		EQU		1110000000000000b
NIVEL_FACIL		EQU		3
NIVEL_MEDIO		EQU		2
NIVEL_DIFICIL	EQU		1
Pos_Esc_LCD_1	EQU		1000000000000000b
Pos_Esc_LCD_2	EQU		1000000000100000b
ULTIMA_LINHA	EQU		1700h ;coordenadas da ultima linha
NIVEL_MAX		EQU		1
NIVEL_MIN		EQU		3
ACTIV_LCD		EQU		100000000000000b ;mascára que ativará o LCD ao ser escrita no porto de controlo
POS_INSTR		EQU		0C23h ;coordenadas da posição onde serão escritas as instruções
POS_STATS		EQU		0E17h ;coordenadas da posição onde será escrito o numero total de obstaculo ultrapassados
PROXIMA_LINHA	EQU		0100h ;Valor que será somado a uma coordenada para incrementar o valor da linha
CONVERSOR_ASCII	EQU		0030h

;Configuracoes do jogo
TXT_PAREDE				EQU		'-'
TXT_OBST				EQU		'X'
LINHAS_CENARIO			EQU		2 ;numero de linhas a excluir por pretencerem ao cenário
COMP_FIXO_OBST			EQU	4
POS_PASSARO_INIT 		EQU	0C14h
PASSARO_ACL_INIT		EQU	4
COL_PASSARO				EQU		20 ;coluna onde o passaro se desloca
COL_OBST_INIT			EQU		004Dh ;Coluna pre-definida onde serão colocados os obstáculos.
NIVEL_INIT				EQU		3 ; Nivel inicial (1-> dificil, 2-> medio, 3->facil)
DST_OBST				EQU		10	; numero de colunas entre obstaculos
ACEL					EQU		10 ;aceleração do passáro em relação à gravidade
LIMITE_PASSARO_TOPO		EQU		0114h ;coordenadas máximas que o pássaro poderá atingir
LIMITE_PASSARO_FUNDO	EQU	1614h 



ORIG	FE00h ; Tabela de interrupcoes
INT0		WORD	rot_I0
INT1		WORD	rot_I1
INT2		WORD	rot_I2
ORIG	FE0Fh
INT15		WORD	rot_I15
				
; Variaveis
				ORIG    8000h
StrPrep			STR		'Prepare-se', FIM_TEXTO
StrInst			STR		'Prima o interruptor I1', FIM_TEXTO
StrPassaro		STR		'o>', FIM_TEXTO
StrLimpa		STR		'  ', FIM_TEXTO
StrGameOver		STR		'Fim de Jogo',FIM_TEXTO
StrGO_Pts		STR		'Pontuacao final ',FIM_TEXTO
StrGO_Pts2		STR		' obstaculos ultrapassados',FIM_TEXTO
Str_Dist		STR     'Distancia:', FIM_TEXTO
Cont_I0			WORD 0 ;Contadores de controlo às interrupções
Cont_I1			WORD 0
Cont_I2			WORD 0
Cont_Obst		WORD 0 ;Contador que limita o aparecimento de novos obstáculos
Cont_Pass		WORD 0 ;Contador que limita a ação da gravidade aplicada ao pássaro.
Cont_Timer		WORD 0 ; Contador auxiliar de forma a permtir executar operações comuns a todos os timers
Pos_Obst		TAB	MAX_OBST ;guardara a coluna onde se encontra o obstaculo
NumI			WORD	0	; Ni do algoritmo do aleatorio
OBST_C			WORD	COL_OBST_INIT
NIVEL			WORD	NIVEL_INIT
I_POS			WORD	0 ;indica a próxima posição livre do vetor
Contador_Cols	WORD	0 ;indica se é necessário introduzir um obstaculo na próxima interação
NOBST_Ult		WORD	0 ;numero de obstaculos ultrapassados
NOBST_Ult_Dec	WORD	0 ;numero de obstaculos ultrapassados (decimal)
Velocidade		WORD	0000h
Pos_Fixa		WORD	0 ; posição do pássaro em vírgula fixa
GRAVIDADE		WORD	1 ; indica se a gravidade se encontra ativa ou não
DST_COLUNAS		WORD	0 ;distancia percorrida (em colunas)

; Inicio do programa
                		ORIG 0000h
init:              		MOV R7, SP_INICIAL ;inicializacao da pilha
                		MOV     SP, R7
                		MOV     R7, INT_MASK
                		MOV     M[INT_MASK_ADDR], R7
						MOV R7, FFFFh ;inicializacao que permite escrever em qualquer parte do ecra
						MOV M[XY_SCREEN], R7
						MOV M[Cont_I0], R0
						MOV M[Cont_Obst], R0
						CALL RContador
						MOV R1, ACTIV_LCD ; ativa o LCD
						
						MOV M[LCD_CONTROLO], R1
						CALL acendeleds
						;CALL escreveLCD
						ENI
						JMP     Inicio

; Tratamento de interrupcoes
; Rotinas de tratamento de interrupções
; I0 -> corresponde ao botão I0
; I15 -> corresponde a temporizador
;
rot_I0:		INC M[Cont_I0]
			RTI
			
rot_I1:	    INC M[Cont_I1]
			RTI
			
rot_I2:		INC M[Cont_I2]
			RTI
			
rot_I15:	INC M[Cont_Timer]
			RTI

	
	
			
; RESUMO: Escreve um caractere numa dada posição do ecrã
; PARAMETROS: Caractere a escrever
; 
;		
			
EscCar:         PUSH    R1
                MOV     R1, M[SP+3]
				INC 	R7
				MOV M[XY_SCREEN], R7
				MOV     M[IO_WRITE], R1
				POP     R1
                RETN    1
				
; RESUMO: Escreve um caractere numa dada posição sem incrementar o ponteiro do ecrã
; PARAMETROS: Caractere a escrever
; 
; 	
EscCarNI:       PUSH    R1
                MOV     R1, M[SP+3]
				MOV M[XY_SCREEN], R7
				MOV     M[IO_WRITE], R1
				POP     R1
                RETN    1
				
; RESUMO: Efetua uma mudança de linha na posição atual
; Sem parametros
;				
MudaLinha:      PUSH    R1
                PUSH    CR
                CALL    EscCar
                POP     R1
                RET
				
; RESUMO: Apaga a string correspondente ao pássaro
; Sem parametros
; OBS: Serve-se da posição atual do passaro.
		
ApagaPassaroAtual:	PUSH    R2
					PUSH StrLimpa
					CALL EscString
					POP     R2
					RET
					
; RESUMO: Apaga o conteúdo da matriz que representa o ecrã.
; Sem parametros.
;	
ApagaEcra:		PUSH R1
				PUSH R2
				PUSH R3
				PUSH R7
				MOV R1, N_LINHAS
				
				linhas: MOV R2, N_COLUNAS
					colunas: MOV R3, R1
							 SHL R3, 8  ; De acordo com a representação o numero de linhas situa-se no primeiro octeto
							 ADD R3, R2 ;R3 contém as coordenadas no formato LLCC
							 MOV R7, R3 ; Esse valor é colocado no registo do ponteiro do ecrã.
							 PUSH ' '
							 CALL EscCar
							 DEC R2
							 BR.NZ colunas
					DEC R1
					BR.NN linhas
				POP R7
				POP R3
				POP R2
				POP R1
				RET

; RESUMO: Escreve uma string no ecrã de acordo com as coordenadas atuais
; PARAMETROS: String a escrever
;				
EscString:      PUSH    R1
                PUSH    R2
				MOV		R2, M[SP+4]
Ciclo:          MOV     R1, M[R2]
                CMP     R1, FIM_TEXTO
                BR.Z    FimEsc
                PUSH    R1
                CALL    EscCar
                INC     R2
                BR      Ciclo
FimEsc:         POP     R2
                POP     R1
                RETN	1
				
				
EscNum:         PUSH    R1
				MOV R1, M[SP+3]
                ADD     R1,'0'
                PUSH    R1
                CALL    EscCar
                POP     R1
                RETN 1

; RESUMO: Reinicia o contador, i.e. coloca nos portos do temporizador os valores predefinidos.
; Sem parametros

RContador:	PUSH R5
			MOV R5, CONT_MS ;reinicia os settings do temporizador
			MOV M[VAL_CONT], R5
			MOV R5, POWER_TEMP ; POWER_TEMP define se o temporizador está ativo ou não.
			MOV M[CONT_CT], R5			
			POP R5
			RET

; RESUMO: Gera um valor pseudo-aleatório.
; Sem parametros
; OBS: Serve-se do valor de M[NumI] o qual é inicializado no inicio de cada instância do jogo
aleatorio: 	PUSH R1
			PUSH R2
			MOV R1, M[NumI]
			MOV R2, 0001h
			AND R2, R1 ;testa o bit de menor peso
			BR.Z ezero 
		
			XOR R1, M[MASK_RANDOM]
		
ezero:	ROR R1, 1
fimaleat: 	MOV M[NumI], R1
			POP R2
			POP R1
		  RET

; RESUMO: Gera um valor aleatório correspondente a uma linha.
; Sem parametros.
; REQUISITOS: Função aleatório
; OBS: O valor é devolvido na forma LL00 (octeto mais significativo), onde LL é o valor aleatório.		  
linha_aleat:	PUSH R1
				PUSH R2
				CALL aleatorio
				MOV R1, M[NumI]; R1 <- valor aleatorio gerado
				MOV R2, LIMITES_ALEAT
				DIV R1, R2 ;limita-se o valor aleatorio entre 0 e 19
				INC R2 ; de forma a evitar que o valor aleatorio seja 0
	; Assim o valor aleatorio fica compreendido entre 1 e 20
				SHL R2, 8 ;prepara o argumento colocando o valor aleatório no octeto mais significativo
				MOV M[SP+4], R2
				POP R2
				POP R1
				RET

; ROTINAS DO JOGO
; RESUMO: Inicializa o cenário e coloca o pássaro na posição inicial.
; Sem parametros
Inicializar: PUSH R1
			 PUSH R2
			 PUSH R3
			 PUSH R7
			 MOV R2, R0 ; R2 e R3 contém as coordenadas onde irão ser colocados os caracteres que correspondem ao cenário
			 MOV R3, ULTIMA_LINHA
			 MOV R1, N_COLUNAS
			ini_e: MOV R7, R2 ;escreve o cenario do jogo
				   PUSH TXT_PAREDE  ;Escrita na primeira linha
				   CALL EscCar
				   MOV R7, R3
				   PUSH TXT_PAREDE   ;Escrita na ultima linha
				   CALL EscCar
				   INC R2
				   INC R3 ;incrementa a coluna da ultima linha
				   DEC R1
				   BR.NZ ini_e
				   
			
			MOV R6, POS_PASSARO_INIT 	   
			CALL PutPassaro ;Colocação inicial do pássaro na posição pre-definida
			POP R7
			POP R3
			POP R2
			POP R1
			RET

; RESUMO: Coloca o passáro na posição enviada por argumento.
; PARAMETROS: Coordenadas na forma (LLCC) correspondentes à posição do pássaro
PutPassaro:			PUSH R2
					PUSH R7
					MOV R7, R6 ;linha 20 coluna 14
					PUSH StrPassaro
					CALL EscString
					POP R7
					POP R2
					RET

aumentanivel:	DSI ;Necessário porque poderá influenciar a execução correta dos obstáculos
				PUSH R1
				MOV R1, NIVEL_MAX
				CMP M[NIVEL], R1 ;impede o incremento do nivel se este já for o máximo (NIVEL_MAX)
				BR.Z ign_an
				DEC M[NIVEL]
				CALL acendeleds
		ign_an:	MOV M[Cont_I1], R0
				POP R1
				ENI
				RET
				
diminuinivel:	DSI
				PUSH R1
				MOV R1, NIVEL_MIN
				CMP M[NIVEL], R1 ;impede o decremento do nivel se este já for o mínimo (NIVEL_MIN)
				BR.Z ign_dn
				INC M[NIVEL]
				CALL acendeleds
		ign_dn:	MOV M[Cont_I2], R0
				POP R1
				ENI
				RET
				
; RESUMO: Inicia uma nova instância do jogo
; Sem parametros.

NovoJogo:  	MOV R1, M[NIVEL]
			CMP M[Cont_Obst], R1 
			CALL.Z acao_obst
			MOV R1, PASSARO_ACL_INIT
			CMP M[Cont_Pass], R1 
			CALL.Z descepassaro ;Desce o pássaro comparando o contador com o valor establecido
			
			MOV R1, 1
		lp: CMP M[Cont_I1], R1
			CALL.Z aumentanivel ; Se for primido o I1, aumenta o nivel (decrementa o valor M[NIVEL])
			CMP M[Cont_I2], R1
			CALL.Z diminuinivel ; Se for primido o I2, diminui o nivel (incrementa o valor M[NIVEL])
		
			CMP M[Cont_I0], R0	
			CALL.NZ sobepassaro
			CMP M[Cont_Timer], R0
			BR.Z lp
			CALL RContador ;reinicia as definições do contador
			CMP M[GRAVIDADE], R0 ;se a gravidade estiver desativada
			BR.Z ign_gravidade
			INC M[Cont_Pass]
ign_gravidade:  MOV R1, 1 ; Ativa a gravidade quando o passaro nao estiver a subir
			MOV M[GRAVIDADE], R1
			INC M[Cont_Obst]
			MOV M[Cont_Timer], R0
			JMP NovoJogo
		   
; RESUMO: Efetua o movimento ascendente do pássaro.
; Sem parametros.		   
				  
sobepassaro:	DSI
				PUSH R1
				PUSH R7
				MOV M[GRAVIDADE], R0 ;desativa a gravidade enquanto o passaro efetuar o movimento ascendente
				CMP R6, LIMITE_PASSARO_TOPO ; se nao atingir o topo do ecra
				BR.Z sobefim
				MOV R7, R6
				CALL ApagaPassaroAtual ;apaga a posicao onde o passaro se encontra
				SUB R6, PROXIMA_LINHA
				CALL PutPassaro
sobefim:		MOV M[Cont_I0], R0
				MOV M[Velocidade], R0
				MOV M[Pos_Fixa], R0
				POP R7
				POP R1
				ENI
				RET

; RESUMO: Efetua o movimento descendente do pássaro.
; Sem parametros.

descepassaro:	PUSH R1
				PUSH R2
				PUSH R7
				PUSH R3	
				PUSH R4				
				CMP R6, LIMITE_PASSARO_FUNDO ; nao efetua a descida caso o passaro se encontre na ultima linha
				JMP.Z fundo
				MOV R7, R6
				CALL ApagaPassaroAtual ;apaga a posicao onde o passaro se encontra
				
				MOV R1, M[Velocidade]
				MOV R2, ACEL
				MOV R3, 10
				DIV R2, R3 ;acel/10
				ADD M[Velocidade], R2
				MOV R3, 10
				MOV R1, M[Velocidade]
				DIV R1, R3 ;v/10
				ADD M[Pos_Fixa], R1
				
				
				AND R1, FF00h ;apenas são necessárias as linhas
				ADD R6, R1 ; Adiciona à posição real a posição em virgula fixa

				ADD R6, PROXIMA_LINHA
				
				
				CALL PutPassaro
fundo:			MOV M[Cont_Pass], R0
				POP R4
				POP R3
				POP R2
				POP R1
				POP R7
				RET

; RESUMO: Apaga uma determinada coluna.
; PARAMETROS: Coordenada no formato (LLCC) da coluna a apagar
ApagaColuna:PUSH R1
			PUSH R2
			PUSH R3
			PUSH R7
			
			MOV R1, M[SP+6] ; Recebe um parametro cujo o segundo octeto corresponde à coluna que se deseja eliminar
			INC R1
			
			MOV R7, R1 

			MOV R3, N_LINHAS ;Coloca o numero de linhas em R3 no octeto mais significativo
			SUB R3, LINHAS_CENARIO ; Compensação, porque se existem X linhas, é necessário apagar todas exceto a primeira e a ultima
			SHL R3, 8
			ADD R3, R1
				
			ap_c: 	ADD R7, PROXIMA_LINHA  ; incrementa o numero da linha
					PUSH ' '
					CALL EscCarNI
					CMP R7, R3 
			BR.NZ ap_c
			

			POP R7
			POP R3
			POP R2
			POP R1
			RETN 1	

; RESUMO: Coloca um obstáculo de acordo com as suas coordenadas
; PARAMETROS: Coordenadas no formato (LLCC) onde CC corresponde à coluna onde irá ser colocado o obstáculo e LL corresponde à primeira linha da zona de passagem
putObst:	DSI
			PUSH R1
			PUSH R2
			PUSH R3
			PUSH R7
			
			MOV R1, M[SP+6]
			
			MOV R2, R0
			
			MOV R3, R1
			MVBH R7, PROXIMA_LINHA  
			MVBL R7, R1 ; R7 <- 01CC
			;R1 <- 01xx
			CMP R7, R1 ;testa primeiro a condição antes de entrar em ciclo
			BR.NZ l ;se a linha for a primeira não é necessário entrar no ciclo
			BR ign_1parte
				
				
				l: PUSH TXT_OBST
					CALL EscCarNI
					ADD R7, PROXIMA_LINHA ; incrementa o numero da linha
					CMP R7, R1
				BR.NZ l
	ign_1parte:MOV R3, COMP_FIXO_OBST
				SHL R3, 8
				ADD R7, R3 ;R7 <- ultrapassa o numero fixo da zona de passagem
				
				MOV R3, N_LINHAS
				SHL R3, 8
				MVBL R3, R1
				SUB R3, PROXIMA_LINHA 
				CMP R7,R3 ; testa a condição para verificar se é necessário entrar em ciclo para escrever os restantes obstáculos até ao fim da coluna
				BR.NZ l2
				BR ign_2parte ;Se a zona de passagem termina no fim da coluna então não é necessário escrever caracteres
				
				l2: PUSH TXT_OBST
					CALL EscCarNI
					ADD R7, PROXIMA_LINHA ; incrementa o numero da linha
					CMP R7,R3
				BR.NZ l2
			
ign_2parte: POP R7
			POP R3
			POP R2
			POP R1
			ENI
			RETN 1

; RESUMO: Desloca os obstáculos uma coluna para a esquerda.
; DETALHADO: Decrementa uma unidade em cada entrada não nula da tabela obstáculos. Não efetua qualquer escrita no ecrã.
; Sem parametros		
movobst:	DSI
			PUSH R1
			PUSH R2
			PUSH R3
			PUSH R4
			MOV R1, Pos_Obst ; R1 <- endereço da tabela
			MOV R2, R0
			MOV R3, Pos_Obst
			ADD R3, DIM_TABS
			MOV R4, 1
			c_mo: 	CMP R0, M[R1] ;o elemento da tabela == 0?
					BR.Z ign_o ; se sim ignora
					MVBL R2, M[R1]
					CMP R2, R4
					BR.Z dec_o
					
					DEC M[R1] ;decrementa a coluna
					INC M[DST_COLUNAS] ; incrementa a distancia percorrida
					BR ign_o
					
			dec_o:	MOV M[R1], R0 ; se a coluna for zero entao o valor e zero
					
			ign_o:	INC R1
					CMP R1, R3 ; enquanto o n de colunas nao for zero
			BR.NZ c_mo
			
			POP R4
			POP R3
			POP R2
			POP R1	
			ENI
			RET


; RESUMO: Escreve os obstáculos existentes na tabela de obstáculos.
; DETALHADO: Percorre todos os elementos da tabela e escreve, de acordo com as coordenadas o respetivo obstáculo.
; OBS: Utiliza a rotina putObst para colocar cada obstaculo na respetiva coluna.
; Sem parametros
		
escreve_obst:	DSI
				PUSH R1

				PUSH R2
				PUSH R3
				PUSH R4
				PUSH R5

				MOV R1, Pos_Obst
				MOV R3, R6
				INC R3
				MOV R4, Pos_Obst
				ADD R4, DIM_TABS
				MOV R5, R0
				
				
				c_go: MOV R2, M[R1] ; R2 <- Objeto da tabela
					  CMP R2, R0 ; se o elemento for 0 significa que nao existe obstaculo
					  BR.NZ escreve
					  PUSH R0 ;se o elemento for 0 é necessário apagar a primeira coluna, uma vez que não será colocado nenhum obstáculo na coluna anterior
					  CALL ApagaColuna
					  
					  BR ign_ob
			    escreve: CALL PutPassaro ; como o obstáculo encontra-se na coluna do pássaro e esta foi anteriormente apagada é necessário voltar a colocá-lo.
				
				
					  MVBL R5, R2 ; formato 00CC de forma a apagar a coluna
					  CMP R5, COL_PASSARO ; se o obstaculo estiver na mesma coluna do passaro
					  CALL.Z ultrapassou ;irá verificar se o passaro se encontra na zona de passagem
					  
					  PUSH R5
					  CALL ApagaColuna
					  PUSH R2 ; escreve a coluna dos obstaculos
					  CALL putObst
				ign_ob: INC R1
					  CMP R1, R4 
				BR.NZ c_go

				POP R5
				POP R4
				POP R3
				POP R2
				POP R1
				ENI
				RET

; RESUMO: Gera objetos aleatorios, guardando-os na tabela Pos_Obst
; Sem parametros
; OBS: É utilizada a rotina linha_aleat para gerar uma linha pseudo-aleatória.

gera_obst:		PUSH R1
				PUSH R2
				PUSH R3
				MOV R1, Pos_Obst
				PUSH R0
				CALL linha_aleat
				POP R2 ;valor aleatório da linha
				MVBH R3, R2
				MVBL R3, COL_OBST_INIT ; a coluna do obstáculo gerado será sempre a inicial
				ADD R1, M[I_POS]
				MOV M[R1], R3 ;guarda o novo elemento na posição livre
				INC M[I_POS] ; como adicionou incrementa o indice da tabela
				
				MOV R1, DST_OBST
				MOV M[Contador_Cols], R1
				
				POP R3
				POP R2
				POP R1
				RET

; RESUMO: Rotina que interliga o movimento dos obstáculos com a escrita 			
; Sem parametros
;				
acao_obst:		DSI
				PUSH R1
				PUSH R2
				PUSH R3
				PUSH R4
				PUSH R5
				MOV R5, DST_OBST

				CMP M[Contador_Cols], R0
				CALL.Z gera_obst ; é gerado um novo obstáculo que ficará guardado na tabela

		
		nao_add:DEC M[Contador_Cols]
				
				CALL escreve_obst ;Escreve os obstáculos presentes na tabela Pos_Obst
				CALL movobst ;Decrementa as colunas dos obstaculos presentes na tabela Pos_Obst

				MOV R1, DIM_TABS ; se o indice I_POS chegar à ultima posição, coloca-o a zero de forma a voltar à primeira posição
				CMP M[I_POS], R1
				BR.NZ sair_ao
				MOV M[I_POS], R0

		sair_ao:MOV M[Cont_Obst], R0
				POP R5
				POP R4
				POP R3
				POP R2
				POP R1
				ENI
				RET
	
; RESUMO: Verifica se o passaro ultrapassou o obstaculo
; OBS: Sub-rotina. Serve-se do valor de R2, uma vez que pretence à rotina escreve_obst
; Apenas pode ser chamada dentro da rotina escreve_obst
ultrapassou:	PUSH R1
				PUSH R2
				PUSH R3
				PUSH R4
				
				MOV R4, R6 ;R4<- posição do passaro

				MOV R1, R2 ; R1 <- elemento da tabela
				MOV R2, R1 ; R2 <- ultimo elemento da zona de passagem
				
				MOV R3, COMP_FIXO_OBST
				
				SHL R3, 8
				ADD R2, R3 ; R2<- Ultima linha da zona de passagem
				
		c_ult:  CMP R1, R4 ; o passaro encontra-se na zona de passagem?
				BR.Z passou
				ADD R1, PROXIMA_LINHA
				CMP R1, R2
				BR.NZ c_ult
				JMP gameover
				
		passou:	INC M[NOBST_Ult];Incrementa n de obstaculos ultrapassados	
				CALL Mostra_Obst_Ultrapassados
				
		fim_ult: POP R4
				POP R3
				POP R2
				POP R1
				RET

; RESUMO: Apresenta o nível do jogo nos 16 leds presentes na placa do processador.
; Sem parametros
;				
acendeleds:	PUSH R1
			PUSH R2
			PUSH R3
			MOV R1, M[NIVEL]
			MOV R2, NIVEL_DIFICIL
			CMP R1, R2
			BR.Z nivel1
			MOV R2, NIVEL_MEDIO
			CMP R1, R2
			BR.Z nivel2
			MOV R2, NIVEL_FACIL
			CMP R1, R2
			BR.Z nivel3

	nivel1: MOV R3, LED_DIFICIL
			BR fim_leds
	nivel2: MOV R3, LED_MEDIO
			BR fim_leds
	nivel3: MOV R3, LED_FACIL
			
	fim_leds:MOV M[LED_ADD], R3 ;escreve o nivel utilizando o esquema de leds
			POP R3
			POP R2
			POP R1
			RET

; RESUMO: Apresenta o número de obstáculos ultrapassados nos displays de 7 segmentos presentes na placa do processador.
; Sem parametros.
; OBS: Serve-se do valor de M[NOBST_Ult] que contém o número de obstáculos ultrapassados.
				
Mostra_Obst_Ultrapassados:PUSH    R1
                PUSH    R2
                PUSH    R3
                MOV 	R2, M[NOBST_Ult]
				MOV	R1, 10			
				DIV	R2, R1 ; resto da divisão por 10
				MOV	M[DISPLAY1], R1 ; Coloca o primeiro numero no display da direita
				MOV	R1, 10
				DIV	R2, R1
				MOV	M[DISPLAY2], R1
				MOV	R1, 10
				DIV	R2, R1
				MOV	M[DISPLAY3], R1
				MOV	M[DISPLAY4], R2
                POP     R3
                POP     R2
                POP     R1
                RET

; RESUMO: Atualiza o LCD, escrevendo a distância total percorrida, dada pelo número de colunas
; Sem parametro
; OBS: A implementação não foi bem executada.
; Ao invés de aparecer apenas o número, aparece o algarismo menos significativo, seguido de um 'D', seguido do resto do número
escreveLCD:		PUSH R1
				PUSH R2
				MOV R1, Str_Dist
				MOV R2, Pos_Esc_LCD_1
				INC R2
				PUSH R1
				PUSH R2
				CALL EscStringLCD
				MOV R1, M[DST_COLUNAS]
				MOV R2, Pos_Esc_LCD_2
				PUSH R1
				PUSH R2
				CALL EscStringNumLCD
				POP R2
				POP R1
				RET
				
; RESUMO: Escreve no LCD o número correspondente à distância percorrida
; 
EscStringNumLCD:PUSH R1
				PUSH R2
				PUSH R3
				MOV R1, M[SP+6] ; R1<-- DST_COLUNAS
				MOV R2, M[SP+5] ; R2<-- Posição do LCD onde vai escrever
				ADD R2, 4 ; como vamos escrever do algarismo menos significativo para o mais significativo, temos de começar a escrever pelo fim
CicloNumLCD:	CMP R2, M[SP+5]
				BR.Z FimNumLCD
				MOV R3, 10
				DIV R1, R3
				OR R3, CONVERSOR_ASCII
				MOV M[LCD], R3
				MOV M[LCD_CONTROLO], R2
				DEC R2
				BR CicloNumLCD
FimNumLCD:		POP R3
				POP R2
				POP R1
				RETN 2		
						
; RESUMO: Escreve no LCD uma string	
;			
EscStringLCD:   PUSH R1
				PUSH R2
				PUSH R3
				PUSH R4
				MOV R1, M[SP+7]
				MOV R2, M[SP+6]
				MOV R3, FIM_TEXTO
CicloLCD:		CMP M[R1], R3 ; a string terminou?
				BR.Z FimEscStringLCD
				MOV R4, M[R1]
				MOV M[LCD], R4
				MOV M[LCD_CONTROLO], R2				
				INC R1
				INC R2
				BR CicloLCD
FimEscStringLCD:POP R4
				POP R3
				POP R2
				POP R1
				RETN 2
				
; RESUMO: Mostra as instruções de final de jogo.
; Sem parametros.
; OBS: É executada quando o pássaro colide com um obstáculo.				
				
gameover:	MOV R7, FFFFh
			CALL ApagaEcra
			MOV M[XY_SCREEN], R7
		MOV R7, POS_INSTR
		PUSH StrGameOver
		CALL EscString
		MOV R7, POS_STATS
		
		PUSH StrGO_Pts
		CALL EscString
		
		;Escreve no ecrã o numero de obstáculos ultrapassados
		MOV 	R2, M[NOBST_Ult]
		
		MOV	R1, 10			
		DIV	R2, R1
		PUSH R1 ;Guarda na pilha os diversos valores
		
		MOV	R1, 10			
		DIV	R2, R1
		PUSH R1
		
		MOV	R1, 10			
		DIV	R2, R1
		PUSH R1
		
		MOV	R1, 10			
		DIV	R2, R1
		PUSH R1
		CALL EscNum ;Escreve os numeros por ordem da pilha
		CALL EscNum
		CALL EscNum
		CALL EscNum
		
		PUSH StrGO_Pts2
		CALL EscString
		ENI ;Porque esta rotina poderá ser chamada dentro de outra cujas interrupções estejam desativadas.
infty_go: CMP M[Cont_I0], R0
	   BR.Z infty_go
	   MOV M[Cont_I0], R0
	   
		; reinicia as variáveis para os seus valores iniciais
		MOV M[Cont_I0], R0
		MOV M[Cont_I1], R0
		MOV M[Cont_I2], R0
		MOV M[Cont_Obst], R0
		MOV M[Cont_Pass], R0
		MOV M[Cont_Timer], R0
			MOV R1, DIM_TABS
			MOV R2, Pos_Obst
			ADD R2, R1
			c_limpa:	MOV M[R2], R0 ; limpa as posições da tabela
						DEC R2
						CMP R2, Pos_Obst
			BR.NZ c_limpa

		MOV M[NumI], R0
		MOV M[DST_COLUNAS], R0
		MOV R1, COL_OBST_INIT
		MOV M[OBST_C], R1
		MOV R1, NIVEL_INIT
		MOV M[NIVEL], R1
		MOV M[I_POS], R0
		MOV M[Contador_Cols], R0
		MOV M[NOBST_Ult], R0
		CALL Mostra_Obst_Ultrapassados
	   
	   JMP init
			
; RESUMO: Apresenta as mensagens iniciais.
; Sem parametros	
Inicio:	MOV R7, POS_INSTR
		PUSH StrPrep
		CALL EscString
		MOV R7, POS_INSTR
		ADD R7, PROXIMA_LINHA
		ADD R7, PROXIMA_LINHA ;Duas linhas depois
		PUSH StrInst
		CALL EscString

infty: INC M[NumI] ;incrementa o valor fixo que dara origem ao valor aleatorio
	   CMP M[Cont_I1], R0
	   BR.Z infty
	   CALL ApagaEcra
	   CALL Inicializar
	   MOV M[Cont_I1], R0
	   CALL NovoJogo ;inicia-se uma nova instância do jogo
       BR infty