<!--
  src/pages/settings/PreferencesPage.vue — User preferences.
  Language (i18n locale), table password, diagnostics toggle, export folder,
  2FA setup/disable section.
-->
<template>
  <div class="q-pa-md">
    <div class="text-subtitle1 text-weight-bold q-mb-md">
      {{ $t('settings.tabs.preferences') }}
    </div>

    <div v-if="section.status === 'loading'" class="text-center q-pa-lg">
      <q-spinner size="2em" />
      <div class="q-mt-sm text-grey-6">{{ $t('common.loading') }}</div>
    </div>

    <template v-else>
      <div class="row q-col-gutter-md">
        <!-- Language -->
        <div class="col-12 col-sm-6">
          <q-select
            v-model="form.language"
            :options="languageOptions"
            :label="$t('settings.preferences.language')"
            emit-value
            map-options
            outlined
            dense
            @update:model-value="onLanguageChange"
          />
        </div>

        <!-- Table Password -->
        <div class="col-12 col-sm-6">
          <q-input
            v-model="form.tablePassword"
            :label="$t('settings.preferences.tablePassword')"
            outlined
            dense
            :type="showPassword ? 'text' : 'password'"
            @update:model-value="onField('tablePassword', $event)"
          >
            <template #append>
              <q-icon
                :name="showPassword ? 'visibility_off' : 'visibility'"
                class="cursor-pointer"
                @click="showPassword = !showPassword"
              />
            </template>
          </q-input>
        </div>

        <!-- Diagnostics -->
        <div class="col-12">
          <q-toggle
            v-model="form.diagnosticsEnabled"
            :label="$t('settings.preferences.diagnostics')"
            @update:model-value="onField('diagnosticsEnabled', $event)"
          />
        </div>

        <!-- Export Folder -->
        <div class="col-12 col-sm-8">
          <q-input
            v-model="form.exportFolder"
            :label="$t('settings.preferences.exportFolder')"
            outlined
            dense
            :placeholder="$t('settings.preferences.exportFolderPlaceholder')"
            @update:model-value="onField('exportFolder', $event)"
          />
        </div>
      </div>

      <q-banner v-if="section.error" class="bg-negative text-white q-mt-md" rounded>
        {{ section.error }}
      </q-banner>

      <div class="row q-mt-lg q-gutter-sm">
        <q-btn
          flat
          :label="$t('settings.revert')"
          @click="revert"
          :disable="!section.dirty"
        />
        <q-btn
          color="primary"
          :label="$t('common.save')"
          @click="save"
          :loading="section.status === 'saving'"
          :disable="!section.dirty"
        />
      </div>

      <!-- 2FA Section -->
      <q-separator class="q-my-lg" />
      <div class="text-subtitle1 text-weight-bold q-mb-md">
        {{ $t('settings.preferences.twoFactor.title') }}
      </div>

      <div class="row items-center q-gutter-md q-mb-md">
        <q-badge
          :color="twoFactorEnabled ? 'positive' : 'grey'"
          :label="twoFactorEnabled
            ? $t('settings.preferences.twoFactor.enabled')
            : $t('settings.preferences.twoFactor.disabled')"
        />
      </div>

      <template v-if="!twoFactorEnabled">
        <q-btn
          color="primary"
          unelevated
          no-caps
          :label="$t('settings.preferences.twoFactor.enable')"
          :loading="twoFactorLoading"
          @click="startSetup2fa"
        />

        <!-- 2FA Setup Dialog -->
        <q-dialog v-model="showSetupDialog" persistent>
          <q-card style="min-width: 360px">
            <q-card-section>
              <div class="text-h6">{{ $t('settings.preferences.twoFactor.setupTitle') }}</div>
            </q-card-section>
            <q-card-section>
              <!-- QR Code placeholder -->
              <div v-if="qrCodeUrl" class="text-center q-mb-md">
                <img :src="qrCodeUrl" alt="QR Code" style="width: 200px; height: 200px" />
              </div>
              <div v-else class="bg-grey-3 text-center q-pa-xl q-mb-md" style="min-height: 200px">
                {{ $t('settings.preferences.twoFactor.qrPlaceholder') }}
              </div>
              <div v-if="twoFactorSecret" class="text-caption text-grey-7 text-center q-mb-md">
                {{ $t('settings.preferences.twoFactor.manualEntry') }}: <code>{{ twoFactorSecret }}</code>
              </div>
              <q-input
                v-model="confirmCode"
                :label="$t('settings.preferences.twoFactor.confirmCode')"
                outlined
                dense
                maxlength="6"
                mask="######"
              />
              <q-banner v-if="twoFactorError" class="bg-negative text-white q-mt-sm" rounded dense>
                {{ twoFactorError }}
              </q-banner>
            </q-card-section>
            <q-card-actions align="right">
              <q-btn flat :label="$t('common.cancel')" @click="showSetupDialog = false" />
              <q-btn
                color="primary"
                unelevated
                no-caps
                :label="$t('common.confirm')"
                :loading="twoFactorLoading"
                :disable="confirmCode.length < 6"
                @click="confirmSetup2fa"
              />
            </q-card-actions>
          </q-card>
        </q-dialog>
      </template>

      <template v-else>
        <q-btn
          color="negative"
          unelevated
          no-caps
          :label="$t('settings.preferences.twoFactor.disable')"
          @click="showDisableDialog = true"
        />

        <!-- 2FA Disable Confirmation Dialog -->
        <q-dialog v-model="showDisableDialog" persistent>
          <q-card style="min-width: 360px">
            <q-card-section>
              <div class="text-h6">{{ $t('settings.preferences.twoFactor.disableTitle') }}</div>
            </q-card-section>
            <q-card-section>
              <div class="text-body2 q-mb-md">
                {{ $t('settings.preferences.twoFactor.disableWarning') }}
              </div>
              <q-input
                v-model="disableCode"
                :label="$t('settings.preferences.twoFactor.confirmCode')"
                outlined
                dense
                maxlength="6"
                mask="######"
              />
              <q-banner v-if="twoFactorError" class="bg-negative text-white q-mt-sm" rounded dense>
                {{ twoFactorError }}
              </q-banner>
            </q-card-section>
            <q-card-actions align="right">
              <q-btn flat :label="$t('common.cancel')" @click="showDisableDialog = false" />
              <q-btn
                color="negative"
                unelevated
                no-caps
                :label="$t('settings.preferences.twoFactor.disable')"
                :loading="twoFactorLoading"
                :disable="disableCode.length < 6"
                @click="handleDisable2fa"
              />
            </q-card-actions>
          </q-card>
        </q-dialog>
      </template>
    </template>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, computed, onMounted, watch } from 'vue';
import { useSettingsStore } from 'src/stores/settingsStore';
import { useAuthStore } from 'stores/authStore';
import { useI18n } from 'vue-i18n';
import * as authApi from 'src/api/auth';

const { locale } = useI18n();
const store = useSettingsStore();
const authStore = useAuthStore();
const section = store.preferences;

const showPassword = ref(false);

const languageOptions = [
  { label: '한국어', value: 'ko' },
  { label: 'English', value: 'en' },
  { label: 'Español', value: 'es' },
];

const form = reactive({
  language: 'ko',
  tablePassword: '',
  diagnosticsEnabled: false,
  exportFolder: '',
});

// 2FA state
const twoFactorEnabled = computed(() => authStore.user?.permissions?.['2fa_enabled'] === 1 || false);
const twoFactorLoading = ref(false);
const twoFactorError = ref<string | null>(null);
const showSetupDialog = ref(false);
const showDisableDialog = ref(false);
const qrCodeUrl = ref<string | null>(null);
const twoFactorSecret = ref<string | null>(null);
const confirmCode = ref('');
const disableCode = ref('');

function syncFromStore() {
  const d = section.draft;
  form.language = (d.language as string) ?? 'ko';
  form.tablePassword = (d.tablePassword as string) ?? '';
  form.diagnosticsEnabled = (d.diagnosticsEnabled as boolean) ?? false;
  form.exportFolder = (d.exportFolder as string) ?? '';
}

function onField(key: string, value: unknown) {
  store.updateField('preferences', key, value);
}

function onLanguageChange(val: string) {
  onField('language', val);
  locale.value = val;
  localStorage.setItem('lobby.locale', val);
}

function revert() {
  store.revertSection('preferences');
  syncFromStore();
  locale.value = form.language;
  localStorage.setItem('lobby.locale', form.language);
}

async function save() {
  await store.saveSection('preferences');
}

// 2FA actions
async function startSetup2fa(): Promise<void> {
  twoFactorLoading.value = true;
  twoFactorError.value = null;
  confirmCode.value = '';
  try {
    const res = await authApi.setup2fa();
    if (res.data) {
      qrCodeUrl.value = res.data.qr_code_url;
      twoFactorSecret.value = res.data.secret;
      showSetupDialog.value = true;
    } else {
      twoFactorError.value = res.error?.message ?? 'Setup failed';
    }
  } catch (err) {
    twoFactorError.value = err instanceof Error ? err.message : 'Setup failed';
  } finally {
    twoFactorLoading.value = false;
  }
}

async function confirmSetup2fa(): Promise<void> {
  twoFactorLoading.value = true;
  twoFactorError.value = null;
  try {
    const res = await authApi.confirm2fa(confirmCode.value);
    if (res.data?.enabled) {
      showSetupDialog.value = false;
      // Reload session to get updated permissions
      await authStore.loadSession();
    } else {
      twoFactorError.value = res.error?.message ?? 'Confirmation failed';
    }
  } catch (err) {
    twoFactorError.value = err instanceof Error ? err.message : 'Confirmation failed';
  } finally {
    twoFactorLoading.value = false;
  }
}

async function handleDisable2fa(): Promise<void> {
  twoFactorLoading.value = true;
  twoFactorError.value = null;
  try {
    const res = await authApi.disable2fa(disableCode.value);
    if (res.data?.disabled) {
      showDisableDialog.value = false;
      disableCode.value = '';
      await authStore.loadSession();
    } else {
      twoFactorError.value = res.error?.message ?? 'Disable failed';
    }
  } catch (err) {
    twoFactorError.value = err instanceof Error ? err.message : 'Disable failed';
  } finally {
    twoFactorLoading.value = false;
  }
}

onMounted(async () => {
  if (section.status === 'idle') {
    await store.fetchSection('preferences');
  }
  syncFromStore();
});

watch(() => section.committed, syncFromStore, { deep: true });
</script>
