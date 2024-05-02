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
import pandas as pd
data = [[],[],[],[],[]]
try_cnt = [0,0,0,0,0]
# args = sys.argv[1:]
for line in sys.stdin:
    if len(line.split()) == 1: continue
    probid, result, timestr, _ = line.split()

    level = subprocess.run("cat problems/" + probid + ".json | jq .level", stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    level = int(level.stdout.strip())

    group = -1
    if 11 <= level and level <= 13:
        group = 0
    elif 14 <= level and level <= 15:
        group = 1
    elif 16 <= level and level <= 18:
        group = 2
    elif 19 <= level and level <= 20:
        group = 3
    elif 21 <= level:
        group = 4

    try_cnt[group] += 1

    if result == "fail":
       continue

    splits = timestr.split(":")
    if len(splits) == 2:
        dt = int(splits[0]) * 60 + int(splits[1])
    else:
        dt = int(splits[0]) * 60 * 60 + int(splits[1]) * 60 + int(splits[2])

    if dt > 3600:
        continue

    data[group].append(dt)

    df0 = pd.DataFrame({ "Value": data[0], "Level": "Easy Gold" })
    df1 = pd.DataFrame({ "Value": data[1], "Level": "Hard Gold" })
    df2 = pd.DataFrame({ "Value": data[2], "Level": "Easy Plat" })
    df3 = pd.DataFrame({ "Value": data[3], "Level": "Hard Plat" })
    df4 = pd.DataFrame({ "Value": data[4], "Level": "Diamond+" })
    combined_df = pd.concat([df0, df1, df2, df3, df4])

palette = {
    "Easy Gold": "#D28500",
    "Hard Gold": "#FFB028",
    "Easy Plat": "#00C78B",
    "Hard Plat": "#51FDBD",
    "Diamond+": "#00B4FC",
}

import matplotlib.pyplot as plt
import seaborn as sns
ax = sns.histplot(data=combined_df, x="Value", hue="Level", palette=palette, stat="count", multiple="stack", bins=range(0, 3601, 300), fill=True)
ax.set_xlim(0, 3600)
ax.set_xticks(range(0, 3601, 300))
ax.get_figure().savefig("fig.png")

percentage = [0 if try_cnt[i] == 0 else len(data[i]) / try_cnt[i] * 100 for i in range(len(try_cnt))]
tmp_data = {
    "Sector": ["Easy Gold", "Hard Gold", "Easy Plat", "Hard Plat", "Diamond+"],
    "Percentage": percentage,
}
df = pd.DataFrame(tmp_data)

_, ax = plt.subplots()
sns.barplot(x="Sector", y="Percentage", hue="Sector", data=df, palette=palette)
plt.xlabel("")  # Remove x-axis label
plt.title("Percentage by Sector")
plt.ylabel("Percentage")
plt.ylim(0, 100)

for bar in ax.patches:
    h, w, x = bar.get_height(), bar.get_width(), bar.get_x()
    xy = (x + w / 2., h/2)
    text = f"{h:.1f}%"
    ax.annotate(text=text, xy=xy, ha="center", va="center")

plt.savefig("ratio.png")
' "$@"
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
