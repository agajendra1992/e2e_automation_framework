
#!/bin/bash

set -u

# ============================================================
# CONFIGURATION
# ============================================================

REGION="ap-south-1"

INSTANCE_NAME="qa-automation-server"

INSTANCE_TYPE="t3.small"

VPC_ID="enter your vpc id"

SECURITY_GROUP_NAME="qa-automation-sg"

KEY_PATH="/Users/gajendrasaxena/Documents/e2e_automation_framework/e2e/src/test/resources/config/enter your keypairqa-automation-key.pem"

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

command -v scp >/dev/null 2>&1 || {
    error "SCP not available."
    exit 1
}


if [ ! -f "$KEY_PATH" ]; then

    error "SSH key not found:"
    echo "$KEY_PATH"

    exit 1
fi


chmod 400 "$KEY_PATH"


# ============================================================
# AWS LOGIN
# ============================================================

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


    # ========================================================
    # FIND UBUNTU AMI
    # ========================================================

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


    # ========================================================
    # SECURITY GROUP
    # ========================================================

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


        # SSH
        aws ec2 authorize-security-group-ingress \
            --region "$REGION" \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0 \
            >/dev/null 2>&1 || true


        # Jenkins
        aws ec2 authorize-security-group-ingress \
            --region "$REGION" \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 8080 \
            --cidr 0.0.0.0/0 \
            >/dev/null 2>&1 || true

    fi


    info "Security Group: $SG_ID"


    # ========================================================
    # KEY NAME
    # ========================================================

    KEY_NAME=$(basename "$KEY_PATH" .pem)

    info "Using key: $KEY_NAME"


    # ========================================================
    # CREATE EC2
    # ========================================================

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
            --instance-ids "$INSTANCE_ID" \
            >/dev/null

    fi

fi


# ============================================================
# WAIT FOR EC2
# ============================================================

info "Waiting for EC2 to become running..."

aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"


info "Waiting for EC2 status checks..."

aws ec2 wait instance-status-ok \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"


# ============================================================
# GET PUBLIC IP
# ============================================================

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

SSH_CONNECTED=false


for i in {1..40}; do

    ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -i "$KEY_PATH" \
        ubuntu@"$PUBLIC_IP" \
        "echo SSH_OK" \
        >/dev/null 2>&1


    if [ $? -eq 0 ]; then

        SSH_CONNECTED=true

        break
    fi


    echo "Waiting for SSH... attempt $i/40"

    sleep 5

done


if [ "$SSH_CONNECTED" != "true" ]; then

    error "Could not connect to EC2 using SSH."

    exit 1
fi


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


# ============================================================
# UPDATE SYSTEM
# ============================================================

echo "[1/12] Updating Ubuntu..."

sudo apt-get update -y


# ============================================================
# INSTALL BASIC PACKAGES + JAVA
# ============================================================

echo
echo "[2/12] Installing required packages..."


sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    software-properties-common \
    apt-transport-https \
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


if [ ! -x "$JAVA21/bin/javac" ]; then

    echo "ERROR: Java 21 javac not found."

    exit 1
fi


echo
echo "Java 17:"

"$JAVA17/bin/java" -version


echo
echo "Java 17 compiler:"

"$JAVA17/bin/javac" -version


echo
echo "Java 21:"

"$JAVA21/bin/java" -version


# ============================================================
# SET SYSTEM JAVA TO JAVA 21
# ============================================================

echo
echo "[3/12] Setting system Java to Java 21..."


sudo update-alternatives \
    --install /usr/bin/java java "$JAVA21/bin/java" 2100


sudo update-alternatives \
    --install /usr/bin/javac javac "$JAVA21/bin/javac" 2100


sudo update-alternatives \
    --set java "$JAVA21/bin/java"


sudo update-alternatives \
    --set javac "$JAVA21/bin/javac"


echo

java -version

javac -version


# ============================================================
# MAVEN
# ============================================================

echo
echo "[4/12] Installing Maven..."


sudo apt-get install -y maven


echo

mvn -version


# ============================================================
# INSTALL GOOGLE CHROME
# ============================================================

echo
echo "[5/12] Installing Google Chrome..."


CHROME_DEB="/tmp/google-chrome-stable.deb"


wget -q \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    -O "$CHROME_DEB"


if [ ! -f "$CHROME_DEB" ]; then

    echo "ERROR: Chrome download failed."

    exit 1
fi


sudo apt-get install -y "$CHROME_DEB"


rm -f "$CHROME_DEB"


echo
echo "Google Chrome installed:"

google-chrome --version


# ============================================================
# INSTALL FIREFOX
# ============================================================

echo
echo "[6/12] Installing Firefox..."


sudo apt-get install -y firefox


echo
echo "Firefox installed:"

firefox --version


# ============================================================
# INSTALL MICROSOFT EDGE
# ============================================================

echo
echo "[7/12] Installing Microsoft Edge..."


sudo mkdir -p /etc/apt/keyrings


curl -fsSL \
    https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --dearmor \
    -o /etc/apt/keyrings/microsoft-edge.gpg


echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
    | sudo tee /etc/apt/sources.list.d/microsoft-edge.list \
    >/dev/null


sudo apt-get update -y


sudo apt-get install -y microsoft-edge-stable


echo
echo "Microsoft Edge installed:"

microsoft-edge --version


# ============================================================
# JENKINS REPOSITORY
# ============================================================

echo
echo "[8/12] Installing Jenkins..."


sudo mkdir -p /etc/apt/keyrings


sudo wget -q \
    -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key


echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    | sudo tee /etc/apt/sources.list.d/jenkins.list \
    >/dev/null


sudo apt-get update -y


sudo apt-get install -y jenkins


# ============================================================
# JENKINS JAVA CONFIGURATION
# ============================================================

echo
echo "[9/12] Configuring Jenkins to use Java 21..."


sudo mkdir -p \
    /etc/systemd/system/jenkins.service.d


sudo tee \
    /etc/systemd/system/jenkins.service.d/java.conf \
    >/dev/null <<EOF

[Service]

Environment="JAVA_HOME=$JAVA21"

EOF


# Remove old JAVA_HOME configuration if present

if [ -f /etc/default/jenkins ]; then

    sudo sed -i '/^JAVA_HOME=/d' \
        /etc/default/jenkins \
        || true

fi


sudo systemctl daemon-reload


# ============================================================
# STOP JENKINS
# ============================================================

echo
echo "Stopping Jenkins if already running..."


sudo systemctl stop jenkins \
    >/dev/null 2>&1 \
    || true


# ============================================================
# JENKINS SECURITY
# ============================================================

echo
echo "[10/12] Configuring Jenkins security..."


sudo mkdir -p \
    /var/lib/jenkins/init.groovy.d


sudo tee \
    /var/lib/jenkins/init.groovy.d/01-security.groovy \
    >/dev/null <<'GROOVY'


import jenkins.model.Jenkins

import hudson.security.HudsonPrivateSecurityRealm

import hudson.security.FullControlOnceLoggedInAuthorizationStrategy

import hudson.model.User


def instance = Jenkins.get()


def username =
        System.getenv("JENKINS_ADMIN_USER") ?: "admin"


def password =
        System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin123"


def existingRealm =
        instance.getSecurityRealm()


if (!(existingRealm instanceof HudsonPrivateSecurityRealm)) {

    println("Configuring Jenkins local security realm...")

    def realm =
            new HudsonPrivateSecurityRealm(false)

    def existingUser =
            User.getById(username, false)


    if (existingUser == null) {

        println("Creating Jenkins admin user: " + username)

        realm.createAccount(
                username,
                password
        )

    } else {

        println(
                "Jenkins admin user already exists: "
                + username
        )
    }


    instance.setSecurityRealm(realm)
}


def strategy =
        new FullControlOnceLoggedInAuthorizationStrategy()


strategy.setAllowAnonymousRead(false)


instance.setAuthorizationStrategy(strategy)


instance.save()


println("Jenkins security configuration completed.")

GROOVY


sudo chown -R \
    jenkins:jenkins \
    /var/lib/jenkins/init.groovy.d


# ============================================================
# JENKINS ENVIRONMENT
# ============================================================

sudo tee \
    /etc/systemd/system/jenkins.service.d/environment.conf \
    >/dev/null <<EOF

[Service]

Environment="JENKINS_ADMIN_USER=admin"

Environment="JENKINS_ADMIN_PASSWORD=admin123"

EOF


sudo systemctl daemon-reload


# ============================================================
# START JENKINS
# ============================================================

echo
echo "[11/12] Starting Jenkins..."


sudo systemctl enable jenkins


sudo systemctl restart jenkins


echo
echo "Waiting for Jenkins startup..."


sleep 20


# ============================================================
# JENKINS HEALTH CHECK
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
    echo " Jenkins FAILED to start"
    echo "=============================================="
    echo


    echo
    echo "--------- SYSTEMCTL STATUS ---------"

    sudo systemctl status \
        jenkins \
        --no-pager \
        -l \
        || true


    echo
    echo "--------- JENKINS JOURNAL ---------"

    sudo journalctl \
        -u jenkins \
        -n 100 \
        --no-pager \
        || true


    echo
    echo "--------- JAVA 21 ---------"

    "$JAVA21/bin/java" -version


    echo
    echo "--------- JENKINS SERVICE ---------"

    sudo systemctl cat jenkins \
        || true


    echo
    echo "--------- JAVA OVERRIDE ---------"

    sudo cat \
        /etc/systemd/system/jenkins.service.d/java.conf \
        || true


    exit 1

fi


# ============================================================
# WAIT FOR JENKINS HTTP
# ============================================================

echo
echo "Waiting for Jenkins HTTP interface..."


JENKINS_READY=false


for i in {1..30}; do

    if curl -s \
        http://localhost:8080/login \
        >/dev/null 2>&1; then

        JENKINS_READY=true

        echo "Jenkins HTTP is ready."

        break
    fi


    echo "Waiting for Jenkins HTTP... $i/30"

    sleep 5

done


if [ "$JENKINS_READY" != "true" ]; then

    echo
    echo "ERROR: Jenkins HTTP did not become ready."

    sudo systemctl status \
        jenkins \
        --no-pager \
        -l \
        || true

    sudo journalctl \
        -u jenkins \
        -n 100 \
        --no-pager \
        || true

    exit 1

fi


# ============================================================
# INSTALL JENKINS PLUGINS
# ============================================================

echo
echo "[12/12] Installing Jenkins plugins..."


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


    sudo chown -R \
        jenkins:jenkins \
        /var/lib/jenkins/plugins

fi


# ============================================================
# RESTART JENKINS AFTER PLUGINS
# ============================================================

echo
echo "Restarting Jenkins after plugin installation..."


sudo systemctl restart jenkins


sleep 20


if sudo systemctl is-active --quiet jenkins; then

    echo
    echo "Jenkins is running successfully."

else

    echo
    echo "Jenkins failed after plugin installation."

    sudo systemctl status \
        jenkins \
        --no-pager \
        -l \
        || true


    echo

    sudo journalctl \
        -u jenkins \
        -n 100 \
        --no-pager \
        || true


    exit 1

fi


# ============================================================
# FINAL BROWSER VERIFICATION
# ============================================================

echo
echo "=============================================="
echo " BROWSER VERIFICATION"
echo "=============================================="


echo
echo "Chrome:"

google-chrome --version


echo
echo "Firefox:"

firefox --version


echo
echo "Edge:"

microsoft-edge --version


# ============================================================
# FINAL JAVA VERIFICATION
# ============================================================

echo
echo "=============================================="
echo " JAVA VERIFICATION"
echo "=============================================="


echo
echo "Jenkins Java 21:"

sudo -u jenkins \
    "$JAVA21/bin/java" \
    -version


echo
echo "Maven Java 17:"


export JAVA_HOME="$JAVA17"

export PATH="$JAVA_HOME/bin:$PATH"


java -version

javac -version

mvn -version


# ============================================================
# FINAL RESULT
# ============================================================

echo
echo "=============================================="
echo " REMOTE SETUP COMPLETE"
echo "=============================================="
echo

echo "Java 21  : Jenkins"

echo "Java 17  : Maven/TestNG"

echo "Chrome   : Installed"

echo "Firefox  : Installed"

echo "Edge     : Installed"

echo "Maven    : Installed"

echo "Git      : Installed"

echo "Jenkins  : Running"

echo

REMOTE_SCRIPT


# ============================================================
# UPLOAD REMOTE SCRIPT
# ============================================================

info "Uploading remote setup script..."


scp \
    -o StrictHostKeyChecking=no \
    -i "$KEY_PATH" \
    /tmp/qa-remote-setup.sh \
    ubuntu@"$PUBLIC_IP":/tmp/qa-remote-setup.sh


# ============================================================
# RUN REMOTE SCRIPT
# ============================================================

info "Running remote setup..."


ssh \
    -o StrictHostKeyChecking=no \
    -i "$KEY_PATH" \
    ubuntu@"$PUBLIC_IP" \
    "chmod +x /tmp/qa-remote-setup.sh && /tmp/qa-remote-setup.sh"


REMOTE_STATUS=$?


# ============================================================
# HANDLE FAILURE
# ============================================================

if [ $REMOTE_STATUS -ne 0 ]; then

    error "Remote QA/Jenkins setup failed."

    echo

    echo "Connect manually using:"

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
echo "Browsers:"
echo "Chrome"
echo "Firefox"
echo "Microsoft Edge"


echo
echo "SSH:"
echo "ssh -i \"$KEY_PATH\" ubuntu@$PUBLIC_IP"


echo
echo "=============================================="
echo " SETUP FINISHED"
echo "=============================================="
echo


echo "Jenkins  -> Java 21"

echo "Maven    -> Java 17"

echo "Chrome   -> Installed"

echo "Firefox  -> Installed"

echo "Edge     -> Installed"

echo
echo "Next step: run the Jenkins pipeline."
echo
```
