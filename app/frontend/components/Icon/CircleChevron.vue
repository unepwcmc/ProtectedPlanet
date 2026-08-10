<template>
  <i class="ct-icon-circle-chevron">
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 34 34"
    >
      <circle
        cx="17"
        cy="17"
        r="17"
        class="ct-icon-circle-chevron__circle"
      />
      <path
        d="M7.712,6.307,1.678.287A.982.982,0,0,0,.288,1.674L5.627,7,.288,12.326a.982.982,0,0,0,1.39,1.386l6.034-6.02a.979.979,0,0,0,0-1.386Z"
        transform="translate(14 10)"
        class="ct-icon-circle-chevron__arrow"
      />
    </svg>
  </i>
</template>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-icon-circle-chevron__circle {
  @apply fill-theme-grey-black;
}

.ct-icon-circle-chevron__arrow {
  @apply fill-white;
}
</style>
