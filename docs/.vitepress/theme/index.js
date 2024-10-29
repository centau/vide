// .vitepress/theme/index.js
import DefaultTheme from 'vitepress/theme'
import layout from './layout.vue'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'
import './vars.css'
import './home.css'

export default {
	extends: DefaultTheme,
	enhanceApp({ app }) {
		enhanceAppWithTabs(app)
	},
	Layout: layout
}