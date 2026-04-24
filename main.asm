x;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
IO_CONFIG:
			bis.b		#0xFF		,		&P3DIR		; Setting all ports as output
			bis.b		#0xFF		,		&P2DIR
			bis.b		#0xFF		,		&P1DIR
			;bis.b		#0xFF		,		&P4DIR

			; Setting up P1.3
			bic.b		#BIT3		,		&P1DIR		; Setting port 1.3 as input
			bis.b		#BIT3		,		&P1REN		; Enable Pull up/down resistor
			bic.b		#BIT3		,		&P1OUT		; Configure as pull down

			; Setting up P1.5
			bic.b		#BIT5		,		&P1DIR		; Setting port 1.5 as input
			bis.b		#BIT5		,		&P1REN		; Enable Pull up/down resistor
			bic.b		#BIT5		,		&P1OUT		; Configure as pull down

			; Setting up P1.7
			bic.b		#BIT7		,		&P1DIR		; Setting port 1.7 as input
			bis.b		#BIT7		,		&P1REN		; Enable Pull up/down resistor
			bic.b		#BIT7		,		&P1OUT		; Configure as pull down

			clr			&P1OUT
			clr			&P3OUT
			;clr			&P4OUT							; Clear all output bits

			bic.b		#LOCKLPM5	,		&PM5CTL0	; Enabling Digital I/O

			bis.b		#BIT3		,		&P3OUT		; Setting 3.3 as 1
			clr			&P2OUT							; Clearing the display
			;bis.b		#0x3F		,		&P2OUT		; Segments ON to display 0

			; Initializing display values
			mov			#0x00		,		R7
			mov			#0x00		,		R8
			mov			#0x00		,		R11
			mov			#0x00		,		R12
			mov			#0x8002		,		R13
			mov			#0x0000		,		0(R13)
			mov			#0x0000		,		2(R13)

			mov.w		#0x0204		,		&TA0CTL		; SMCLK, /1, Halt, Clear TA0R(Count)
			mov.w		#4106		,		&TA0CCR0	; Clock count max value
			mov.w		#0x0000		,		&TA0R		; Reset clock count to zero


ADC_CONFIG: bis 		#0xAA80		,		&ADC12CTL0	; Configuring the Control Registers
			bis 		#0x6204		,		&ADC12CTL1
			clr			&ADC12CTL2
			bis 		#17			,		&ADC12CTL3	; Selecting Memory Register 17
			bis 		#10			,		&ADC12MCTL17; Read A10 on Mem 17


INT_CONFIG: bis			#BIT1		,		&ADC12IER1	; Enable MEM17 interrupt
			nop
			eint
			nop
			bis			#0x0013		,		&ADC12CTL0 	; Turn it on


MAIN_LOOP:	bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			jmp 		MAIN_LOOP
			nop
			nop

ISR_ADC12:	bic			#0x0013		,		&ADC12CTL0 	; Turn off the ADC
			bit			#BIT1		,		&ADC12IFGR1
			jz			ISR_END
			bit			#BIT7		,		&P1IN 		; Checking if S1 is pressed
			jz			BUTTON1
MULTIPLY:	mov			2(R13)		,		&MPY
			mov			0(R13)		,		&OP2
			mov			&RES0		,		R4			; Storing result
			jmp			SEP_PROD

BUTTON1:	bit			#BIT5		,		&P1IN 		; Checking if S3 is pressed
			jnz			READ_VALUE
BUTTON2:	bit     	#BIT3		,		&P1IN		; Checking if S3 is pressed
			jz			DISPLAY_COUNT
READ_VALUE:	mov			&ADC12MEM17	, 		R10
			bit			#BIT3		,		&P1IN
			jnz			SEP_DIG2

SEP_DIG1:	mov			R10			,		2(R13)		; Storing for multiplication
			mov			R10			,		R11			; Serperating the Two digits
			mov			R10			,		R12
			and			#0x000F		,		R11			; Right Digit
			and 		#0x00F0		,		R12			; Left Digit
			rra			R12								; Getting the digit as the LSB
			rra			R12								; By rotating right 4 times
			rra			R12
			rra			R12
			jmp			DISPLAY_COUNT


SEP_DIG2:	mov			R10			,		0(R13)		; Storing for multiplication
			mov			R10			,		R7			; Serperating the Two digits
			mov			R10			,		R8
			and			#0x000F		,		R7			; Right Digit
			and 		#0x00F0		,		R8			; Left Digit
			rra			R8								; Getting the digit as the LSB
			rra			R8								; By rotating right 4 times
			rra			R8
			rra			R8

DISPLAY_COUNT:	mov			#0x16		,		R15

DISPLAY:
			;-------------------- Displaying First Number --------------------
			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT0		,		&P3OUT
			mov			R12			,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying


			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT1		,		&P3OUT
			mov			R11			,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying

			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			;-------------------- Displaying Second Number -------------------
			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT2		,		&P3OUT
			mov			R8			,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying


			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT3		,		&P3OUT
			mov			R7			,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying

			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt


			dec			R15
			jnz			DISPLAY
			jmp         ISR_END

SEP_PROD:	mov			R4			,		4(R13)
			mov			R4			,		6(R13)
			mov			R4			,		8(R13)
			mov			R4			,		10(R13)

			and			#0x000F		,		4(R13)		; First Digit
			and			#0x00F0		,		6(R13)		; Second Digit
			and 		#0x0F00		,		8(R13)		; Third Digit
			and			#0xF000		,		10(R13)		; Fourth Digit

			;--------- Doing Rotations --------

			mov			#0x04		,		R14
loop1:		rra			6(R13)
			dec			R14
			jnz			loop1

			mov			#0x08		,		R14
loop2:		rra			8(R13)
			dec			R14
			jnz			loop2

			mov			#0xB		,		R14
			clrc
			rrc			10(R13)
loop3:		rra			10(R13)
			dec			R14
			jnz			loop3


			mov			#0x08		,		R14
DISPLAY_PROD:
			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT0		,		&P3OUT
			mov			10(R13)		,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying


			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT1		,		&P3OUT
			mov			8(R13)			,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying

			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT2		,		&P3OUT
			mov			6(R13)		,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying


			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt

			clr 		&P3OUT
			clr			&P2OUT							; Clearing the display
			bis.b		#BIT3		,		&P3OUT
			mov			4(R13)		,		R5
			call		#setDisplay						; Setting Display
			bis.b		R6			,		&P2OUT		; Displaying

			bis			#BIT4		,		&TA0CTL		; Start the Clock
			call		#delay							; Delay
			bic			#BIT4		,		&TA0CTL		; Stop the Clock
			bic			#0xFFFF		,		&TA0R		; Reset the count to zero
			bic			#BIT0		,		&TA0CCTL0	; Reset interrupt


			dec			R14
			jnz			DISPLAY_PROD

ISR_END:
			bic 		#0x02E		,		&ADC12IV
			bis			#0x0013		,		&ADC12CTL0 	; Turn it on
			reti

;------------------------------------------------------------------------------------------------------------
; Subroutines
;------------------------------------------------------------------------------------------------------------

delay:
main:		bit			#BIT0		,		&TA0CCTL0	; Testing for an interrupt by comparing the first bit
			jz			main
			ret




setDisplay:
			cmp.b		#0x00		,		R5			; Checking if 0
			jnz			skip0							; Skip if not 0
			mov.b		#0x3F		,		R6			; Segments ON to display 0
			jmp			return

skip0:		cmp.b		#0x01		,		R5			; Checking if 1
			jnz			skip1							; Skip if not 1
			mov.b		#0x06		,		R6			; Segments ON to display 1
			jmp			return

skip1:		cmp.b		#0x02		,		R5			; Checking if 2
			jnz			skip2							; Skip if not 2
			mov.b		#0x5B		,		R6			; Segments ON to display 2
			jmp			return

skip2:		cmp.b		#0x03		,		R5			; Checking if 3
			jnz			skip3							; Skip if not 3
			mov.b		#0x4F		,		R6			; Segments ON to display 3
			jmp			return

skip3:		cmp.b		#0x04		,		R5			; Checking if 4
			jnz			skip4							; Skip if not 4
			mov.b		#0x66		,		R6			; Segments ON to display 4
			jmp			return

skip4:		cmp.b		#0x05		,		R5			; Checking if 5
			jnz			skip5							; Skip if not 5
			mov.b		#0x6D		,		R6			; Segments ON to display 5
			jmp			return

skip5:		cmp.b		#0x06		,		R5			; Checking if 6
			jnz			skip6							; Skip if not 6
			mov.b		#0x7D		,		R6			; Segments ON to display 6
			jmp			return

skip6:		cmp.b		#0x07		,		R5			; Checking if 7
			jnz			skip7							; Skip if not 7
			mov.b		#0x07		,		R6			; Segments ON to display 7
			jmp			return

skip7:		cmp.b		#0x08		,		R5			; Checking if 8
			jnz			skip8							; Skip if not 8
			mov.b		#0x7F		,		R6			; Segments ON to display 8
			jmp			return

skip8:		cmp.b		#0x09		,		R5			; Checking if 9
			jnz			skip9							; Skip if not 9
			mov.b		#0x6F		,		R6			; Segments ON to display 9
			jmp			return

skip9:		cmp.b		#0x0A		,		R5			; Checking if A
			jnz			skipA							; Skip if not A
			mov.b		#0x77		,		R6			; Segments ON to display A
			jmp			return

skipA:		cmp.b		#0x0B		,		R5			; Checking if B
			jnz			skipB							; Skip if not B
			mov.b		#0x7C		,		R6			; Segments ON to display B
			jmp			return

skipB:		cmp.b		#0x0C		,		R5			; Checking if C
			jnz			skipC							; Skip if not C
			mov.b		#0x39		,		R6			; Segments ON to display C
			jmp			return

skipC:		cmp.b		#0x0D		,		R5			; Checking if D
			jnz			skipD							; Skip if not D
			mov.b		#0x5E		,		R6			; Segments ON to display D
			jmp			return

skipD:		cmp.b		#0x0E		,		R5			; Checking if E
			jnz			skipE							; Skip if not E
			mov.b		#0x79		,		R6			; Segments ON to display E
			jmp			return

skipE:		cmp.b		#0x0F		,		R5			; Checking if F
			jnz			return							; Skip if not F
			mov.b		#0x71		,		R6			; Segments ON to display F
			jmp			return

return:		ret



;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
            .sect   ".int45"
            .short  ISR_ADC12
