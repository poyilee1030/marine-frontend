# CLAUDE.md

給 agent／新 session 的單一入口。計畫、選型與規則的權威來源是 [ROADMAP.md](ROADMAP.md)；本檔只放「動手前要知道的事」。

## 維護者

維護者是 drone 開發者，**不熟前端**。只用 ROADMAP 列出的主流工具與樸素寫法（ROADMAP 工作流程規則 10），
不要引入 ROADMAP 沒列的套件，也不要用進階技巧；解釋前端概念時用白話。

## 安裝與檢查

```bash
npm ci              # 安裝（照 package-lock.json；不要用 npm install，除非刻意新增／升級套件）
npm run check       # tsc --noEmit
npm test            # vitest run
npm run build       # tsc --noEmit && vite build
```

三條都要過才能開 PR（工作流程規則 7）。

## 執行前置條件

```bash
# 1. SITL（marlin-drone）
cd ~/poyi/marlin-drone && bash multiple_sitl/create_dockers.sh 1 --autopilot ardupilot
# 2. 後端（marine-backend-py，:8100）
cd ~/GitHubPoyi/marine-backend-py && scripts/dev.sh
# 3. 前端
cd ~/GitHubPoyi/marine-frontend && npm run dev     # http://localhost:5173
```

drone-1 的 API 在 `http://172.18.10.2:7070`。驗收量 drone 自己的 `GET /get_drone_state`
（`scripts/watch_drone.sh`），不量畫面（工作流程規則 4）。

## 流程

- 一個 step ＝ 一個 branch（`step-N-<短名>`）＝ 一個 PR，標題 `step-N: <一句話目標>`。
- `src/view.ts` 的純函式**先寫測試、看它紅、再實作**（工作流程規則 11）。
- 每個 step 在 `docs/baseline.md` 最後面追加一段（append-only），含踩坑；開工前先讀上一段。
- PR 用 GitHub REST API 開（本機沒有 `gh`），token 取自 `git remote get-url origin`。
  remote URL 內嵌 PAT 是維護者的習慣，不要改動 remote。
- 其餘規則：ROADMAP「工作流程規則」；出問題時：ROADMAP「出問題時看哪裡」。

## 已知的坑（細節見 docs/baseline.md）

- 查殘留程序不要用 `pgrep -f <字串>`：會比對到呼叫它的 shell 自己。用 `pgrep -x <程序名>` 或 `ps -eo pid,cmd | grep '[v]ite'`。
- `tsconfig.json` 的 `include` 只放 `src`；把 `vite.config.ts` 放進去會拉進 Vite 的 Node 型別而報一堆錯。
