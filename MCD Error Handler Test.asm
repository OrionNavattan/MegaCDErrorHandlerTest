
		opt l.					; . is the local label symbol
		opt ae-					; automatic evens are disabled by default
		opt ws+					; allow statements to contain white-spaces
		opt w+					; print warnings

		MainCPU: equ 1 ; enable some debugging features for Main CPU only

		include "Debugger Macros and Common Defs.asm"
		include "Mega CD Main CPU (Mode 1).asm"
		include "Common Macros.asm"
		include "Sub CPU Commands.asm"
		include "Constants and RAM Addresses.asm"

ROM_Start:
Vectors:
		dc.l stack_pointer			; Initial stack pointer value
		dc.l EntryPoint					; Start of program
		dc.l BusError					; Bus error
		dc.l AddressError				; Address error
		dc.l IllegalInstr				; Illegal instruction
		dc.l ZeroDivide					; Division by zero
		dc.l ChkInstr					; CHK exception
		dc.l TrapvInstr					; TRAPV exception
		dc.l PrivilegeViol				; Privilege violation
		dc.l Trace					; TRACE exception
		dc.l Line1010Emu				; Line-A emulator
		dc.l Line1111Emu				; Line-F emulator
		dcb.l 2,ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Format error
		dc.l ErrorExcept				; Uninitialized interrupt
		dcb.l 8,ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Spurious exception
		dc.l ErrorExcept					; IRQ level 1
		dc.l ErrorExcept					; IRQ level 2
		dc.l ErrorExcept					; IRQ level 3
		dc.l ErrorExcept					; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorExcept					; IRQ level 5
		dc.l VBlank					; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorExcept					; IRQ level 7
		dc.l SubCPUError						; Trap 0
		dc.l SubCPUTimeout					; 	; Trap 1
		dcb.l 14,ErrorExcept				; TRAP #02..#15 exceptions
		dcb.l 16,ErrorExcept				; Unused (reserved)

Header:
		dc.b "SEGA GENESIS    "		; Hardware system ID (Console name)
		dc.b "ORION   2023.DEC"				; Copyright holder and release date
		dc.b "ORION'S MODE 1 ERROR HANDLER TEST               " ; Domestic name
		dc.b "ORION'S MODE 1 ERROR HANDLER TEST               " ; International name


		dc.b "FFFFFFFFFFFFFF"				; Serial/version number (Rev non-0)

Checksum: 	dc.w $0
		dc.b "JC              "				; I/O support
ROM_Start_Ptr:	dc.l ROM_Start					; Start address of ROM
ROM_End_Ptr:	dc.l ROM_End-1					; End address of ROM
		dc.l $FF0000					; Start address of RAM
		dc.l $FFFFFF					; End address of RAM

		dc.l $20202020					; dummy values (SRAM disabled)
		dc.l $20202020					; SRAM start
		dc.l $20202020					; SRAM end

		dc.b "                                                    " ; Notes (unused, anything can be put in this space, but it has to be 52 bytes.)
		dc.b "JUE             "				; Region (Country code)
EndOfHeader:
; ===========================================================================

		include "Mega CD Initialization.asm"	; EntryPoint

VBlank:
		bset #mcd_int_bit,(mcd_md_interrupt).l	; trigger VBlank on sub CPU
		rte
; ===========================================================================

SubCPUCmd:
		pushr.l	a0
		lea (mcd_subcom_0).l,a0
		move.w	d0,mcd_maincom_0-mcd_subcom_0(a0)	; send command ID to sub CPU

	.waitsub:
		cmpi.b	#$FF,mcd_sub_flag-mcd_subcom_0(a0)	; is sub CPU OK?
		bne.s	.subOK				; branch if it is
		trap #0

	.subok:
		tst.w	(a0)			; has the sub CPU processed the command?
		beq.s	.waitsub			; if not, wait
		cmp.w	(a0),d0		; is it the command we sent?
		bne.s	.waitsub	; if not, wait

		clr.w	mcd_maincom_0-mcd_subcom_0(a0)			; mark as ready to send commands again

	.waitsubdone:
		tst.w	(a0)			; is the sub CPU done processing the command?
		bne.s	.waitsubdone			; if not, wait
		popr.l	a0
		rts

; ===========================================================================

WaitSubCPU:
		moveq	#'R',d0		; flag for initialization success

	WaitLoop:
		cmpi.b	#$FF,mcd_sub_flag-mcd_mem_mode(a3)	; is sub CPU OK?
		bne.s	.subOK				; branch if so
		trap #0
; ===========================================================================

	.subOK:
		cmp.b	mcd_subcom_0-mcd_mem_mode(a3),d0		; is sub CPU done initializing?
		bne.s	WaitLoop				; branch if not

		move.b	d0,mcd_maincom_0-mcd_mem_mode(a3)	; acknowledge

	.waitack:
		tst.b	mcd_subcom_0-mcd_mem_mode(a3)	; is sub CPU ready?
		bne.s	.waitack						; branch if not

		clr.b	mcd_maincom_0-mcd_mem_mode(a3)	; we are ready to send commands
		; fall through into Main Menu
; ===========================================================================

		include "Main Menu.asm"
		include "FormatString Test.asm"

TestSymbols:
		incbin "FormatString Test Symbols.kos"

		include "KosM to PrgRAM.asm"
		include "Kosinski Decompression.asm"

SubCPU_Program:
		incbin "Sub CPU Program.kosm"
		even

		include "Mega CD Exception Handler (Main CPU).asm"

ROM_End:
		end
