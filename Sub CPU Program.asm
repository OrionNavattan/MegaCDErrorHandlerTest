
		opt l.					; . is the local label symbol
		opt ae-					; automatic evens are disabled by default
		opt ws+					; allow statements to contain white-spaces
		opt w+					; print warnings


		include "Debugger Macros and Common Defs.asm"
		include "Mega CD Sub CPU.asm"
		include "Common Macros.asm"
		include "Sub CPU Commands.asm"


		org	sp_start

SubPrgHeader:	index.l *

		dc.b	'MAIN       ',0				; module name (always MAIN), flag (always 0)
		dc.w	0,0							; version, type
		dc.l	0							; pointer to next module
		dc.l	0			; size of program
		ptr		UserCallTable	; pointer to usercall table
		dc.l	0							; workram size
; ===========================================================================

UserCallTable:	index *
		ptr	Init		; Call 0; initialization
		ptr	Main		; Call 1; main
		ptr	VBlank		; Call 2; user VBlank
		dc.w	0		; Call 3; unused
; ===========================================================================

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
; ===========================================================================

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
; ===========================================================================

Main:
		addq.w #4,sp	; throw away return address to BIOS code, as we will not be returning there
		moveq	#'R',d0
		move.b	d0,(mcd_subcom_0).w		; signal initialization success

	WaitReady:
		cmpi.b	#$FF,(mcd_main_flag).w	; is main CPU OK?
		bne.s	.mainOK				; branch if so
		trap #0
; ===========================================================================

	.mainOK:
		cmp.b	(mcd_maincom_0).w,d0		; has main CPU acknowledged?
		bne.s	WaitReady			; branch if not

		moveq	#0,d0
		move.b	d0,(mcd_subcom_0).w		; we are ready to accept commands once main CPU clears its com register

	.waitmainready:
		tst.b	(mcd_maincom_0).w	; is main CPU ready to send commands?
		bne.s	.waitmainready		; branch if not

MainLoop:
		cmpi.b	#$FF,(mcd_main_flag).w	; is main CPU OK?
		bne.s	.mainok				; branch if it is
		trap #0				; main CPU crash
; ===========================================================================

	.mainok:
		move.w	(mcd_maincom_0).w,d0	; get command ID from main CPU
		beq.s	MainLoop				; wait if not set
		cmp.w	(mcd_maincom_0).w,d0	; safeguard against spurious writes?
		bne.s	MainLoop
		cmpi.w	#sizeof_SubCPUCmd_Index/2,d0	; is it a valid command?
		bhi.s	.invalid				; branch if not

		add.w	d0,d0
		move.w	SubCPUCmd_Index-2(pc,d0.w),d0	; minus 2 since IDs start at 1
		jsr	SubCPUCmd_Index(pc,d0.w)		; run the command
		bra.s	MainLoop
; ===========================================================================

.invalid:
		bsr.s	CmdFinish
		bra.s	MainLoop
; ===========================================================================

CmdFinish:
		move.w	(mcd_maincom_0).w,(mcd_subcom_0).w	; acknowledge command

	.wait:
		cmpi.b	#$FF,(mcd_main_flag).w	; is main CPU OK?
		bne.s	.mainok				; branch if it is
		trap #0
; ===========================================================================

	.mainok:
		tst.w	(mcd_maincom_0).w			; is the main CPU ready?
		bne.s	.wait			; if not, wait
		tst.w	(mcd_maincom_0).w
		bne.s	.wait			; if not, wait

		clr.w	(mcd_subcom_0).w			; mark as ready for another command
		rts
; ===========================================================================

SubCPUCmd_Index:	index *,1

GenSubCmdIndex:	macro	name
		ptr \name
		endm

		SubCPUCommands	GenSubCmdIndex	; generate the index table for all commands

		arraysize	SubCPUCmd_Index
; ===========================================================================

TestAddrErr:
		move.w	(1).w,d0	; crash the CPU with a word operation at an odd address
		bra.s	CmdFinish
; ===========================================================================

TestIllegal:
		illegal		; trigger illegal instruction exception
		bra.s	CmdFinish
; ===========================================================================

VBlank:
		rts
; ===========================================================================

		include "Mega CD Exception Handler (Sub CPU).asm"

	SPEnd:
		end
