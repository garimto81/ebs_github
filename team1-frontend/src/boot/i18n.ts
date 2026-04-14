// src/boot/i18n.ts — vue-i18n 9.x setup
// Locales: ko (default), en (Vegas), es (Vegas sub). UI-A1 §7.

import { defineBoot } from '#q-app/wrappers';
import { createI18n } from 'vue-i18n';
import messages from 'src/i18n';

export type MessageLanguages = keyof typeof messages;
export type MessageSchema = (typeof messages)['ko'];

// Locale detection: localStorage > navigator.language > 'ko'
function detectLocale(): MessageLanguages {
  const saved = typeof localStorage !== 'undefined' ? localStorage.getItem('lobby.locale') : null;
  if (saved && saved in messages) return saved as MessageLanguages;

  const nav = typeof navigator !== 'undefined' ? navigator.language.slice(0, 2) : 'ko';
  if (nav in messages) return nav as MessageLanguages;

  return 'ko';
}

export default defineBoot(({ app }) => {
  const i18n = createI18n<{ message: MessageSchema }, MessageLanguages>({
    locale: detectLocale(),
    fallbackLocale: 'ko',
    legacy: false,
    globalInjection: true,
    messages,
  });

  app.use(i18n);
});
