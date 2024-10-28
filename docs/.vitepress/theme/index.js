// .vitepress/theme/index.js
import DefaultTheme from 'vitepress/theme'
import layout from './layout.vue'
import './vars.css'

export default {
	extends: DefaultTheme,
	Layout: layout
}