.PHONY: check-required-commands
check-required-commands: ## 必要なコマンドが入っているかチェック
	@bash scripts/check-required-commands.sh

.PHONY: bench
bench: ## benchmarkerを実行(private-isu用)
	@make clean-logs
	ssh isu-bench 'private_isu.git/benchmarker/bin/benchmarker -u private_isu.git/benchmarker/userdata -t http://192.168.1.10/'

.PHONY: clean
clean: ## isuconでDLしたものを全て削除
	@rm -rf isu-* tmp/*
	@mkdir isu-webapp isu-common
	@touch isu-webapp/.gitkeep isu-common/.gitkeep

.PHONY: getting-started
getting-started: ## Getting Started
	@echo '01: isuconのCFn Stackを作成'
	@echo '```tmp/hosts.csv'
	@echo 'isu-1,IPアドレス1'
	@echo 'isu-bench,IPアドレス2'
	@echo '```'
	@echo '02: make create-sshconfig(awsと通信したくない場合は、事前にtmp/hosts.csvを用意)'
	@echo '03: make check-ssh'
	@echo '04: make setup'
	@echo '05: make show-services'
	@echo '06: cat .env || cp .env.sample .env && direnv allow'
	@echo '07: vim .env (ssh isu-1をして.envに必要情報を記述)'
	@echo '08: make download でisu-commonやisu-webにDL'
	@echo '09: make switch-to-golang-isu-app で動くアプリの言語を変更する'
	@echo '10: make deploy-app'
	@echo '11: make setup-1st-bench'
	@echo '- isu-common/etc/nginx/nginx.confに設定をペースト'
	@echo '12: make deploy-config この時点で、localからmysqlに繋げられる'
	@echo '13: make deploy-one-shot-scripts'
	@echo '14: make show-table-counts'
	@echo '15: make show-tables'
	@echo '16: make clean-logs'
	@echo '17: benchmark(ボタンポチ)'
	@echo '18: make download-and-analyze-logs'
	@echo '- make alp-result'
	@echo '- make slow-query-result'
	@echo '- scripts/download-and-analyze-logs.shのalpの-mオプションを調整(パスなどを正規表現で調整)'
	@echo '19: make show-table-counts(ベンチマーク後、user数が増えているはず)'
	@echo '20: make show-tables'
	@echo '21: 改善 → git push → 11や13へ'
	@echo '----'
	@echo 'ex-app: `grep -rn "Open(" isu-webapp/` して、 `&interpolateParams=true` を追加する'
	@echo 'ex-app: `make put-pprof-go` すると、pprofの用意'
	@echo '----[ oneshot ]'
	@echo 'ex-app: `make put-cache-users-sample-go` すると、キャッシュのサンプルを置く'
	@echo 'ex-app: `make put-writeout-images-go` すると、画像書き出しのone shotスクリプトを置く'
	@echo '----[ db,nginx ]'
	@echo 'ex-db: `make create-index` (scripts/create-index.shをいじる)'
	@echo 'ex-nginx: `cat snippets/nginx-static-files/README.md` すると、静的ファイルをnginxで返す方法'
	@echo 'ex-nginx: `cat snippets/nginx-images/README.md` すると、画像ファイルをnginxで返す方法(少しappとも関係あり)'

tmp/hosts.csv: ## tmp/hosts.csvをAWSと通信して作成
	@bash scripts/create-hosts-csv.sh

.PHONY: create-sshconfig
create-sshconfig: tmp/hosts.csv ## ~/.ssh/config-for-isucon.d/config 作成
	@bash scripts/create-sshconfig.sh

.PHONY: check-ssh
check-ssh: tmp/hosts.csv ## sshできるか確認
	@cat tmp/hosts.csv | cut -d',' -f1 | xargs -I{} bash -c 'echo "----[ {} ]" && ssh {} "ls"'

.PHONY: setup
setup: ## 各isu-serverのセットアップ
	@bash scripts/setup-apt-get.sh
	#@bash scripts/setup-fluent-bit.sh
	@bash scripts/setup-mysql-users.sh
	@bash scripts/setup-alp.sh

.PHONY: setup-1st-bench
setup-1st-bench: ## 1回目のbenchmarkに必要なことを各isu-serverのセットアップ
	@bash scripts/setup-1st-bench-nginx.sh
	@bash scripts/setup-1st-bench-mysql.sh
	@echo 'この時点では、まだリモートサーバに反映されていません'
	# prometheus と fluent-bitはまた今度
	#@bash scripts/setup-1st-bench-prometheus-mysqld-exporter.sh
	#@bash scripts/setup-1st-bench-fluent-bit.sh

.PHONY: reup
reup: ## コンテナを再アップ
	@bash scripts/reup-containers.sh

.PHONY: loki-sample
loki-sample: ## Lokiにちゃんとログが入っているか確認
	$(eval START=$(shell date -u +'%Y-%m-%dT00:00:00+09:00'))
	$(eval END=$(shell date -u +'%Y-%m-%dT23:59:59+09:00'))
	$(eval JOB='nginx.access')
	@curl -s "http://localhost:3100/loki/api/v1/query_range" --data-urlencode 'query={job="nginx.access"}' --data-urlencode 'start=${START}' --data-urlencode 'end=${END}' --data-urlencode 'limit=10' | jq '.data.result'

################################################################################
# ポートフォワーディング for Loki
################################################################################
.PHONY: port-forward-3100-isu-1
port-forward-3100-isu-1: ## 3100番ポートをフォワード
	$(call port-forward-3100,isu-1)

.PHONY: port-forward-3100-isu-2
port-forward-3100-isu-2: ## 3100番ポートをフォワード
	$(call port-forward-3100,isu-2)

.PHONY: port-forward-3100-isu-3
port-forward-3100-isu-3: ## 3100番ポートをフォワード
	$(call port-forward-3100,isu-3)

.PHONY: port-forward-3100-isu-4
port-forward-3100-isu-4: ## 3100番ポートをフォワード
	$(call port-forward-3100,isu-4)

.PHONY: port-forward-3100-isu-5
port-forward-3100-isu-5: ## 3100番ポートをフォワード
	$(call port-forward-3100,isu-5)

################################################################################
# Kaizen
################################################################################
.PHONY: initialize-webapp
initialize-webapp: ## アプリのinitialize URLを叩く
	@bash scripts/initialize-webapp.sh

.PHONY: clean-logs
clean-logs: ## ログファイルを削除
	@bash scripts/clean-logs.sh

.PHONY: download-and-analyze-logs
download-and-analyze-logs: ## ログファイルをダウンロードして分析
	@bash scripts/download-and-analyze-logs.sh

.PHONY: alp
alp: ## alpコマンドを tmp/analysis/latest/nginx-access.log.isu-1 に打つ(マッチンググループのデバッグ用)
	@bash scripts/alp.sh

.PHONY: alp-result
alp-result: ## alpの結果を表示
	@cat tmp/analysis/latest/analyzed-alp-nginx-access.log.*

.PHONY: slow-query-result
slow-query-result: ## slow-queryの結果を表示
	@cat tmp/analysis/latest/analyzed-pt-query-digest-slow.log.* | less

.PHONY: create-index
create-index: ## scripts/create-index.sh
	@bash scripts/create-index.sh

.PHONY: put-pprof-go
put-pprof-go: ## pprof.goを置く
	@bash scripts/put-pprof-go.sh

.PHONY: put-cache-users-sample-go
put-cache-users-sample-go: ## cache_users_sample.goを置く
	@bash scripts/put-cache-users-sample-go.sh

.PHONY: put-writeout-images-go
put-writeout-images-go: ## writeout-imagesを置く
	@bash scripts/put-writeout-images-go.sh

################################################################################
# Deploy
################################################################################
.PHONY: deploy-config
deploy-config: ## 各サーバに設定ファイルをデプロイ
	@bash scripts/deploy-config.sh

.PHONY: deploy-app
deploy-app: ## 各サーバにAppをデプロイ
	@bash scripts/deploy-app.sh

.PHONY: deploy-one-shot-scripts
deploy-one-shot-scripts: ## 各サーバにdeploy-one-shot-scriptsをデプロイ
	@bash scripts/deploy-one-shot-scripts.sh

################################################################################
# Switch to golang app
################################################################################
.PHONY: switch-to-golang-isu-app
switch-to-golang-isu-app: ## golangのアプリケーションに切り替え
	@bash scripts/switch-to-golang-isu-app.sh

################################################################################
# Download
################################################################################
.PHONY: download
download: ## isucon関連の利用するファイルをダウンロード
	@bash scripts/download-webapp.sh
	@bash scripts/download-nginx.sh
	@bash scripts/download-mysql.sh
	@bash scripts/download-env.sh

################################################################################
# Info
################################################################################
.PHONY: show-services
show-services: ## isuconに関連があるサービス一覧表示
	@bash scripts/show-services.sh

.PHONY: show-table-counts
show-table-counts: tmp/db-tables ## isuconに関連があるdb.tableのカウント一覧
	@bash scripts/show-table-counts.sh

.PHONY: show-tables
show-tables: tmp/db-tables ## isuconに関連があるdb.table情報一覧
	@bash scripts/show-tables.sh

.PHONY: update-db-statistcs
update-db-statistics: tmp/db-tables ## isuconに関連があるdb.table情報一覧
	@bash scripts/update-db-statistics.sh

tmp/db-tables: ## tmp/db-tablesを作成(isuconに関連がある)
	@bash scripts/create-db-tables.sh

################################################################################
# Utility-Command help
################################################################################
.DEFAULT_GOAL := getting-started

################################################################################
# マクロ
################################################################################
# Makefileの中身を抽出してhelpとして1行で出す
# $(1): Makefile名
# 使い方例: $(call help,{included-makefile})
define help
  grep -E '^[\.a-zA-Z0-9_-]+:.*?## .*$$' $(1) \
  | grep --invert-match "## non-help" \
  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
endef

# 指定されたhostに3100番のポートフォワーディング
# $(1): ホスト名
# 使い方例: $(call port-forward-3100,host名)
define port-forward-3100
  (grep '$(1)' tmp/isu-servers &> /dev/null && ssh $(1) -R 3100:localhost:3100 -N) || echo '$(1)がありません'
endef

################################################################################
# タスク
################################################################################
.PHONY: help
help: ## Make タスク一覧
	@echo '######################################################################'
	@echo '# Makeタスク一覧'
	@echo '# $$ make XXX'
	@echo '# or'
	@echo '# $$ make XXX --dry-run'
	@echo '######################################################################'
	@echo $(MAKEFILE_LIST) \
	| tr ' ' '\n' \
	| xargs -I {included-makefile} $(call help,{included-makefile})
