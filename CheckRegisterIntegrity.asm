; --------------------------------------------------------------
; Subroutine that check if current register values match
; array they were initialized with. Used by console utils
; and console flow tests.
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
		bra.w	TestDone
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
