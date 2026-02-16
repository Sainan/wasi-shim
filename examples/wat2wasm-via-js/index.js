const fs = require("node:fs");
const path = require("node:path");
const runWasiProgram = require("../../lib.js");

let fh;
runWasiProgram(fs.readFileSync("wat2wasm"), {
	argv: [ "wat2wasm", "shim.wat", "--output=-" ],
	stdout: (bytes) => {
		if (!fh) {
			fh = fs.createWriteStream(path.resolve(__dirname, "../../shim.wasm"));
		}
		fh.write(bytes);
	},
	files: [ { name: "shim.wat", data: fs.readFileSync(path.resolve(__dirname, "../../shim.wat")) } ]
}).then(() => fh.close());
