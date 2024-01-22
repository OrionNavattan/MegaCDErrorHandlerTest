MainMenu:
		disable_ints
		lea	-sizeof_Console_RAM(sp),sp
		lea (sp),a3
		bsr.w	ErrorHandler_SetupVDP
		bsr.w	Error_InitConsole

MainMenu_Return:
		Console.WriteLine	'%<pal1>MEGA CD ERROR HANDLER TEST ROM'	; title and instructions are static colors
		Console.WriteLine	'%<pal0>Use Up/Down to select a test;'
		Console.WriteLine	'press Start to run.'
		bsr.w	Console_StartNewLine		; skip a line

		pushr.l	d0/d1
		bsr.w	Console_GetPosAsXY
		movem.w	d0/d1,(v_options_coords).w	; save start coordinates for redrawing later
		popr.l	d0/d1

		moveq	#id_FirstSelection,d5	; initial menu selection
		moveq	#id_FirstSelection,d2
		move.b	d2,(v_menu_selection).w	; save in RAM
		bra.s	InitialDraw
; ===========================================================================

MainMenuLoop:
		cmpi.b	#$FF,(mcd_sub_flag).l	; is sub CPU OK?
		bne.s	.subOK			; branch if so
		trap #0

	.subok:
		enable_ints
		bsr.w	VSync	; wait for VBlank
		lea (v_joypad_hold).w,a0	; read the joypad
		lea (port_1_data).l,a1
		bsr.w	ReadJoypad

		moveq	#0,d2
		move.b	(v_menu_selection).w,d2	; d2 = current menu selection
		andi.b	#btnStart|btnUp|btnDn,d1	; d1 still contains pressed joypad buttons
		beq.s	MainMenuLoop			; branch if up, down, or start weren't pressed

		bclr	#bitStart,d1
		bne.w	StartTest		; branch if start is pressed
	;	bne.s	MainMenuLoop
		cmpi.b	#btnUp|btnDn,d1		; this can happen with worn joypads
		beq.s	MainMenuLoop		; branch if it did
		bclr	#bitUp,d1		; is up pressed?
		bne.s	.up				; branch if so
		; if we're here, down is pressed

	;.down:
		cmpi.b	#id_LastSelection,d2
		beq.s	.alreadymax			; branch if we're already on the highest selection
		addq.w	#2,d2		; move selection down
		bra.s	RedrawMenu
; ===========================================================================

	.up:
		tst.b	d2
		beq.s	.already0	; branch if selection is already 0
		subq.w	#2,d2		; move selection up
		bra.s	RedrawMenu
; ===========================================================================

	.already0:
		moveq	#id_LastSelection,d2	; wrap to last option
		bra.s	RedrawMenu
; ===========================================================================

	.alreadymax:
		moveq	#id_FirstSelection,d2	; wrap to first option

RedrawMenu:
		move.b	d2,(v_menu_selection).w	; save selection for next time
		movem.w	(v_options_coords).w,d0/d1
		bsr.w	Console_SetPosAsXY	; set start coordinates
		moveq	#id_FirstSelection,d5		; index to data for first option
		disable_ints

InitialDraw:
		moveq	#(sizeof_MenuOps/2)-1,d3	; redraw all options

	.redrawloop:
		move.w	#tile_line3,d1		; non-selected options are purple
		cmp.b	d2,d5			; is this the selected option?
		bne.s	.notselected	; branch if not
		move.w	#tile_line2,d1	; selected option is white

	.notselected:
		move.w	MenuOps(pc,d5.w),d4
		lea	MenuOps(pc,d4.w),a0
		bsr.w	Console_WriteLine_WithPattern	; draw the option text
		bsr.w	Console_StartNewLine		; skip a line
		addq.b	#2,d5			; next option
		dbf	d3,.redrawloop		; repeat for all options
		bra.w	MainMenuLoop	; return to loop start
; ===========================================================================

MenuOps:	index *,,2
		id_FirstSelection:	equ ptr_id
		ptr	MainCPUAddrErr
		ptr	MainCPUIllegal
		ptr SubCPUAdderr
		ptr	SubCPUIllegal
		id_LastSelection:	equ ptr_id
		ptr	FormatStringTst
		arraysize MenuOps

MainCPUAddrErr:
		dc.b	' - Test Main CPU address error',0
		even

MainCPUIllegal:
		dc.b	' - Test Main CPU illegal instruction',0
		even

SubCPUAdderr:
		dc.b	' - Test Sub CPU address error',0
		even

SubCPUIllegal:
		dc.b	' - Test Sub CPU illegal instruction',0
		even

FormatStringTst:
		dc.b	' - Run FormatString Test',0
		even

; ----------------------------------------------------------------------------
; Subroutine to reset the console before and after running a test program
; ----------------------------------------------------------------------------

TestDone:
		lea 4(sp),a3	; if returning from a finished test, skip over return address

ClearTestConsole:
		disable_ints
		lea	ErrorHandler_ConsoleConfig_Initial(pc),a1
		lea (vdp_data_port).l,a6
		lea	vdp_control_port-vdp_data_port(a6),a5
		bra.w	Console_Reset	; clear screen and reset console position
; ===========================================================================

StartTest:
		lea (sp),a3
		bsr.s	ClearTestConsole	; clear console for test program

		move.w	TestPointers(pc,d2.w),d2
		jsr	TestPointers(pc,d2.w)		; run the test

		bra.w	MainMenu_Return	; return to main menu if test allows user to exit

TestPointers:	index *,,2
		ptr TestMainCPUAddErr
		ptr	TestMainCPUIllegal
		ptr	TestSubCPUAddrErr
		ptr TestSubCPUIllegal
		ptr FormatStringTest
; ===========================================================================

TestMainCPUAddErr:
		move.w	1(a0),d0	; crash the CPU with a word operation at an odd address
		rts
; ===========================================================================

TestMainCPUIllegal:
		illegal		; trigger illegal instruction exception
		rts
; ===========================================================================

TestSubCPUAddrErr:
		moveq	#subcmd_TestAddrErr,d0		; send command to crash sub CPU with address error
		bra.w	SubCPUCmd
; ===========================================================================

TestSubCPUIllegal:
		moveq	#subcmd_TestIllegal,d0		; send command to crash sub CPU with illegal instruction
		bra.w	SubCPUCmd