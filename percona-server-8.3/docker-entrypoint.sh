#!/bin/bash

# script from https://github.com/percona/percona-docker/blob/main/percona-xtradb-cluster-8.0/dockerdir/entrypoint.sh
set -eo pipefail
shopt -s nullglob
set -o xtrace

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi
CFG=/etc/mysql/node.cnf

# skip setup if they want an option that stops mysqld
wantHelp=
for arg; do
	case "$arg" in
		-'?'|--help|--print-defaults|-V|--version)
			wantHelp=1
			break
			;;
	esac
done

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	set +o xtrace
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
	set -o xtrace
}

# usage: process_init_file FILENAME MYSQLCOMMAND...
#    ie: process_init_file foo.sh mysql -uroot
# (process a single initializer file, based on its extension. we define this
# function here, so that initializer scripts (*.sh) can use the same logic,
# potentially recursively, or override the logic used in subsequent calls)
process_init_file() {
	local f="$1"; shift
	local mysql=( "$@" )

	case "$f" in
		*.sh)     echo "$0: running $f"; . "$f" ;;
		*.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
		*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
		*)        echo "$0: ignoring $f" ;;
	esac
	echo
}

_check_config() {
	toRun=( "$@" --verbose --help --wsrep-provider='none' )
	if ! errors="$("${toRun[@]}" 2>&1 >/dev/null)"; then
		cat >&2 <<-EOM

			ERROR: mysqld failed while attempting to check config
			command was: "${toRun[*]}"

			$errors
		EOM
		exit 1
	fi
}

# Fetch value from server config
# We use mysqld --verbose --help instead of my_print_defaults because the
# latter only show values present in config files, and not server defaults
_get_config() {
	local conf="$1"; shift
	"$@" --verbose --help --wsrep-provider='none' --log-bin-index="$(mktemp -u)" 2>/dev/null \
		| awk '$1 == "'"$conf"'" && /^[^ \t]/ { sub(/^[^ \t]+[ \t]+/, ""); print; exit }'
	# match "datadir      /some/path with/spaces in/it here" but not "--xyz=abc\n     datadir (xyz)"
}

function join {
	local IFS="$1"; shift
	joined=$(tr "$IFS" '\n' <<< "$*" | sort -u | tr '\n' "$IFS")
	echo "${joined%?}"
}

# if vault secret file exists we assume we need to turn on encryption
vault_secret="/etc/mysql/vault-keyring-secret/keyring_vault.conf"
if [ -f "$vault_secret" ]; then
	sed -i "/\[mysqld\]/a early-plugin-load=keyring_vault.so" $CFG
	sed -i "/\[mysqld\]/a keyring_vault_config=$vault_secret" $CFG
	sed -i "/\[mysqld\]/a default_table_encryption=ON" $CFG
	sed -i "/\[mysqld\]/a table_encryption_privilege_check=ON" $CFG
	sed -i "/\[mysqld\]/a innodb_undo_log_encrypt=ON" $CFG
	sed -i "/\[mysqld\]/a innodb_redo_log_encrypt=ON" $CFG
	sed -i "/\[mysqld\]/a binlog_encryption=ON" $CFG
	sed -i "/\[mysqld\]/a binlog_rotate_encryption_master_key_at_startup=ON" $CFG
	sed -i "/\[mysqld\]/a innodb_temp_tablespace_encrypt=ON" $CFG
	sed -i "/\[mysqld\]/a innodb_parallel_dblwr_encrypt=ON" $CFG
	sed -i "/\[mysqld\]/a innodb_encrypt_online_alter_logs=ON" $CFG
	sed -i "/\[mysqld\]/a encrypt_tmp_files=ON" $CFG
fi

file_env 'XTRABACKUP_PASSWORD' 'xtrabackup'
file_env 'CLUSTERCHECK_PASSWORD' 'clustercheck'
NODE_NAME=$(hostname -f)
NODE_PORT=3306
# Is running in Kubernetes/OpenShift, so find all other pods belonging to the cluster
if [ -n "$PXC_SERVICE" ]; then
	echo "Percona XtraDB Cluster: Finding peers"
	/usr/bin/peer-list -on-start="/usr/bin/configure-pxc.sh" -service="${PXC_SERVICE}"
	CLUSTER_JOIN="$(grep '^wsrep_cluster_address=' "$CFG" | cut -d '=' -f 2 | sed -e 's^.*gcomm://^^')"
	echo "Cluster address set to: $CLUSTER_JOIN"
elif [ -n "$DISCOVERY_SERVICE" ]; then
	echo 'Registering in the discovery service'
	NODE_IP=$(hostname -I | awk ' { print $1 } ')

	if [ "${DISCOVERY_SERVICE:0:4}" != "http" ]; then
		DISCOVERY_SERVICE="http://${DISCOVERY_SERVICE}"
	fi
	curl "$DISCOVERY_SERVICE/v2/keys/pxc-cluster/queue/$CLUSTER_NAME" -XPOST -d value="$NODE_IP" -d ttl=60

	#get list of IP from queue
	i=$(curl "$DISCOVERY_SERVICE/v2/keys/pxc-cluster/queue/$CLUSTER_NAME" | jq -r '.node.nodes[].value')

	# this remove my ip from the list
	i1="${i[@]//$NODE_IP}"

	# Register the current IP in the discovery service
	# key set to expire in 30 sec. There is a cronjob that should update them regularly
	curl "$DISCOVERY_SERVICE/v2/keys/pxc-cluster/$CLUSTER_NAME/$NODE_IP/ipaddr" -XPUT -d value="$NODE_IP" -d ttl=30
	curl "$DISCOVERY_SERVICE/v2/keys/pxc-cluster/$CLUSTER_NAME/$NODE_IP/hostname" -XPUT -d value="$HOSTNAME" -d ttl=30
	curl "$DISCOVERY_SERVICE/v2/keys/pxc-cluster/$CLUSTER_NAME/$NODE_IP" -XPUT -d ttl=30 -d dir=true -d prevExist=true

	i=$(curl "$DISCOVERY_SERVICE/v2/keys/pxc-cluster/$CLUSTER_NAME/?quorum=true" | jq -r '.node.nodes[]?.key' | awk -F'/' '{print $(NF)}')
	# this remove my ip from the list
	i2="${i[@]//$NODE_IP}"
	CLUSTER_JOIN=$(join , $i1 $i2 )

	sed -r "s|^[#]?wsrep_node_address=.*$|wsrep_node_address=${NODE_IP}|" "${CFG}" 1<> "${CFG}"
	sed -r "s|^[#]?wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" "${CFG}" 1<> "${CFG}"
	sed -r "s|^[#]?wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${CLUSTER_JOIN}|" "${CFG}" 1<> "${CFG}"
	sed -r "s|^[#]?wsrep_node_incoming_address=.*$|wsrep_node_incoming_address=${NODE_NAME}:${NODE_PORT}|" "${CFG}" 1<> "${CFG}"

	/usr/bin/clustercheckcron clustercheck "${CLUSTERCHECK_PASSWORD}" 1 /var/lib/mysql/clustercheck.log 1 &

else
	: checking incoming cluster parameters
	NODE_IP=$(hostname -I | awk ' { print $1 } ')
	sed -r "s|^[#]?wsrep_node_address=.*$|wsrep_node_address=${NODE_IP}|" "${CFG}" 1<> "${CFG}"
	sed -r "s|^[#]?wsrep_node_incoming_address=.*$|wsrep_node_incoming_address=${NODE_NAME}:${NODE_PORT}|" "${CFG}" 1<> "${CFG}"

	if [[ -n "${CLUSTER_JOIN}" ]]; then
		sed -r "s|^[#]?wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${CLUSTER_JOIN}|" "${CFG}" 1<> "${CFG}"
	fi

	if [[ -n "${CLUSTER_NAME}" ]]; then
		sed -r "s|^[#]?wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" "${CFG}" 1<> "${CFG}"
	fi

fi

if [ ! -z "${PERCONA_INSTANCE_ID}" ]; then
  CALL_HOME_OPTIONAL_PARAMS+=" -i ${PERCONA_INSTANCE_ID}"
fi

if [ ! -z "${PERCONA_TELEMETRY_CONFIG_FILE_PATH}" ]; then
  CALL_HOME_OPTIONAL_PARAMS+=" -j ${PERCONA_TELEMETRY_CONFIG_FILE_PATH}"
fi

if [ ! -z "${PERCONA_SEND_TIMEOUT}" ]; then
  CALL_HOME_OPTIONAL_PARAMS+=" -t ${PERCONA_SEND_TIMEOUT}"
else
  CALL_HOME_OPTIONAL_PARAMS+=" -t 7"
fi

if [ ! -z "${PERCONA_CONNECT_TIMEOUT}" ]; then
  CALL_HOME_OPTIONAL_PARAMS+=" -c ${PERCONA_CONNECT_TIMEOUT}"
else
  CALL_HOME_OPTIONAL_PARAMS+=" -c 2"
fi

# if we have CLUSTER_JOIN - then we do not need to perform datadir initialize
# the data will be copied from another node

if [ -z "$CLUSTER_JOIN" ] && [ "$1" = 'mysqld' -a -z "$wantHelp" ]; then
	# still need to check config, container may have started with --user
	_check_config "$@"

	# Get config
	DATADIR="$(_get_config 'datadir' "$@")"

	if [ ! -d "$DATADIR/mysql" ]; then
		file_env 'MYSQL_ROOT_PASSWORD'
		if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
			echo >&2 'error: database is uninitialized and password option is not specified '
			echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD'
			exit 1
		fi

		rm -rf $DATADIR/* && mkdir -p "$DATADIR"

		echo 'Initializing database'
		"$@" --initialize-insecure --skip-ssl
		echo 'Database initialized'

		SOCKET="$(_get_config 'socket' "$@")"
		"$@" --skip-networking --socket="${SOCKET}" &
		pid="$!"

		mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" --password="" )
		wsrep_local_state_select="SELECT variable_value FROM performance_schema.global_status WHERE variable_name='wsrep_local_state_comment'"

		for i in {120..0}; do
			wsrep_local_state=$(echo "$wsrep_local_state_select" | "${mysql[@]}" -s 2> /dev/null) || true
			if [ "$wsrep_local_state" = 'Synced' ]; then
				break
			fi
			echo 'MySQL init process in progress...'
			sleep 1
		done
		if [ "$i" = 0 ]; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
			# sed is for https://bugs.mysql.com/bug.php?id=20545
			mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
		fi

		if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
			MYSQL_ROOT_PASSWORD="$(pwmake 128)"
			echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
		fi

		rootCreate=
		# default root to listen for connections from anywhere
		file_env 'MYSQL_ROOT_HOST' '%'
		if [ ! -z "$MYSQL_ROOT_HOST" -a "$MYSQL_ROOT_HOST" != 'localhost' ]; then
			# no, we don't care if read finds a terminating character in this heredoc
			# https://unix.stackexchange.com/questions/265149/why-is-set-o-errexit-breaking-this-read-heredoc-expression/265151#265151
			read -r -d '' rootCreate <<-EOSQL || true
				CREATE USER 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
				GRANT ALL ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ;
			EOSQL
		fi

		file_env 'MONITOR_HOST' 'localhost'
		file_env 'MONITOR_PASSWORD' 'monitor'
		"${mysql[@]}" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;

			DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root', 'mysql.infoschema', 'mysql.pxc.internal.session', 'mysql.pxc.sst.role', 'mysql.session') OR host NOT IN ('localhost') ;
			ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
			${rootCreate}

			CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY '${XTRABACKUP_PASSWORD}';
			GRANT RELOAD,PROCESS,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost';

			CREATE USER 'monitor'@'${MONITOR_HOST}' IDENTIFIED BY '${MONITOR_PASSWORD}' WITH MAX_USER_CONNECTIONS 10;
			GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO 'monitor'@'${MONITOR_HOST}';
			GRANT SELECT ON performance_schema.* TO 'monitor'@'${MONITOR_HOST}';

			CREATE USER 'clustercheck'@'localhost' IDENTIFIED BY '${CLUSTERCHECK_PASSWORD}';
			GRANT PROCESS ON *.* TO 'clustercheck'@'localhost';

			DROP DATABASE IF EXISTS test;
			FLUSH PRIVILEGES ;
		EOSQL

		if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
			mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
		fi

		file_env 'MYSQL_DATABASE'
		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
			mysql+=( "$MYSQL_DATABASE" )
		fi

		file_env 'MYSQL_USER'
		file_env 'MYSQL_PASSWORD'
		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" | "${mysql[@]}"

			if [ "$MYSQL_DATABASE" ]; then
				echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
			fi

			echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
		fi

		echo
		ls /docker-entrypoint-initdb.d/ > /dev/null
		for f in /docker-entrypoint-initdb.d/*; do
			process_init_file "$f" "${mysql[@]}"
		done

		if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
			"${mysql[@]}" <<-EOSQL
				ALTER USER 'root'@'%' PASSWORD EXPIRE;
			EOSQL
		fi
		if ! kill -s TERM "$pid" || ! wait "$pid"; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		echo
		echo 'MySQL init process done. Ready for start up.'
		echo
	fi

	# exit when MYSQL_INIT_ONLY environment variable is set to avoid starting mysqld
	if [ ! -z "$MYSQL_INIT_ONLY" ]; then
		echo 'Initialization complete, now exiting!'
		exit 0
	fi
fi

if [ "$1" = 'mysqld' -a -z "$wantHelp" ]; then
	"$@" --version | tee /tmp/version_info
	DATADIR="$(_get_config 'datadir' "$@")"
	if [ -f "$DATADIR/version_info" ] && ! diff /tmp/version_info "$DATADIR/version_info"; then
		SOCKET="$(_get_config 'socket' "$@")"
		"$@" --skip-networking --socket="${SOCKET}" --wsrep-provider='none' &
		pid="$!"

		mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" --password="" )
		if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
			mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
		fi

		for i in {120..0}; do
			if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
				break
			fi
			echo 'MySQL init process in progress...'
			sleep 1
		done
		if [ "$i" = 0 ]; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		mysql_upgrade "${mysql[@]:1}"
		if ! kill -s TERM "$pid" || ! wait "$pid"; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi
	fi
	"$@" --version > "$DATADIR/version_info"
	grep -v wsrep_sst_auth "$CFG"
fi

wsrep_start_position_opt=""
if [ "$1" = 'mysqld' -a -z "$wantHelp" ]; then
	DATADIR="$(_get_config 'datadir' "$@")"
	grastate_loc="${DATADIR}/grastate.dat"

	if [ -s "$grastate_loc" -a -d "$DATADIR/mysql" ]; then
		uuid=$(grep 'uuid:' "$grastate_loc" | cut -d: -f2 | tr -d ' ' || :)
		seqno=$(grep 'seqno:' "$grastate_loc" | cut -d: -f2 | tr -d ' ' || :)

		# If sequence number is not equal to -1, wsrep-recover co-ordinates aren't used.
		# lp:1112724
		# So, directly pass whatever is obtained from grastate.dat
		if [ -n "$seqno" ] && [ "$seqno" -ne -1 ]; then
			echo "Skipping wsrep-recover for $uuid:$seqno pair"
			echo "Assigning $uuid:$seqno to wsrep_start_position"
			wsrep_start_position_opt="--wsrep_start_position=$uuid:$seqno"
		fi
	fi

	if [ -z "$wsrep_start_position_opt" -a -d "$DATADIR/mysql" ]; then
		wsrep_verbose_logfile=$(mktemp $DATADIR/wsrep_recovery_verbose.XXXXXX)
		"$@" --wsrep_recover --log-error-verbosity=3 --log_error="$wsrep_verbose_logfile"

		if grep ' Recovered position:' "$wsrep_verbose_logfile"; then
			start_pos="$(
				grep ' Recovered position:' "$wsrep_verbose_logfile" \
					| sed 's/.*\ Recovered\ position://' \
					| sed 's/^[ \t]*//'
			)"
			wsrep_start_position_opt="--wsrep_start_position=$start_pos"
		else
			# The server prints "..skipping position recovery.." if started without wsrep.
			if grep 'skipping position recovery' "$wsrep_verbose_logfile"; then
				echo "WSREP: Position recovery skipped"
			else
				echo >&2 "WSREP: Failed to recover position: "
				cat "$wsrep_verbose_logfile"
				exit 1
			fi
		fi
		rm "$wsrep_verbose_logfile"
	fi
fi

# PERCONA_TELEMETRY_DISABLE is handled at the very beginning of call-home.sh
/call-home.sh -f "PRODUCT_FAMILY_PXC" -v "${PXC_TELEMETRY_VERSION}" -d "DOCKER" ${CALL_HOME_OPTIONAL_PARAMS} &> /dev/null || :

exec "$@" $wsrep_start_position_opt