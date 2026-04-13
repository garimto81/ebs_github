// src/i18n/index.ts — vue-i18n locale registry
// Default: ko. Fallback: ko. See boot/i18n.ts for locale detection.

import ko from './ko.json';
import en from './en.json';
import es from './es.json';

export default {
  ko,
  en,
  es,
} as const;
