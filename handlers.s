.extern kmalloc
.extern kfree

.extern _destroyPS

.extern PS_PTR
.extern KERN_STATE_SP

.text
	%% EVT HANDLERS %%
	.set STDOUT, 0
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

		.set STDIN, 1
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



