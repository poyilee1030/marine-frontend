#!/usr/bin/env bash
# 直接向 drone 查狀態，每 0.5 秒查一次、共查 <seconds>×2 次，印完就結束。
# drone 正常回應時總共約 <seconds> 秒；drone 不回應時每次還要多等最多 0.4 秒（curl 逾時），
# 總時間最多拉長到約 1.8 倍。每一行印的都是查詢當下的實際時間。
# 用途：驗收時量「drone 實際上怎麼了」，而不是看網頁上的數字（ROADMAP 工作流程規則 4）。
#
# 用法：scripts/watch_drone.sh <drone_url> <seconds>
# 例如：scripts/watch_drone.sh http://172.18.10.2:7070 300
# 需要：curl、jq
set -euo pipefail

# 秒數只收 1 以上、開頭不是 0 的整數：bash 會把 08、010 這種開頭是 0 的數字當成八進位。
if [ $# -ne 2 ] || ! [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
  echo "用法：$0 <drone_url> <seconds>   例：$0 http://172.18.10.2:7070 5" >&2
  exit 2
fi
if ! command -v jq >/dev/null; then
  echo "需要 jq（Ubuntu：sudo apt install jq）" >&2
  exit 2
fi

drone_url="${1%/}"
count=$(( $2 * 2 )) # 每 0.5 秒一次

echo "時間 alt_rel is_armed flight_mode"
for (( i = 0; i < count; i++ )); do
  now=$(date +%H:%M:%S.%3N)
  # --max-time：drone 沒回應時最多等 0.4 秒，保證迴圈不會卡住。
  # 單次失敗不中止整段紀錄，印一行說明原因，繼續量。
  # jq 放在自己的 if 裡：寫成 echo 的參數 $(... | jq ...) 的話，jq 失敗 bash 也不會發現。
  if ! json=$(curl -sf --max-time 0.4 "$drone_url/get_drone_state"); then
    echo "$now 連不上 $drone_url"
  elif ! fields=$(echo "$json" | jq -r '"\(.alt_rel) \(.is_armed) \(.flight_mode)"' 2>/dev/null); then
    echo "$now 回應不是預期的 JSON"
  else
    echo "$now $fields"
  fi
  sleep 0.5
done
