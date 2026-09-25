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
- 每個 step 的程式碼（不含測試、docs）不超過 800 行，超過就拆成 `step-N-a`、`step-N-b`（工作流程規則 12）；PR 描述貼上規則 12 量法指令的輸出。
- 每個 step 在 `docs/baseline.md` 最後面追加一段（append-only），含踩坑；開工前先讀上一段。
- PR 用 GitHub REST API 開（本機沒有 `gh`），token 取自 `git remote get-url origin`。PR 標題與描述用繁體中文（工作流程規則 1）。
  remote URL 內嵌 PAT 是維護者的習慣，不要改動 remote。
- 每個 step 附一章教材 `docs/stepNN.html`（`incremental-html-textbook` skill；程式驗證完才寫），並更新 `docs/index.html`、前一章的 next 導覽；開 PR 前交給 `cold-read`（工作流程規則 2）。
- 教材快照同步：改到教材有引用的檔案時，`grep -l '<檔名或函式名>' docs/*.html` 找出引用它的章，核對節錄、輸出與數字。review 時「動到被引用的檔案、docs 卻沒動」就是一個 finding。
- 其餘規則：ROADMAP「工作流程規則」；出問題時：ROADMAP「出問題時看哪裡」。

## 已知的坑（細節見 docs/baseline.md）

- 查殘留程序不要用 `pgrep -f <字串>`，也不要用 `ps … | grep '[v]ite'`：兩者都會比對到呼叫它的 shell 自己的指令列（`[v]` 只擋得住 grep 本身，擋不住指令裡其他地方的 vite 字樣）。用程序名稱：`pgrep -x watch_drone.sh`；查 vite 用 `for p in $(pgrep -x node); do tr '\0' ' ' < /proc/$p/cmdline; echo; done | grep vite`。
- `tsconfig.json` 的 `include` 只放 `src`；把 `vite.config.ts` 放進去會拉進 Vite 的型別檔（它要 Node 的型別，本專案沒裝），報 40 個錯。
