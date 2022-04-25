#!/bin/bash -xe
export HOME="/root"
SSM_DB_PASSWORD="/gh/db/pass"
GHOST_PACKAGE="ghost-4.12.1.tgz"
DB_URL=${db_url_tpl}
DB_USER="gh_user"
DB_NAME="gh_db"

REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
DB_PASSWORD=123
EFS_ID=123

### Install pre-reqs
curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
sudo python3 /tmp/get-pip.py
sudo /usr/local/bin/pip install botocore
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs
sudo npm install pm2 -g

### EFS mount
mkdir -p /var/lib/ghost/content
yum -y install amazon-efs-utils
mount -t efs -o tls $EFS_ID:/ /var/lib/ghost/content

### Configure and start ghost app
mkdir ghost
wget https://registry.npmjs.org/ghost/-/$GHOST_PACKAGE
tar -xzvf $GHOST_PACKAGE -C ghost --strip-components=1
rm $GHOST_PACKAGE && cd ghost

cat << EOF >> config.production.json
{
    "database": {
            "client": "mysql",
            "connection": {
                    "host": "$DB_URL",
                    "port": 3306,
                    "user": "$DB_USER",
                    "password": "$DB_PASSWORD",
                    "database": "$DB_NAME"
            }
    },
    "server": {
            "host": "0.0.0.0",
            "port": "2368"
    },
    "paths": {
        "contentPath": "/var/lib/ghost/content"
    }
}
EOF

rsync -axvr --ignore-existing /ghost/content/ /var/lib/ghost/content || true
chmod 755 -R /var/lib/ghost

npm install

NODE_ENV=production pm2 start /ghost/index.js --name "ghost" -i max
