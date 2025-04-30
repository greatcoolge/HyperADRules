#!/bin/sh
LC_ALL='C'

rm *.txt
wait
echo '创建临时文件夹'
mkdir -p ./tmp/

# 下载规则列表
echo '下载规则'
rules=(
  "https://raw.githubusercontent.com/hl2guide/Filterlist-for-AdGuard/master/filter_whitelist.txt"
  "https://raw.githubusercontent.com/Cats-Team/AdRules/script/script/allowlist.txt"
  # 添加更多规则源
)

allow=(
  "https://raw.githubusercontent.com/Kuroba-Sayuki/FuLing-AdRules/Master/FuLingRules/FuLingAllowList.txt"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-referral.tx"
  # 添加更多允许列表源
)

# 处理规则列表
echo '下载规则列表'
for i in "${!rules[@]}"
do
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "rules${i}.txt" --connect-timeout 60 -s "${rules[$i]}" | iconv -t utf-8 &
done
wait

# 处理允许列表
echo '下载允许列表'
for i in "${!allow[@]}"
do
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "allow${i}.txt" --connect-timeout 60 -s "${allow[$i]}" | iconv -t utf-8 &
done
wait

echo '规则下载完成'

# 添加空格
file="$(ls|sort -u)"
for i in $file; do
  echo -e '\n' >> $i &
done
wait


# 合并规则并去重
echo '处理规则和允许列表'
cat rules*.txt | sort -n | grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|local|loopback)$" \
 | grep -Ev "local.*\.local.*$" \
 | sort \
 | uniq > base-src-domain.txt
wait
cat base-src-domain.txt | grep -Ev '#|\$|@|!|/|\\|\*' \
 | grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" \
 | sed "s/^/@@||&/g" | sed "s/$/&^/g" | sed '/^$/d' \
 | grep -v '^#' \
 | sort -n | uniq | awk '!a[$0]++' \
 | grep -E "^((\|\|)\S+\^)" > tmp-rules.txt
wait

cat allow*.txt | grep -v '#' | sed '/^$/d' \
 | sed "s/^/@@||&/g" | sed "s/$/&^/g" \
 | sort -n | uniq | awk '!a[$0]++' > tmp-allow.txt
wait

# 最终合并文件
cat tmp-allow.txt tmp-rules.txt > final-rules.txt

# 运行Python处理后续
python .././data/python/rule.py
python .././data/python/filter-dns.py
python .././data/python/title.py

echo '更新成功'
exit
