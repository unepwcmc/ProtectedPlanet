<!-- Used for region -->
<template>
  <div class="card--feault-block sm-sources pdf-break-inside-avoid">
    <h2 class="card__h2">{{ title }} {{ count }}</h2>
    
    <div class="card__content flex">
      <ol class="list--underline-sources">
        <li 
          class="list__li"
          v-for="(source, i) in sources"
          :key="i"
        >
          <span class="list__title">{{ source.title }}</span>
          <span class="list__date">{{ sourceUpdated }}: {{ source.date_updated }}</span>
          <span class="list__party">{{ source.resp_party }}</span>
        </li>
      </ol>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatsSources',

  props: {
    count: {
      required: true,
      type: Number
    },
    sources: {
      required: true,
      type: Array
    },
    sourceUpdated: {
      required: true,
      type: String
    },
    title: {
      required: true,
      type: String
    }
  }
}
</script>