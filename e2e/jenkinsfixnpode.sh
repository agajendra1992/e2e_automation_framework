```bash
#!/bin/bash

set -e

echo "=================================================="
echo " Jenkins Built-In Node Fix"
echo "=================================================="

echo ""
echo "1. Jenkins service"
sudo systemctl is-active jenkins

echo ""
echo "2. Java version"
java -version

echo ""
echo "3. Jenkins process"
ps -ef | grep '[j]enkins'

echo ""
echo "4. Jenkins Home"

JENKINS_HOME="/var/lib/jenkins"
echo "JENKINS_HOME=$JENKINS_HOME"

if [ ! -d "$JENKINS_HOME" ]; then
    echo "ERROR: Jenkins Home does not exist"
    exit 1
fi

echo ""
echo "5. Jenkins configuration"

CONFIG="$JENKINS_HOME/config.xml"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Jenkins config.xml not found"
    exit 1
fi

echo "Configuration file:"
ls -lh "$CONFIG"

echo ""
echo "Current executor configuration:"
sudo grep -E '<numExecutors>|<mode>' "$CONFIG" || true

echo ""
echo "6. Creating backup"

BACKUP="$JENKINS_HOME/config.xml.backup.$(date +%Y%m%d_%H%M%S)"

sudo cp "$CONFIG" "$BACKUP"

echo "Backup created:"
echo "$BACKUP"

echo ""
echo "7. Setting executor count to 1"

sudo sed -i 's#<numExecutors>[^<]*</numExecutors>#<numExecutors>1</numExecutors>#' "$CONFIG"

if ! sudo grep -q '<numExecutors>' "$CONFIG"; then
    echo "Adding numExecutors..."
    sudo sed -i 's#</hudson>#<numExecutors>1</numExecutors></hudson>#' "$CONFIG"
fi

echo ""
echo "8. Setting node mode to NORMAL"

sudo sed -i 's#<mode>[^<]*</mode>#<mode>NORMAL</mode>#' "$CONFIG"

if ! sudo grep -q '<mode>' "$CONFIG"; then
    echo "Adding node mode..."
    sudo sed -i 's#</hudson>#<mode>NORMAL</mode></hudson>#' "$CONFIG"
fi

echo ""
echo "9. Fixing ownership"

sudo chown jenkins:jenkins "$CONFIG"

echo ""
echo "10. Final configuration before restart"

sudo grep -E '<numExecutors>|<mode>' "$CONFIG" || true

echo ""
echo "11. Restarting Jenkins"

sudo systemctl restart jenkins

echo ""
echo "Waiting for Jenkins to start..."
sleep 20

echo ""
echo "12. Jenkins service"

sudo systemctl is-active jenkins

echo ""
echo "13. Jenkins port"

if sudo ss -lntp | grep -q ':8080'; then
    echo "SUCCESS: Jenkins is listening on port 8080"
else
    echo "ERROR: Jenkins is NOT listening on port 8080"
fi

echo ""
echo "14. Final configuration"

sudo grep -E '<numExecutors>|<mode>' "$CONFIG" || true

echo ""
echo "=================================================="
echo " Jenkins Logs - Last 30 Lines"
echo "=================================================="

sudo journalctl -u jenkins -n 30 --no-pager

echo ""
echo "=================================================="
echo " DONE"
echo "=================================================="

echo ""
echo "Now open Jenkins:"
echo ""
echo "Manage Jenkins"
echo "    -> Nodes"
echo "    -> Built-In Node"
echo ""

echo "Expected:"
echo "    Executors: 1"
echo "    Status: Online"
echo ""
```
