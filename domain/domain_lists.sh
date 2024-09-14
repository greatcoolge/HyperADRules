#!/bin/sh

set -e  # 在命令出错时立即退出脚本，并返回非零退出码
set -x  # 输出每一条命令在执行时的状态

# 定义要处理的 URL 列表
urls="
https://raw.githubusercontent.com/Cats-Team/AdRules/script/script/allowlist.txt
https://raw.githubusercontent.com/privacy-protection-tools/dead-horse/master/anti-ad-white-list.txt
"

# 定义临时文件和输出文件的路径
temp_file="all_domains.txt"  # 临时文件保存在当前目录
output_dir="list"  # 指定目标目录（修改为所需的目录）
output_file="$output_dir/allow1.txt"  # 在指定目录下生成文件

# 输出调试信息
echo "Temporary file: $temp_file"
echo "Output directory: $output_dir"
echo "Output file: $output_file"

# 确保目标目录存在
mkdir -p "$output_dir" || { echo "Failed to create directory $output_dir"; exit 1; }

# 清空临时文件
> "$temp_file"

# 下载、过滤并合并所有域名列表
for url in $urls; do
  echo "Processing URL: $url"
  curl -s "$url" | awk 'NF && !/^#|^!/' >> "$temp_file" || { echo "Failed to process $url"; exit 1; }
done

# 创建最终的 allow1.txt 文件，添加 @@||...^ 格式
awk '{ print "@@||" $0 "^" }' "$temp_file" > "$output_file" || { echo "Failed to create $output_file"; exit 1; }

# 输出生成的文件路径
echo "Generated file: $output_file"

# 可选：查看生成的文件内容
cat "$output_file"

# 确保文件被写入并刷新
sync

# 清理临时文件
rm -f "$temp_file"

echo "Temporary file $temp_file has been deleted."

# 添加更新时间戳的逻辑
# 更新文件的时间戳，触发 Git 识别为变更
touch "$output_file"

# 提交更改到本地仓库
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Action"

# 添加并提交更改
git add "$output_file"
git commit -m "Forced update at $(date +'%Y-%m-%d %H:%M:%S')（北京时间）" || echo "No actual file changes, but forced commit."

# 可选：推送到远程仓库（如果需要）
# git push origin master
