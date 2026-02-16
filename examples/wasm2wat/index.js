const fs = require("node:fs");
const path = require("node:path");
const runWasiProgram = require("../../lib.js");

runWasiProgram(fs.readFileSync("wasm2wat.wasm"), {
	argv: [ "wasm2wat", "shim.wasm" ],
	files: [ { name: "shim.wasm", data: fs.readFileSync(path.resolve(__dirname, "../../shim.wasm")) } ],
});
