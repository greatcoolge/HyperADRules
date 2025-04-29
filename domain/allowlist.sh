#!/bin/bash

# 创建临时文件夹
TMP_DIR="tmp_domain_work"
mkdir -p "$TMP_DIR"

# 清理旧文件
echo "Clean..."
rm -f domain.txt allow.txt invalid_rules.txt adblocker_with_prefix.txt
rm -f "$TMP_DIR"/*

# 提取纯域名函数
extract_domain_from_rule() {
    local rule="$1"
    if [[ "$rule" =~ ^@@\|\|([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\^$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$rule" =~ ^@@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$rule" =~ ^([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$ ]]; then
        echo "$rule"
    fi
}

# 下载+转换函数（处理乱码）
download_and_convert() {
    local url="$1"
    local tmpfile="$TMP_DIR/$(echo "$url" | md5sum | cut -c1-8).txt"
    local outfile="${tmpfile}.converted"

    content=$(wget --no-check-certificate -t 3 -T 10 --waitretry=5 -q -O - "$url")
    [[ -z "$content" ]] && return

    echo "$content" > "$tmpfile"
    encoding=$(uchardet "$tmpfile" | awk '{print $1}')
    
    if iconv -f "$encoding" -t UTF-8//IGNORE "$tmpfile" -o "$outfile" 2>/dev/null; then
        cat "$outfile"
    else
        echo "Warn: Failed to convert $url from $encoding" >&2
    fi
}

export -f download_and_convert

# 处理规则列表函数
process_list() {
    local input_list=$1 output_file=$2 invalid_file=$3
    echo "Processing $output_file..."

    grep -vE '^\s*$|^\s*#' "$input_list" | parallel -j 10 download_and_convert {} > "$TMP_DIR/merged.txt"

    awk '{ print $1 }' "$TMP_DIR/merged.txt" | while read -r line; do
        [[ "$line" =~ ^[!#\<] ]] && continue
        [[ "$line" =~ \$important ]] && echo "$line" >> "$invalid_file" && continue

        if [[ "$line" =~ ^(REG|ALL|Blocked|RZD)$ || "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            continue
        fi

        domain=$(extract_domain_from_rule "$line")

        if [[ -n "$domain" ]]; then
            echo "$domain"
        else
            echo "$line" >> "$invalid_file"
        fi
    done | grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | sort -u > "$output_file"
}

# 执行处理
process_list "allowlist" "domain.txt" "invalid_rules.txt"
wait

# 清理无效与空行
echo "Cleaning up domain list..."
sed -i '/^$/d;s/[[:space:]]//g' domain.txt

echo "Cleaning up invalid rules..."
sed -i '/^$/d;s/[[:space:]]//g' invalid_rules.txt
sort -u invalid_rules.txt -o invalid_rules.txt

# 生成带 adblock 前缀的列表
echo "Generating adblocker list..."
awk '{ printf("@@||%s^\n", $0) }' domain.txt > adblocker_with_prefix.txt

# 清理临时目录
rm -rf "$TMP_DIR"

# 完成提示
echo "Pure domain list generated in 'domain.txt'."
echo "Invalid rules saved in 'invalid_rules.txt'."
echo "Adblocker list with @@||^ prefix saved in 'adblocker_with_prefix.txt'."
