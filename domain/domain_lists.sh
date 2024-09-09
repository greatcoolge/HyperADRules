curl -s "$url" | awk 'NF && !/^#|^!/' >> "$temp_file"
if [ $? -ne 0 ]; then
  echo "curl 或 awk 命令失败"
  exit 1
fi
