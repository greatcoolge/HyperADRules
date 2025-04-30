import os
import re
import requests
import hashlib
import subprocess
from concurrent.futures import ThreadPoolExecutor
from chardet import detect


# 清理旧文件
def clean_files():
    print("Clean...")
    files_to_remove = ["domain.txt", "allow.txt", "invalid_rules.txt", "adblocker_with_prefix.txt",
                       "tmp_detect_*", "tmp_merge.txt"]
    for file in files_to_remove:
        if os.path.exists(file):
            os.remove(file)


# 提取纯域名函数
def extract_domain_from_rule(rule):
    match = re.match(r'^@@\|\|([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\^?$', rule)
    if match:
        return match.group(1)
    match = re.match(r'^@@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$', rule)
    if match:
        return match.group(1)
    match = re.match(r'^([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$', rule)
    if match:
        return rule
    return None


# 下载并转换函数
def download_and_convert(url, log_file, allowlist_tmp):
    tmpfile = f"tmp_detect_{hashlib.md5(url.encode()).hexdigest()[:8]}.txt"
    print(f"Downloading from {url}...")

    try:
        content = requests.get(url, timeout=10).text
        if content:
            with open(tmpfile, "w", encoding="utf-8") as f:
                f.write(content)
            # 检测编码并转换为 UTF-8
            encoding = detect(content)['encoding']
            with open(tmpfile, 'r', encoding=encoding) as f:
                content = f.read()
            with open(allowlist_tmp, "a", encoding="utf-8") as f:
                f.write(content)
            with open(log_file, "a") as log:
                log.write(f"Downloaded and processed: {url}\n")
        else:
            with open(log_file, "a") as log:
                log.write(f"Failed to download or no content for {url}\n")
    except Exception as e:
        with open(log_file, "a") as log:
            log.write(f"Error downloading {url}: {str(e)}\n")
    finally:
        if os.path.exists(tmpfile):
            os.remove(tmpfile)


# 处理规则列表函数
def process_list(input_list, output_file, invalid_file, allowlist_tmp, log_file):
    print(f"Merging {output_file}...")
    with open(input_list, "r", encoding="utf-8") as file:
        lines = file.readlines()

    with ThreadPoolExecutor(max_workers=10) as executor:
        for url in lines:
            url = url.strip()
            if url and not url.startswith(("#", " ")):
                executor.submit(download_and_convert, url, log_file, allowlist_tmp)

    with open(output_file, "w", encoding="utf-8") as out_file, open(invalid_file, "w", encoding="utf-8") as invalid_file:
        with open(allowlist_tmp, "r", encoding="utf-8") as file:
            for line in file:
                domain = line.strip()
                if domain.startswith(("#", "<", "!", "^")):
                    continue
                if any(domain.startswith(prefix) for prefix in ["REG", "ALL", "Blocked", "RZD"]) or re.match(r'^\d+\.\d+\.\d+\.\d+$', domain):
                    continue
                pure_domain = extract_domain_from_rule(domain)
                if "$important" in domain:
                    invalid_file.write(domain + "\n")
                elif pure_domain:
                    out_file.write(pure_domain + "\n")
                else:
                    invalid_file.write(domain + "\n")

    os.remove(allowlist_tmp)


# 集成allowlist URL列表
allowlist_urls = [
    "https://raw.githubusercontent.com/Kuroba-Sayuki/FuLing-AdRules/Master/FuLingRules/FuLingAllowList.txt",
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-referral.txt",
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-urlshortener.txt",
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/adblock/whitelist-referral-native.txt",
    "https://raw.githubusercontent.com/privacy-protection-tools/dead-horse/master/anti-ad-white-list.txt",
    "https://raw.githubusercontent.com/liwenjie119/adg-rules/master/white.txt",
    "https://raw.githubusercontent.com/Cats-Team/AdRules/script/script/allowlist.txt",
    "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt",
    "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt",
    "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/whitelist/master/domains.list",
    "https://raw.githubusercontent.com/neodevpro/neodevhost/master/ownallowlist",
    "https://raw.githubusercontent.com/EnergizedProtection/unblock/master/basic/formats/domains.txt",
    "https://raw.githubusercontent.com/217heidai/adblockfilters/refs/heads/main/rules/white.txt",
    "https://oisd.nl/excludes.php",
    "https://raw.githubusercontent.com/zoonderkins/blahdns/refs/heads/master/hosts/whitelist.txt"
]

# 临时文件名
allowlist_tmp = "allowlist_combined.txt"
log_file = "script.log"

# 清理旧文件
clean_files()

# 下载并合并allowlist文件
print("Downloading allowlist URLs...")
with open(allowlist_tmp, "w", encoding="utf-8") as f:
    pass  # 清空文件

for url in allowlist_urls:
    download_and_convert(url, log_file, allowlist_tmp)

# 执行处理
process_list("allowlist_combined.txt", "domain.txt", "invalid_rules.txt", allowlist_tmp, log_file)

# 清理空行和空格
print("Cleaning up domain list...")
with open("domain.txt", "r+", encoding="utf-8") as file:
    lines = [line.strip() for line in file.readlines() if line.strip()]
    file.seek(0)
    file.truncate(0)
    file.writelines(f"{line}\n" for line in sorted(set(lines)))

print("Cleaning up invalid rules list...")
with open("invalid_rules.txt", "r+", encoding="utf-8") as file:
    lines = [line.strip() for line in file.readlines() if line.strip()]
    file.seek(0)
    file.truncate(0)
    file.writelines(f"{line}\n" for line in sorted(set(lines)))

# 添加 adblock 前缀
print("Adding @@||^ prefix to domain list...")
with open("adblocker_with_prefix.txt", "w", encoding="utf-8") as file:
    with open("domain.txt", "r", encoding="utf-8") as domain_file:
        for domain in domain_file:
            file.write(f"@@||{domain.strip()}^\n")

# 完成提示
print("Pure domain list generated in 'domain.txt'.")
print("Invalid rules saved in 'invalid_rules.txt'.")
print("Adblocker list with @@||^ prefix saved in 'adblocker_with_prefix.txt'.")
