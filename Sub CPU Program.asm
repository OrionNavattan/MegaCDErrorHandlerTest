
		opt l.					; . is the local label symbol
		opt ae-					; automatic evens are disabled by default
		opt ws+					; allow statements to contain white-spaces
		opt w+					; print warnings
		opt m+					; do not expand macros - if enabled, this can break assembling

		TestType: equ 0	; 0 = no error, 1 = address error, 2 = illegal instruction

		include "Debugger Macros and Common Defs.asm"
		include "Mega CD Sub CPU.asm"
		include "Common Macros.asm"


		org	sp_start

SubPrgHeader:	index.l *
		dc.b	'MAIN       ',0				; module name (always MAIN), flag (always 0)
		dc.w	0,0							; version, type
		dc.l	0							; pointer to next module
		dc.l	0			; size of program
		ptr		UserCallTable	; pointer to usercall table
		dc.l	0							; workram size

UserCallTable:	index *
		ptr	Init		; Call 0; initialization
		ptr	Main		; Call 1; main
		ptr	VBlank		; Call 2; user VBlank
		dc.w	0		; Call 3; unused

Init:
		lea ExceptionPointers(pc),a0 ; pointers to exception entry points
		lea _AddressError(pc),a1	; first error vector in jump table
		moveq	#9-1,d0			; 9 vectors total

	.vectorloop:
		addq.l	#2,a1		; skip over instruction word
		move.l	(a0)+,(a1)+	; set table entry to point to exception entry point
		dbf d0,.vectorloop	; repeat for all vectors

		move.l	#MainCPUError,(_Trap0).w	; vector for main CPU error
		rts

	ExceptionPointers:
		dc.l AddressError
		dc.l IllegalInstr
		dc.l ZeroDivide
		dc.l ChkInstr
		dc.l TrapvInstr
		dc.l PrivilegeViol
		dc.l Trace
		dc.l Line1010Emu
		dc.l Line1111Emu

Main:
		addq.w #4,sp	; throw away return address to BIOS code, as we will not be returning there

		moveq	#'R',d0
		move.b	d0,(mcd_subcom_0).w	; signal success

WaitLoop:
		cmpi.b	#$FF,(mcd_main_flag).w	; is main CPU OK?
		bne.s	.mainOK				; branch if it is
		trap #0

	.mainOK:
		cmp.b	(mcd_maincom_0).w,d0		; 	has main CPU acknowledged?
		bne.s	WaitLoop			; branch if not

		clr.b	(mcd_subcom_0).w

	if TestType=1
		move.w	1(a0),d0	; crash the CPU with a word operation at an odd address
	elseif 	TestType=2
		illegal
	endc

MainLoop:
		cmpi.b	#$FF,(mcd_main_flag).w	; is main CPU OK?
		bne.s	MainLoop				; branch if it is
		trap #0

VBlank:
		rts

		include "Mega CD Exception Handler (Sub CPU).asm"

	SPEnd:
		end
