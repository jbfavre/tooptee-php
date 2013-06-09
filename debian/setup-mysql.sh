#!/bin/sh

set -eu

[ $# -ge 2 ] || {
    echo "Usage: debian/setup-mysql.sh port data-dir" >&2
    exit 1
}

# CLI arguments #
port=$1
datadir=$2
action=${3:-start}

localbase=`dirname $datadir`/mysql_base

if [ "$(id -u)" -eq 0 ];
then
    myuser="mysql"
else
    myuser=$(whoami)
fi
echo "********** Running MySQL as $myuser"
# Some vars #

socket=$datadir/mysql.sock
# Commands:
mysqladmin="mysqladmin -u root -P $port -h localhost --socket=$socket"
mysqld="$localbase/bin/mysqld --no-defaults --bind-address=127.0.0.1 --port=$port --socket=$socket --datadir=$datadir --user=$myuser"

# Main code #

if [ "$action" = "stop" ]; then
    $mysqladmin shutdown
    rm -rf $localbase
    exit
fi

# Copy the necessary pieces of mysql to a local dir to avoid apparmor restrictions
rm -rf $localbase
mkdir -p $localbase/bin
mkdir -p $localbase/share
cp /usr/sbin/mysqld $localbase/bin
cp /usr/bin/my_print_defaults $localbase/bin
cp -r /usr/share/mysql $localbase/share

rm -rf $datadir
mkdir -p $datadir
chmod go-rx $datadir

mysql_install_db --basedir=$localbase --datadir=$datadir --rpm --force --tmpdir=/tmp --user=$myuser >> $datadir/install_db.log 2>&1

tmpf=$(mktemp)
cat > "$tmpf" <<EOF
USE mysql;
UPDATE user SET password=PASSWORD('') WHERE user='root';
FLUSH PRIVILEGES;
EOF

$mysqld --bootstrap --skip-grant-tables < "$tmpf" >> $datadir/bootstrap.log 2>&1

unlink "$tmpf"

# Start the daemon
$mysqld > $datadir/run.log 2>&1 &

pid=$!

# wait for the server to be actually available
c=0;
while ! nc -z localhost $port; do
    c=$(($c+1));
    sleep 3;
    if [ $c -gt 20 ]; then
	echo "Timed out waiting for mysql server to be available" >&2
	if [ "$pid" ]; then
	    kill $pid || :
	    sleep 2
	    kill -s KILL $pid || :
	fi
	exit 1
    fi
done
