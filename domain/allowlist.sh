#!/bin/bash

# 清理旧文件
echo "Clean..."
rm -f domain.txt allow.txt invalid_rules.txt important_rules.txt adblocker_with_prefix.txt tmp_detect_* tmp_merge.txt

# 提取纯域名函数
extract_domain_from_rule() {
    echo "Processing: $1"  # 调试信息，查看当前正在处理的规则
    # 支持中间带连字符 "--" 的域名
    if [[ "$1" =~ ^@@\|\|([a-zA-Z0-9.-]+(?:--[a-zA-Z0-9]+)*\.[a-zA-Z]{2,})\^$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$1" =~ ^@@([a-zA-Z0-9.-]+(?:--[a-zA-Z0-9]+)*\.[a-zA-Z]{2,})$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$1" =~ ^([a-zA-Z0-9.-]+(?:--[a-zA-Z0-9]+)*\.[a-zA-Z]{2,})$ ]]; then
        echo "$1"
    fi
}

# 下载+转换函数
download_and_convert() {
    local url="$1"
    local tmpfile="tmp_detect_$(echo "$url" | md5sum | cut -c1-8).txt"
    content=$(wget --no-check-certificate -t 3 -T 10 --waitretry=5 -q -O - "$url")

    if [[ -n "$content" ]]; then
        echo "$content" > "$tmpfile"
        encoding=$(uchardet "$tmpfile" | awk '{print $1}')
        iconv -f "$encoding" -t UTF-8//IGNORE "$tmpfile" 2>/dev/null || cat "$tmpfile"
    fi

    rm -f "$tmpfile"
}

export -f download_and_convert

# 处理规则列表函数
process_list() {
    local input_list=$1 output_file=$2 invalid_file=$3 important_file=$4
    echo "Merging $output_file..."

    # 先筛选出包含 $important 的规则，存入 important_rules.txt
    grep -v '^#' "$input_list" | grep -v '^[[:space:]]*$' | grep '\$important' > "$important_file"

    # 剩下的规则不包含 $important
    grep -v '^#' "$input_list" | grep -v '^[[:space:]]*$' | grep -v '\$important' | parallel -j 10 download_and_convert {} > tmp_merge.txt

    awk '{ print $1 }' tmp_merge.txt | while read -r domain; do
        [[ "$domain" =~ ^[!#\<] ]] && continue

        # 排除无效的规则
        if [[ "$domain" =~ ^(REG|ALL|Blocked|RZD)$ || "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            continue
        fi

        pure_domain=$(extract_domain_from_rule "$domain")

        # 如果规则包含 $important，且非域名，存入 important_rules.txt
        if [[ "$domain" =~ \$important && -z "$pure_domain" ]]; then
            echo "$domain" >> "$important_file"
        elif [[ -n "$pure_domain" ]]; then
            echo "$pure_domain"
        elif [[ -z "$pure_domain" && "$domain" != *$'\n' ]]; then
            # 仅将那些未匹配到域名且含有有意义规则的行加入无效文件
            echo "$domain" >> "$invalid_file"
        fi
    done | sort -u > "$output_file"

    rm -f tmp_merge.txt
}

# 执行处理
process_list "allowlist" "domain.txt" "invalid_rules.txt" "important_rules.txt"
wait

# 清理空行和空格
echo "Cleaning up domain list..."
sed -i '/^$/d' domain.txt
sed -i 's/[[:space:]]//g' domain.txt

echo "Cleaning up invalid rules list..."
sed -i '/^$/d' invalid_rules.txt
sed -i 's/[[:space:]]//g' invalid_rules.txt
sort -u invalid_rules.txt -o invalid_rules.txt

echo "Cleaning up important rules list..."
sed -i '/^$/d' important_rules.txt
sed -i 's/[[:space:]]//g' important_rules.txt
sort -u important_rules.txt -o important_rules.txt

# 添加 adblock 前缀
echo "Adding @@||^ prefix to domain list..."
while read -r domain; do
    echo "@@||$domain^"
done < domain.txt > adblocker_with_prefix.txt

# 完成提示
echo "Pure domain list generated in 'domain.txt'."
echo "Invalid rules saved in 'invalid_rules.txt'."
echo "Important rules saved in 'important_rules.txt'."
echo "Adblocker list with @@||^ prefix saved in 'adblocker_with_prefix.txt'."
