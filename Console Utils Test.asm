; ---------------------------------------------------------------
; Console run and console clear tests
; ---------------------------------------------------------------

ConsoleUtilsTest:
		; Initialize registers with pseudo-random values,
		; found at "RegisterData" byte-array (see below)
		movem.l	RegisterData(pc),d0-a6

		bsr.s	TestProgram
		bra.w	TestDone
; ===========================================================================

TestProgram:
		KDebug.WriteLine "Entering test program..."

		Console.SetXY #1,#1
		Console.Write "%<pal1>Refreshing in ~1 second..."
		KDebug.WriteLine "About to call Console.Sleep..."
		Console.Sleep #60
		KDebug.WriteLine "Console.Sleep finished"
		Console.Clear

		Console.WriteLine "Refreshed!"
		Console.Sleep #0
		Console.WriteLine "Printed a line without a delay!"

		Console.Sleep #30
		Console.Write "Minimal sleep... #1"
		Console.Sleep #30
		Console.Write "Minimal sleep... #2"
		Console.Sleep #30
		Console.WriteLine "Minimal sleep... #3"
		Console.Sleep #30

		jsr	CheckRegisterIntergity(pc)

		Console.Write "Paused. Press A/B/C/Start to continue..."
		KDebug.WriteLine "Prepare to call Console.Pause..."
		Console.Pause
		KDebug.WriteLine "Console.Pause called"
		Console.WriteLine "WELL PRESSED!"
		KDebug.WriteLine "Printed success message to the console"

		jsr	CheckRegisterIntergity(pc)

		KDebug.WriteLine "Testing KDebug writes exclusively..."
		KDebug.Write "You should see "
		KDebug.Write "this line once endl token is encountered!%<endl>"
		KDebug.Write "This line is extremely long and certainly flushes the buffer several times!"
		KDebug.BreakLine

		KDebug.StartTimer
		nop
		nop
		KDebug.EndTimer

		KDebug.StartTimer
		nop
		nop
		KDebug.EndTimer

		KDebug.StartTimer
		nop
		nop
		KDebug.EndTimer

		KDebug.StartTimer
		nop
		nop
		KDebug.EndTimer

		KDebug.WriteLine "You should see debugger now. Type 'c' and press Enter to continue..."
		KDebug.BreakPoint

		Console.BreakLine
		Console.WriteLine "ALL DONE!"

		bsr.s CheckRegisterIntergity	; has to be a bsr due to how CheckRegisterIntergity handles test abortion
		rts
