StringsBuffer:	equ $FF0000
short_data_chunk:	equ	$10000
long_data_chunk:	equ	$10080

_bufferSize = $20					; if you change this, you have to alter all the buffer overflow tests suites ...
_canaryValue = $DC					; an arbitrary byte value, written after the buffer to detect overflows

FormatStringTest:
		lea TestSymbols(pc),a0		; load the dummy symbol table used by this test
		lea (wordram_2M).l,a1
		bsr.w KosDec

		Console.WriteLine 'Running "FormatString" tests...'

		lea	TestData(pc),a6		; a6 = test data
		lea	(StringsBuffer).l,a5		; a5 = string buffer
		moveq	#0,d1					; d1 will be tests counter

	.run_test:
		KDebug.WriteLine "Running test #%<.b d1 deci>..."
		lea	(a5),a0						; a0 = buffer
		movea.l	(a6),a1						; a1 = source string
		lea	$A(a6),a2						; a2 = arguments stack
		moveq	#_bufferSize-1,d7				; d7 = string buffer size -1
		lea	IdleFlush(pc),a4
		move.b	#_canaryValue,_bufferSize(a5)	; write down canary value after the end of the buffer

		jsr	FormatString(pc)					; HERE'S OUR STAR LADIES AND GENTLEMEN !~  LET'S SEE HOW IT SURVIVES THE TEST

		cmpi.b	#_canaryValue,_bufferSize(a5)	; make sure canary value didn't get overwritten ...
		bne.w	.buffer_overflow					; if it did, then writting past the end of the buffer is detected
		sf.b	_bufferSize(a5)					; add null-terminator past the end of the buffer, so strings are displayed correctly ...

		movea.l	4(a6),a1						; a1 = Compare string
		moveq	#0,d4
		move.b	(a1)+,d4						; d4 = correctly formatted output size

		lea	(a5),a2						; a2 = Got string
		lea	(a1),a3						; a3 = Expected string

		suba.l	a5,a0
		move.w	a0,d3							; d3 = actual output size
		cmp.w	d3,d4							; compare actual output size to the expected
		bne.w	.size_mismatch					; if they don't match, branch

		subq.w	#1,d4
		bmi.w	.next_test

	.compare_loop:
		cmpm.b	(a1)+,(a5)+
		bne.w	.byte_mismatch
		dbf	d4,.compare_loop

	.next_test:
		addq.w	#1,d1							; increment test number
		adda.w	8(a6),a6						; a6 => Next test
		tst.w	(a6)							; is test header valid?
		bpl.w	.run_test						; if yes, keep doing tests

		Console.WriteLine 'Number of completed tests: %<.b d1 deci>'
		Console.WriteLine '%<pal1>ALL TESTS HAVE PASSED SUCCESSFULLY'
		bra.w	TestDone
; ===========================================================================

	.print_failure_header:
		Console.WriteLine '%<pal2>Test #%<.b d1 deci> FAILED'
; ===========================================================================

	.print_failure_diff:
		Console.WriteLine '%<pal0>Got:%<endl>%<pal2>"%<.l a2 str>"'
		Console.WriteLine '%<pal0>Expected:%<endl>%<pal2>"%<.l a3 str>"'

	.halt_tests:
		Console.WriteLine '%<pal1>TEST FAILURE, STOPPING'
		bra.w	TestDone
; ===========================================================================

	.buffer_overflow:
		bsr.w	.print_failure_header
		Console.WriteLine '%<pal1>Error: Writing past the end of buffer'
		bra.s	.halt_tests
; ===========================================================================

	.size_mismatch:
		bsr.w	.print_failure_header
		Console.WriteLine '%<pal1>Error: Size mismatch (%<.b d3> != %<.b d4>)'
		bra.w	.print_failure_diff
; ===========================================================================

	.byte_mismatch:
		bsr.w	.print_failure_header
		Console.WriteLine '%<pal1>Error: Byte mismatch (%<.b -1(a1)> != %<.b -1(a5)>)'
		bra.w	.print_failure_diff

; --------------------------------------------------------------
; Buffer flush function
; --------------------------------------------------------------

IdleFlush:
		; Make sure buffer starts where expected
		pushr.l	a0
		neg.w	d7
		add.w	#_bufferSize-1,d7
		sub.w	d7,a0					; a0 = start of the buffer
		assert.l	a0,eq,a5				; buffer should start at the expected location
		popr.l	a0

		moveq	#0,d7
		subq.w	#1,d7					; set sarry flag, so FormatString is terminated after this flush
		rts
; ===========================================================================

dcs	macro
		dc.b	.end\@-.start\@
	.start\@:
		dc.b	\1
	.end\@:
		dc.b	0				; also put a null-terminator, so MDShell may print it as C-string also ...
	endm

addTest macro args,source_str,compare_str
	.test_header\@:
		dc.l	.source_string\@						; (a6) => Source string absolute pointer
		dc.l	.compare_string\@						; 4(a6) => Compare string absolute pointer
		dc.w	.test_end\@-.test_header\@				; 8(a6)	=> End of test relative pointer

		rept narg(args)									; $A(a6) and on => Arguments stack
			dc\args
			shift args
		endr

	.source_string\@:
		dc.b \source_str

	.compare_string\@:
		dcs <\compare_str>								; this string also includes "length" byte for correct computations
		even

	.test_end\@:
	endm


TestData:

	; NOTICE: Null-terminator is not included in the output string compared here.
	;	While FormatString *does* add null-ternimator, returned buffer position
	;	points *before* null-terminator, not *after* it (if no overflows occured).

	; TODOh: Replace numbers with literal constants ...

	; #00: Simple test
	addTest { <.l 0> }, &
			<'Simple string',$00>, &
			<'Simple string'>

	; #01: Buffer limit test #1 ($20 bytes)
	addTest { <.l 0> }, &
			<'This string might overflow the buffer!',$00>, &
			<'This string might overflow the b'>

	; #02: Buffer limit test #2
	addTest { <.l 0> }, &
			<'This string might overflow the b',$00>, &
			<'This string might overflow the b'>

	; #03: Buffer limit test #3
	addTest { <.l 0> }, &
			<'This string might overflow the ',$00>, &
			<'This string might overflow the '>

	; #04: Formatters test #1
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<deci|word,hex|long,hex|long,$00>, &
			<'12340123456789ABCDEF'>

	; #05: Formatters test #2
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<deci|word,' ',hex|long,' ',hex|long,$00>, &
			<'1234 01234567 89ABCDEF'>

	; #06: Formatters test #3
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'--',deci|word,' ',hex|long,' ',hex|long,'--',$00>, &
			<'--1234 01234567 89ABCDEF--'>

	; #07: Buffer limit + formatters test #1
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'--------',deci|word,' ',hex|long,' ',hex|long,'--',$00>, &
			<'--------1234 01234567 89ABCDEF--'>

	; #08: Buffer limit + formatters test #2
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'----------',deci|word,' ',hex|long,' ',hex|long,'--',$00>, &
			<'----------1234 01234567 89ABCDEF'>

	; #09: Buffer limit + formatters test #3
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'-----------',deci|word,' ',hex|long,' ',hex|long,'--',$00>, &
			<'-----------1234 01234567 89ABCDE'>

	; #10: Multiple formatters test
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<deci|word|signed,' ',bin|byte,' ',hex|byte|signed,$00>, &
			<'+1234 00100011 +67'>

	; #11: String decoding test #1
	addTest { <.l SampleString1> }, &
			<str,$00>, &
			<'<String insertion test>'>

	; #12: Buffer limit + String decoding test #1
	addTest { <.l SampleString1>, <.l SampleString1> }, &
			<str,str,$00>, &
			<'<String insertion test><String i'>

	; #13: Buffer limit + String decoding test #2
	addTest { <.l SampleString2> }, &
			<str,$00>, &
			<'This string takes all the buffer'>

	; #14: Buffer limit + String decoding test #3
	addTest { <.l SampleString2>, <.l SampleString2> }, &
			<str,str,$00>, &
			<'This string takes all the buffer'>

	; #15: Zero-length string decoding test #1
	addTest { <.l EmptyString> }, &
			<'[',str,']',$00>, &
			<'[]'>

	; #16: Zero-length string decoding test #2
	addTest { <.l EmptyString>, <.l EmptyString>, <.l EmptyString>, <.l EmptyString> }, &
			<str,str,'-',str,str,$00>, &
			<'-'>

	; #17: Zero-length string decoding test #3
	addTest { <.l EmptyString>, <.l EmptyString> }, &
			<'[',str,str,']',$00>, &
			<'[]'>

	; #18: Character decoding test #1
	addTest { <.l OneCharacterString> }, &
			<str,$00>, &
			<'a'>

	; #19: Character decoding test #2
	addTest { <.l OneCharacterString>, <.l OneCharacterString> }, &
			<str,str,$00>, &
			<'aa'>

	; #20: Buffer limit + Character decoding test #1
	addTest { <.l OneCharacterString> }, &
			<'This string takes all the buffer',str,$00>, &
			<'This string takes all the buffer'>

	; #21: Buffer limit + Character decoding test #2
	addTest { <.l OneCharacterString> }, &
			<'This string takes almost all ..',str,$00>, &
			<'This string takes almost all ..a'>

	; #22: Buffer limit + Character decoding test #3
	addTest { <.l OneCharacterString>, <.l OneCharacterString> }, &
			<'This string takes almost all ..',str,str,$00>, &
			<'This string takes almost all ..a'>

	; #23: Buffer limit + Character decoding test #4
	addTest { <.l OneCharacterString> }, &
			<'This string takes almost all ..',str,'!',$00>, &
			<'This string takes almost all ..a'>

	; #24: Labels test #1
	addTest { <.l short_data_chunk> }, &
			<sym|long,$00>, &
			<'short_data_chunk'>

	; #25: Labels test #2
	addTest { <.l short_data_chunk+1> }, &
			<sym|long,$00>, &
			<'short_data_chunk+1'>

	; #26: Labels test #3
	addTest { <.l long_data_chunk+$10001> }, &
			<sym|long,$00>, &
			<'long_data_chunk+10001'>

	; #27: Buffer limit + Lables test
	addTest { <.l long_data_chunk+$10001> }, &
			<'Overflow>>> ',sym|long,$00>, &
			<'Overflow>>> long_data_chunk+1000'>

	; #28: Signed hex numbers test
	addTest { <.w $1234>, <.l -$01234567>, <.w $FFFF> }, &
			<hex|word|signed,' ',hex|long|signed,' ',hex|word|signed,$00>, &
			<'+1234 -01234567 -0001'>

	; #29: Empty output test #1
	addTest { <.l 0> }, &
			<'',$00>, &
			<''>

	; #30: Empty output test #2
	addTest { <.l EmptyString> }, &
			<str,$00>, &
			<''>

	; #31: Advanced symbol output test #1
	addTest { <.l $100> }, &
			<sym|long,$00>, &
			<'Offset_100'>

	; #32: Advanced symbol output test #2
	addTest { <.l $101> }, &
			<sym|long,$00>, &
			<'Offset_100+1'>

	; #33: Advanced symbol output test #3
	addTest { <.l $1FF> }, &
			<sym|long,$00>, &
			<'Offset_100+FF'>

	; #34: Advanced symbol output test #4 (non-existent symbol)
	addTest { <.l 0> }, &
			<sym|long,$00>, &
			<'00000000'>

	; #35: Advanced symbol output test #5 (non-existent symbol)
	addTest { <.l 0> }, &
			<sym|long|forced,$00>, &
			<'<unknown>'>

	; #36: Advanced symbol output test #6 (non-existent symbol)
	addTest { <.l $FF> }, &
			<sym|long,$00>, &
			<'000000FF'>

	; #37: Advanced symbol output test #7 (non-existent symbol)
	addTest { <.l $FF> }, &
			<sym|long|forced,$00>, &
			<'<unknown>'>

	; #38: Advanced symbol output test #8 (far away symbol)
	addTest { <.l $20000> }, &
			<sym|long|forced,$00>, &
			<'long_data_chunk+FF80'>

	; #39: Advanced symbol output test #9 (far away symbol)
	addTest { <.l $20080> }, &
			<sym|long|forced,$00>, &
			<'long_data_chunk+10000'>

	; #40: Advanced symbol output test #10 (RAM addr)
	addTest { <.l $FF0000> }, &
			<sym|long,$00>, &
			<'RAM_Offset_FF0000'>

	; #41: Advanced symbol output test #11 (RAM addr)
	addTest { <.l $FFFF0000> }, &
			<sym|long|forced,$00>, &
			<'RAM_Offset_FF0000'>

	; #42: Advanced symbol output test #12 (RAM addr)
	addTest { <.l $FFFF0001> }, &
			<sym|long,$00>, &
			<'RAM_Offset_FF0000+1'>

	; #43: Advanced symbol output test #13 (RAM addr)
	addTest { <.l $FFFF0002> }, &
			<sym|long|forced,$00>, &
			<'RAM_Offset_FF0000+2'>

	; #44: Advanced symbol output test #10 (RAM addr #2)
	addTest { <.l $FF8000> }, &
			<sym|long,$00>, &
			<'RAM_Offset_FFFF8000'>

	; #45: Advanced symbol output test #11 (RAM addr #2)
	addTest { <.w $8000> }, &
			<sym|word,$00>, &
			<'RAM_Offset_FFFF8000'>

	; #46: Advanced symbol output test #12 (RAM addr #2)
	addTest { <.w $8001> }, &
			<sym|word,$00>, &
			<'RAM_Offset_FFFF8000+1'>

	; #47: Advanced symbol output test #13 (RAM addr #3)
	addTest { <.w $FF> }, &
			<sym|byte,$00>, &
			<'RAM_End'>

	; #48: Symbol and displacement test #1
	addTest { <.l $1001> }, &
			<sym|long|split,symdisp,$00>, &
			<'ShouldOverflowBufferWithDis+1'>

	; #49: Symbol and displacement test #2
	addTest { <.l $1001> }, &
			<'>>>',sym|long|split,symdisp,'this is no longer visible!',$00>, &
			<'>>>ShouldOverflowBufferWithDis+1'>

	; #50: Symbol and displacement test #3
	addTest { <.l $1001> }, &
			<'>>>',sym|long|split,'(',symdisp,')',$00>, &
			<'>>>ShouldOverflowBufferWithDis(+'>

	; #51: Symbol and displacement test #4
	addTest { <.l $1000> }, &
			<sym|long|split,'(',symdisp,')',$00>, &
			<'ShouldOverflowBufferWithDis()'>

	; #52: Symbol and displacement test #5
	addTest { <.l $1003> }, &
			<'>>>>',sym|long,$00>, &
			<'>>>>ShouldOverflowBufferWithDisp'>

	; #53: Symbol and displacement test #6
	addTest { <.l $1005> }, &
			<sym|long,$00>, &
			<'ShouldOverflowBufferWithDisp2+1'>

	; #54: Symbol and displacement test #7
	addTest { <.l $1007> }, &
			<sym|long,$00>, &
			<'ShouldOverflowBufferEvenWithoutD'>

	; #55: Symbol and displacement test #8
	addTest { <.l $1009> }, &
			<sym|long,$00>, &
			<'ShouldOverflowBufferEvenWithoutD'>

	; #56: Symbol and displacement test #9
	addTest { <.l $100B> }, &
			<sym|long,$00>, &
			<'ShouldOverflowBufferEvenWithoutD'>

	; #57: Symbol and displacement test #10
	addTest { <.l long_data_chunk+$10010> }, &
			<sym|long,$00>, &
			<'long_data_chunk+10010'>

	; #58: Symbol and displacement test #11
	addTest { <.l long_data_chunk+$100010> }, &
			<sym|long,$00>, &
			<'long_data_chunk+100010'>
	; #59: Control character with argument flow: Fits buffer
	addTest { <.l 0> }, &
			<'We should be able to fit it ',setw,40,$00>, &
			<'We should be able to fit it ',setw,40>

	; #60: Control character with argument flow: Fits buffer's edge
	addTest { <.l 0> }, &
			<'We should be able to fit it: ',setw,40,$00>, &
			<'We should be able to fit it: ',setw,40>

	; #61: Control character with argument flow: On buffer's edge
	addTest { <.l 0> }, &
			<"We shouldn't truncate argument ",setw,40,$00>, &
			<"We shouldn't truncate argument ">

	; #62: Control character with argument flow: Controls only test #1
	addTest { <.l 0> }, &
			<setw,40,$00>, &
			<setw,40>

	; #63: Control character with argument flow: Controls only test #2
	addTest { <.l 0> }, &
			<setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,$00>, &
			<setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40,setw,40>

		dc.w	-1
; ===========================================================================

SampleString1:
		dc.b	'<String insertion test>',0

SampleString2:
		dc.b	'This string takes all the buffer',0

EmptyString:
		dc.b	0

OneCharacterString:
		dc.b	'a',0

		even
