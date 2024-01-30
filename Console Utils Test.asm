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

; --------------------------------------------------------------
; Subroutine that check if current register values match
; array they were initialized with
; --------------------------------------------------------------

CheckRegisterIntergity:
		pushr.l	d0-a6

		lea	(sp),a0				; a0 = registers dump pointer
		lea	RegisterData(pc),a1		; a1 = source registers pointer
		moveq	#15-1, d0				; d0 = number of registers minus 1

	.loop:
		cmpm.l	(a0)+,(a1)+
		dbne	d0,.loop
		bne.s	.corrupted
		popr.l	d0-a6
		rts
; ===========================================================================

.corrupted:
		subq.w	#4,a0
		subq.w	#4,a1
		lea	RegisterNames-RegisterData(a1),a2
		lea	sizeof_dumpedregs(sp),a3

		Console.Write "%<endl,pal1>@%<.l (a3) sym|split>: %<endl,pal0> Register %<pal1>%<.l a2 str>%<pal0> corrupted!%<endl> Got %<pal2>%<.l (a0)>%<pal0>, expected %<pal2>%<.l (a1)>%<pal0,endl>"

		lea	sizeof_dumpedregs+4(sp),sp	; throw away dumped registers and return address to test flow
		rts
; ===========================================================================

RegisterData:
		dc.b $47, $2F, $74, $1E, $5B, $57, $06, $22, $38, $3D, $52, $9E, $AF, $4F
		dc.b $BD, $96, $F0, $8A, $3B, $BB, $B9, $E2, $96, $B0, $6E, $26, $FB, $C1
		dc.b $6D, $21, $D0, $06, $41, $04, $0E, $FD, $93, $72, $92, $32, $E0, $AB
		dc.b $2F, $77, $70, $A8, $76, $B6, $0F, $3C, $6D, $7C, $70, $72, $B5, $AA
		dc.b $5A, $CB, $DC, $F9

RegisterNames:
		dc.w 'd0',0,'d1',0,'d2',0,'d3',0,'d4',0,'d5',0,'d6',0,'d7',0
		dc.w 'a0',0,'a1',0,'a2',0,'a3',0,'a4',0,'a5',0,'a6',0
