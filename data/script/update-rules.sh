#!/bin/sh
LC_ALL='C'

# 清理临时文件
rm *.txt

wait
echo '创建临时文件夹'
mkdir -p ./tmp/

# 添加补充规则
cp ./data/rules/adblock.txt ./tmp/rules01.txt
cp ./data/rules/whitelist.txt ./tmp/allow01.txt

cd tmp

# 下载规则并处理
# 下载 yhosts 规则
curl https://raw.githubusercontent.com/VeleSila/yhosts/master/hosts | sed '/0.0.0.0 /!d; /#/d; s/0.0.0.0 /||/; s/$/\^/' > rules001.txt

# 下载大圣净化规则
curl https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts > rules002.txt
sed -i '/视频/d;/奇艺/d;/微信/d;/localhost/d' rules002.txt
sed -i '/127.0.0.1 /!d; s/127\.0\.0\.1 /||/; s/$/\^/' rules002.txt

# 下载乘风视频过滤规则
curl https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/mv.txt | awk '!/^$/{if($0 !~ /[#^|\/\*\]\[\!]/){print "||"$0"^"} else if($0 ~ /[#\$|@]/){print $0}}' | sort -u > rules003.txt

echo '下载规则'
rules=(
  "https://filters.adtidy.org/android/filters/2_optimized.txt"
  "https://filters.adtidy.org/android/filters/11_optimized.txt"
  "https://filters.adtidy.org/android/filters/17_optimized.txt"
  "https://filters.adtidy.org/android/filters/3_optimized.txt"
  "https://filters.adtidy.org/android/filters/224_optimized.txt"
  "https://perflyst.github.io/PiHoleBlocklist/SmartTV-AGH.txt"
#!/bin/sh
LC_ALL='C'

# 清理临时文件
rm *.txt

wait
echo '创建临时文件夹'
mkdir -p ./tmp/

# 添加补充规则
cp ./data/rules/adblock.txt ./tmp/rules01.txt
cp ./data/rules/whitelist.txt ./tmp/allow01.txt

cd tmp

# 下载规则并处理
# 下载 yhosts 规则
curl -v https://raw.githubusercontent.com/VeleSila/yhosts/master/hosts | sed '/0.0.0.0 /!d; /#/d; s/0.0.0.0 /||/; s/$/\^/' > rules001.txt

# 下载大圣净化规则
curl -v https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts > rules002.txt
sed -i '/视频/d;/奇艺/d;/微信/d;/localhost/d' rules002.txt
sed -i '/127.0.0.1 /!d; s/127\.0\.0\.1 /||/; s/$/\^/' rules002.txt

# 下载乘风视频过滤规则
curl -v https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/mv.txt | awk '!/^$/{if($0 !~ /[#^|\/\*\]\[\!]/){print "||"$0"^"} else if($0 ~ /[#\$|@]/){print $0}}' | sort -u > rules003.txt

echo '下载规则'
rules=(
  "https://filters.adtidy.org/android/filters/2_optimized.txt"
  "https://filters.adtidy.org/android/filters/11_optimized.txt"
  "https://filters.adtidy.org/android/filters/17_optimized.txt"
  "https://filters.adtidy.org/android/filters/3_optimized.txt"
  "https://filters.adtidy.org/android/filters/224_optimized.txt"
  "https://perflyst.github.io/PiHoleBlocklist/SmartTV-AGH.txt"
  "https://easylist-downloads.adblockplus.org/easyprivacy.txt"
  "https://raw.githubusercontent.com/Noyllopa/NoAppDownload/master/NoAppDownload.txt"
  "https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.adblock"
  "https://small.oisd.nl/"
  "https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt"
  "https://anti-ad.net/easylist.txt"
  "https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt"
  "https://mirror.ghproxy.com/raw.githubusercontent.com/8680/GOODBYEADS/master/dns.txt"
)

allow=(
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/ChineseFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/GermanFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/TurkishFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/Kuroba-Sayuki/FuLing-AdRules/Master/FuLingRules/FuLingAllowList.txt"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-referral.txt"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-urlshortener.txt"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/adblock/whitelist-referral-native.txt"
  "https://raw.githubusercontent.com/greatcoolge/neodevhost/refs/heads/master/allow"
  "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/allowlist.txt"
  "https://raw.githubusercontent.com/privacy-protection-tools/dead-horse/master/anti-ad-white-list.txt"
  "https://raw.githubusercontent.com/liwenjie119/adg-rules/master/white.txt"
  "https://raw.githubusercontent.com/ChengJi-e/AFDNS/master/QD.txt"
)

# 并行下载规则文件
for i in "${!rules[@]}" "${!allow[@]}"
do
  # 通过 tee 命令将日志输出到终端并同时写入文件
  curl -v --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "rules${i}.txt" --connect-timeout 60 -s "${rules[$i]}" | tee -a download_log.txt &
  curl -v --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "allow${i}.txt" --connect-timeout 60 -s "${allow[$i]}" | tee -a download_log.txt &
done
wait
echo '规则下载完成'

# 处理规则
file="$(ls | sort -u)"
for i in $file; do
  echo -e '\n' >> $i &
done
wait

# 处理基础规则
cat | sort -n | grep -v -E "^((#.*)|(\s*))$" \
  | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|local|loopback)$" \
  | grep -Ev "local.*\.local.*$" \
  | sed s/127.0.0.1/0.0.0.0/g | sed s/::/0.0.0.0/g | grep '0.0.0.0' | grep -Ev '.0.0.0.0 ' | sort \
  | uniq > base-src-hosts.txt &
wait

# 转换 Hosts 规则为 ABP 规则
cat base-src-hosts.txt | grep -Ev '#|\$|@|!|/|\\|\*' \
  | grep -v -E "^((#.*)|(\s*))$" \
  | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" \
  | sed 's/127.0.0.1 //' | sed 's/0.0.0.0 //' \
  | sed "s/^/||&/g" | sed "s/$/&^/g" | sed '/^$/d' \
  | grep -v '^#' \
  | sort -n | uniq | awk '!a[$0]++' \
  | grep -E "^((\|\|)\S+\^)" & # Hosts 规则转 ABP 规则

# 允许域名转 ABP 规则
cat *.txt | sed '/^$/d' | grep -v '#' \
  | grep -v '^@@' \
  | sed "s/^/@@||&/g" | sed "s/$/&^/g" \
  | sort -n | uniq | tee /tmp/debug_output.txt | awk '!a[$0]++' &

wait

# 合并多个规则文件，去重重复规则，并处理允许清单
cat *.txt | sed '/^$/d' | grep -v '#' \
  | sed '/^@@/!s/$/&^/g' | sort -n | uniq > merged_rules.txt &

# 处理允许清单（@@ 开头的规则），输出到 allow.txt 文件
cat *.txt | sed '/^$/d' | grep -v '#' \
  | grep '^@@' | sort -n | uniq > allow.txt &

wait
echo "规则转换和文件合并完成"

# 处理 AdGuard 规则
cat rules*.txt | grep -Ev "^((\!)|(\[)).*" \
  | sort -n | uniq | awk '!a[$0]++' > tmp-rules.txt &

# 处理允许列表规则
cat | grep -E "^[(\@\@)|(\|\|)][^\/\^]+\^$" \
  | grep -Ev "([0-9]{1,3}.){3}[0-9]{1,3}" \
  | sort | uniq > ll.txt &

wait

# 允许清单处理
cat *.txt | grep '^@' | sort -n | uniq > tmp-allow.txt &
wait

cp tmp-allow.txt .././allow.txt
cp tmp-rules.txt .././rules.txt

echo "规则合并完成"

# Python 处理重复规则
python .././data/python/rule.py
python .././data/python/filter-dns.py

# Start Add title and date
python .././data/python/title.py

wait
echo '更新成功'

exit
