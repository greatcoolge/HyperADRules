#!/bin/sh
LC_ALL='C'

rm *.txt
wait
echo '创建临时文件夹'
mkdir -p ./tmp/

#添加补充规则
cp ./data/rules/adblock.txt ./tmp/rules01.txt
cp ./data/rules/whitelist.txt ./tmp/allow01.txt
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
| grep -v '!' | grep -P -v '[\x80-\xFF]' \
| sort -n | uniq | awk '!a[$0]++' > tmp-allow.txt
wait

# 最终合并文件
echo '合并并去重规则和允许列表'

# 合并允许列表和规则列表
cat tmp-allow.txt tmp-rules.txt | \
  # 过滤掉空行和注释行
  grep -v -E '^(\s*$|#)' | \
  # 去除无效的规则（如包含特殊字符或 IP 地址）
  grep -Ev '#|\$|@|!|/|\\|\*|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
  # 确保规则格式一致，去掉额外的空格
  sed 's/^[ \t]*//;s/[ \t]*$//' | \
  # 排序并去重
  sort -u > final-rules.txt

echo '更新成功'

# 运行Python处理后续
python .././data/python/rule.py
python .././data/python/title.py

echo '更新成功'
exit
