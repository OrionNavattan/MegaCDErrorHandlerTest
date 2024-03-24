; ---------------------------------------------------------------
; Flow tester

; This unit tests whether using debugger macros in instruction
; flow affects program execution, which they shouldn't.
; The check is performed on processor registers state, which
; should be influenced by calling internal debugger routines.
; ---------------------------------------------------------------

ConsoleFlowTest:
		; Initialize registers with pseudo-random values,
		; found at "RegisterData" byte-array (see below)
		movem.l	RegisterData(pc),d0-a6

Test_BasicString:
		; Using Console.Write with Console with plain string ...
		Console.Write "Starting flow tests within console program..."
		jsr	CheckRegisterIntergity(pc)

Test_LineBreak:
		; Using Console.BreakLine ...
		Console.BreakLine
		jsr	CheckRegisterIntergity(pc)

Test_BasicFlags:
		; Using Console.Write with basic control flags ...
		Console.Write "Flags: %<pal0>CO%<pal1>LO%<pal2>RS%<pal3>!~%<endl>"
		jsr	CheckRegisterIntergity(pc)

Test_ExtendedFlags:
		; Using "setx" and "setw" flags with test output ...
		Console.Write "%<setx,1,setw,20>"
		Console.Write "Testing paragraph fill with 'setx' and 'setw' flags...%<pal0>"

		; Using "Console_SetXY" and "Console_SetWidth" ...
		pushr.l	d0-d1,-(sp)
		moveq	#24,d0				; X
		moveq	#2,d1				; Y
		jsr	Console_SetPosAsXY(pc)
		moveq	#10,d1
		jsr	Console_SetWidth(pc)

		Console.Write "%<pal3>Paragraph fill test with %<pal2>direct API%<pal3> calls...%<pal0>"
		popr.l	d0-d1

		Console.Write "%<endl,setx,0,setw,40>"
		jsr	CheckRegisterIntergity(pc)

Test_Formatters:
		; Using Console.Write to display formatted values ...
		Console.Write "Testing formatters ...%<endl>"
		jsr	CheckRegisterIntergity(pc)

Test_Formatter_Default:
		Console.Write "%<pal1>Default: %<pal0>"
		Console.Write "%<.b d0>-%<.w d0>-%<.l d0>%<endl>"
		jsr	CheckRegisterIntergity(pc)

Test_Formatter_HEX:
		Console.Write "%<pal1>hex: %<pal0>"
		Console.Write "%<.b d0 hex>-%<.w d0 hex>-%<.l d0 hex>%<endl>"
		jsr	CheckRegisterIntergity(pc)

Test_Formatter_DEC:
		Console.Write "%<pal1>deci: %<pal0>"
		Console.Write "%<.b d0 deci>-%<.w d0 deci>-%<.l d0 deci>%<endl>"
		jsr	CheckRegisterIntergity(pc)

Test_Formatter_SYM:
		Console.Write "%<pal1>sym: %<pal0>"
		Console.Write "%<.b d0 sym>-%<.w d0 sym>-%<.l d0 sym>%<endl>"
		jsr	CheckRegisterIntergity(pc)

Test_Formatter_SYM_SPLIT:
		Console.Write "%<pal1>sym|split: %<pal0>"
		Console.Write "%<.b d0 sym|split>%<pal2>%<symdisp>%<pal0>-"
		Console.Write "%<.w d0 sym|split>%<pal2>%<symdisp>%<pal0>-"
		Console.Write "%<.l d0 sym|split>%<pal2>%<symdisp>%<pal0>"
		jsr	CheckRegisterIntergity(pc)

Test_MiscCommands:
		; Using misc. commands related to Console entity ...
		Console.SetXY #3,#22
		Console.Write "Positioning test #1 ..."
		Console.BreakLine
		Console.Write "Positioning test #2 ..."
		jsr	CheckRegisterIntergity(pc)

Test_Assertions:
		Console.SetXY #0,#26
		Console.Write "Testing assertions..."

		assert.l	d0,eq,#$472F741E
		assert.l	d1,ge,RegisterData+4
		assert.w	d2,hs,RegisterData+8+2
		assert.b	d3,ls,RegisterData+12+3

		Console.Write " ALL DONE!"
		bra.w	TestDone
