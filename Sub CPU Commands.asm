; ---------------------------------------------------------------------------
; Sub CPU command definitions

; By default, start at 1. This special macro is used to generate ID
; constants for both CPUs and an index table for the sub CPU's command
; handler.
; ---------------------------------------------------------------------------

SubCPUCommands:	macro	func

		\func 	TestAddrErr		; test an address error on the sub CPU
		\func	TestIllegal		; test an illegal instruction exception on the sub CPU
		endm

GenSubCmdIDs:	macro	name
subcmd_\name: rs.b 1
		endm

		rsset 1

		SubCPUCommands	GenSubCmdIDs	; generate ID constants for all sub CPU commands
