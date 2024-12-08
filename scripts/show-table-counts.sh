#!/usr/bin/env bash
set -eu
#set -x
# -e: エラーが発生した時点でスクリプトを終了
# -u: 未定義の変数を使用した場合にエラーを発生
# -x: スクリプトの実行内容を表示(debugで利用)

#
# 通知
#
echo '-------[ 🚀Show services🚀 ]'

#
# 各テーブルのテーブルのCOUNT
#
#cat tmp/db-tables | grep -v '^DB'
while read -r server; do
  echo "----[ ${server} ]"
  while read -r db table; do
    ssh -n ${server} "sudo mysql -e \"select '${db}.${table}', count(1) from ${db}.${table};\" | tail -n1"
  done < <(cat tmp/db-tables | grep -v '^DB')
done < <(cat tmp/isu-servers)
