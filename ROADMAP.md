# marine-frontend ROADMAP

給 drone 容器開發者「功能做完後手動測試」用的極簡網頁：一張地圖、幾個點、兩顆按鈕。
純 TypeScript + DOM，不用任何 UI 框架。後端是 `marine-backend-py`（FastAPI，:8100）。

**讀者設定：** 維護者是 drone 開發者，**不熟前端**。所以本專案只用最主流、教學最多的工具與寫法，
不追新版、不用花招；遇到問題先看「出問題時看哪裡」一節。

## 專案目標（第一階段）

```
瀏覽器 ── marine-frontend (Vite dev server :5173)
   │  /api/* 經 Vite proxy 轉到 → marine-backend-py :8100 → drone-N :7070 → SITL
   │
   ├─ 地圖（Leaflet + OSM 圖磚）上每台 drone 一個點，每 1 秒更新
   ├─ 側欄：每台 drone 的名稱、飛行模式、高度、是否 armed、電壓、遙測年齡
   └─ 選一台 → [起飛 (高度, 預設 10 m)] [降落]，結果與 drone 的錯誤理由寫進訊息區
```

**第一階段最終驗收**：在地圖上看到 drone-1 的點；按「起飛」後，drone 自己的
`GET /get_drone_state` 出現 `alt_rel ≥ 9.5` 且 `is_armed=true`，地圖上的點與側欄同步變化；
按「降落」後回到 `alt_rel < 1` 且 `is_armed=false`。量測取自 drone，不取自畫面。

**第一階段不做**：goto／點地圖飛過去、RTL、改高度、航跡線、離線圖磚、RWD、主題、登入、實機。

---

## 軟硬體基準表（2026-09 時點）

| 項目 | 值 | 來源 |
|---|---|---|
| 開發主機 | Ubuntu 22.04.4, x86_64 | 主機實查 |
| Node.js | 24.13.0 / npm 11.6.2 | `node -v`、`npm -v` |
| Vite | **8.3.1**（latest；engines: `node ^20.19.0 \|\| >=22.12.0`） | `npm view vite`，2026-09-25 查 |
| TypeScript | **6.0.3**（2026-04 發布；**刻意不用** latest 7.0.2，見選型決策 3） | `npm view typescript`，2026-09-25 查 |
| Leaflet | **1.9.4**（latest stable，2023-05 發布；2.0 仍在 `2.0.0-alpha.1`，2025-08） | `npm view leaflet`，2026-09-25 查 |
| @types/leaflet | 1.9.22 | `npm view @types/leaflet`，2026-09-25 查 |
| Vitest | **4.1.11**（2026-08 發布；peer `vite ^6 \|\| ^7 \|\| ^8`；**刻意不用** 3 週前才出的 5.0） | `npm view vitest`，2026-09-25 查 |
| 套件管理器 | npm（Node 內建） | 見選型決策 0 |
| 後端 | `marine-backend-py` :8100 | 見該 repo 的 ROADMAP |

新增任何相依時同步記錄版本；精確版本由 `package-lock.json` 釘死。

---

## 選型決策

0. **套件管理器用 npm。** Node 內建，接手的人不必多裝任何東西；只有 4～5 個相依，
   pnpm 的優點（省硬碟、嚴格 `node_modules`、monorepo）用不到。
   裝套件一律 `npm ci`（照 `package-lock.json` 裝，不會偷偷升版）；
   只有在「要新增或升級套件」時才用 `npm install <套件>`，並把 `package-lock.json` 一起 commit。
1. **TypeScript + Vite，不用框架。** 「純 JS」跟「有型別」之間取型別：drone 狀態有 40 幾個
   欄位、單位各不相同（見後端 ROADMAP 的 G2），打錯欄位名只有型別檢查抓得到。
   Vite 只當 dev server、proxy 和打包器用，不引入它的任何 plugin。
   整個專案只有 4 個 devDependencies（`vite`、`typescript`、`vitest`、`@types/leaflet`）
   和 1 個 dependency（`leaflet`）。
2. **測試用 Vitest。** Vite 官方搭配的測試工具，教學最多、零設定（直接讀 `vite.config.ts`），
   測試檔的 import 寫法與正式程式碼完全相同。
   **不採用**「Node 內建 `node --test` 直接跑 `.ts`」：雖然少一個相依，但它依賴 Node 很新的
   type stripping，要另開 `erasableSyntaxOnly`、`allowImportingTsExtensions`，
   import 必須寫 `.ts` 副檔名、部分語法不能用——出錯時新手分不出是自己寫錯還是踩到限制。
3. **TypeScript 6.0.3，不用最新的 7.0。** 7.0 是 Go 重寫版（目前的 7.0.2 是 2026-07 發布），
   依賴舊 JS Compiler API 的工具還在跟進中；而且網路上的教學與問答幾乎都是 6.x 以前寫的。
   本專案只用 `tsc --noEmit` 做型別檢查，兩版對程式碼沒有差別，所以選踩雷機率最低的。
   升到 7.x 是第一階段之後、生態穩定了再做的事（只改 `package.json` 一行）。
4. **Vite 8。** **後備：** 若 dev server 或 proxy 有 8.x 特有問題、半天內解不掉 →
   `vite@7.3.6`，設定檔語法相同，零程式碼改動。
5. **Leaflet 1.9.4，不用 2.0 alpha、不用 MapLibre。** 只需要畫點，Leaflet 最小、API 最穩；
   2.0 仍是 alpha。MapLibre（向量圖磚、WebGL）對「幾個點」來說太重。
   用 `L.circleMarker` 而非 `L.marker`：預設 marker 圖示在打包器下會因路徑解析而破圖
   （Leaflet 的已知問題），circleMarker 不需要任何圖片。
6. **OSM 公開圖磚，需要網路。** 開發期低用量符合 OSM 圖磚使用政策
   （須顯示 attribution，Leaflet 預設就有）。離線／場域無網路時，改用 marlin
   `map-server`（:8080 PMTiles）是第一階段之後的事。
7. **`/api` 走 Vite proxy，不設 CORS。** 前端程式碼只寫相對路徑 `/api/...`，
   後端位址只存在於 `vite.config.ts` 一處。
8. **輪詢用 `setTimeout` 串接，不用 `setInterval`。** 上一個請求結束後才排下一個，
   後端變慢時請求不會堆積。

---

## 對後端介面的審查（缺口）

介面契約由 `marine-backend-py` 定義（其 ROADMAP 的 step-2、step-3）；前端在 `src/api.ts`
手寫對應的型別。以下是前端必須自己處理的語意：

| # | 缺口 | 不處理會怎樣 | 在哪處理 |
|---|---|---|---|
| F-G1 | `online=false` 時位置欄位是 `null` | 畫 marker 時 crash 或畫在 (0,0) | step-2：`toView()` 回傳 `show=false` |
| F-G2 | GPS fix 之前 `lat`/`lng` 可能是 0（後端 G5） | 點出現在非洲外海 | step-2：`gps_fix_type < 3` 或 `lat==0 && lng==0` → 不畫點，側欄顯示「無 GPS fix」 |
| F-G3 | `online=true` 但遙測凍住（後端 G3） | 看起來正常，其實位置是舊的 | step-2：`telemetry_age_s > 3` → 灰色、標示「遙測過期 N 秒」 |
| F-G4 | takeoff 回 200 只代表已派發（後端 G6） | 畫面說「起飛成功」其實沒有 | step-3：訊息區寫「已派發 task_id=…」，再輪詢 `/tasks/{id}` 顯示最終 state |
| F-G5 | **LAND 必須能中斷正在進行的 TAKEOFF**（drone 的語意：新任務會取代舊任務，被取代的是 `superseded`，不是失敗） | 爬升中按不了降落——測試用的 UI 最不能有這個 | step-3：按鈕只在「HTTP 請求進行中」時 disable，不因 task 還在 running 就鎖住 |
| F-G6 | 錯誤資訊在 `detail`（409 飛控拒絕、504 飛控沒回應、502 drone 連不上、422 參數錯） | 只看到「失敗」，不知道原因 | step-3：訊息區顯示 `HTTP <status>: <detail>` |
| F-G7 | **FastAPI 的 `detail` 有兩種形狀**：自己丟的錯誤（409/502/504）是字串；參數驗證失敗（422）是陣列 `[{"loc": [...], "msg": "...", "type": "..."}]`。後端與 drone 都會原樣轉發 422 | 訊息區顯示 `HTTP 422: [object Object]`，看不到原因 | step-3：`formatDetail()`——字串照印；陣列則每筆印成 `<loc 用 . 串起來>: <msg>`，多筆以 `; ` 分隔；其他形狀 `JSON.stringify` |

後端是 FastAPI，所以 `http://localhost:8100/docs` 有自動產生的 API 文件頁：
寫 `src/api.ts` 的型別時照它對，懷疑是前端還是後端的問題時先在那頁直接送請求。
型別**手寫**，不用 `openapi-typescript` 之類的自動產生工具（多一層工具、多一種出錯方式）。

---

## 工作流程規則（每個 Step 都適用）

1. **一個 Step ＝ 一個 PR ＝ 一個 branch。** branch 名 `step-N-<短名>`，
   PR 標題 `step-N: <一句話目標>`。
2. **Definition of Done：**
   - 驗收證據貼在 PR 描述：指令輸出、截圖、`watch_drone.sh` 的紀錄。
   - 在 `docs/baseline.md` 最後面追加本 step 的一段。
   - ROADMAP 裡本 step 打勾。
3. **合併前 self-review，發現項分流。** 本 step 範圍內的當場修並重驗；
   行為層級的改動排成後續 step。
4. **量下游輸出端。** 「按了起飛有沒有用」看的是 **drone 自己的 `GET /get_drone_state`**
   （用 `scripts/watch_drone.sh` 記錄），不是畫面上的數字——畫面上的數字就是本專案的輸出，
   它自己證明不了自己。
5. **測試編排腳本進 repo**（`scripts/`）。每個 step 重跑同一套；腳本的缺陷修進腳本本體。
6. **腳本一定會自己結束。** 開頭 `set -euo pipefail`；迴圈跑固定次數；
   每個 `curl` 都帶 `--max-time`。第一階段的腳本不在背景啟動任何程式。
7. **每個 PR 必過：** `npm run check`（`tsc --noEmit`）、`npm test`（`vitest run`）、`npm run build`。
   畫面邏輯盡量放在純函式（`src/view.ts`）裡，才能不開瀏覽器就測。
8. **基線對照：** 每個 step 把 `npm run build` 最後印出的檔案大小那幾行原樣貼進
   `docs/baseline.md`。起降耗時的基線與容差沿用後端
   `docs/baseline.md`（中位數 ±30% 與 ±5 s 取較寬者）。
9. **只在刻意起飛的 drone 上測；** 同一時間只有一個 GCS 對同一台 drone 下指令。
10. **程式寫法保持樸素。**
    - 原始檔只有三個：`src/main.ts`（DOM 與 Leaflet，畫面）、`src/api.ts`（打後端）、
      `src/view.ts`（純邏輯，不碰 DOM），外加各自的 `*.test.ts`。要多開檔案先在 PR 說明理由。
    - 不用 `class`、不用 decorator、不寫複雜泛型；資料用 `type` 描述、邏輯用普通函式。
    - 非同步一律 `async`/`await`，不用 `.then()` 鏈。
    - 不引入 ROADMAP 沒列的套件；要加先改 ROADMAP 的基準表與選型決策。
    - 註解用中文，寫「為什麼這樣做」，不寫「這行在做什麼」。

---

## 出問題時看哪裡

| 症狀 | 先看哪裡 | 常見原因 |
|---|---|---|
| 畫面空白 | 瀏覽器按 **F12 → Console** 分頁的紅字 | JS 執行錯誤；紅字會指出檔名與行號 |
| 地圖整片灰色、沒有街道 | F12 → **Network** 分頁，看 `tile.openstreetmap.org` 的請求 | 主機沒網路 |
| 側欄顯示「後端連不上」 | F12 → Network，看 `/api/drones` 的狀態碼；以及跑 `npm run dev` 的終端 | 後端沒開（502／`ECONNREFUSED` 會印在 `npm run dev` 的終端） |
| Console 出現 `CORS` 字樣 | `src/` 裡搜尋 `http://` | 程式寫了絕對網址；應該一律寫 `/api/...`（選型決策 7） |
| 按了起飛沒反應／被拒 | 訊息區的 `HTTP <status>: <detail>`；再到 `http://localhost:8100/docs` 送同樣的請求 | 結果相同 → 是後端或 drone 拒絕，不是前端的問題 |
| 畫面數字和 drone 對不上 | 另開終端跑 `scripts/watch_drone.sh` | 以 drone 的數字為準（工作流程規則 4） |
| `npm run check` 報錯 | 錯誤訊息的 `檔名(行,列)` | 欄位名打錯、可能是 `null` 沒處理——這正是用 TypeScript 的目的 |
| `npm ci` 失敗 | 錯誤訊息開頭 | `package.json` 與 `package-lock.json` 不一致：改過套件卻沒 commit lock 檔 |

**執行前置條件：**

```bash
# 1. SITL（marlin-drone）
cd ~/poyi/marlin-drone && bash multiple_sitl/create_dockers.sh 1 --autopilot ardupilot
# 2. 後端
cd ~/GitHubPoyi/marine-backend-py && scripts/dev.sh
# 3. 前端
cd ~/GitHubPoyi/marine-frontend && npm run dev     # http://localhost:5173
```

---

## Step 總覽

| Step | 內容 | 機器 | 預估 | 前置 |
|---|---|---|---|---|
| 1 | 骨架 + 空地圖 + 基線 | 主機 | 0.5–1 天 | 無（可與後端 step-1 並行） |
| 2 | 地圖上顯示 drone + 側欄狀態 | 主機 + SITL | 1 天 | 本 repo step-1、後端 step-2 |
| 3 | 起飛／降落按鈕 + 訊息區 | 主機 + SITL | 1 天 | 本 repo step-2、後端 step-3 |

```
後端 : B1 ──► B2 ──► B3
                │       │
前端 : F1 ──────┴─► F2  └─► F3 ──► 第一階段完成
```

---

## Step 1 — 骨架 + 空地圖 + 基線

**目標：** `npm run dev` 打開就是一張置中在 SITL 預設起飛點的地圖；
型別檢查、測試、打包三條指令都能跑。

**內容**
- [ ] 手寫最小骨架（**不用** `npm create vite` 的範本，免得留下計數器、logo 等樣板殘留）：
  - `index.html`：`<div id="map">`、`<aside id="panel">`，一段 inline CSS 讓兩者並排
  - `src/main.ts`：建立 Leaflet 地圖，中心 `25.0226887, 121.4872364`
    （marlin-drone `startup_sitl.sh` 的 `DEFAULT_LAT/LON`），zoom 17，OSM 圖磚
  - `vite.config.ts`：`server.proxy = { "/api": "http://localhost:8100" }`
  - `tsconfig.json`：`strict`、`noEmit`、`module: "esnext"`、`moduleResolution: "bundler"`、
    `lib: ["dom", "es2022"]`（只開這些，每個選項旁邊用註解說明用途）
- [ ] `package.json` scripts：
  `dev`＝`vite`、`check`＝`tsc --noEmit`、`test`＝`vitest run`、
  `build`＝`tsc --noEmit && vite build`
- [ ] `src/smoke.test.ts`：一個能跑的測試，證明 Vitest 管線通（step-2 有了 `view.test.ts` 後刪掉）
- [ ] `scripts/watch_drone.sh <drone_url> <seconds>`：每 0.5 s 直接打 drone 的
      `GET /get_drone_state`，印出 `時間 alt_rel is_armed flight_mode`，跑 `seconds×2` 次後結束
      （工作流程規則 6）。之後每個 step 驗收都用它量下游
- [ ] `docs/baseline.md`（append-only），第一段：各工具版本、`npm run build` 印出的大小
- [ ] `README.md`：
  - 進度照實寫
  - **名詞與檔案地圖**（寫給不熟前端的人）：`package.json`／`package-lock.json`／
    `node_modules` 各是什麼、`npm ci` 與 `npm install` 差在哪、Vite 做了什麼
    （dev server、proxy、打包）、`index.html` 與 `src/` 下每個檔案的角色、`dist/` 是什麼
- [ ] `CLAUDE.md`（安裝、三條檢查指令、執行前置條件、PR 流程、指向「工作流程規則」與
      「出問題時看哪裡」）、`.gitignore`（`node_modules/`、`dist/`）、`LICENSE`，
      以及與之一致的 `package.json` license 欄位

**驗收**
- 全新 clone 上 `npm ci && npm run check && npm test && npm run build` 全部通過
- `npm run dev` → 瀏覽器看到地圖，中心在新北起飛點，右下角有 OSM attribution（附截圖）
- `scripts/watch_drone.sh http://172.18.10.2:7070 5` 印出約 10 行後自己結束
- `docs/baseline.md` 有版本與打包大小

---

## Step 2 — 地圖上顯示 drone + 側欄狀態

**目標：** 每台 drone 在地圖上一個點，每 1 秒跟著 `GET /api/drones` 更新；
側欄列出每台的狀態。

**內容**
- [ ] `src/api.ts`：`DroneStatus` 型別（對應後端 step-2 的回應）、`fetchDrones()`
- [ ] `src/view.ts`（純函式，不碰 DOM／Leaflet）：
      `toView(d: DroneStatus) → { show, lat, lng, color, label }`
  - `show=false`：`online=false`，或 `gps_fix_type < 3`，或 `lat==0 && lng==0`（F-G1、F-G2）
  - `color`：灰＝離線或 `telemetry_age_s > 3`（F-G3）；綠＝armed；藍＝disarmed
- [ ] `src/main.ts`：以 `setTimeout` 串接每 1 s 輪詢；依 `name` 建立／更新／移除
      `L.circleMarker`；側欄每台一列：名稱、`flight_mode_name`、`alt_rel`（小數 1 位）、
      armed、`battery_voltage`、遙測年齡；請求失敗時側欄頂端顯示「後端連不上」
- [ ] `src/view.test.ts`：正常、離線、無 fix、(0,0)、遙測過期、armed／disarmed 顏色；
      刪掉 step-1 的 `src/smoke.test.ts`

**驗收**
- `npm run check && npm test && npm run build` 通過
- SITL drone-1 運行中：地圖上的點與側欄的 `lat`/`lng` 和
  `curl 172.18.10.2:7070/get_drone_state` 相差 1e-5 以內（附截圖與 curl 輸出）
- 停掉後端 → 3 s 內出現「後端連不上」；後端恢復後自動回復，不必重新整理
- 讓 drone-1 失聯（停 coordinator）→ 3 s 內該點變灰或消失，側欄標示離線
- 打包大小追加到 `docs/baseline.md`

---

## Step 3 — 起飛／降落按鈕 + 訊息區

**目標：** 在畫面上讓選中的 drone 起飛、降落，每個指令的結果——包括 drone 的拒絕理由——
都看得到。

**內容**
- [ ] 選取：點地圖上的點或側欄的列 → 成為「目前 drone」，側欄反白
- [ ] 高度輸入框（`type=number`，min 1、max 500、預設 10）、`[起飛]`、`[降落]` 按鈕
- [ ] `src/api.ts`：`takeoff(name, altitude)`、`land(name)`、`getTask(name, taskId)`；
      非 2xx 時丟出帶 `status` 與 `detail` 的錯誤
- [ ] `src/view.ts`：`formatDetail(detail: unknown) → string`（F-G7：字串／422 陣列／其他）
- [ ] 訊息區（往下累加的純文字清單，每筆有時間）：
  - 送出：`14:03:07 drone-1 TAKEOFF 10 m → 已派發 task_id=ab12…`
  - 失敗：`14:03:07 drone-1 TAKEOFF → HTTP 409: <drone 的 detail>`（F-G6）
  - 422：`14:03:07 drone-1 TAKEOFF → HTTP 422: body.altitude: Input should be …`（F-G7）
  - 結果：每 1 s 輪詢 `/tasks/{id}`，直到 state 進入終態
    （succeeded／failed／rejected／superseded），寫一筆 `task ab12… → succeeded`（F-G4）
- [ ] 按鈕只在 HTTP 請求進行中 disable；task 還在 running 時**降落照樣能按**（F-G5）
- [ ] `src/view.test.ts`：`formatDetail` 三種形狀（字串、422 陣列單筆與多筆、其他）、task 終態判斷

**驗收**（全部在 SITL drone-1 上，另開終端跑 `scripts/watch_drone.sh http://172.18.10.2:7070 300`）
- 按「起飛」(10 m)：`watch_drone.sh` 紀錄出現 `alt_rel ≥ 9.5` 且 `is_armed=true`；
  從按下到達高度的時間落在後端 `docs/baseline.md` 的起飛容差內；
  訊息區最後出現 `→ succeeded`
- 按「降落」：`watch_drone.sh` 紀錄出現 `is_armed=false` 且 `alt_rel < 1`
- 爬升途中按「降落」：drone 轉為下降（`flight_mode` 變 QLAND＝20），
  訊息區顯示起飛 task 的終態（drone 文件只寫明「goto 途中下 LAND」會是 `superseded`，
  起飛途中的情況要以實測為準，把實際結果記進 `docs/baseline.md`）
- 剛降落、`is_ready_to_arm=false` 時按「起飛」：訊息區顯示的狀態碼與 `detail`
  和直接 `curl -X POST 172.18.10.2:7070/api/takeoff` 的結果相同
- 以上各附 `watch_drone.sh` 紀錄片段與截圖；`watch_drone.sh` 結束後 `pgrep -f watch_drone` 查無殘留

---

## 里程碑

| 里程碑 | 條件 |
|---|---|
| **M1：看得到** | step-2 合併：地圖上看得到 drone，狀態每秒更新 |
| **M2：第一階段完成** | step-3 合併：在地圖上看到 drone、讓它起飛、讓它降落 |

---

## 第一階段之後（尚未規劃，只列出來免得忘記）

- 點地圖 goto、RTL、改高度按鈕
- 航跡線（最近 N 個點）、機頭方向（`yaw`）
- 離線圖磚：接 marlin `map-server` :8080 的 PMTiles（需要 protomaps-leaflet）
- 打包成靜態檔由後端直接服務，省掉 Vite dev server
- 實機：起飛二次確認

---

## 來源（2026-09 時點）

- npm registry：`npm view vite|typescript|vitest|leaflet|@types/leaflet dist-tags`、
  `npm view <pkg> time`、`npm view vitest@4.1.11 peerDependencies engines`（2026-09-25）
- 不選 TS 7 的背景：[Announcing TypeScript 7.0](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)；
  生態相容性 [vite-plugin-dts 在 TS 7 下無法建置（losol/origo#19）](https://github.com/losol/origo/issues/19)、
  [typescript-eslint 尚未支援 TS 7（athrvk/vayu#467）](https://github.com/athrvk/vayu/issues/467)
- FastAPI 422 的 `detail` 陣列格式：FastAPI 預設的 `RequestValidationError` 處理器
