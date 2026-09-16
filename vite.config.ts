import { defineConfig } from 'vite';
 
export default defineConfig({
    // Some older CommonJS packages (e.g. 3d-view-controls, stats-js) reference
    // Node's `global` object. Webpack used to polyfill this automatically;
    // Vite doesn't, so we alias it to the browser's `globalThis` ourselves.
    define: {
        global: 'globalThis',
    },
    // Relative base so the built site works regardless of the repo name
    // it's published under on GitHub Pages (https://username.github.io/repo-name/).
    base: './',
    server: {
        port: 5660,
        open: false,
        watch: {
            ignored: ['**/.vs/**'],
        }
    },
    build: {
        outDir: 'dist',
        emptyOutDir: true,
    },
});
 
