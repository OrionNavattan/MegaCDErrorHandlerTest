		rsset $FFFFFFF6
stack_pointer:		equ __rs	; $FFFFFFF6
v_joypad_hold:		rs.w 1		; $FFFFFFF6
v_options_coords:	rs.l 1		; $FFFFFFF8	; start coordinates for options on menu screen
v_keep_after_reset:	equ __rs
					rs.b 1
v_menu_selection:	rs.b 1		; $FFFFFFFD
v_console_region:	rs.b 1		; $FFFFFFFE
v_bios_id:			rs.b 1		; $FFFFFFFF


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
