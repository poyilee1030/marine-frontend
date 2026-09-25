#!/usr/bin/env bash
# 直接向 drone 查狀態，每 0.5 秒印一行，跑 <seconds> 秒後自己結束。
# 用途：驗收時量「drone 實際上怎麼了」，而不是看網頁上的數字（ROADMAP 工作流程規則 4）。
#
# 用法：scripts/watch_drone.sh <drone_url> <seconds>
# 例如：scripts/watch_drone.sh http://172.18.10.2:7070 300
# 需要：curl、jq
set -euo pipefail

if [ $# -ne 2 ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
  echo "用法：$0 <drone_url> <seconds>   例：$0 http://172.18.10.2:7070 5" >&2
  exit 2
fi

drone_url="${1%/}"
count=$(( $2 * 2 )) # 每 0.5 秒一次

echo "時間 alt_rel is_armed flight_mode"
for (( i = 0; i < count; i++ )); do
  now=$(date +%H:%M:%S.%3N)
  # --max-time：drone 沒回應時最多等 0.4 秒，保證迴圈不會卡住。
  # 單次失敗不中止整段紀錄，印一行「連不上」繼續量。
  if json=$(curl -sf --max-time 0.4 "$drone_url/get_drone_state"); then
    echo "$now $(echo "$json" | jq -r '"\(.alt_rel) \(.is_armed) \(.flight_mode)"')"
  else
    echo "$now 連不上 $drone_url"
  fi
  sleep 0.5
done
