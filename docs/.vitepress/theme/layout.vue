<!--.vitepress/theme/MyLayout.vue-->
<script setup>
import DefaultTheme from 'vitepress/theme'

const { Layout } = DefaultTheme
</script>

<template>
  <Layout>
    <template #layout-top>
      <div class="banner">
		Vide is 0.x software and may go through breaking changes through different versions
	  </div>
    </template>
  </Layout>
</template>