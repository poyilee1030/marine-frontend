# marine-frontend

給 drone 容器開發者「功能做完後手動測試」用的極簡網頁：一張地圖、幾個點、兩顆按鈕。
純 TypeScript + DOM，不用任何 UI 框架。後端是 [`marine-backend-py`](https://github.com/poyilee1030/marine-backend-py)（FastAPI，:8100）。

計畫與規則見 [ROADMAP.md](ROADMAP.md)；每個 step 的量測數字見 [docs/baseline.md](docs/baseline.md)。

## 進度

| Step | 內容 | 狀態 |
|---|---|---|
| 1 | 骨架 + 空地圖 + 基線 | 完成：地圖顯示、三條檢查指令、`watch_drone.sh` 都已驗證。`/api` proxy 只驗證到「有轉發」（後端尚未實作，回 502） |
| 2 | 地圖上顯示 drone + 側欄狀態 | 未開始（需要後端 step-2） |
| 3 | 起飛／降落按鈕 + 訊息區 | 未開始（需要後端 step-3） |

目前打開網頁只會看到一張置中在 SITL 起飛點的地圖和空的側欄，**還看不到 drone**。

## 快速開始

需要：Node.js 24（附帶 npm）、`curl`、`jq`（`scripts/watch_drone.sh` 用）、能連外網（地圖圖磚）。

```bash
npm ci            # 照 package-lock.json 安裝套件
npm run dev       # 開 http://localhost:5173
```

每次改完程式都要過的三條檢查：

```bash
npm run check     # 型別檢查
npm test          # 單元測試
npm run build     # 打包（會先再做一次型別檢查）
```

直接看 drone 的實際狀態（不經過網頁）：

```bash
scripts/watch_drone.sh http://172.18.10.2:7070 5   # 每 0.5 秒一行，5 秒後結束
```

出問題時先看 ROADMAP 的「出問題時看哪裡」一節。

## 名詞與檔案地圖（寫給不熟前端的人）

### 名詞

| 名詞 | 是什麼 |
|---|---|
| **Node.js** | 在瀏覽器以外執行 JavaScript 的程式。這裡只拿來跑開發工具（Vite、tsc、Vitest），網頁本身跑在瀏覽器裡。 |
| **npm** | Node 內建的套件管理器，負責下載套件、執行 `package.json` 裡的指令（`npm run xxx`）。 |
| **`package.json`** | 專案的「清單」：用到哪些套件（允許的版本範圍）、有哪些指令可以 `npm run`。 |
| **`package-lock.json`** | 實際裝了哪個**確切**版本（連間接相依都有）。一定要 commit；它讓每台機器裝到一模一樣的東西。 |
| **`node_modules/`** | 套件實際下載到的地方。可以隨時刪掉重裝，不進 git。 |
| **`npm ci`** | 照 `package-lock.json` 原樣安裝，不會改動任何版本。**平常都用這個。** |
| **`npm install <套件>`** | 新增或升級套件，會改寫 `package.json` 與 `package-lock.json`。只在刻意要改套件時用，改完兩個檔一起 commit。 |
| **TypeScript** | 加上型別的 JavaScript。瀏覽器看不懂 `.ts`，要先轉成 `.js`（由 Vite 負責）；`tsc` 在這裡只做型別檢查。 |
| **Vite** | 開發工具，做三件事：① `npm run dev` 開一個本機網頁伺服器，改檔案瀏覽器會自動更新；② 把 `/api/...` 的請求轉給後端（proxy）；③ `npm run build` 把程式打包成瀏覽器能直接用的檔案。 |
| **Vitest** | 測試工具，`npm test` 會執行所有 `*.test.ts`。 |
| **Leaflet** | 畫地圖的函式庫。地圖圖片（圖磚）從 OpenStreetMap 下載。 |
| **proxy** | 網頁只向 `localhost:5173` 發請求，由 Vite 代為轉給 `localhost:8100` 的後端。這樣瀏覽器不會因為「跨網域」（CORS）而擋下請求。 |

### 檔案

| 檔案 | 角色 |
|---|---|
| `index.html` | 網頁本體：左邊地圖（`#map`）、右邊側欄（`#panel`），版面用一小段 CSS 寫在裡面。 |
| `src/main.ts` | 網頁的程式進入點：建立地圖。之後的畫面操作（畫點、側欄、按鈕）都在這裡。 |
| `src/api.ts` | （step-2 起）向後端發請求、描述後端回應的型別。 |
| `src/view.ts` | （step-2 起）純邏輯：把後端資料換成「要不要畫、什麼顏色、寫什麼字」，不碰畫面，所以能寫單元測試。 |
| `src/*.test.ts` | 單元測試。現在只有 `smoke.test.ts`（證明測試管線能跑），step-2 會換成 `view.test.ts`。 |
| `vite.config.ts` | Vite 設定：`/api` 要轉到哪個後端位址，**只寫在這裡**。 |
| `tsconfig.json` | TypeScript 設定，每個選項旁邊有中文註解。 |
| `scripts/watch_drone.sh` | 驗收工具：直接向 drone 查狀態並印出來，用來確認「drone 真的起飛了」，而不是只看網頁。 |
| `docs/baseline.md` | 每個 step 的量測數字與踩坑紀錄，只往後加、不改舊的。 |
| `dist/` | `npm run build` 的產物，不進 git。 |

## 授權

[MIT](LICENSE)
