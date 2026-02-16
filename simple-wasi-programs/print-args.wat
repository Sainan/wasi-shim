(module
	(import "wasi_snapshot_preview1" "args_sizes_get" (func $args_sizes_get (param i32 i32) (result i32)))
	(import "wasi_snapshot_preview1" "args_get" (func $args_get (param i32 i32) (result i32)))
	(import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
	(memory (export "memory") 1)
	(data (i32.const 0xffff) "\n")
	(func (export "_start")
		(local $argc i32)
		(local $argv_buf_size i32)
		(local $i i32)
		(drop
			(call $args_sizes_get
				(i32.const 0)
				(i32.const 4)
				)
			)
		(local.set $argc (i32.load align=4 (i32.const 0)))
		(local.set $argv_buf_size (i32.load align=4 (i32.const 4)))
		(drop
			(call $args_get
				(i32.const 0)
				(i32.mul (i32.const 4) (local.get $argc))
				)
			)
		(block
			(loop
				;; if ($i == $argc) break;
				(br_if 1 (i32.eq (local.get $i) (local.get $argc)))
				;; $iovs = 0xffe0;
				;; $iovs->base = $argv[$i];
				(i32.store align=4 (i32.const 0xffe0) (i32.load (i32.mul (local.get $i) (i32.const 4))))
				;; $iovs->len = strlen($argv[$i]);
				(i32.store align=4 (i32.const 0xffe4) (call $strlen (i32.load (i32.mul (local.get $i) (i32.const 4)))))
				(drop
					(call $fd_write
						(i32.const 1)
						(i32.const 0xffe0)
						(i32.const 1)
						(i32.const 0xffe8)
						)
					)
				;; $iovs->base = 0xffff;
				(i32.store align=4 (i32.const 0xffe8) (i32.const 0xffff))
				;; $iovs->len = 1;
				(i32.store align=4 (i32.const 0xffec) (i32.const 1))
				(drop
					(call $fd_write
						(i32.const 1)
						(i32.const 0xffe8)
						(i32.const 1)
						(i32.const 0xffe8)
						)
					)
				;; ++$i;
				(local.set $i (i32.add (local.get $i) (i32.const 1)))
				;; continue;
				(br 0)
				)
			)
		)
	(func $strlen (param $ptr i32) (result i32)
		(local $len i32)
		(block
			(loop
				;; if (*$ptr == '\0') break;
				(br_if 1 (i32.eqz (i32.load8_u (local.get $ptr))))
				;; ++$ptr;
				(local.set $ptr (i32.add (local.get $ptr) (i32.const 1)))
				;; ++$len;
				(local.set $len (i32.add (local.get $len) (i32.const 1)))
				;; continue;
				(br 0)
				)
			)
		(local.get $len)
		)
	)
