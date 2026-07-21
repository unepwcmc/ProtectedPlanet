export default {
	customSyntax: "postcss-html",
	extends: [
		"stylelint-config-standard",
		"stylelint-config-standard-vue",
		"stylelint-config-tailwindcss"
	],
	plugins: ["@namics/stylelint-bem"],
	rules: {
		// As of 04Jun2025 Stylelint doesn't recognise Tailwind @reference tag so we need to ignore
		"at-rule-no-unknown": [true, {
			ignoreAtRules: ["reference"]
		}],
		"function-no-unknown": null,
		"no-descending-specificity": null,
		"plugin/stylelint-bem-namics": {
			namespaces: [
				"app",
				"ct-"
			],
			patternPrefixes: [],
			helperPrefixes: []
		},
		"selector-class-pattern": null,
		"selector-pseudo-class-no-unknown": [
			true,
			{
				ignorePseudoClasses: ["deep"]
			}
		]
	}
}
