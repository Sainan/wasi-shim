const shimModule = typeof window == "undefined"
	? require("node:fs/promises").readFile(require("node:path").resolve(__dirname, "shim.wasm")).then(WebAssembly.compile)
	: WebAssembly.compileStreaming(fetch(new URL("shim.wasm", document.currentScript.src)))
	;

const runWasiProgram = async (bytes, options = {}) => {
	if (!options.stderr) {
		let buf = "";
		options.stderr = (bytes) => {
			buf += new TextDecoder().decode(bytes);
			const arr = buf.split("\n");
			buf = arr.pop();
			for (let i = 0; i != arr.length; ++i) {
				console.log(arr[i]);
			}
		};
	}
	options.stdout ??= options.stderr;
	options.args ??= options.argv;
	options.args ??= [];
	options.envs ??= [];
	options.files ??= [];

	let memory, exit_code;
	const glue = {
		read_i32: (addr) => new DataView(memory.buffer).getInt32(addr, true),
		write_i8: (addr, value) => {
			new DataView(memory.buffer).setInt8(addr, value);
		},
		write_i16: (addr, value) => {
			new DataView(memory.buffer).setInt16(addr, value, true);
		},
		write_i32: (addr, value) => {
			new DataView(memory.buffer).setInt32(addr, value, true);
		},
		write_i64: (addr, value) => {
			new DataView(memory.buffer).setBigInt64(addr, value, true);
		},

		stdout_write: (addr, len) => {
			options.stdout(new Uint8Array(memory.buffer, addr, len));
		},
		stderr_write: (addr, len) => {
			options.stderr(new Uint8Array(memory.buffer, addr, len));
		},

		get_num_args: () => options.args.length,
		get_combined_args_size: () => options.args.reduce((accum, arg) => accum + new TextEncoder().encode(arg).length, 0),
		get_arg: (addr, index) => new TextEncoder().encodeInto(options.args[index], new Uint8Array(memory.buffer, addr)).written,

		get_num_envs: () => options.envs.length,
		get_combined_envs_size: () => options.envs.reduce((accum, env) => accum + new TextEncoder().encode(env).length, 0),
		get_env: (addr, index) => new TextEncoder().encodeInto(options.envs[index], new Uint8Array(memory.buffer, addr)).written,

		file_name_to_index: (path, path_len) => {
			const filename = new TextDecoder().decode(new Uint8Array(memory.buffer, path, path_len));
			return options.files.findIndex(file => file.name == filename);
		},
		file_size: (file_index) => BigInt(options.files[file_index].data.byteLength),
		file_read: (file_index, offset_i64, buf, len) => {
			const offset = Number(offset_i64);
			const src = new Uint8Array(options.files[file_index].data);
			const available = src.byteLength - offset;
			const nread = Math.min(len, available);
			const dst = new Uint8Array(memory.buffer, buf, nread);
			for (let i = 0; i != nread; ++i) {
				dst[i] = src[offset + i];
			}
			return nread;
		},

		set_exit_code: (value) => {
			exit_code = value;
		},
	};
	const shimInstance = await WebAssembly.instantiate(await shimModule, { glue });
	let programInstance;
	if (bytes instanceof Promise) {
		programInstance = (await WebAssembly.instantiateStreaming(bytes, { wasi_snapshot_preview1: shimInstance.exports })).instance;
	}
	else {
		programInstance = (await WebAssembly.instantiate(bytes, { wasi_snapshot_preview1: shimInstance.exports })).instance;
	}
	memory = programInstance.exports.memory;
	try {
		programInstance.exports._start();
	}
	catch (e) {
		if (exit_code === undefined) {
			throw e;
		}
	}
	return exit_code;
};

if (typeof window == "undefined") {
	module.exports = runWasiProgram;
}
else {
	window.runWasiProgram = runWasiProgram;
}
