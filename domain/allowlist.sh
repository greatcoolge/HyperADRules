#!/bin/bash

# Clean up old files
echo "Clean..."
rm -f domain.txt allow.txt invalid_rules.txt adblocker_with_prefix.txt

# Function to extract pure domain names
extract_domain_from_rule() {
    # Extract from @@||domain.com^
    if [[ "$1" =~ ^@@\|\|([a-zA-Z0-9.-]+)\^$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$1" =~ ^([a-zA-Z0-9.-]+)$ ]]; then
        echo "$1"
    fi
}

# Function to normalize domain (keep only base domain)
normalize_domain() {
    domain=$1
    domain_parts=($(echo "$domain" | tr '.' ' '))
    num_parts=${#domain_parts[@]}
    if [[ $num_parts -gt 2 ]]; then
        echo "${domain_parts[$num_parts-2]}.${domain_parts[$num_parts-1]}"
    else
        echo "$domain"
    fi
}

# Function to remove subdomains if parent domain exists
process_domains() {
    local input_file=$1 output_file=$2
    echo "Processing domain list..."
    declare -A domain_map
    while read -r domain; do
        normalized_domain=$(normalize_domain "$domain")
        domain_map["$normalized_domain"]=1
    done < "$input_file"
    for domain in "${!domain_map[@]}"; do
        echo "$domain"
    done > "$output_file"
}

# Process allowlist
process_list() {
    local output_file=$1 invalid_file=$2 tmp_file="tmp_$output_file"
    echo "Merging $output_file..."
    # 从allowlist读取URL并下载内容
    grep -v '^#' "allowlist" | xargs -P 5 -I {} wget --no-check-certificate -t 1 -T 10 -q -O - "{}" > "$tmp_file"

    awk '{ print $1 }' "$tmp_file" | while read domain; do
        [[ "$domain" =~ ^! ]] && continue  # 跳过以 ! 开头的规则（比如 !blocked.com）

        pure_domain=$(extract_domain_from_rule "$domain")
        normalized_domain=$(normalize_domain "$pure_domain")

        if [[ -n "$normalized_domain" ]]; then
            echo "$normalized_domain"
        else
            echo "$domain" >> "$invalid_file"
        fi
    done | sort -u > "$output_file"

    rm -f "$tmp_file"
}

# Only process allowlist
process_list "domain.txt" "invalid_rules.txt"
wait

# Clean up domain list
echo "Cleaning up domain list..."
sed -i '/^$/d' domain.txt
sed -i 's/[[:space:]]//g' domain.txt

# Remove subdomains if parent exists
process_domains "domain.txt" "domain.txt"

# Clean up invalid_rules list
echo "Cleaning up invalid rules list..."
sed -i '/^$/d' invalid_rules.txt
sed -i 's/[[:space:]]//g' invalid_rules.txt
sort -u invalid_rules.txt -o invalid_rules.txt

# Generate adblocker with @@|| prefix
echo "Adding @@||^ prefix to domain list..."
while read domain; do
    echo "@@||$domain^"
done < domain.txt > adblocker_with_prefix.txt

# Done
echo "Pure domain list generated in 'domain.txt'."
echo "Invalid rules saved in 'invalid_rules.txt'."
echo "Adblocker list with @@||^ prefix saved in 'adblocker_with_prefix.txt'."
