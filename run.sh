#!/usr/bin/env bash

set -Eeu

msg() {
	printf >&2 "%s\n" "${1:-}"
}

die() {
	local msg=${1:-}
	local code=${2:-1}
	if [[ -n $msg ]]; then
		msg "$msg"
	fi
	exit "$code"
}

fetchprob() {
	local problemid="$1"
	if ! [[ -f "problems/$problemid.json" ]]; then
		msg "fetching problem info for problem $problemid..."
		mkdir -p problems
		curl -sSLo "problems/$problemid.json" "https://solved.ac/api/v3/problem/show?problemId=$problemid"
	fi
}

fetchprobs() {
	cat rpd.txt | awk 'NF==4{print $1}' | xargs -P8 -n1 "$0" fetchprob
}

drawfig() {
	cat rpd.txt | .venv/bin/python3 -c '
import sys
import subprocess
data = []
args = sys.argv[1:]
print(args)
for line in sys.stdin:
    if len(line.split()) == 1: continue
    probid, result, timestr, _ = line.split()
    if result == "fail":
        continue
    level = subprocess.run("cat problems/" + probid + ".json | jq .level", stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    level = int(level.stdout.strip())
    if level < int(args[0]) or level > int(args[1]):
        continue
    splits = timestr.split(":")
    if len(splits) == 2:
        dt = int(splits[0]) * 60 + int(splits[1])
    else:
        dt = int(splits[0]) * 60 * 60 + int(splits[1]) * 60 + int(splits[2])
    data.append(dt)

import matplotlib.pyplot as plt
import seaborn as sns
ax = sns.histplot(data=data, stat="count", binwidth=300)
ax.set_xlim(0, 3600)
ax.xaxis.set_ticks(range(0, 3601, 300))
ax.get_figure().savefig("fig.png")
' "$@"
	# open -a Preview fig.png
}

# track() {
# 	local projectids=("$@")
# 	local interval=30
# 	local timestamp
# 	while true; do
# 		for projectid in "${projectids[@]}"; do
# 			mkdir -p "$projectid"
# 			timestamp=$(date +'%s')
# 			msg "fetching stats for project $projectid at $(date -d @"$timestamp")..."
# 			curl -o "$projectid/$timestamp.json" "https://www.makestar.co/_n/project/v1/$projectid/story"
# 		done
# 		sleep "$interval"
# 	done
# }

# archive() {
# 	local projectids=("$@")
# 	for projectid in "${projectids[@]}"; do
# 		msg "archiving project $projectid to $projectid.tar.gz..."
# 		tar -caf "$projectid.tar.gz" "$projectid" && rm -r "$projectid"
# 	done
# }

# awk() {
# 	stdbuf -oL awk "$@"
# }

# dates() {
# 	local projectid=$1
# 	find "$projectid" -iname '*.json' | sort -V | sed 's/.*\/\(.*\).json/\1/g' | python3 -c '
# import sys
# from datetime import datetime
# for line in sys.stdin:
#     print(datetime.fromtimestamp(int(line.strip())).isoformat())
# '
# }

# sales() {
# 	local projectid=$1
# 	find "$projectid" -iname '*.json' | sort -V | xargs -d$'\n' cat |
# 		jq -r '.resData.krProjectDTO.rewards[] | .title + "\t" + (.saleCount | tostring)'
# }

# stats() {
# 	local projectid=$1
# 	local rewardcnt
# 	rewardcnt=$(jq -r '.resData.krProjectDTO.rewards | length' "$(find "$projectid" -iname '*.json' | head -n1)")
# 	paste <(dates "$projectid" | awk -v cnt="$rewardcnt" '{for (i=0; i<cnt; i++) print}') <(sales "$projectid") |
# 		awk -F'\t' 'BEGIN {OFS=FS} counts[$2]!=$3 {print $1, $2, $3-counts[$2]; counts[$2]=$3}'
# }

# amounts() {
# 	local projectid=$1
# 	find "$projectid" -iname '*.json' | sort -V | xargs -d$'\n' cat |
# 		jq -r '.resData | (.cnt | tostring) + "\t" + (.amount | tostring)'
# }

# newstats() {
# 	local projectid=$1
# 	paste <(dates "$projectid") <(amounts "$projectid") |
# 		awk -F'\t' 'BEGIN {OFS=FS} cnt!=$2 {print $1, $2-cnt, $3-amt; cnt=$2; amt=$3}'
# }

# rank() {
# 	awk -F'\t' 'BEGIN {OFS=FS} {print $3, $1}' | sort -srh | awk -F'\t' 'BEGIN {OFS=FS} {print $2, $1}'
# }

"$@"
