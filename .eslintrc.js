module.exports = {
	'env': {
		'browser': true,
    'es6': true,
    'node': true
	},
	'extends': [
		'eslint:recommended',
		'plugin:vue/recommended'
	],
	'globals': {
		'Atomics': 'readonly',
		'SharedArrayBuffer': 'readonly'
	},
	'parserOptions': {
		'ecmaVersion': 2018,
		'sourceType': 'module'
	},
	'plugins': [
		'vue'
	],
	'rules': {
		'indent': [
			'error',
			2
		],
		'linebreak-style': [
			'error',
			'unix'
		],
		'quotes': [
			'error',
			'single'
		],
		'semi': [
			'error',
			'never'
    ],
    'padding-line-between-statements': [
      'error',
      { 'blankLine': 'always', 'prev': '*', 'next': 'return' },
      { 'blankLine': 'always', 'prev': ['const', 'let', 'var'], 'next': '*' },
      { 'blankLine': 'any', 'prev': ['const', 'let', 'var'], 'next': ['const', 'let', 'var'] }
    ],
    'no-console': 'off'
	}
}