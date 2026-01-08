.extern kmalloc
.extern kfree

.extern _destroyPS

.extern PS_PTR
.extern KERN_STATE_SP

.text
	%% EVT HANDLERS %%
	.set STDOUT, #0
	_writeHndlr:
		% _write(count:u32, buffer:&u8) -> void
		% a1: count
		% a2: buffer

		% get memory for struct
		% takes up 12 bytes

		sub sp, sp, #4
		str lr, [sp]

		mv a0, #12
		call kmalloc
		mv x10, xr

		ld lr, [sp]
		add sp, sp, #4

		% refer to documentation for struct layout
		mv c0, STDOUT
		str c0, [x10] % fd
		str a1, [x10, #4] % count
		str a2, [x10, #8] % buffer

		% in order to tell the cpu request, use CSTR bit 13
		% CSTR = CSTR | (1 << 13)
		ldcstr c0
		mv c1, #1
		lsl c1, c1, #13
		or c0, c0, c1
		mvcstr c0
		hlt

		% clear bit
		% it is guaranteed registers are not changed
		not c1, c1
		and c0, c0, c1
		mvcstr c0
		% bit 13 should be cleared

		% free memory
		mv a0, a2
		mv a1, #12
		sub sp, sp, #4
		str lr, [sp]
		call kfree
		ld lr, [sp]
		add sp, sp, #4

		ub HNDLR_END

		.set STDIN, #1
	_readHndlr:
		nop

		ub HNDLR_END


	_exitHndlr:
		% basic exit
		% restore sp
		ld sp, KERN_STATE_SP
		% return value of user program is in xr
		sub sp, sp, #4
		str xr, [sp]

		% remove PS
		call _destroyPS

		ld xr, [sp]
		add sp, sp, #4

		hlt


	_excpHndlr1:
		% for now, place non-0 in PS.excpType
		ld c1, PS_PTR
		mv c2, #0b10 % FETCH ABORT
		mv c0, #566
		strb c2, [c1], c0
		hlt

	_excpHndlr0:
	_excpHndlr2:
		% for now, place non-0 in PS.excpType
		ld c1, PS_PTR
		mv c2, #0b01 % DATA ABORT
		mv c0, #566
		strb c2, [c1], c0
		hlt


	HNDLR_END:
		ld c1, PS_PTR

		% restore
		ld sp, [c1, #6]
		ld x0, [c1, #18]
		ld x1, [c1, #22]
		ld x2, [c1, #26]
		ld x3, [c1, #30]
		ld x4, [c1, #34]
		ld x5, [c1, #38]
		ld x6, [c1, #42]
		ld x7, [c1, #46]
		ld x8, [c1, #50]
		ld x9, [c1, #54]
		ld x10, [c1, #58]
		ld x11, [c1, #62]
		ld x17, [c1, #66]
		ld x18, [c1, #70]
		ld x19, [c1, #74]
		ld x20, [c1, #78]
		ld x21, [c1, #82]
		ld x22, [c1, #86]
		ld x23, [c1, #90]
		ld x24, [c1, #94]
		ld x25, [c1, #98]
		ld x26, [c1, #102]
		ld x27, [c1, #106]
		ld x28, [c1, #110]
		ld x29, [c1, #114]

		eret


.evt
	EVT_START:
	% save cpu context
	ld c1, PS_PTR
	% ir was saved by cpu
	% PS.sp
	str sp, [c1, #6]

	% restore kernel sp
	ld sp, KERN_STATE_SP

	ldcstr c0
	str x0, [c1, #14]

	% PS.grp[i]
	str x0, [c1, #18]
	str x1, [c1, #22]
	str x2, [c1, #26]
	str x3, [c1, #30]
	str x4, [c1, #34]
	str x5, [c1, #38]
	str x6, [c1, #42]
	str x7, [c1, #46]
	str x8, [c1, #50]
	str x9, [c1, #54]
	str x10, [c1, #58]
	str x11, [c1, #62]
	str x17, [c1, #66]
	str x18, [c1, #70]
	str x19, [c1, #74]
	str x20, [c1, #78]
	str x21, [c1, #82]
	str x22, [c1, #86]
	str x23, [c1, #90]
	str x24, [c1, #94]
	str x25, [c1, #98]
	str x26, [c1, #102]
	str x27, [c1, #106]
	str x28, [c1, #110]
	str x29, [c1, #114]

	% get the offset based off on exception number
	resr c0
	% save it as well
	str c0, [c1, #16]

	% if RESR is 0x0, it is a syscall, refer to a0 for offset
	% else if it is an exception, use the RESR contents
	cmp c0, #0x0
	bne offsetFromExecp

	% offset into table is done as follows:
	% IR := EVT_BASE + SIZE_OF_HEADER_CODE + (INDEX * SIZE_OF_EVT_ENTRY)

	offsetFromSyscall:
	mv c0, a0

	offsetFromExecp:
	% as is

	calculateOffset:
	mv c4, #8
	mul c2, c0, c4 % INDEX * SIZE_OF_EVT_ENTRY (8 bytes)
	add c2, c2, HEADER_CODE_SIZE % + SIZE_OF_HEADER_CODE
	ld c1, =#0x00040000
	add c2, c2, c1 % + EVT_BASE

	ld c0, [c2]
	ubr c0
	.set HEADER_CODE_SIZE, @-EVT_START + 4

	%% BEGIN EVT ENTRIES %%
	.byte 0b00000000 % syscall read
	.hword 0x0000 % unused
	.byte 0x00 % unsused
	.word _readHndlr

	.byte 0b00000001 % syscall write
	.hword 0x0000
	.byte 0x00
	.word _writeHndlr

	.byte 0b00000010 % syscall exit
	.hword 0x0000
	.byte 0x00
	.word _exitHndlr

	% pad in for now
	% an entry is 8 bytes, 9 entries between write and first exception, 9 * 8 = 72 bytes
	.zero #72
	% ....

	.byte 0b01001100 % exception for invalid access
	.hword 0x0000
	.byte 0x00
	.word _excpHndlr0

	.byte 0b10001101 % exception for invalid instruction
	.hword 0x0000
	.byte 0x00
	.word _excpHndlr1

	.byte 0b01001110 % exception for privilege use
	.hword 0x0000
	.byte 0x00
	.word _excpHndlr2
