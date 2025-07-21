import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    base: '/ui/',
    server: {
        port: 3000,
        proxy: {
            '/service-a': {
                target: 'http://localhost:80',
                changeOrigin: true,
                secure: false,
            },
            '/service-b': {
                target: 'http://localhost:80',
                changeOrigin: true,
                secure: false,
            }
        }
    },
    preview: {
        port: 3001,
        host: '0.0.0.0',
        proxy: {
            '/service-a': {
                target: 'http://localhost:80',
                changeOrigin: true,
                secure: false,
            },
            '/service-b': {
                target: 'http://localhost:80',
                changeOrigin: true,
                secure: false,
            }
        }
    },
    build: {
        outDir: 'dist',
        assetsDir: 'assets',
    }
}) 