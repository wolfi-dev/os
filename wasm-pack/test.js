const fs = require('fs');
const path = require('path');
const wasmFile = path.join(__dirname, 'pkg', 'wasm_pack_test_bg.wasm');
const wasmModule = path.join(__dirname, 'pkg', 'wasm_pack_test.js');

(async () => {
    const wasm = await import(wasmModule);
    const result = wasm.greet();
    console.log(result);
    if (result === 'Hello, wasm-pack!') {
        console.log('Test passed: wasm-pack is working correctly');
    } else {
        console.error('Test failed: unexpected result from WebAssembly module');
        process.exit(1);
    }
})();