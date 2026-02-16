A language-agnostic WASI shim written in WebAssembly text format (WAT), using only WASM 1.0 features.

## Glue

Now, some glue code is required, at the very least to provide the shim with access to the target's memory. Have a look at [shim.wat](shim.wat)'s imports, as well as the example implementations [in Pluto](lib.pluto) and [in JavaScript](lib.js).
