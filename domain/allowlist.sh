#!/bin/sh
LC_ALL='C'

rm *.txt

wait
echo '创建临时文件夹'
mkdir -p ./tmp/

#添加补充规则
cp ./data/rules/adblock.txt ./tmp/rules01.txt
cp ./data/rules/whitelist.txt ./tmp/allow01.txt

cd tmp


echo '下载规则'
rules=(
  "https://raw.githubusercontent.com/hl2guide/Filterlist-for-AdGuard/master/filter_whitelist.txt"
  "https://raw.githubusercontent.com/Cats-Team/AdRules/script/script/allowlist.txt"
  "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt"
  "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt"
  "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/whitelist/master/domains.list"
  "https://raw.githubusercontent.com/neodevpro/neodevhost/master/ownallowlist"
  "https://raw.githubusercontent.com/EnergizedProtection/unblock/master/basic/formats/domains.txt"
  "https://raw.githubusercontent.com/217heidai/adblockfilters/refs/heads/main/rules/white.txt"
  "https://raw.githubusercontent.com/privacy-protection-tools/dead-horse/master/anti-ad-white-list.txt"
  "https://oisd.nl/excludes.php"
  "https://raw.githubusercontent.com/zoonderkins/blahdns/refs/heads/master/hosts/whitelist.txt"
 )

allow=(
  "https://raw.githubusercontent.com/Kuroba-Sayuki/FuLing-AdRules/Master/FuLingRules/FuLingAllowList.txt"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-referral.tx"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-urlshortener.txt"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/adblock/whitelist-referral-native.txt"
  "https://raw.githubusercontent.com/liwenjie119/adg-rules/master/white.txt"
  "https://raw.githubusercontent.com/ChengJi-e/AFDNS/master/QD.txt"
)

for i in "${!rules[@]}" "${!allow[@]}"
do
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "./tmp/rules${i}.txt" --connect-timeout 60 -s "${rules[$i]}" | iconv -t utf-8 &
  curl -m 60 --retry-delay 2 --retry 5 --parallel --parallel-immediate -k -L -C - -o "./tmp/allow${i}.txt" --connect-timeout 60 -s "${allow[$i]}" | iconv -t utf-8 &
done
wait
echo '规则下载完成'

# 添加空格
file="$(ls|sort -u)"
for i in $file; do
  echo -e '\n' >> $i &
done
wait

echo '处理规则中'

cat | sort -n| grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|local|loopback)$" \
 | grep -Ev "local.*\.local.*$" \
 | sort \
 |uniq >base-src-domain.txt &
wait
cat base-src-domain.txt | grep -Ev '#|\$|@|!|/|\\|\*'\
 | grep -v -E "^((#.*)|(\s*))$" \
 | grep -v -E "^[0-9f\.:]+\s+(ip6\-)|(localhost|loopback)$" \
  
 | sed "s/^/@@||&/g" |sed "s/$/&^/g"| sed '/^$/d' \
 | grep -v '^#' \
 | sort -n | uniq | awk '!a[$0]++' \
 | grep -E "^((\|\|)\S+\^)" & 

cat | sed '/^$/d' | grep -v '#' \
 | sed "s/^/@@||&/g" | sed "s/$/&^/g"  \
 | sort -n | uniq | awk '!a[$0]++' & #将允许域名转换为ABP规则

cat | sed '/^$/d' | grep -v "#" \
 |sed "s/^/@@||&/g" | sed "s/$/&^/g" | sort -n \
 | uniq | awk '!a[$0]++' & #将允许域名转换为ABP规则



echo 开始合并

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

# 删除临时文件夹及其内容
echo '删除临时文件夹'
rm -rf ./tmp/

exit
