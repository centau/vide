//import { defineConfig } from "vitepress"
import { withMermaid } from "vitepress-plugin-mermaid";

// https://vitepress.dev/reference/site-config
export default withMermaid({
    title: "Vide",
    titleTemplate: ":title - A reactive UI library for Luau",
    description: "A reactive UI library for Luau.",
    base: "/vide/",
    head: [["link", { rel: "icon", href: "/vide/logo.svg" }]],

    themeConfig: {
        logo: "/logo.svg",

        search: {
            provider: "local"
        },

        footer: {
            message: 'Released under the MIT License.',
        },

        // https://vitepress.dev/reference/default-theme-config
        nav: [
            { text: "Home", link: "/" },
            { text: "Tutorials", link: "/tut/crash-course/1-introduction" },
            { text: "API", link: "/api/reactivity-core"},
        ],

        sidebar: {
            "/api/": [
                {
                    text: "API",
                    items: [
                        { text: "Reactivity: Core", link: "/api/reactivity-core" },
                        { text: "Reactivity: Utility", link: "/api/reactivity-utility" },
                        { text: "Reactivity: Dynamic Scoping", link: "/api/reactivity-dynamic" },
                        { text: "Element Creation", link: "/api/creation" },
                        { text: "Animation", link: "/api/animation" },
                        { text: "Strict Mode", link: "/api/strict-mode" },
                    ]
                }
            ],

            "/tut/": [
                {
                    text: "Crash Course",
                    items: [
                        { text: "Introduction", link: "/tut/crash-course/1-introduction" },
                        { text: "Element Creation", link: "/tut/crash-course/2-creation" },
                        { text: "Components", link: "/tut/crash-course/3-components" },
                        { text: "Sources", link: "/tut/crash-course/4-source" },
                        { text: "Effects", link: "/tut/crash-course/5-effect" },
                        { text: "Scopes", link: "/tut/crash-course/6-scope" },
                        { text: "Reactive Components", link: "/tut/crash-course/7-reactive-component" },
                        { text: "Implicit Effects", link: "/tut/crash-course/8-implicit-effect" },
                        { text: "Derived Sources", link: "/tut/crash-course/9-derived-source" },
                        { text: "Cleanup", link: "/tut/crash-course/10-cleanup" },
                        { text: "Dynamic Scoping", link: "/tut/crash-course/11-dynamic-scope" },
                        { text: "Actions", link: "/tut/crash-course/12-actions" },
                        { text: "Strict Mode", link: "/tut/crash-course/13-strict-mode" },
                        { text: "Concepts Summary", link: "/tut/crash-course/14-concepts" }
                    ]
                },
                {
                    text: "Dynamic Scoping",
                    items: [
                        { text: "Custom Scopes", link: "/tut/advanced/custom"}
                    ]
                },
                {
                    text: "Design Patterns",
                    items: [
                    ]
                }
            ],
        },

        socialLinks: [
            { icon: "github", link: "https://github.com/centau/vide" }
        ]
    }
})
