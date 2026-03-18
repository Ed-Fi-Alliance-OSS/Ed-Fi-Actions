import js from '@eslint/js';
import globals from 'globals';

export default [
  js.configs.recommended,
  {
    plugins: {
    },
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    rules: {
    },
    ignores: [
      'dist/**',
      'node_modules/**',
    ]
  },
];
