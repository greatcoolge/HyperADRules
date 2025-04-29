#!/bin/bash

# Clean up old files
echo "Clean..."
rm -f domain.txt allow.txt invalid_rules.txt adblocker_with_prefix.txt

# Function to extract pure domain names
extract_domain_from_rule() {
    # Extract from @@||domain.com^
    if [[ "$1" =~ ^@@\|\|([a-zA-Z0-9.-]+)\^$ ]]; then
        echo "${BASH_REMATCH[1]}"
    # Extract from @@domain.com
    elif [[ "$1" =~ ^@@([a-zA-Z0-9.-]+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    # Extract from domain.com
    elif [[ "$1" =~ ^([a-zA-Z0-9.-]+)$ ]]; then
        echo "$1"
    else
        echo "Invalid rule format: $1"
    fi
}

# Function to process list and handle invalid rules
process_list() {
    local input_list=$1 output_file=$2 invalid_file=$3 tmp_file="tmp_$output_file"
    echo "Merging $output_file..."
    
    # Download list from URLs and process each domain
    grep -v '^#' "allowlist" | xargs -P 5 -I {} wget --no-check-certificate -t 1 -T 10 -q -O - "{}" > "$tmp_file"

    awk '{ print $1 }' "$tmp_file" | while read domain; do
        # Skip lines starting with ! or #
        [[ "$domain" =~ ^[!#] ]] && continue
        
        # Extract the domain and normalize
        pure_domain=$(extract_domain_from_rule "$domain")
        
        # Print for debugging purposes
        echo "Processed domain: $pure_domain"

        if [[ -n "$pure_domain" ]]; then
            echo "$pure_domain"
        else
            # Only add non-empty invalid rules
            if [[ -n "$domain" ]]; then
                echo "$domain" >> "$invalid_file"
            fi
        fi
    done | sort -u > "$output_file"

    rm -f "$tmp_file"
}

# Process allowlist
process_list "allowlist" "domain.txt" "invalid_rules.txt"
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
