<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 29 29"
    fill="currentColor"
  >
    <circle
      class="ct-icon-circle-close__circle"
      cx="14.5"
      cy="14.5"
      r="14.5"
    />
    <path
      class="ct-icon-circle-close__cross"
      d="M6.807,5.5l3.922-3.922A.924.924,0,0,0,9.422.271L5.5,4.193,1.578.271A.924.924,0,0,0,.271,1.578L4.193,5.5.271,9.422a.924.924,0,0,0,1.307,1.307L5.5,6.807l3.922,3.922a.924.924,0,1,0,1.307-1.307Z"
      transform="translate(9 9)"
    />
  </svg>
</template>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-icon-circle-close__circle {
  @apply opacity-20;
}
</style>
