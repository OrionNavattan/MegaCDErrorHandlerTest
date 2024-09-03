; ---------------------------------------------------------------
; Assertion tests
; ---------------------------------------------------------------

AssertionTest:
		; Initialize registers with pseudo-random values,
		; found at "RegisterData" byte-array (see below)
		movem.l	RegisterData(pc),d0-a6

		move.w	#0,ccr		; clear CCR

		assert.l	d0, eq, RegisterData
		jsr	CheckRegisterIntergity_CheckCCR(pc)

		assert.b	d0, ne
		jsr	CheckRegisterIntergity_CheckCCR(pc)

		assert.w	d1, pl, , UnreachableDebugger
		jsr	CheckRegisterIntergity_CheckCCR(pc)

		assert.w	.local_data, eq, #$1234
		jsr	CheckRegisterIntergity_CheckCCR(pc)

		assert.w	.local_data, eq, #$1234, UnreachableDebugger
		jsr	CheckRegisterIntergity_CheckCCR(pc)

		assert.w	.local_data, ne, , UnreachableDebugger
		jsr	CheckRegisterIntergity_CheckCCR(pc)

		assert.l	.reallyLongLabelIHopeItWontTriggerSomeErrorsOrSmth, eq, #$BADBEEF, ReachableDebugger

		Console.WriteLine	"The last assertion should've failed!"
		Console.Write		"%<pal1>TESTS FAILED"
		bra.w	TestDone
; ===========================================================================

.local_data:
		dc.w	$1234

.reallyLongLabelIHopeItWontTriggerSomeErrorsOrSmth:
		dc.l	0
; ===========================================================================

UnreachableDebugger:
		Console.WriteLine	"This debugger should've been unreachable!"
		Console.Write		"%<pal1>TESTS FAILED"
		Console.WriteLine	'%<pal0>Reboot console to return to Main Menu'
		bra.s	*		; no return due to console program invocation

	; This is to make sure sure ASM68K's local label flag is intact
	; If it isn't, this'll become a global label and raise a
	; duplicate label error
	.local_data:
		dc.w	0
; ===========================================================================

ReachableDebugger:
		Console.WriteLine	"%<pal1>TESTS PASSED IS HEADER ABOVE READS:%<endl>Got: 00000000"
		Console.WriteLine	'%<pal0>Reboot console to return to Main Menu'
		bra.s	*		; no return due to console program invocation

; ===========================================================================

CheckRegisterIntergity_CheckCCR:
		pushr.w	sr
		tst.b	1(sp)					; CCR must be zero
		bne.s	.ccr_polluted			; if not, branch
		pushr.l	d0-a6

		lea		(sp),a0				; a0 = registers dump pointer
		lea		RegisterData(pc),a1	; a1 = source registers pointer
		moveq	#15-1,d0				; d0 = number of registers minus 1

	.loop:
		cmpm.l	(a0)+,(a1)+
		dbne	d0,.loop
		bne.s	.corrupted
		popr.l	d0-a6
		popr.w	sr
		rts
; ===========================================================================

.ccr_polluted:
		Console.Write "%<endl>%<pal1>CCR polluted!"
		addq.w	#4+2,sp		; throw away dumped SR and return address to test flow
		bra.w	TestDone
; ===========================================================================

.corrupted:
		subq.w	#4,a0
		subq.w	#4,a1
		lea		RegisterNames-RegisterData(a1),a2
		lea		sizeof_dumpedregs(sp),a3

		Console.Write "%<endl,pal1>@%<.l (a3) sym|split>: %<endl,pal0> Register %<pal1>%<.l a2 str>%<pal0> corrupted!%<endl> Got %<pal2>%<.l (a0)>%<pal0>, expected %<pal2>%<.l (a1)>%<pal0,endl>"

		lea	sizeof_dumpedregs+4+2(sp),sp	; throw away dumped registers and return address to test flow
		bra.w	TestDone
