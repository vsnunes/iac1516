Pos_Esc_LCD_1 EQU 1000000000000000b
Pos_Esc_LCD_2 EQU 1000000000001010b




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
				OR R3, 0030h
				;CALL EscNum
				MOV M[LCD], R3
				MOV M[LCD_CONTROLO], R2
				DEC R2
				BR CicloNumLCD
FimNumLCD:		POP R3
				POP R2
				POP R1
				RETN 2				
				
EscStringLCD:   PUSH R1
				PUSH R2
				PUSH R3
				PUSH R4
				MOV R1, M[SP+7]
				MOV R2, M[SP+6]
				MOV R3, FIM_TEXTO
CicloLCD:		CMP M[R1], R3
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