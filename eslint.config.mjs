import tseslint from "typescript-eslint"
import pluginVue from "eslint-plugin-vue"
import stylistic from "@stylistic/eslint-plugin"
import globals from "globals"

export default tseslint.config(
	{
		files: ["app/frontend/**/*.ts", "app/frontend/**/*.vue"],
		extends: [
			...tseslint.configs.recommended,
			...pluginVue.configs["flat/recommended"]
		],
		languageOptions: {
			sourceType: "module",
			globals: {
				...globals.browser
			},
			parserOptions: {
				parser: tseslint.parser
			}
		},
		rules: {
			"vue/multi-word-component-names": "off",
			"vue/no-v-html": "off",
			"vue/attribute-hyphenation": "off"
		}
	},
	{
		files: ["app/frontend/**/*.ts", "app/frontend/**/*.vue"],
		...stylistic.configs.customize({
			semi: false,
			indent: 2,
			quotes: "single",
			commaDangle: "never",
			blockSpacing: true
		})
	}
)
