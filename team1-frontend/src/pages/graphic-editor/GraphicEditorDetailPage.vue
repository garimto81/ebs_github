<!--
  src/pages/graphic-editor/GraphicEditorDetailPage.vue — Skin metadata
  + activate/deactivate controls. The actual visual editing UX is in
  Team 4 (Flutter). This page is the Lobby-side lifecycle manager.
  Implements: metadata display/edit (Admin), rive-js preview placeholder,
  activate/deactivate lifecycle, status badge (draft/validated/active/archived).
-->
<template>
  <q-page padding>
    <q-btn
      flat
      dense
      icon="arrow_back"
      :label="$t('common.back')"
      class="q-mb-md"
      @click="router.back()"
    />

    <LoadingState v-if="loading" />
    <template v-else-if="skin">
      <div class="row q-col-gutter-md">
        <!-- Left column: Preview + Status -->
        <div class="col-12 col-md-5">
          <!-- Rive Preview placeholder -->
          <q-card flat bordered class="q-mb-md">
            <q-card-section class="text-subtitle2 text-weight-bold">
              {{ $t('graphicEditor.preview') }}
            </q-card-section>
            <q-separator />
            <div class="bg-grey-3 text-center q-pa-xl" style="min-height: 200px">
              Rive Preview
            </div>
          </q-card>

          <!-- Status + Actions -->
          <q-card flat bordered>
            <q-card-section>
              <div class="row items-center q-gutter-sm q-mb-md">
                <div class="text-subtitle2 text-weight-bold">
                  {{ $t('graphicEditor.status') }}
                </div>
                <q-badge
                  :color="statusColor(skin.status)"
                  :label="skin.status"
                />
              </div>

              <div class="text-caption text-grey-7 q-mb-xs">
                {{ $t('graphicEditor.version') }}: v{{ skin.version }}
              </div>
              <div class="text-caption text-grey-7 q-mb-xs">
                {{ $t('graphicEditor.fileSize') }}: {{ formatFileSize(skin.file_size) }}
              </div>
              <div class="text-caption text-grey-7 q-mb-xs">
                {{ $t('graphicEditor.uploadedAt') }}: {{ skin.uploaded_at }}
              </div>
              <div v-if="skin.activated_at" class="text-caption text-grey-7">
                {{ $t('graphicEditor.activatedAt') }}: {{ skin.activated_at }}
              </div>
            </q-card-section>

            <q-card-actions
              v-if="canWrite"
              align="left"
            >
              <q-btn
                v-if="skin.status !== 'active'"
                color="positive"
                unelevated
                no-caps
                :label="$t('graphicEditor.activate')"
                :loading="activating"
                @click="handleActivate"
              />
              <q-btn
                v-if="skin.status === 'active'"
                color="warning"
                unelevated
                no-caps
                :label="$t('graphicEditor.deactivate')"
                :loading="activating"
                @click="handleDeactivate"
              />
            </q-card-actions>
          </q-card>
        </div>

        <!-- Right column: Metadata -->
        <div class="col-12 col-md-7">
          <q-card flat bordered>
            <q-card-section class="text-subtitle2 text-weight-bold">
              {{ $t('graphicEditor.metadata') }}
            </q-card-section>
            <q-separator />
            <q-card-section>
              <!-- Read-only mode -->
              <template v-if="!editing">
                <div class="q-mb-md">
                  <div class="text-caption text-grey-7">{{ $t('graphicEditor.metaTitle') }}</div>
                  <div class="text-body1">{{ skin.metadata.title || skin.name }}</div>
                </div>
                <div class="q-mb-md">
                  <div class="text-caption text-grey-7">{{ $t('graphicEditor.metaDescription') }}</div>
                  <div class="text-body2">{{ skin.metadata.description || '—' }}</div>
                </div>
                <div class="q-mb-md">
                  <div class="text-caption text-grey-7">{{ $t('graphicEditor.metaAuthor') }}</div>
                  <div class="text-body2">{{ skin.metadata.author || '—' }}</div>
                </div>
                <div>
                  <div class="text-caption text-grey-7">{{ $t('graphicEditor.metaTags') }}</div>
                  <div v-if="skin.metadata.tags.length > 0" class="row q-gutter-xs q-mt-xs">
                    <q-chip
                      v-for="tag in skin.metadata.tags"
                      :key="tag"
                      dense
                      color="blue-1"
                      text-color="primary"
                      :label="tag"
                    />
                  </div>
                  <div v-else class="text-body2">—</div>
                </div>
              </template>

              <!-- Edit mode (Admin only) -->
              <template v-else>
                <q-input
                  v-model="draft.title"
                  :label="$t('graphicEditor.metaTitle')"
                  outlined
                  dense
                  class="q-mb-md"
                />
                <q-input
                  v-model="draft.description"
                  :label="$t('graphicEditor.metaDescription')"
                  outlined
                  dense
                  type="textarea"
                  autogrow
                  class="q-mb-md"
                />
                <q-input
                  v-model="draft.author"
                  :label="$t('graphicEditor.metaAuthor')"
                  outlined
                  dense
                  class="q-mb-md"
                />
                <q-select
                  v-model="draft.tags"
                  :label="$t('graphicEditor.metaTags')"
                  outlined
                  dense
                  multiple
                  use-chips
                  use-input
                  new-value-mode="add-unique"
                  :hint="$t('graphicEditor.tagsHint')"
                />
              </template>
            </q-card-section>

            <q-card-actions v-if="canWrite" align="right">
              <template v-if="!editing">
                <q-btn
                  flat
                  no-caps
                  icon="edit"
                  :label="$t('common.edit')"
                  @click="startEdit"
                />
              </template>
              <template v-else>
                <q-btn
                  flat
                  no-caps
                  :label="$t('common.cancel')"
                  @click="cancelEdit"
                />
                <q-btn
                  color="primary"
                  unelevated
                  no-caps
                  :label="$t('common.save')"
                  :loading="saving"
                  @click="saveMetadata"
                />
              </template>
            </q-card-actions>
          </q-card>
        </div>
      </div>
    </template>
  </q-page>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import LoadingState from 'components/common/LoadingState.vue';
import * as skinsApi from 'src/api/skins';
import type { Skin, SkinStatus, SkinMetadata } from 'src/types/entities';

const props = defineProps<{ skinId: string }>();

const router = useRouter();
const authStore = useAuthStore();
const skin = ref<Skin | null>(null);
const loading = ref(true);
const editing = ref(false);
const saving = ref(false);
const activating = ref(false);

const canWrite = computed(() => authStore.hasPermission('GraphicEditor', 'Write'));

const draft = reactive<SkinMetadata>({
  title: '',
  description: '',
  author: null,
  tags: [],
});

onMounted(async () => {
  try {
    const res = await skinsApi.getById(Number(props.skinId));
    if (res.data) skin.value = res.data;
  } finally {
    loading.value = false;
  }
});

function statusColor(s: SkinStatus): string {
  switch (s) {
    case 'active': return 'positive';
    case 'validated': return 'info';
    case 'archived': return 'grey';
    default: return 'warning';
  }
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function startEdit(): void {
  if (!skin.value) return;
  draft.title = skin.value.metadata.title;
  draft.description = skin.value.metadata.description;
  draft.author = skin.value.metadata.author;
  draft.tags = [...skin.value.metadata.tags];
  editing.value = true;
}

function cancelEdit(): void {
  editing.value = false;
}

async function saveMetadata(): Promise<void> {
  if (!skin.value) return;
  saving.value = true;
  try {
    const res = await skinsApi.updateMetadata(Number(props.skinId), { ...draft });
    if (res.data) {
      skin.value = res.data;
      editing.value = false;
    }
  } finally {
    saving.value = false;
  }
}

async function handleActivate(): Promise<void> {
  activating.value = true;
  try {
    const res = await skinsApi.activate(Number(props.skinId));
    if (res.data) skin.value = res.data;
  } finally {
    activating.value = false;
  }
}

async function handleDeactivate(): Promise<void> {
  activating.value = true;
  try {
    const res = await skinsApi.deactivate(Number(props.skinId));
    if (res.data) skin.value = res.data;
  } finally {
    activating.value = false;
  }
}
</script>
