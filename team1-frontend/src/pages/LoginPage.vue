<!--
  src/pages/LoginPage.vue — BS-01-auth login + 2FA + session restore.
  Design reference: UI-01 §0 (Login), §0.1 (2FA TOTP), §0.3 (Session Restore Dialog).

  Flow:
  1. Mount → tryRestoreSession() (refresh-token cookie path)
     - success + lastContext → show Session Restore Dialog
     - success no context → redirect /series
     - failure → render login form
  2. Submit email/password → authStore.login()
     - requires2fa=true → switch to TOTP step (§0.1)
     - success → same dialog/redirect logic as §1
  3. TOTP 6-digit → authStore.verify2fa()
  4. Forgot Password link → /forgot-password (§0.2)
-->
<template>
  <q-page class="login-page flex flex-center bg-grey-2">
    <q-inner-loading :showing="checking">
      <q-spinner-gears size="48px" color="primary" />
    </q-inner-loading>

    <q-card v-if="!checking" class="login-card q-pa-lg" style="width: 360px">
      <q-card-section class="text-center q-pb-none">
        <div class="text-h5 text-weight-bold">{{ $t('login.title') }}</div>
        <div class="text-caption text-grey-7">
          {{ $t('login.subtitle') }}
        </div>
      </q-card-section>

      <!-- Step 1: Email + Password -->
      <q-card-section v-if="step === 'credentials'">
        <q-form @submit.prevent="handleLogin">
          <q-input
            v-model="email"
            :label="$t('login.email')"
            type="email"
            outlined
            dense
            autofocus
            :rules="[(v: string) => !!v || $t('common.required')]"
            class="q-mb-sm"
          />
          <q-input
            v-model="password"
            :label="$t('login.password')"
            :type="showPassword ? 'text' : 'password'"
            outlined
            dense
            :rules="[(v: string) => !!v || $t('common.required')]"
          >
            <template #append>
              <q-icon
                :name="showPassword ? 'visibility_off' : 'visibility'"
                class="cursor-pointer"
                @click="showPassword = !showPassword"
              />
            </template>
          </q-input>

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
            :label="$t('login.submit')"
            no-caps
          />

          <div class="row items-center q-my-md">
            <q-separator class="col" />
            <span class="q-mx-sm text-grey">{{ $t('login.or') }}</span>
            <q-separator class="col" />
          </div>

          <q-btn
            outline
            class="full-width"
            no-caps
            @click="handleGoogleLogin"
          >
            <q-icon name="login" class="q-mr-sm" />
            {{ $t('login.googleLogin') }}
          </q-btn>

          <div class="text-right q-mt-sm">
            <q-btn
              flat
              dense
              no-caps
              color="primary"
              size="sm"
              :label="$t('login.forgotPassword')"
              @click="router.push('/forgot-password')"
            />
          </div>
        </q-form>
      </q-card-section>

      <!-- Step 2: TOTP (BS-01 §A-18, UI-01 §0.1) -->
      <q-card-section v-else-if="step === 'totp'">
        <q-form @submit.prevent="handleVerify2fa">
          <div class="text-body2 q-mb-sm">
            {{ $t('login.twoFactorPrompt') }}
          </div>
          <q-input
            v-model="totpCode"
            :label="$t('login.twoFactor')"
            mask="######"
            outlined
            dense
            autofocus
            input-class="text-center text-h6 letter-spacing-wide"
            :rules="[
              (v: string) =>
                /^\d{6}$/.test(v) || $t('login.errors.twoFactorInvalid'),
            ]"
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
            :label="$t('login.verify')"
            no-caps
          />
          <q-btn
            flat
            dense
            no-caps
            class="full-width q-mt-sm"
            :label="$t('common.back')"
            @click="backToCredentials"
          />
        </q-form>
      </q-card-section>
    </q-card>

    <!-- Session Restore Dialog (UI-01 §0.3, §9.6) -->
    <q-dialog v-model="restoreDialogOpen" persistent>
      <q-card style="min-width: 320px">
        <q-card-section>
          <div class="text-h6">{{ $t('login.restorePrompt') }}</div>
          <div v-if="restoreContext" class="text-body2 q-mt-sm text-grey-8">
            {{ $t('login.restoreTable') }}
            <strong>#{{ restoreContext.tableId }}</strong>
          </div>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn
            flat
            no-caps
            color="grey-8"
            :label="$t('login.restoreFresh')"
            @click="freshStart"
          />
          <q-btn
            unelevated
            no-caps
            color="primary"
            :label="$t('login.restoreContinue')"
            @click="restoreContinue"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { getGoogleLoginUrl } from 'src/api/auth';

type Step = 'credentials' | 'totp';

const router = useRouter();
const authStore = useAuthStore();

const checking = ref(true);
const step = ref<Step>('credentials');
const email = ref('');
const password = ref('');
const showPassword = ref(false);
const totpCode = ref('');
const submitting = ref(false);
const errorMessage = ref<string | null>(null);

const restoreDialogOpen = ref(false);
const restoreContext = ref<{ tableId: number; flightId: number } | null>(
  null,
);

onMounted(async () => {
  // GAP-L-005 / UI-01 §0.3: attempt silent session restore on boot.
  try {
    const restored = await authStore.tryRestoreSession();
    if (restored) {
      resolvePostLogin();
      return;
    }
  } catch {
    // fall through to login form
  }
  checking.value = false;
});

function resolvePostLogin(): void {
  const nav = authStore.navigation;
  if (nav?.last_table_id && nav?.last_flight_id) {
    restoreContext.value = {
      tableId: nav.last_table_id,
      flightId: nav.last_flight_id,
    };
    restoreDialogOpen.value = true;
    checking.value = false;
  } else {
    void router.replace('/series');
  }
}

async function handleLogin(): Promise<void> {
  submitting.value = true;
  errorMessage.value = null;
  try {
    const result = await authStore.login(email.value, password.value);
    if (result.success) {
      resolvePostLogin();
      return;
    }
    if (result.requires2fa) {
      step.value = 'totp';
      return;
    }
    errorMessage.value = result.errorMessage ?? 'Login failed';
  } finally {
    submitting.value = false;
  }
}

async function handleVerify2fa(): Promise<void> {
  submitting.value = true;
  errorMessage.value = null;
  try {
    const result = await authStore.verify2fa(totpCode.value);
    if (result.success) {
      resolvePostLogin();
      return;
    }
    errorMessage.value = ('errorMessage' in result ? result.errorMessage : null) ?? '2FA verification failed';
  } finally {
    submitting.value = false;
  }
}

function backToCredentials(): void {
  step.value = 'credentials';
  totpCode.value = '';
  errorMessage.value = null;
}

function restoreContinue(): void {
  if (!restoreContext.value) return;
  void router.replace(
    `/flights/${restoreContext.value.flightId}/tables`,
  );
}

function freshStart(): void {
  void router.replace('/series');
}

function handleGoogleLogin(): void {
  window.location.href = getGoogleLoginUrl();
}
</script>

<style scoped>
.letter-spacing-wide {
  letter-spacing: 8px;
}
</style>
