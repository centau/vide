import { defineConfig } from "vitepress"

// https://vitepress.dev/reference/site-config
export default defineConfig({
    title: "Vide",
    titleTemplate: ":title - A reactive UI library for Luau",
    description: "A reactive UI library for Luau.",
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
                        { text: "Reactivity: Control Flow", link: "/api/reactivity-flow" },
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
                        { text: "Stateful Components", link: "/tut/crash-course/6-stateful-component" },
                        { text: "Property Binding", link: "/tut/crash-course/7-property-binding" },
                        { text: "Cleanup", link: "/tut/crash-course/8-cleanup" },
                        { text: "Control Flow", link: "/tut/crash-course/9-control-flow" },
                        { text: "Property Nesting", link: "/tut/crash-course/10-property-nesting" },
                        { text: "Actions", link: "/tut/crash-course/11-actions" },
                        { text: "Strict Mode", link: "/tut/crash-course/12-strict-mode" },
                    ]
                },
                {
                    text: "Control Flow WIP",
                    items: [
                        { text: "switch", link: "/tut/control-flow/switch.md" },
                        { text: "indexes", link: "/tut/control-flow/indexes.md" },
                        { text: "values", link: "/tut/control-flow/values.md" },
                    ]
                },
                {
                    text: "Advanced Reactivity WIP",
                    items: [
                        { text: "reactive-scopes", link: "/tut/reactive-scoping.md"}
                    ]
                }
            ],
        }

        // socialLinks: [
        //     { icon: "github", link: "https://github.com/centau/vide" }
        // ]
    }
})
