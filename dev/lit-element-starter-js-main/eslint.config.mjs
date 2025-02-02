import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [{
    ignores: [
        "node_modules/*",
        "**/rollup-config.js",
        "**/custom-elements.json",
        "**/web-dev-server.config.js",
    ],
}, ...compat.extends("eslint:recommended"), {
    languageOptions: {
        globals: {
            ...globals.browser,
            ...globals.mocha,
            chai: "readonly",
            "SendNewMessageEvent": "readonly",
        },

        //parser: babelParser,
        ecmaVersion: 5,
        sourceType: "script",

        parserOptions: {
            requireConfigFile: false,
        },
    },
    files: ["dev/**/*"],

    rules: {
        semi: "error",
        "no-unexpected-multiline": "off",
    },
}, {
    files: ["**/rollup.config.js", "**/web-test-runner.config.js"],

    languageOptions: {
        globals: {
            ...globals.node,
        },
    },
}];