#!/usr/bin/env bash
set -eu
#set -x
# -e: エラーが発生した時点でスクリプトを終了
# -u: 未定義の変数を使用した場合にエラーを発生
# -x: スクリプトの実行内容を表示(debugで利用)

#
# 通知
#
echo '----[ 🚀Create index🚀 ]'

#
# index
#
readonly DB_NAME='isuride'
echo '--'
echo "DB_NAME(合っているか確認してください): ${DB_NAME}"
echo '--'
while read server; do
  #
  # CREATE Index
  #
  # コピペ時: ここから
  index_name='idx_rides_chair_id_updated_at'
  sql="create index ${index_name} on rides(chair_id, updated_at DESC);"
  echo "${sql}"
  ssh -n ${server} "sudo mysql ${DB_NAME} -e '${sql}'" || echo "index: ${index_name}は既に有るので問題なし(Duplicate key nameならば)"
  echo ''
  # コピペ時: ここまで

  # コピペ時: ここから
  index_name='idx_ride_statuses_ride_id_created_at'
  sql="create index ${index_name} on ride_statuses(ride_id, created_at);"
  echo "${sql}"
  ssh -n ${server} "sudo mysql ${DB_NAME} -e '${sql}'" || echo "index: ${index_name}は既に有るので問題なし(Duplicate key nameならば)"
  echo ''
  # コピペ時: ここまで

  # コピペ時: ここから
  index_name='idx_ride_statuses_ride_id_chair_sent_at_created_at'
  sql="create index ${index_name} on ride_statuses(ride_id, chair_sent_at, created_at);"
  echo "${sql}"
  ssh -n ${server} "sudo mysql ${DB_NAME} -e '${sql}'" || echo "index: ${index_name}は既に有るので問題なし(Duplicate key nameならば)"
  echo ''
  # コピペ時: ここまで

  # コピペ時: ここから
  index_name='idx_ride_statuses_ride_id_app_sent_at_created_at'
  sql="create index ${index_name} on ride_statuses(ride_id, app_sent_at, created_at);"
  echo "${sql}"
  ssh -n ${server} "sudo mysql ${DB_NAME} -e '${sql}'" || echo "index: ${index_name}は既に有るので問題なし(Duplicate key nameならば)"
  echo ''
  # コピペ時: ここまで

  #
  # DROP Index
  #
  #sql="drop index idx_post_id on comments;"
  #echo "${sql}"
  #ssh -n ${server} "sudo mysql ${DB_NAME} -e '${sql}'" || echo 'index無し'
  #echo ''
done < <(cat tmp/isu-servers)

echo 'make show-tables で確認してください'

#
# 通知
#
echo '----'
echo '👍️Done: Create index'
echo '----'
