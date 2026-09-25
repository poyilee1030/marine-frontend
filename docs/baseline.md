# marine-frontend 基線紀錄（append-only）

每個 step 在最後面追加一段；**舊段落的數字永遠不改**，有更正就在新段落寫明。

---

## step-1 — 骨架 + 空地圖（2026-09-25）

### 工具版本

| 項目 | 版本 |
|---|---|
| Node.js / npm | 24.13.0 / 11.6.2 |
| TypeScript | 6.0.3 |
| Vite | 8.3.1 |
| Vitest | 4.1.11 |
| Leaflet / @types/leaflet | 1.9.4 / 1.9.22 |
| 截圖用瀏覽器 | Google Chrome 146.0.7680.80（headless） |

`npm ci` 共安裝 50 個套件（含間接相依），`found 0 vulnerabilities`。

### `npm run build` 輸出（全新 clone）

```
dist/index.html                   0.73 kB │ gzip:  0.51 kB
dist/assets/index-vh-t_kPv.css   15.09 kB │ gzip:  6.36 kB
dist/assets/index-BvjQebgt.js   150.17 kB │ gzip: 44.05 kB
```

JS 幾乎全是 Leaflet 本身；CSS 是 `leaflet/dist/leaflet.css`。

### 測試

`npm test`：1 個測試檔、1 個測試，約 85 ms。

### `scripts/watch_drone.sh http://172.18.10.2:7070 5`

- 印出 10 行資料、耗時 5.19 s、exit 0、結束後無殘留程序。
- 間隔約 0.52 s（`sleep 0.5` ＋一次 curl 的時間），5 秒的紀錄實際多約 0.2 s。
- drone 連不上時每行印「連不上 <url>」，照樣在時限內結束、exit 0；參數錯誤 exit 2。

### dev server

- `npm run dev` 約 90 ms ready，http://localhost:5173/ 顯示地圖（截圖：`docs/screenshots/step-1-map.png`）。
- proxy 有轉發：後端未啟動時 `GET /api/health` 回 502，dev server 終端印出
  `http proxy error: /api/health ... ECONNREFUSED 127.0.0.1:8100`。

### drone-1 當下狀態（只讀，本 step 未下任何指令）

- 18:43 左右：`flight_mode=15`、`is_armed=false`、`is_ready_to_arm=true`、`gps_fix_type=6`；
  ROADMAP 規劃當時記的是 `is_ready_to_arm=false`（QRTL），已不同。
- 19:16：`is_armed=true`、`flight_mode=20`（QLAND）、`alt_rel≈3.0`——**當時有別的 GCS／session 在操作 drone-1**。
  step-3 驗收前要先確認沒有其他人在下指令（工作流程規則 9）。
- `/get_drone_state` 共 45 個欄位。

### 踩坑

1. **`tsc` 報出 40 個 `node_modules/vite/...` 的錯誤**（`Cannot find name 'Buffer'`、`node:http` 等）。
   原本以為把 `vite.config.ts` 放進 `include` 讓它也被型別檢查比較周全；實際上它會把 Vite 的型別檔
   一起拉進來。組成（實測）：39 個在 `node_modules/vite/dist/node/index.d.ts`，其中 37 個是 TS2591
   （找不到 `Buffer`、`node:http` 等名稱）——該檔第一行 `/// <reference types="node" />` 要 Node 的型別，
   而本專案沒裝 `@types/node`；另 1 個在 `node_modules/rolldown/...`（TS2550，`asyncDispose` 需要 `lib: esnext`）。
   修法：`include` 只放 `src`。（一度同時開了 `skipLibCheck`；事後在全新 clone 上分開測：
   只改 `include` → 0 個錯誤；只開 `skipLibCheck` 也是 0 個，但那只是把套件型別檔的錯誤藏起來。
   所以只保留 `include` 這一項，`tsconfig` 少一個選項。）
   用「故意在 `src/main.ts` 放一個型別錯誤」確認 `tsc` 仍會抓到 `src/` 的錯誤。
2. **`pgrep -f watch_drone` 在腳本已結束後仍回報 1 個程序。** 原本以為 `-f` 比對全指令列最保險；
   實際上它比對到的是「呼叫 pgrep 的那個 shell」，因為那個 shell 的指令列本身就含有 `watch_drone` 字樣。
   改用 `pgrep -x watch_drone.sh`（只比對程序名稱）。同一個坑查 vite 殘留時又踩一次：
   `pgrep -f vite` 同樣會算到自己。**變體**（寫教材時又踩一次）：`ps -eo pid,cmd | grep '[v]ite'` 也會中——
   `[v]` 只擋得住 grep 比對到自己，當下那條指令裡寫到 `reader-vite.log` 這種檔名時，照樣比對到自己的 shell。
   可靠的做法是比對程序名稱：`for p in $(pgrep -x node); do tr '\0' ' ' < /proc/$p/cmdline; echo; done | grep vite`。
3. **背景啟動 dev server 時 `setsid npm run dev &` 的 `$!` 不是 process group。** 在有 job control 的 shell 裡，
   背景工作本身就是 group leader，`setsid` 會再 fork 一次、父程序馬上結束，`kill -- -$!` 收不到 vite。
   第一階段的 `scripts/` 不在背景起任何程式（工作流程規則 6），這裡只影響手動驗收；
   要收 dev server 時用 `ps -eo pgid,cmd | grep '[n]ode_modules/.bin/vite'` 找到 PGID 再 `kill -- -<PGID>`
   （這裡的 grep 只用來找 PGID，比對到自己的 shell 頂多多送一個訊號給已結束的 group，不影響結果；確認殘留仍要用上面那個比對程序名稱的做法）。
   另外實測：vite 殘留佔住 5173 時，再 `npm run dev` 會印 `Port 5173 is in use, trying another one...` 並改用 5174，
   瀏覽器若還開著 5173，看到的就是舊的那個 server。
4. headless Chrome 的 `--window-size=1280,800` 含工具列高度，實際 viewport 約 712 px，
   截圖底部會有一條白邊——不是版面問題（側欄邊框線也停在同一高度）。

### 教材 `docs/step01.html` 與冷讀（開 PR 後補上）

- 章節在 PR 開出後才補寫（step-execution 不寫教材，當時誤把「頁不存在」當成跳過冷讀的理由；
  頁不存在是因為沒寫）。已把「每個 step 附一章」寫進 ROADMAP 的 Definition of Done。
- 寫章時回頭實測，發現踩坑 1 原本的修法寫錯了：`include` 與 `skipLibCheck` 各自單獨都能消掉錯誤，
  已拿掉 `skipLibCheck`（見踩坑 1）。`tsconfig.json` 的註解也從「lib 只有 dom」更正為「本專案沒裝 Node 的型別」。
- 冷讀兩支：連續性回報 13 項，全部回核成立（實跑確認：在既有 clone 內 `git switch` 可行；40 個錯誤是
  39 個 vite＋1 個 rolldown；位址不存在時 `watch_drone.sh 5` 實測 9.07 s、被拒絕時 5.06 s）。
  身分冷讀（設定：會 Python／FastAPI 的 drone 開發者、沒碰過前端）回報 22 項，補了 18 項；
  沒改的：`audited 51` 的 51 無法從 lock 檔推得（lock 有 74 筆）所以不解釋、`Object.is equality`、
  bash 的 `[[ =~ ]]`／`for ((…))`（註解已足夠猜出用途）。
- 兩張手繪 SVG 以 headless Chrome 在強制淺色／強制深色兩份副本下截圖檢查過；未在真人瀏覽器上看過。
