import { defineConfig } from "vite";

export default defineConfig({
  server: {
    // 前端程式只寫相對路徑 /api/...，由 dev server 轉給後端。
    // 這樣瀏覽器看到的永遠是同一個網址，不會遇到 CORS；後端位址只寫在這裡。
    proxy: {
      "/api": "http://localhost:8100",
    },
  },
});
