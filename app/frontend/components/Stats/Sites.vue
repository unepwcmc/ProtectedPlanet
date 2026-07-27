<template>
  <div>
    <div class="flex flex-v-center flex-h-between">
      <h2 v-text="title" />
      <a
        class="margin-space--left button--all"
        :href="viewAll"
        :title="textViewAll"
        v-text="textViewAll"
      />
    </div>

    <div class="cards--search-results-areas preview">
      <a
        v-for="(siteDetail, i) in siteDetails"
        :key="i"
        class="card__link"
        :href="`/${siteDetail.site_id}`"
        :title="`View more about the site: ${siteDetail.name}`"
      >
        <div class="card__image-placeholder">
          <div
            class="card__image"
            :style="{ backgroundImage: `url(${siteDetail.thumbnail_link})` }"
          />
        </div>

        <div class="card__content">
          <h3
            class="card__title"
            v-text="siteDetail.name"
          />
        </div>
      </a>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { StatsSitesProps } from '@/types/backend'

type StatsSites = StatsSitesProps
defineProps<StatsSites>()
</script>
