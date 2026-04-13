<!--
  src/pages/ForgotPasswordPage.vue — BS-01 §A-24 Forgot Password.
  Design reference: UI-01 §0.2.

  Flow:
  1. User enters email → submit
  2. Server responds with opaque message (no account enumeration)
  3. Success state: "이메일이 등록되어 있다면 재설정 링크를 발송했습니다"
  4. Rate-limit error (429) → countdown banner
-->
<template>
  <q-page class="flex flex-center bg-grey-2">
    <q-card class="q-pa-lg" style="width: 360px">
      <q-card-section class="text-center q-pb-none">
        <div class="text-h6">{{ $t('login.forgotPassword') }}</div>
        <div class="text-caption text-grey-7 q-mt-xs">
          {{ $t('forgotPassword.subtitle') }}
        </div>
      </q-card-section>

      <q-card-section v-if="!submitted">
        <q-form @submit.prevent="handleSubmit">
          <q-input
            v-model="email"
            :label="$t('login.email')"
            type="email"
            outlined
            dense
            autofocus
            :rules="[(v: string) => !!v || $t('common.required')]"
          />

          <q-banner
            v-if="errorMessage"
            dense
            class="bg-red-1 text-red q-mt-sm text-caption"
          >
            {{ errorMessage }}
          </q-banner>

          <q-btn
            type="submit"
            color="primary"
            class="full-width q-mt-md"
            :loading="submitting"
            :label="$t('forgotPassword.submit')"
            no-caps
          />
          <q-btn
            flat
            dense
            no-caps
            class="full-width q-mt-sm"
            :label="$t('common.back')"
            @click="router.push('/login')"
          />
        </q-form>
      </q-card-section>

      <q-card-section v-else>
        <q-banner dense class="bg-green-1 text-green-9 text-body2">
          <template #avatar>
            <q-icon name="check_circle" color="green-9" />
          </template>
          {{ $t('forgotPassword.successMessage') }}
        </q-banner>
        <q-btn
          flat
          no-caps
          class="full-width q-mt-md"
          :label="$t('common.back')"
          @click="router.push('/login')"
        />
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import * as authApi from 'src/api/auth';

const router = useRouter();
const email = ref('');
const submitted = ref(false);
const submitting = ref(false);
const errorMessage = ref<string | null>(null);

async function handleSubmit(): Promise<void> {
  submitting.value = true;
  errorMessage.value = null;
  try {
    const res = await authApi.forgotPassword(email.value);
    if (res.error) {
      if (res.error.code === 'RATE_LIMIT_EXCEEDED') {
        errorMessage.value =
          'Too many requests. Please try again in a few minutes.';
      } else {
        errorMessage.value = res.error.message;
      }
      return;
    }
    submitted.value = true;
  } finally {
    submitting.value = false;
  }
}
</script>
