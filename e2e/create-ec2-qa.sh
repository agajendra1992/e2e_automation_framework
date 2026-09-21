#!/bin/bash

set -u

# ============================================================
# CONFIGURATION
# ============================================================

REGION="ap-south-1"
INSTANCE_NAME="qa-automation-server"
INSTANCE_TYPE="t3.small"

VPC_ID="vpc-05d7719c05d193867"
SECURITY_GROUP_NAME="qa-automation-sg"

KEY_PATH="/Users/gajendrasaxena/Documents/e2e_automation_framework/e2e/src/test/resources/config/qa-automation-key.pem"

GITHUB_REPO="https://github.com/agajendra1992/e2e_automation_framework.git"
GITHUB_BRANCH="gajendra"

JENKINS_JOB="e2e-automation"
JENKINSFILE="e2e/JenkinsFile"

JENKINS_ADMIN_USER="admin"
JENKINS_ADMIN_PASSWORD="admin123"

GITHUB_CREDENTIAL_ID="agajendra1992"

JAVA17="/usr/lib/jvm/java-17-openjdk-amd64"
JAVA21="/usr/lib/jvm/java-21-openjdk-amd64"

# ============================================================
# COLORS
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================
# CHECK LOCAL REQUIREMENTS
# ============================================================

echo
echo "=============================================="
echo " QA AUTOMATION EC2 + JENKINS SETUP"
echo "=============================================="
echo

command -v aws >/dev/null 2>&1 || {
    error "AWS CLI not installed."
    exit 1
}

command -v ssh >/dev/null 2>&1 || {
    error "SSH not available."
    exit 1
}

if [ ! -f "$KEY_PATH" ]; then
    error "SSH key not found:"
    echo "$KEY_PATH"
    exit 1
fi

chmod 400 "$KEY_PATH"

info "Checking AWS login..."

aws sts get-caller-identity --region "$REGION" >/dev/null 2>&1

if [ $? -ne 0 ]; then
    error "AWS login failed."
    exit 1
fi

info "AWS login successful."

# ============================================================
# FIND EXISTING EC2
# ============================================================

info "Checking existing EC2 instance..."

INSTANCE_ID=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters \
    "Name=tag:Name,Values=$INSTANCE_NAME" \
    "Name=instance-state-name,Values=pending,running,stopped,stopping" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then

    info "EC2 not found. Creating new instance..."

    AMI_ID=$(aws ec2 describe-images \
        --region "$REGION" \
        --owners 099720109477 \
        --filters \
        "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
        "Name=state,Values=available" \
        --query "sort_by(Images,&CreationDate)[-1].ImageId" \
        --output text)

    if [ "$AMI_ID" = "None" ] || [ -z "$AMI_ID" ]; then
        error "Could not find Ubuntu AMI."
        exit 1
    fi

    info "Ubuntu AMI: $AMI_ID"

    # --------------------------------------------------------
    # SECURITY GROUP
    # --------------------------------------------------------

    SG_ID=$(aws ec2 describe-security-groups \
        --region "$REGION" \
        --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" \
        --query "SecurityGroups[0].GroupId" \
        --output text)

    if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then

        info "Creating security group..."

        SG_ID=$(aws ec2 create-security-group \
            --region "$REGION" \
            --group-name "$SECURITY_GROUP_NAME" \
            --description "QA Automation Jenkins Security Group" \
            --vpc-id "$VPC_ID" \
            --query "GroupId" \
            --output text)

        aws ec2 authorize-security-group-ingress \
            --region "$REGION" \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0 >/dev/null 2>&1 || true

        aws ec2 authorize-security-group-ingress \
            --region "$REGION" \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 8080 \
            --cidr 0.0.0.0/0 >/dev/null 2>&1 || true

    fi

    info "Security Group: $SG_ID"

    # --------------------------------------------------------
    # KEY NAME
    # --------------------------------------------------------

    KEY_NAME=$(basename "$KEY_PATH" .pem)

    info "Using key: $KEY_NAME"

    INSTANCE_ID=$(aws ec2 run-instances \
        --region "$REGION" \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --block-device-mappings \
        '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
        --tag-specifications \
        "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    info "Created instance: $INSTANCE_ID"

else

    info "Existing EC2 found: $INSTANCE_ID"

    STATE=$(aws ec2 describe-instances \
        --region "$REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text)

    if [ "$STATE" = "stopped" ]; then
        info "Starting stopped EC2..."

        aws ec2 start-instances \
            --region "$REGION" \
            --instance-ids "$INSTANCE_ID" >/dev/null

    fi
fi

# ============================================================
# WAIT FOR INSTANCE
# ============================================================

info "Waiting for EC2..."

aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

aws ec2 wait instance-status-ok \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ "$PUBLIC_IP" = "None" ] || [ -z "$PUBLIC_IP" ]; then
    error "Public IP not found."
    exit 1
fi

info "EC2 Public IP: $PUBLIC_IP"

# ============================================================
# WAIT FOR SSH
# ============================================================

info "Waiting for SSH..."

for i in {1..30}; do

    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -i "$KEY_PATH" \
        ubuntu@"$PUBLIC_IP" "echo SSH_OK" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        break
    fi

    sleep 5

done

info "SSH connection successful."

# ============================================================
# CREATE REMOTE SETUP SCRIPT
# ============================================================

cat > /tmp/qa-remote-setup.sh <<'REMOTE_SCRIPT'
#!/bin/bash

set -u

echo
echo "=============================================="
echo " REMOTE QA AUTOMATION SETUP"
echo "=============================================="
echo

export DEBIAN_FRONTEND=noninteractive

echo "[1/10] Updating packages..."

sudo apt-get update -y

echo "[2/10] Installing required packages..."

sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    software-properties-common \
    openjdk-17-jdk \
    openjdk-21-jdk

# ============================================================
# JAVA PATHS
# ============================================================

JAVA17="/usr/lib/jvm/java-17-openjdk-amd64"
JAVA21="/usr/lib/jvm/java-21-openjdk-amd64"

echo
echo "Checking Java installations..."

if [ ! -x "$JAVA17/bin/java" ]; then
    echo "ERROR: Java 17 not found."
    exit 1
fi

if [ ! -x "$JAVA17/bin/javac" ]; then
    echo "ERROR: Java 17 javac not found."
    exit 1
fi

if [ ! -x "$JAVA21/bin/java" ]; then
    echo "ERROR: Java 21 not found."
    exit 1
fi

echo "Java 17:"
"$JAVA17/bin/java" -version

echo
echo "Java 17 compiler:"
"$JAVA17/bin/javac" -version

echo
echo "Java 21:"
"$JAVA21/bin/java" -version

# ============================================================
# SYSTEM JAVA = 21
# ============================================================

echo
echo "[3/10] Setting system Java to Java 21..."

sudo update-alternatives --install /usr/bin/java java "$JAVA21/bin/java" 2100
sudo update-alternatives --install /usr/bin/javac javac "$JAVA21/bin/javac" 2100

sudo update-alternatives --set java "$JAVA21/bin/java"
sudo update-alternatives --set javac "$JAVA21/bin/javac"

echo
java -version
javac -version

# ============================================================
# MAVEN
# ============================================================

echo
echo "[4/10] Installing Maven..."

sudo apt-get install -y maven

echo
mvn -version

# ============================================================
# JENKINS REPOSITORY
# ============================================================

echo
echo "[5/10] Installing Jenkins..."

sudo mkdir -p /etc/apt/keyrings

sudo wget -q \
    -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null

sudo apt-get update -y

sudo apt-get install -y jenkins

# ============================================================
# JENKINS JAVA CONFIG
# ============================================================

echo
echo "[6/10] Configuring Jenkins to use Java 21..."

sudo mkdir -p /etc/systemd/system/jenkins.service.d

sudo tee /etc/systemd/system/jenkins.service.d/java.conf >/dev/null <<EOF
[Service]
Environment="JAVA_HOME=$JAVA21"
EOF

# Remove possible old Jenkins Java configuration
if [ -f /etc/default/jenkins ]; then

    sudo sed -i \
        '/^JAVA_HOME=/d' \
        /etc/default/jenkins || true

fi

sudo systemctl daemon-reload

# ============================================================
# STOP JENKINS BEFORE CONFIGURATION
# ============================================================

echo
echo "Stopping Jenkins if running..."

sudo systemctl stop jenkins 2>/dev/null || true

# ============================================================
# JENKINS INIT SCRIPTS
# ============================================================

echo
echo "[7/10] Creating Jenkins initialization scripts..."

sudo mkdir -p /var/lib/jenkins/init.groovy.d

sudo tee /var/lib/jenkins/init.groovy.d/01-security.groovy >/dev/null <<'GROOVY'
import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.model.User

def instance = Jenkins.get()

def username = System.getenv("JENKINS_ADMIN_USER") ?: "admin"
def password = System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin123"

def realm = new HudsonPrivateSecurityRealm(false)

def existingUser = User.getById(username, false)

if (existingUser == null) {
    println("Creating Jenkins admin user: " + username)
    realm.createAccount(username, password)
} else {
    println("Jenkins admin user already exists: " + username)
}

instance.setSecurityRealm(realm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)

instance.setAuthorizationStrategy(strategy)

instance.save()

println("Jenkins security configuration completed.")
GROOVY

sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

# ============================================================
# ENVIRONMENT FILE
# ============================================================

sudo mkdir -p /etc/systemd/system/jenkins.service.d

sudo tee /etc/systemd/system/jenkins.service.d/environment.conf >/dev/null <<EOF
[Service]
Environment="JENKINS_ADMIN_USER=admin"
Environment="JENKINS_ADMIN_PASSWORD=admin123"
EOF

sudo systemctl daemon-reload

# ============================================================
# START JENKINS
# ============================================================

echo
echo "[8/10] Starting Jenkins..."

sudo systemctl enable jenkins

sudo systemctl restart jenkins

sleep 15

# ============================================================
# SELF-HEAL CHECK
# ============================================================

if sudo systemctl is-active --quiet jenkins; then

    echo
    echo "=============================================="
    echo " Jenkins started successfully"
    echo "=============================================="
    echo

else

    echo
    echo "=============================================="
    echo " Jenkins failed to start"
    echo "=============================================="
    echo

    echo
    echo "------ SYSTEMCTL STATUS ------"
    sudo systemctl status jenkins --no-pager -l || true

    echo
    echo "------ JENKINS JOURNAL ------"
    sudo journalctl -u jenkins -n 100 --no-pager || true

    echo
    echo "------ JAVA CHECK ------"
    "$JAVA21/bin/java" -version

    echo
    echo "------ JENKINS SERVICE CONFIG ------"
    sudo systemctl cat jenkins || true

    echo
    echo "------ JAVA CONFIG ------"
    cat /etc/systemd/system/jenkins.service.d/java.conf || true

    exit 1

fi

# ============================================================
# WAIT FOR JENKINS PORT
# ============================================================

echo
echo "Waiting for Jenkins HTTP port..."

for i in {1..30}; do

    if curl -s http://localhost:8080/login >/dev/null 2>&1; then
        echo "Jenkins HTTP is ready."
        break
    fi

    sleep 5

done

# ============================================================
# INSTALL PLUGINS
# ============================================================

echo
echo "[9/10] Installing Jenkins plugins..."

PLUGIN_CLI="/opt/jenkins-plugin-manager.jar"

if [ ! -f "$PLUGIN_CLI" ]; then

    sudo wget -q \
        -O "$PLUGIN_CLI" \
        https://github.com/jenkinsci/plugin-installation-manager-tool/releases/latest/download/jenkins-plugin-manager-2.13.2.jar

fi

if [ -f "$PLUGIN_CLI" ]; then

    sudo java -jar "$PLUGIN_CLI" \
        --war /usr/share/java/jenkins.war \
        --plugin-download-directory /var/lib/jenkins/plugins \
        --plugins \
        git \
        github \
        github-api \
        workflow-aggregator \
        workflow-job \
        workflow-cps \
        pipeline-stage-view \
        junit \
        ws-cleanup \
        credentials-binding \
        job-dsl \
        || true

    sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins

fi

# ============================================================
# RESTART AFTER PLUGINS
# ============================================================

echo
echo "Restarting Jenkins after plugin installation..."

sudo systemctl restart jenkins

sleep 15

if sudo systemctl is-active --quiet jenkins; then
    echo "Jenkins is running."
else

    echo
    echo "Jenkins failed after plugin restart."

    sudo systemctl status jenkins --no-pager -l || true

    echo
    sudo journalctl -u jenkins -n 100 --no-pager || true

    exit 1
fi

# ============================================================
# FINAL JAVA VERIFICATION
# ============================================================

echo
echo "[10/10] Final environment verification..."

echo
echo "Jenkins Java:"
sudo -u jenkins "$JAVA21/bin/java" -version

echo
echo "Maven Java 17:"

export JAVA_HOME="$JAVA17"
export PATH="$JAVA_HOME/bin:$PATH"

java -version
javac -version
mvn -version

echo
echo "=============================================="
echo " REMOTE SETUP COMPLETE"
echo "=============================================="
REMOTE_SCRIPT

# ============================================================
# COPY SCRIPT TO EC2
# ============================================================

info "Uploading setup script..."

scp -o StrictHostKeyChecking=no \
    -i "$KEY_PATH" \
    /tmp/qa-remote-setup.sh \
    ubuntu@"$PUBLIC_IP":/tmp/qa-remote-setup.sh

# ============================================================
# RUN REMOTE SETUP
# ============================================================

info "Running remote setup..."

ssh -o StrictHostKeyChecking=no \
    -i "$KEY_PATH" \
    ubuntu@"$PUBLIC_IP" \
    "chmod +x /tmp/qa-remote-setup.sh && /tmp/qa-remote-setup.sh"

REMOTE_STATUS=$?

if [ $REMOTE_STATUS -ne 0 ]; then

    error "Remote Jenkins setup failed."

    echo
    echo "You can connect manually with:"
    echo
    echo "ssh -i \"$KEY_PATH\" ubuntu@$PUBLIC_IP"
    echo

    exit 1
fi

# ============================================================
# FINAL OUTPUT
# ============================================================

echo
echo "=============================================="
echo " QA AUTOMATION SERVER READY"
echo "=============================================="
echo

echo "EC2 Instance:"
echo "$INSTANCE_ID"

echo
echo "Public IP:"
echo "$PUBLIC_IP"

echo
echo "Jenkins:"
echo "http://$PUBLIC_IP:8080"

echo
echo "Jenkins User:"
echo "$JENKINS_ADMIN_USER"

echo
echo "Jenkins Password:"
echo "$JENKINS_ADMIN_PASSWORD"

echo
echo "GitHub Repository:"
echo "$GITHUB_REPO"

echo
echo "Branch:"
echo "$GITHUB_BRANCH"

echo
echo "Jenkinsfile:"
echo "$JENKINSFILE"

echo
echo "Jenkins Job:"
echo "$JENKINS_JOB"

echo
echo "SSH:"
echo "ssh -i \"$KEY_PATH\" ubuntu@$PUBLIC_IP"

echo
echo "=============================================="
echo " IMPORTANT"
echo "=============================================="
echo
echo "Jenkins runs with Java 21."
echo "Maven/tests use Java 17."
echo
echo "After login, change the temporary Jenkins password."
echo