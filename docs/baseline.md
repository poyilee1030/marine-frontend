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

1. **`tsc` 報出 40 幾個 `node_modules/vite/...` 的錯誤**（`Cannot find name 'Buffer'`、`node:http` 等）。
   原本以為把 `vite.config.ts` 放進 `include` 讓它也被型別檢查比較周全；實際上它會把 Vite 的
   Node 端型別一起拉進來，而本專案 `lib` 只有 `dom`。
   修法：`include` 只放 `src`，並開 `skipLibCheck`（Vite 官方範本也開）。
   用「故意在 `src/main.ts` 放一個型別錯誤」確認 `tsc` 仍會抓到 `src/` 的錯誤。
2. **`pgrep -f watch_drone` 在腳本已結束後仍回報 1 個程序。** 原本以為 `-f` 比對全指令列最保險；
   實際上它比對到的是「呼叫 pgrep 的那個 shell」，因為那個 shell 的指令列本身就含有 `watch_drone` 字樣。
   改用 `pgrep -x watch_drone.sh`（只比對程序名稱）。同一個坑查 vite 殘留時又踩一次：
   `pgrep -f vite` 同樣會算到自己；查殘留請用 `ps -eo pid,cmd | grep '[v]ite'`。
3. **背景啟動 dev server 時 `setsid npm run dev &` 的 `$!` 不是 process group。** 在有 job control 的 shell 裡，
   背景工作本身就是 group leader，`setsid` 會再 fork 一次、父程序馬上結束，`kill -- -$!` 收不到 vite。
   第一階段的 `scripts/` 不在背景起任何程式（工作流程規則 6），這裡只影響手動驗收；
   要收 dev server 時用 `ps -eo pgid,cmd | grep '[n]ode_modules/.bin/vite'` 找到 PGID 再 `kill -- -<PGID>`。
4. headless Chrome 的 `--window-size=1280,800` 含工具列高度，實際 viewport 約 712 px，
   截圖底部會有一條白邊——不是版面問題（側欄邊框線也停在同一高度）。
