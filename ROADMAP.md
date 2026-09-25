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
這些排在第二階段之後，見下方「階段總覽」。

---

## 階段總覽（2026-09-25 重新審查）

每個階段拆成數個 step，一個 step ＝ 一個 PR。每個 step 的程式碼（定義與量法見工作流程規則 12）
**預估不超過 800 行**；超過的在規劃時就拆成 `step-N-a`、`step-N-b`…。

| 階段 | 目標 | Steps | 預估程式碼（行） | 後端依賴 | 狀態 |
|---|---|---|---|---|---|
| 1 看得到、飛得起來 | 地圖上看到 drone；起飛、降落 | 1、2、3 | 145（實測）、約 250、約 350 | 後端 step-2、step-3 | step-1 在 PR #1 |
| 2 更多飛行指令 | 返航（RTL）、改高度、點地圖 goto | 4、5 | 約 100、約 210 | 後端要新增 rtl／change-alt／goto 的轉發（**尚未排入後端 ROADMAP**） | 未開始 |
| 3 看得更清楚 | 航跡線、機頭方向 | 6 | 約 150 | 後端 `GET /api/drones` 要多回 `yaw`（後端 step-2 的回應沒有） | 未開始 |
| 4 場域部署 | 不靠外網的圖磚；由後端直接提供網頁 | 7、8 | 約 40、約 30 | step-8 需要後端提供靜態檔（尚未排入後端 ROADMAP） | 未開始 |
| 5 實機前置 | 畫面標示 SITL／實機；實機指令二次確認 | 9 | 約 150 | 後端要能標示哪台是實機（後端的實機階段） | 只列方向 |

**拆分結果：九個 step 的預估都在 800 行以下，目前沒有需要拆成 `-a`／`-b` 的。** 最大的是 step-3（約 350 行）。

- 估算依據：step-1 實測 145 行（`index.html` 38、`package.json` 23、`scripts/watch_drone.sh` 39、
  `src/main.ts` 15、`tsconfig.json` 19、`vite.config.ts` 11）；其他 step 逐檔估算，寫在各 step 的「預估程式碼」一行。
- 真正需要盯的不是單一 step，而是 **`src/main.ts` 會跨 step 累積**：第一階段結束約 320 行，第三階段結束約 580 行。
  超過約 500 行時，依工作流程規則 10 在 PR 說明是否拆檔（例如把側欄與訊息區搬出去）。
- 第二、四、五階段都卡在後端還沒規劃的功能。後端 ROADMAP 排入之前，這些 step 只能先寫純函式與測試，無法驗收。
- step-7（圖磚）只依賴 step-1，可以在任何時候插隊做。

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
   （須顯示 attribution，Leaflet 預設就有）。離線／場域無網路時改用 marlin 的 `map-server`，排在 step-7。
   **2026-09-25 重新審查時實測更正**：`map-server`（:8080）是 **TileServer GL**，不是原本以為的「PMTiles，要裝
   protomaps-leaflet」。它直接輸出 PNG 點陣圖磚（`/styles/basic-preview/{z}/{x}/{y}.png`，z17 實測 200、`image/png`），
   所以 **Leaflet 原本的 `L.tileLayer` 就能用，不必加任何套件**。圖資範圍只有台北一帶
   （`/data.json`：經度 121.346–121.676、緯度 24.926–25.209，向量資料最大 zoom 14）。
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
   PR 標題 `step-N: <一句話目標>`。拆開的 step 用 `step-N-a-<短名>`、PR 標題 `step-N-a: …`（見規則 12）。
2. **Definition of Done：**
   - 驗收證據貼在 PR 描述：指令輸出、截圖、`watch_drone.sh` 的紀錄。
   - PR 描述貼上本 step 的程式碼行數（規則 12 的量法指令輸出）。
   - 在 `docs/baseline.md` 最後面追加本 step 的一段。
   - 教材一章 `docs/stepNN.html`（寫給不熟前端的讀者；程式驗證完才寫），更新 `docs/index.html` 與前一章的導覽，
     開 PR 前交給冷讀掃過。之後動到教材引用的檔案時，同一個 PR 要同步那一章的節錄與數字。
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
11. **先寫測試，再寫程式。** 適用於 `src/view.ts` 裡的每個純函式，順序固定：
    1. **寫測試**：在 `src/view.test.ts` 寫出案例（給這個輸入 → 應該得到這個輸出）。
       函式本身先只寫空殼——型別正確、內容是 `throw new Error("未實作")`——讓 `npm run check` 能過。
    2. **看它失敗**：跑 `npm test`，確認新測試是紅的。沒看過它失敗，就不能確定它真的有在測。
    3. **寫實作**：改到 `npm test` 全綠為止；過程中不改測試的預期值，除非發現是測試寫錯
       （要在 commit 訊息說明）。
    4. **修 bug 也一樣**：先寫一個能重現這個 bug 的失敗測試，再修。
    - **Commit 順序**：「測試＋空殼」一個 commit，「實作」下一個 commit；
      PR 描述貼上第 2 步的失敗輸出，當作「先寫測試」的證據。
    - **不寫單元測試的部分**：`src/main.ts`（直接操作 DOM 與 Leaflet）和 `src/api.ts`
      （只是薄薄一層 `fetch`；不 mock `fetch`，那是新手不需要的花招）。
      這兩處改用驗收條件驗證（截圖＋`watch_drone.sh`）。
      也因此，能抽成純函式的判斷邏輯一律搬進 `view.ts`（規則 7），才吃得到測試。
12. **每個 step 的程式碼不超過 800 行（不含測試）。** 一個 PR 太大，review 看不完、出問題也難二分。
    - **算哪些**：非測試的 `src/**/*.ts`、`index.html`、`vite.config.ts`、`tsconfig.json`、`package.json`、`scripts/` 下的腳本。
      **不算**：`*.test.ts`、`docs/`（含教材）、`*.md`、`package-lock.json`、`LICENSE`、`.gitignore`。
    - **量法**：數「新增的行」，在 step 的 branch 上跑
      ```bash
      git diff --numstat main...HEAD -- src index.html scripts vite.config.ts tsconfig.json package.json \
        ':(exclude)**/*.test.ts' | awk '{a+=$1} END {print a}'
      ```
      （step-1 實測 145。）
    - **規劃時**：每個 step 在「Step 總覽」寫預估行數。預估超過 800 的，規劃時就拆成 `step-N-a`、`step-N-b`、`step-N-c`…，
      每一個都要能**單獨合併、單獨驗收**（不能出現「a 合併後畫面有按鈕但按了沒反應」這種半成品）。
    - **實作中量到超過 800**：停下來，把還沒做的部分移到下一個字母（例如 step-N 改成 step-N-a，剩下的變成 step-N-b），
      ROADMAP 同步改，本 PR 只收已完成而且能單獨驗收的部分。
    - **例外**：有非常強烈的理由才可以不拆，理由寫進 ROADMAP 該 step 與 PR 描述。
      可以接受的例子：拆開後中間那個版本會讓 drone 處於不安全或畫面與 drone 不一致的狀態。
      「拆開比較麻煩」「差一點點」不算理由。

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

| 階段 | Step | 內容 | 預估程式碼（行） | 機器 | 預估時間 | 前置 |
|---|---|---|---|---|---|---|
| 1 | 1 | 骨架 + 空地圖 + 基線 | 145（實測） | 主機 | 0.5–1 天 | 無（可與後端 step-1 並行） |
| 1 | 2 | 地圖上顯示 drone + 側欄狀態 | 約 250 | 主機 + SITL | 1 天 | 本 repo step-1、後端 step-2 |
| 1 | 3 | 起飛／降落按鈕 + 訊息區 | 約 350 | 主機 + SITL | 1 天 | 本 repo step-2、後端 step-3 |
| 2 | 4 | 返航（RTL）與改高度 | 約 100 | 主機 + SITL | 0.5 天 | step-3、後端的 rtl／change-alt 轉發 |
| 2 | 5 | 點地圖 goto | 約 210 | 主機 + SITL | 1 天 | step-4、後端的 goto 轉發 |
| 3 | 6 | 航跡線 + 機頭方向 | 約 150 | 主機 + SITL | 0.5–1 天 | step-5、後端回傳 `yaw` |
| 4 | 7 | 圖磚來源可切換（OSM／本機 map-server） | 約 40 | 主機 | 0.5 天 | step-1（可隨時插隊） |
| 4 | 8 | 由後端直接提供網頁 | 約 30 | 主機 + SITL | 0.5 天 | step-3、後端提供靜態檔 |
| 5 | 9 | 實機前置：環境標示 + 二次確認 | 約 150 | 主機 | 1 天 | 後端實機階段 |

第一階段的相依（後續階段的後端 step 尚未排定，見「階段總覽」）：

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
- [x] 手寫最小骨架（**不用** `npm create vite` 的範本，免得留下計數器、logo 等樣板殘留）：
  - `index.html`：`<div id="map">`、`<aside id="panel">`，一段 inline CSS 讓兩者並排
  - `src/main.ts`：建立 Leaflet 地圖，中心 `25.0226887, 121.4872364`
    （marlin-drone `startup_sitl.sh` 的 `DEFAULT_LAT/LON`），zoom 17，OSM 圖磚
  - `vite.config.ts`：`server.proxy = { "/api": "http://localhost:8100" }`
  - `tsconfig.json`：`strict`、`noEmit`、`module: "esnext"`、`moduleResolution: "bundler"`、
    `lib: ["dom", "es2022"]`（只開這些，每個選項旁邊用註解說明用途）
    ——實作時追加兩項（見 `docs/baseline.md` step-1 踩坑 1）：`types: ["vite/client"]`
    （讓 `import "*.css"` 有型別）、`include: ["src"]`（`vite.config.ts` 不納入型別檢查，
    否則會拉進 Vite 的 Node 型別）
- [x] `package.json` scripts：
  `dev`＝`vite`、`check`＝`tsc --noEmit`、`test`＝`vitest run`、
  `build`＝`tsc --noEmit && vite build`
- [x] `src/smoke.test.ts`：一個能跑的測試，證明 Vitest 管線通（step-2 有了 `view.test.ts` 後刪掉）
- [x] `scripts/watch_drone.sh <drone_url> <seconds>`：每 0.5 s 直接打 drone 的
      `GET /get_drone_state`，印出 `時間 alt_rel is_armed flight_mode`，跑 `seconds×2` 次後結束
      （工作流程規則 6）。之後每個 step 驗收都用它量下游
- [x] `docs/baseline.md`（append-only），第一段：各工具版本、`npm run build` 印出的大小
- [x] 教材：`docs/index.html`（目錄）與 `docs/step01.html`（本 step 一章）——開 PR 後才補上，見 PR #1 討論
- [x] `README.md`：
  - 進度照實寫
  - **名詞與檔案地圖**（寫給不熟前端的人）：`package.json`／`package-lock.json`／
    `node_modules` 各是什麼、`npm ci` 與 `npm install` 差在哪、Vite 做了什麼
    （dev server、proxy、打包）、`index.html` 與 `src/` 下每個檔案的角色、`dist/` 是什麼
- [x] `CLAUDE.md`（安裝、三條檢查指令、執行前置條件、PR 流程、指向「工作流程規則」與
      「出問題時看哪裡」）、`.gitignore`（`node_modules/`、`dist/`）、`LICENSE`（MIT），
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
（依工作流程規則 11，下列順序就是實作順序）
- [ ] `src/api.ts`：`DroneStatus` 型別（對應後端 step-2 的回應：`name`、`online`、`error`、`lat`、`lng`、`alt_rel`、
      `is_armed`、`flight_mode`、`flight_mode_name`、`battery_voltage`、`gps_fix_type`、`telemetry_age_s`，
      連線失敗時除了 `name`／`online`／`error` 都是 `null`）、`fetchDrones()`
- [ ] **先寫** `src/view.test.ts`，並確認它失敗：正常、離線、無 fix、(0,0)、遙測過期、
      armed／disarmed 顏色；刪掉 step-1 的 `src/smoke.test.ts`
- [ ] 再寫 `src/view.ts`（純函式，不碰 DOM／Leaflet），直到測試全綠：
      `toView(d: DroneStatus) → { show, lat, lng, color, label }`
  - `show=false`：`online=false`，或 `gps_fix_type < 3`，或 `lat==0 && lng==0`（F-G1、F-G2）
  - `color`：灰＝離線或 `telemetry_age_s > 3`（F-G3）；綠＝armed；藍＝disarmed
- [ ] `src/main.ts`：以 `setTimeout` 串接每 1 s 輪詢；依 `name` 建立／更新／移除
      `L.circleMarker`；側欄每台一列：名稱、`flight_mode_name`、`alt_rel`（小數 1 位）、
      armed、`battery_voltage`、遙測年齡；請求失敗時側欄頂端顯示「後端連不上」

**預估程式碼：** 約 250 行（`api.ts` 35、`view.ts` 60、`main.ts` 125、`index.html` 30）。

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

**內容**（依工作流程規則 11，先做前兩項）
- [ ] **先寫** `src/view.test.ts` 的新案例，並確認它失敗：`formatDetail` 三種形狀
      （字串、422 陣列單筆與多筆、其他）、task 終態判斷
- [ ] 再寫 `src/view.ts`，直到測試全綠：`formatDetail(detail: unknown) → string`
      （F-G7：字串／422 陣列／其他）、`isTerminal(state) → boolean`
- [ ] 選取：點地圖上的點或側欄的列 → 成為「目前 drone」，側欄反白
- [ ] 高度輸入框（`type=number`，min 1、max 500、預設 10）、`[起飛]`、`[降落]` 按鈕
- [ ] `src/api.ts`：`takeoff(name, altitude)`、`land(name)`、`getTask(name, taskId)`；
      非 2xx 時丟出帶 `status` 與 `detail` 的錯誤
- [ ] 訊息區（往下累加的純文字清單，每筆有時間）：
  - 送出：`14:03:07 drone-1 TAKEOFF 10 m → 已派發 task_id=ab12…`
  - 失敗：`14:03:07 drone-1 TAKEOFF → HTTP 409: <drone 的 detail>`（F-G6）
  - 422：`14:03:07 drone-1 TAKEOFF → HTTP 422: body.altitude: Input should be …`（F-G7）
  - 結果：每 1 s 輪詢 `/tasks/{id}`，直到 state 進入終態
    （succeeded／failed／rejected／superseded），寫一筆 `task ab12… → succeeded`（F-G4）
  - 追蹤最多 60 s，超過就寫一筆 `task ab12… → 追蹤逾時（最後狀態 running）` 並停止輪詢
    （後端 step-1 基線：起飛約 5.3 s、降落約 23–24 s；60 s 約是降落的 2.5 倍）
- [ ] 按鈕只在 HTTP 請求進行中 disable；task 還在 running 時**降落照樣能按**（F-G5）

**預估程式碼：** 約 350 行（`api.ts` 60、`view.ts` 50、`main.ts` 180、`index.html` 60）。

**驗收**（全部在 SITL drone-1 上，另開終端跑 `scripts/watch_drone.sh http://172.18.10.2:7070 300`）
- 按「起飛」(10 m)：`watch_drone.sh` 紀錄出現 `alt_rel ≥ 9.5` 且 `is_armed=true`；
  從按下到達高度的時間落在後端 `docs/baseline.md` 的起飛容差內；
  訊息區最後出現 `→ succeeded`
- 按「降落」：`watch_drone.sh` 紀錄出現 `is_armed=false` 且 `alt_rel < 1`
- 爬升途中按「降落」：drone 轉為下降（`flight_mode` 變 QLAND＝20），
  訊息區顯示起飛 task 的終態（drone 文件只寫明「goto 途中下 LAND」會是 `superseded`，
  起飛途中的情況要以實測為準，把實際結果記進 `docs/baseline.md`）
- 高度填 600 按「起飛」（合法範圍 1–500，見後端 ROADMAP「對 drone 側介面的審查」）：訊息區顯示
  `HTTP 422: <loc>: <msg>`（F-G7），內容和直接 `curl -X POST 172.18.10.2:7070/api/takeoff -d '{"altitude":600}'` 的 `detail` 一致；
  `watch_drone.sh` 紀錄 `is_armed` 維持 `false`
- **不再驗「剛降落、`is_ready_to_arm=false` 時起飛會被拒」**（2026-09-25 重新審查更正）：後端 step-1 實測，
  降落後停在 QLAND 時 `is_ready_to_arm` 必定是 false，但 `POST /api/takeoff` 會先切 GUIDED，照樣飛得起來
  （後端選型決策 7）。所以 UI 不可因 `is_ready_to_arm=false` 就擋住起飛按鈕
- 以上各附 `watch_drone.sh` 紀錄片段與截圖；`watch_drone.sh` 結束後 `pgrep -x watch_drone.sh` 查無殘留（不要用 `pgrep -f`：會比對到自己的 shell，見 `docs/baseline.md` step-1 踩坑 2）

---

## Step 4 — 返航（RTL）與改高度（第二階段）

**目標：** 選中的 drone 可以返航、改飛行高度，結果照 step-3 的訊息區格式顯示。

**內容**
- [ ] `src/api.ts`：`rtl(name)`、`changeAlt(name, altitude)`。drone 端是 `POST /api/rtl`（沒有參數）與
      `POST /api/change-alt {"altitude": …}`（2026-09-25 讀 drone 的 `/openapi.json` 確認），經後端轉發
- [ ] 控制區加 `[返航]`、`[改高度]`，沿用 step-3 的高度輸入框、送出流程、錯誤顯示與 task 追蹤
- [ ] 有新的判斷邏輯才加純函式；有的話照規則 11 先寫測試

**預估程式碼：** 約 100 行（`api.ts` 25、`main.ts` 55、`index.html` 20）。

**驗收**（SITL drone-1，另開終端跑 `watch_drone.sh`）
- 在空中按「改高度」20 m：`watch_drone.sh` 紀錄 `alt_rel` 到 19.5 以上，訊息區出現 `→ succeeded`
- 按「返航」：`flight_mode` 換成返航類模式（編號以實測記入 `docs/baseline.md`），最後 `is_armed=false`
- 返航途中按「降落」：drone 轉為 QLAND（20），返航 task 的終態以實測記錄

---

## Step 5 — 點地圖 goto（第二階段）

**目標：** 在地圖上點一個位置、確認後，選中的 drone 飛過去；誤點不會讓 drone 動。

**內容**
- [ ] **先寫** `src/view.test.ts` 新案例並確認失敗，再寫 `src/view.ts`：
      `checkGotoTarget(drone, target, altitude)` → 可以送出，或拒絕理由（沒選 drone、離線、沒有 GPS fix、
      距離超過上限——上限先定 2000 m，實測後調整並寫回這裡）
- [ ] `src/main.ts`：點地圖 → 放一個目標標記，側欄顯示目標座標與距離、`[前往]`／`[取消]`；
      按「前往」才送出；task 進入終態後移除標記
- [ ] `src/api.ts`：`goto(name, lat, lon, altitude)`（drone 端必填 `lat`、`lon`、`altitude`，`yaw` 可省略）
- [ ] `scripts/watch_drone.sh` 多印 `lat lng` 兩欄（驗收要看位置）

**預估程式碼：** 約 210 行（`view.ts` 40、`main.ts` 120、`api.ts` 15、`index.html` 25、`watch_drone.sh` 10）。

**驗收**
- 點離 drone 約 100 m 處、按「前往」：`watch_drone.sh` 紀錄的 `lat`/`lng` 逐步接近目標，最後距離 < 5 m
- 只點地圖不按「前往」：drone 不動（`watch_drone.sh` 位置不變）
- goto 途中按「降落」：goto task 終態為 `superseded`（drone 文件寫明的行為），drone 原地降落

---

## Step 6 — 航跡線與機頭方向（第三階段）

**目標：** 地圖上看得出 drone 飛過的路徑與機頭朝向。

**內容**
- [ ] **先寫測試**再寫 `src/view.ts`：
  - `appendTrack(track, point, maxPoints)`：保留最近 N 點（先定 300 點，約 5 分鐘）；離線或沒有 fix 時不加點
  - `headingEnd(lat, lng, yaw, lengthM)`：機頭方向短線的終點座標
- [ ] `src/main.ts`：每台一條 `L.polyline` 航跡，加一條從點往機頭方向的短線
      （`circleMarker` 不能旋轉；用短線表示方向，不引入圖示檔）
- [ ] `src/api.ts`：`DroneStatus` 加 `yaw`

**預估程式碼：** 約 150 行（`view.ts` 50、`main.ts` 80、`api.ts` 5、`index.html` 15）。

**驗收**
- 起飛後 goto 一段：航跡線畫出實際路徑，形狀和 `watch_drone.sh` 記錄的座標一致
- 機頭短線的方向和 `curl 172.18.10.2:7070/get_drone_state` 的 `yaw` 相差 5° 以內（附截圖與 curl 輸出）

---

## Step 7 — 圖磚來源可切換（第四階段）

**目標：** 沒有外網時地圖照樣有底圖。

**內容**
- [ ] `src/main.ts`：用 Leaflet 內建的 `L.control.layers`，讓使用者在「OSM（需要網路）」與「本機 map-server」之間切換；
      本機圖磚 `http://localhost:8080/styles/basic-preview/{z}/{x}/{y}.png`（見選型決策 6）
- [ ] README 與教材寫明本機圖資的範圍與最大 zoom（選型決策 6）

**預估程式碼：** 約 40 行（全在 `main.ts`）。

**驗收**
- 封鎖 `tile.openstreetmap.org`（或拔網路）後切到「本機 map-server」：地圖照樣有底圖（截圖）；
  F12 → Network 看得到圖磚請求打到 `:8080`
- 切回 OSM、恢復網路後照常

---

## Step 8 — 由後端直接提供網頁（第四階段）

**目標：** 不跑 Vite dev server，打開後端的 `http://localhost:8100/` 就能用。

**內容**
- [ ] 確認 `npm run build` 的 `dist/` 只用相對路徑，`/api` 與網頁同源，不需要 proxy
- [ ] README 寫部署步驟（`npm run build` → 後端提供 `dist/`）；後端掛靜態檔是後端 repo 的 step

**預估程式碼：** 約 30 行（設定與文件以外的少量調整）。

**驗收**
- 停掉 Vite，打開 `http://localhost:8100/`：看得到地圖與 drone，起飛、降落照常（`watch_drone.sh` 紀錄）

---

## Step 9 — 實機前置：環境標示與二次確認（第五階段，只列方向）

- 畫面頂端清楚標示這台是「SITL」還是「實機」（資料來自後端 drone 清單的新欄位）
- 實機的起飛與 goto 要二次確認（確認框顯示 drone 名稱、指令與高度）
- 認證、時鐘（後端 G10）等細節等後端實機階段定案後再展開；展開後若預估超過 800 行，依規則 12 拆成 `step-9-a`、`step-9-b`

**預估程式碼：** 約 150 行（方向性估計，展開時重估）。

---

## 里程碑

| 里程碑 | 條件 |
|---|---|
| **M1：看得到** | step-2 合併：地圖上看得到 drone，狀態每秒更新 |
| **M2：第一階段完成** | step-3 合併：在地圖上看到 drone、讓它起飛、讓它降落 |
| **M3：第二階段完成** | step-5 合併：返航、改高度、點地圖 goto |
| **M4：第三階段完成** | step-6 合併：航跡線與機頭方向 |
| **M5：第四階段完成** | step-8 合併：不靠外網、不靠 Vite 也能用 |

---

## 尚未規劃（只列出來免得忘記）

- 對前端的推播（WebSocket）：後端「第一階段之後」有列，輪詢不夠用了再說
- 測試過程錄製與回放（指令與狀態的時間軸）
- 多台 drone、多人同時操作（後端 G9）
- 任務上傳（drone 有 `POST /api/upload-mission`）
- RWD、主題、登入

---

## 來源（2026-09 時點）

- npm registry：`npm view vite|typescript|vitest|leaflet|@types/leaflet dist-tags`、
  `npm view <pkg> time`、`npm view vitest@4.1.11 peerDependencies engines`（2026-09-25）
- 不選 TS 7 的背景：[Announcing TypeScript 7.0](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)；
  生態相容性 [vite-plugin-dts 在 TS 7 下無法建置（losol/origo#19）](https://github.com/losol/origo/issues/19)、
  [typescript-eslint 尚未支援 TS 7（athrvk/vayu#467）](https://github.com/athrvk/vayu/issues/467)
- FastAPI 422 的 `detail` 陣列格式：FastAPI 預設的 `RequestValidationError` 處理器
- drone 指令的參數：`curl 172.18.10.2:7070/openapi.json`（2026-09-25；`GotoTaskRequest` 必填 `lat`、`lon`、`altitude`，
  `ChangeAltTaskRequest` 必填 `altitude`，`ReturnRtlTaskRequest` 無必填）
- `map-server`：`curl localhost:8080/styles.json`、`/data.json`、`/styles/basic-preview/17/109807/56080.png`（2026-09-25，TileServer GL）
- 後端現況：`marine-backend-py` 的 ROADMAP 與 `docs/baseline.md`（step-1 已完成；選型決策 7、起降基線）
