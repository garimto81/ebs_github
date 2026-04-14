// ESLint v9 Flat Config for Team 1 Frontend (Quasar 2 + Vue 3 + TypeScript)
// Initial migration — permissive rules (mostly warnings) to unblock Phase 0.4 gate.
// Tighten progressively as the codebase stabilises.

import js from '@eslint/js'
import pluginVue from 'eslint-plugin-vue'
import vueTsEslintConfig from '@vue/eslint-config-typescript'

export default [
  {
    ignores: [
      'dist/**',
      '.quasar/**',
      'node_modules/**',
      'coverage/**',
      'playwright-report/**',
      'test-results/**',
      'src-ssr/**',
      'src-capacitor/**',
      'src-cordova/**',
      '**/*.d.ts',
      'quasar.config.*.temporary.compiled*',
    ],
  },

  js.configs.recommended,
  ...pluginVue.configs['flat/recommended'],
  ...vueTsEslintConfig(),

  {
    languageOptions: {
      globals: {
        process: 'readonly',
        ga: 'readonly',
        cordova: 'readonly',
        __statics: 'readonly',
        __QUASAR_SSR__: 'readonly',
        __QUASAR_SSR_SERVER__: 'readonly',
        __QUASAR_SSR_CLIENT__: 'readonly',
        __QUASAR_SSR_PWA__: 'readonly',
      },
    },
    rules: {
      'vue/multi-word-component-names': 'off',
      'vue/no-v-html': 'warn',
      '@typescript-eslint/no-unused-vars': [
        'warn',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-non-null-assertion': 'off',
      'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
      'no-debugger': 'error',
      'prefer-const': 'warn',
    },
  },

  // Node / CommonJS config and tooling scripts
  {
    files: [
      'quasar.config.js',
      'playwright.config.ts',
      'vitest.config.ts',
      'postcss.config.cjs',
      'eslint.config.js',
      'qa/**/*.js',
      'specs/**/*.js',
      'scripts/**/*.js',
    ],
    languageOptions: {
      globals: {
        module: 'readonly',
        require: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
      },
    },
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-var-requires': 'off',
      'no-undef': 'off',
      'no-console': 'off',
    },
  },

  // Test files — relax more rules
  {
    files: ['**/*.test.ts', '**/*.spec.ts', 'e2e/**/*.ts', 'test/**/*.ts'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      'no-console': 'off',
    },
  },
]
