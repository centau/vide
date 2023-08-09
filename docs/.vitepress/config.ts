import { defineConfig } from "vitepress"

// https://vitepress.dev/reference/site-config
export default defineConfig({
    title: "Vide",
    description: "A declarative and reactive library for Luau.",
    base: "/vide/",
    head: [["link", { rel: "icon", href: "/vide/logo.svg" }]],

    themeConfig: {
        logo: "/logo.svg",

        // https://vitepress.dev/reference/default-theme-config
        nav: [
            { text: "Home", link: "/" },
            { text: "Tutorials", link: "/tut/crash-course/1-introduction" },
            { text: "API", link: "/api/reactivity-core"},
            { text: "GitHub", link: "https://github.com/centau/vide" }
        ],

        sidebar: {
            "/api/": [
                {
                    text: "API",
                    items: [
                        { text: "Reactivity: Core", link: "/api/reactivity-core" },
                        { text: "Reactivity: Utility", link: "/api/reactivity-utility" },
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
                        { text: "Source", link: "/tut/crash-course/4-source" },
                        { text: "Derived Source", link: "/tut/crash-course/5-derived-source" },
                        { text: "Table Source", link: "/tut/crash-course/6-table-source" },
                        { text: "Property Groups", link: "/tut/crash-course/7-property-groups" },
                    ]
                },
                {
                    text: "Tutorials",
                    items: [
                        { text: "Crash Course", link: "/tut/crash-course/index" },
                    ]
                }
            ],
        }

        // socialLinks: [
        //     { icon: "github", link: "https://github.com/centau/vide" }
        // ]
    }
})
