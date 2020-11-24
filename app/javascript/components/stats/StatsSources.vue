<template>
  <div class="card--stats-sources sm-sources pdf-break-inside-avoid">
    <h2 class="card__h2">{{ data.title }} {{ data.count }}</h2>
    
    <div class="card__content flex">
      <ol class="list--underline-sources">
        <li 
          class="list__li"
          v-for="(source, i) in data.sources"
          :key="i"
        >
          <span class="list__title">{{ source.title }}</span>
          <span class="list__date">{{ data.source_updated }}: {{ source.date_updated }}</span>
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
    data: {
      required: true,
      type: Object
    }
  }
}
</script>