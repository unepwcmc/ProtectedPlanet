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
			ignoreAtRules: ["reference","apply"]
		}],
		// stylelint-config-tailwindcss@1.0.1 (the latest release) only patches
		// at-rule-no-unknown/function-no-unknown, not this rule, so every `@apply`
		// utility list is flagged as an invalid prelude without this override.
		"at-rule-prelude-no-invalid": [true, {
			ignoreAtRules: ["apply"]
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
