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

# Function to process list and handle invalid rules
process_list() {
    local input_list=$1 output_file=$2 invalid_file=$3 tmp_file="tmp_$output_file"
    echo "Merging $output_file..."
    grep -v '^#' "$input_list" | xargs -P 5 -I {} wget --no-check-certificate -t 1 -T 10 -q -O - "{}" > "$tmp_file"

    awk '{ print $1 }' "$tmp_file" | while read domain; do
        # Ignore comments or blocked domains (starting with ! or #), or lines with <
        [[ "$domain" =~ ^[#!<] ]] && continue  

        pure_domain=$(extract_domain_from_rule "$domain")

        # If the domain contains $important, treat it as invalid and save it to the invalid file
        if [[ "$domain" =~ \$important ]]; then
            echo "$domain" >> "$invalid_file"
        elif [[ -n "$pure_domain" ]]; then
            # If the domain is valid (without $important), output it
            echo "$pure_domain"
        else
            echo "$domain" >> "$invalid_file"
        fi
    done | sort -u > "$output_file"

    rm -f "$tmp_file"
}

# Only process allowlist
process_list "allowlist" "domain.txt" "invalid_rules.txt"
wait

# Clean up domain list
echo "Cleaning up domain list..."
sed -i '/^$/d' domain.txt
sed -i 's/[[:space:]]//g' domain.txt

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
