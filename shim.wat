(module
	;; The most important part: Some way to access our target's memory.
	(import "glue" "read_i32" (func $read_i32 (param $addr i32) (result i32)))
	(import "glue" "write_i8" (func $write_i8 (param $addr i32) (param $value i32)))
	(import "glue" "write_i16" (func $write_i16 (param $addr i32) (param $value i32)))
	(import "glue" "write_i32" (func $write_i32 (param $addr i32) (param $value i32)))
	(import "glue" "write_i64" (func $write_i64 (param $addr i32) (param $value i64)))
	;; Standard output hooks.
	(import "glue" "stdout_write" (func $stdout_write (param $addr i32) (param $len i32)))
	(import "glue" "stderr_write" (func $stderr_write (param $addr i32) (param $len i32)))
	;; Arguments. These functions can simply return 0.
	(import "glue" "get_num_args" (func $get_num_args (result i32)))
	(import "glue" "get_combined_args_size" (func $get_combined_args_size (result i32)))
	(import "glue" "get_arg" (func $get_arg (param $addr i32) (param $arg_index i32) (result i32)))
	;; Filesystem.
	(import "glue" "file_name_to_index" (func $file_name_to_index (param $path i32) (param $path_len i32) (result i32))) ;; -1 = no such file
	(import "glue" "file_size" (func $file_size (param $file_index i32) (result i64)))
	(import "glue" "file_read" (func $file_read (param $file_index i32) (param $offset i64) (param $buf i32) (param $len i32) (result i32)))
	;; The final call that will be made. The VM will trap on "unreachable" afterwards.
	(import "glue" "set_exit_code" (func $set_exit_code (param $exit_code i32)))

	(memory 1)
	(func $file_get_offset (param $file_index i32) (result i64)
		(i64.load offset=0 align=8
			(i32.mul
				(local.get $file_index)
				(i32.const 8)
				)
			)
		)
	(func $file_set_offset (param $file_index i32) (param $offset i64)
		(i64.store offset=0 align=8
			(i32.mul
				(local.get $file_index)
				(i32.const 8)
				)
			(local.get $offset)
			)
		)

	(func (export "args_get") (param $argv i32) (param $argv_buf i32) (result i32)
		(local $arg_index i32)
		(loop
			;; *$argv = $argv_buf;
			(call $write_i32
				(local.get $argv)
				(local.get $argv_buf)
				)
			;; ++$argv;
			(local.set $argv
				(i32.add
					(local.get $argv)
					(i32.const 4)
					)
				)
			;; memcpy($argv_buf, args[$arg_index], strlen(args[$arg_index])); $argv_buf += strlen(args[$arg_index]);
			(local.set $argv_buf
				(i32.add
					(local.get $argv_buf)
					(call $get_arg
						(local.get $argv_buf)
						(local.get $arg_index)
						)
					)
				)
			;; *$argv_buf = '\0';
			(call $write_i8
				(local.get $argv_buf)
				(i32.const 0)
				)
			;; ++$argv_buf;
			(local.set $argv_buf
				(i32.add
					(local.get $argv_buf)
					(i32.const 1)
					)
				)
			;; ++$arg_index;
			(local.set $arg_index
				(i32.add
					(local.get $arg_index)
					(i32.const 1)
					)
				)
			;; if ($arg_index == get_num_args()) break;
			(br_if 0
				(i32.ne
					(local.get $arg_index)
					(call $get_num_args)
					)
				)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "args_sizes_get") (param $argc i32) (param $argv_buf_size i32) (result i32)
		(call $write_i32
			(local.get $argc)
			(call $get_num_args)
			)
		(call $write_i32
			(local.get $argv_buf_size)
			(call $get_combined_args_size)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "environ_get") (param i32 i32) (result i32)
		(unreachable) ;; TODO
		)
	(func (export "environ_sizes_get") (param $environ_count i32) (param $environ_buf_size i32) (result i32)
		;; TODO: Add glue hooks
		;; *$environ_count = 0;
		(call $write_i32
			(local.get $environ_count)
			(i32.const 0)
			)
		;; *$environ_buf_size = 0;
		(call $write_i32
			(local.get $environ_count)
			(i32.const 0)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "fd_close") (param $fd i32) (result i32)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "fd_fdstat_get") (param $fd i32) (param $buf i32) (result i32)
		;; if ($fd != 3) return WASI_ERRNO_BADF;
		(if
			(i32.ne (local.get $fd) (i32.const 3))
			(then
				(return (i32.const 8))
				)
			)
		;; $buf->filetype = WASI_FILETYPE_DIRECTORY;
		(call $write_i8
			(local.get $buf)
			(i32.const 3)
			)
		;; $buf->flags = 0;
		(call $write_i16
			(i32.add (local.get $buf) (i32.const 2))
			(i32.const 0)
			)
		;; $buf->rights_base = -1;
		(call $write_i64
			(i32.add (local.get $buf) (i32.const 8))
			(i64.const -1)
			)
		;; $buf->rights_inheriting = -1;
		(call $write_i64
			(i32.add (local.get $buf) (i32.const 16))
			(i64.const -1)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "fd_fdstat_set_flags") (param i32 i32) (result i32)
		(unreachable) ;; TODO
		)
	(func (export "fd_prestat_get") (param $fd i32) (param $buf i32) (result i32)
		;; if ($fd != 3) return WASI_ERRNO_BADF;
		(if
			(i32.ne (local.get $fd) (i32.const 3))
			(then
				(return (i32.const 8))
				)
			)
		;; $buf->tag = WASI_PREOPENTYPE_DIR;
		(call $write_i8
			(local.get $buf)
			(i32.const 0)
			)
		;; $buf->name_len = 1;
		(call $write_i32
			(i32.add (local.get $buf) (i32.const 4))
			(i32.const 1)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "fd_prestat_dir_name") (param $fd i32) (param $path i32) (param $path_len i32) (result i32)
		;; if ($fd != 3) return WASI_ERRNO_BADF;
		(if
			(i32.ne (local.get $fd) (i32.const 3))
			(then
				(return (i32.const 8))
				)
			)
		;; $path[0] = '.';
		(call $write_i8
			(local.get $path)
			(i32.const 46)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "fd_read") (param $fd i32) (param $iovs i32) (param $iovs_len i32) (param $out_nread i32) (result i32)
		(local $iov_read i32)
		(local $total_read i32)
		(block
			(loop
				;; if ($iovs_len == 0) break;
				(br_if 1 (i32.eqz (local.get $iovs_len)))
				;; --$iovs_len
				(local.set $iovs_len (i32.sub (local.get $iovs_len) (i32.const 1)))
				;; $iov_read = file_read($fd - 10, $file_get_offset($fd - 10), $iovs->base, $iovs->len);
				(local.set $iov_read
					(call $file_read
						(i32.sub (local.get $fd) (i32.const 10))
						(call $file_get_offset (i32.sub (local.get $fd) (i32.const 10)))
						(call $read_i32 (local.get $iovs))
						(call $read_i32 (i32.add (local.get $iovs) (i32.const 4)))
						)
					)
				;; file_set_offset($fd - 10, $file_get_offset($fd - 10) + $iov_read);
				(call $file_set_offset
					(i32.sub (local.get $fd) (i32.const 10))
					(i64.add
						(call $file_get_offset (i32.sub (local.get $fd) (i32.const 10)))
						(i64.extend_i32_u (local.get $iov_read))
						)
					)
				;; $total_read += $iov_read;
				(local.set $total_read
					(i32.add
						(local.get $total_read)
						(local.get $iov_read)
						)
					)
				;; ++$iovs;
				(local.set $iovs (i32.add (local.get $iovs) (i32.const 8)))
				;; continue;
				(br 0)
				)
			)
		;; *$out_nread = $total_read;
		(call $write_i32
			(local.get $out_nread)
			(local.get $total_read)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "fd_seek") (param $fd i32) (param $delta i64) (param $whence i32) (param $out_off i32) (result i32)
		(block
			(block
				(block
					;; switch ($whence) { case 0: goto SEEK_SET; case 1: goto SEEK_CUR; case 2: goto SEEK_END; default: goto SEEK_RET; }
					(block
						(br_table 0 1 2 3 (local.get $whence))
						)
					;; SEEK_SET:
					;; $file_set_offset($fd - 10, $delta);
					(call $file_set_offset
						(i32.sub (local.get $fd) (i32.const 10))
						(local.get $delta)
						)
					;; goto SEEK_RET;
					(br 2)
					)
				;; SEEK_CUR:
				;; $file_set_offset($fd - 10, $file_get_offset($fd - 10) + $delta);
				(call $file_set_offset
					(i32.sub (local.get $fd) (i32.const 10))
					(i64.add
						(call $file_get_offset (i32.sub (local.get $fd) (i32.const 10)))
						(local.get $delta)
						)
					)
				;; goto SEEK_RET;
				(br 1)
				)
			;; SEEK_END:
			;; $file_set_offset($fd - 10, file_size($fd - 10));
			(call $file_set_offset
				(i32.sub (local.get $fd) (i32.const 10))
				(call $file_size
					(i32.sub (local.get $fd) (i32.const 10))
					)
				)
			;; goto SEEK_RET;
			(br 0)
			)
		;; SEEK_RET:
		;; *$out_off = $file_get_offset($fd - 10)
		(call $write_i64
			(local.get $out_off)
			(call $file_get_offset (i32.sub (local.get $fd) (i32.const 10)))
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func $fd_write_aux (param $fd i32) (param $addr i32) (param $len i32)
		(if (i32.eq (local.get $fd) (i32.const 1))
			(then
				(call $stdout_write (local.get $addr) (local.get $len))
				)
			(else
				(call $stderr_write (local.get $addr) (local.get $len))
				)
			)
		)
	(func (export "fd_write") (param $fd i32) (param $iovs i32) (param $iovs_len i32) (param $out_nwritten i32) (result i32)
		(local $nwritten i32)
		;; if ($fd != 1 && $fd != 2) return WASI_ERRNO_BADF;
		(if
			(i32.and
				(i32.ne (local.get $fd) (i32.const 1))
				(i32.ne (local.get $fd) (i32.const 2))
				)
			(then
				(return (i32.const 8))
				)
			)
		(block
			(loop
				;; if ($iovs_len == 0) break;
				(br_if 1 (i32.eqz (local.get $iovs_len)))
				;; --$iovs_len
				(local.set $iovs_len (i32.sub (local.get $iovs_len) (i32.const 1)))
				;; $fd_write_aux($fd, $iovs->base, $iovs->len);
				(call $fd_write_aux
					(local.get $fd)
					(call $read_i32 (local.get $iovs))
					(call $read_i32 (i32.add (local.get $iovs) (i32.const 4)))
					)
				;; $nwritten += $iovs->len;
				(local.set $nwritten
					(i32.add
						(local.get $nwritten)
						(call $read_i32 (i32.add (local.get $iovs) (i32.const 4)))
						)
					)
				;; ++$iovs;
				(local.set $iovs (i32.add (local.get $iovs) (i32.const 8)))
				;; continue;
				(br 0)
				)
			)
		;; *$out_nwritten = $nwritten;
		(call $write_i32
			(local.get $out_nwritten)
			(local.get $nwritten)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "path_filestat_get") (param $fd i32) (param $flags i32) (param $path i32) (param $path_len i32) (param $buf i32) (result i32)
		(local $file_index i32)
		;; if ($fd != 3) return WASI_ERRNO_BADF;
		(if
			(i32.ne (local.get $fd) (i32.const 3))
			(then
				(return (i32.const 8))
				)
			)
		;; $file_index = file_name_to_index($path, $path_len);
		(local.set $file_index
			(call $file_name_to_index
				(local.get $path)
				(local.get $path_len)
				)
			)
		;; if ($file_index == -1) return WASI_ERRNO_NOENT;
		(if
			(i32.eq (local.get $file_index) (i32.const -1))
			(then
				(return (i32.const 44))
				)
			)
		;; $buf->filetype = WASI_FILETYPE_REGULAR_FILE;
		(call $write_i8
			(i32.add (local.get $buf) (i32.const 16))
			(i32.const 4)
			)
		;; $buf->size = file_size($file_index);
		(call $write_i64
			(i32.add (local.get $buf) (i32.const 32))
			(call $file_size
				(local.get $file_index)
				)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "path_open") (param $fd i32) (param $dirflags i32) (param $path i32) (param $path_len i32) (param $oflags i32) (param $fs_rights_base i64) (param $fs_rights_inheriting i64) (param $fdflags i32) (param $out_fd i32) (result i32)
		(local $file_index i32)
		;; if ($fd != 3) return WASI_ERRNO_BADF;
		(if
			(i32.ne (local.get $fd) (i32.const 3))
			(then
				(return (i32.const 8))
				)
			)
		;; $file_index = file_name_to_index($path, $path_len);
		(local.set $file_index
			(call $file_name_to_index
				(local.get $path)
				(local.get $path_len)
				)
			)
		;; if ($file_index == -1) return WASI_ERRNO_NOENT;
		(if
			(i32.eq (local.get $file_index) (i32.const -1))
			(then
				(return (i32.const 44))
				)
			)
		;; *$out_fd = 10 + $file_index;
		(call $write_i32
			(local.get $out_fd)
			(i32.add
				(i32.const 10)
				(local.get $file_index)
				)
			)
		;; return WASI_ERRNO_SUCCESS;
		(i32.const 0)
		)
	(func (export "proc_exit") (param $exit_code i32)
		;; set_exit_code($exit_code);
		(call $set_exit_code (local.get $exit_code))
		;; __trap();
		(unreachable)
		)
	)
