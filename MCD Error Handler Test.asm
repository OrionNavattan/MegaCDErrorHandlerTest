
		opt l.					; . is the local label symbol
		opt ae-					; automatic evens are disabled by default
		opt ws+					; allow statements to contain white-spaces
		opt w+					; print warnings

		TestType: equ 3	; 0 = no error, 1 = address error, 2 = illegal instruction, 3 = string formatter test

		MainCPU: equ 1 ; enable some debugging features for Main CPU only

		include "Debugger Macros and Common Defs.asm"
		include "Mega CD Main CPU (Mode 1).asm"
		include "Common Macros.asm"


workram:		equ $FF0000

stack_pointer:		equ $FFFFFFFE
v_console_region:	equ $FFFFFFFE
v_bios_id:	equ $FFFFFFFF
sizeof_workram:	equ $10000
countof_color:		equ 16					; colors per palette line
countof_pal:		equ 4					; total palette lines
sizeof_pal:		equ countof_color*2			; total bytes in 1 palette line (32 bytes)
sizeof_pal_all:		equ sizeof_pal*countof_pal		; bytes in all palette lines (128 bytes)
vram_window:		equ $A000				; window nametable - unused
vram_fg:			equ $C000			; foreground nametable ($1000 bytes); extends until $CFFF
vram_bg:			equ $E000			; background nametable ($1000 bytes); extends until $EFFF
vram_sprites:			equ $F800			; sprite attribute table ($280 bytes)
vram_hscroll:			equ $FC00			; horizontal scroll table ($380 bytes); extends until $FF7F

cGreen:		equ $0E0					; color green
cRed:		equ $00E					; color red
cBlue:		equ $E00					; color blue

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
		dc.b "ORIONNA 2023.DEC"				; Copyright holder and release date
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

		include "Mega CD Initialization.asm"	; EntryPoint

WaitSubCPU:
		moveq	#'R',d0
	WaitLoop:
		cmpi.b	#$FF,mcd_sub_flag-mcd_mem_mode(a3)	; is sub CPU OK?
		bne.s	.subOK				; branch if it is
		trap #0

	.subOK:
		cmp.b	mcd_subcom_0-mcd_mem_mode(a3),d0		; is sub CPU done initializing?
		bne.s	WaitLoop				; branch if not

		move.b	d0,mcd_maincom_0-mcd_mem_mode(a3)	; acknowledge

	.waitack:
		tst.b	mcd_subcom_0-mcd_mem_mode(a3)	; is sub CPU ready?
		bne.s	.waitack						; branch if not

		clr.b	mcd_maincom_0-mcd_mem_mode(a3)


	if TestType=1
		move.w	1(a0),d0	; crash the CPU with a word operation at an odd address
	elseif 	TestType=2
		illegal				; test illegal instruction vector
	endc

	if TestType<3
	    ; If we're not running a console test
		move.w	#cGreen,(vdp_data_port).l	; signal success

	else
		; Prepare to run a console program
		lea	-sizeof_Console_RAM(sp),sp
		lea (sp),a3
		bsr.w	ErrorHandler_SetupVDP
		bsr.w	Error_InitConsole
	endc

	if TestType=3
		bsr.s FormatStringTest
	endc

MainLoop:
		cmpi.b	#$FF,mcd_sub_flag-mcd_mem_mode(a3)	; is sub CPU OK?
		bne.s	MainLoop				; branch if it is
		trap #0

	if TestType=3
		include "FormatString Test.asm"

TestSymbols:
		incbin "FormatString Test Symbols.kos"
	endc

VBlank:

		bset #mcd_int_bit,(mcd_md_interrupt).l	; trigger VBlank on sub CPU
		rte

		include "KosM to PrgRAM.asm"
		include "Kosinski Decompression.asm"

SubCPU_Program:
		incbin "Sub CPU Program.kosm"
		even

		include "Mega CD Exception Handler (Main CPU).asm"

ROM_End:
		end
