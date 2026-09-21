
#!/bin/bash

set -e

# ============================================================
# EC2 + JENKINS + GITHUB MASTER SETUP
# Run this script from your Mac
# ============================================================

REGION="ap-south-1"

INSTANCE_TYPE="t3.small"
INSTANCE_NAME="qa-automation-server"

KEY_NAME="qa-automation-key"
KEY_PATH="/Users/gajendrasaxena/Documents/e2e_automation_framework/e2e/src/test/resources/config/qa-automation-key.pem"

SECURITY_GROUP_NAME="qa-automation-sg"
VPC_ID="vpc-05d7719c05d193867"

GITHUB_REPO_URL="https://github.com/agajendra1992/e2e_automation_framework.git"
GITHUB_BRANCH="master"

JENKINS_JOB_NAME="e2e-automation"

JENKINS_ADMIN_USER="admin"

echo ""
echo "============================================================"
echo "       QA AUTOMATION EC2 + JENKINS SETUP"
echo "============================================================"
echo ""

# ============================================================
# CHECK AWS CLI
# ============================================================

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

echo "AWS CLI: OK"

# ============================================================
# CHECK AWS LOGIN
# ============================================================

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "ERROR: AWS authentication failed."
    exit 1
fi

echo "AWS authentication: OK"

# ============================================================
# CHECK SSH KEY
# ============================================================

if [ ! -f "$KEY_PATH" ]; then
    echo "ERROR: SSH key not found:"
    echo "$KEY_PATH"
    exit 1
fi

chmod 400 "$KEY_PATH"

echo "SSH key: OK"

# ============================================================
# CHECK VPC
# ============================================================

VPC_CHECK=$(aws ec2 describe-vpcs \
    --region "$REGION" \
    --vpc-ids "$VPC_ID" \
    --query "Vpcs[0].VpcId" \
    --output text 2>/dev/null || true)

if [ "$VPC_CHECK" != "$VPC_ID" ]; then
    echo "ERROR: VPC not found:"
    echo "$VPC_ID"
    exit 1
fi

echo "VPC: $VPC_ID"

# ============================================================
# FIND LATEST UBUNTU 24.04 AMI
# ============================================================

echo ""
echo "Finding latest Ubuntu 24.04 AMI..."

AMI_ID=$(aws ec2 describe-images \
    --region "$REGION" \
    --owners 099720109477 \
    --filters \
    "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
    "Name=state,Values=available" \
    "Name=architecture,Values=x86_64" \
    --query "Images | sort_by(@,&CreationDate)[-1].ImageId" \
    --output text)

if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
    echo "ERROR: Ubuntu AMI not found."
    exit 1
fi

echo "AMI: $AMI_ID"

# ============================================================
# FIND SUBNET
# ============================================================

echo ""
echo "Finding subnet..."

SUBNET_ID=$(aws ec2 describe-subnets \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[?MapPublicIpOnLaunch==\`true\`][0].SubnetId" \
    --output text)

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then

    SUBNET_ID=$(aws ec2 describe-subnets \
        --region "$REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[0].SubnetId" \
        --output text)
fi

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
    echo "ERROR: No subnet found in VPC."
    exit 1
fi

echo "Subnet: $SUBNET_ID"

# ============================================================
# GET MAC PUBLIC IP
# ============================================================

echo ""
echo "Getting your public IP..."

MY_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')

if [ -z "$MY_IP" ]; then
    echo "ERROR: Could not determine public IP."
    exit 1
fi

echo "Your IP: $MY_IP"

# ============================================================
# SECURITY GROUP
# ============================================================

echo ""
echo "============================================================"
echo " SECURITY GROUP"
echo "============================================================"

SG_ID=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters \
    "Name=group-name,Values=$SECURITY_GROUP_NAME" \
    "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" \
    --output text 2>/dev/null || true)

if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then

    echo "Creating security group..."

    SG_ID=$(aws ec2 create-security-group \
        --region "$REGION" \
        --group-name "$SECURITY_GROUP_NAME" \
        --description "QA Automation Jenkins Security Group" \
        --vpc-id "$VPC_ID" \
        --query "GroupId" \
        --output text)

fi

echo "Security Group: $SG_ID"

# ============================================================
# SSH 22
# ============================================================

echo ""
echo "Configuring SSH port 22..."

aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "$MY_IP/32" \
    >/dev/null 2>&1 || true

# ============================================================
# JENKINS 8080
# ============================================================

echo "Configuring Jenkins port 8080..."

aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    >/dev/null 2>&1 || true

echo "Security group configured."

# ============================================================
# FIND EXISTING INSTANCE
# ============================================================

echo ""
echo "============================================================"
echo " EC2 INSTANCE"
echo "============================================================"

INSTANCE_ID=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters \
    "Name=tag:Name,Values=$INSTANCE_NAME" \
    "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[].Instances[0].InstanceId" \
    --output text 2>/dev/null || true)

# ============================================================
# CREATE INSTANCE
# ============================================================

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then

    echo "Creating EC2 instance..."

    INSTANCE_ID=$(aws ec2 run-instances \
        --region "$REGION" \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --subnet-id "$SUBNET_ID" \
        --associate-public-ip-address \
        --tag-specifications \
        "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    echo "Created: $INSTANCE_ID"

else

    echo "Existing EC2 found: $INSTANCE_ID"

    INSTANCE_STATE=$(aws ec2 describe-instances \
        --region "$REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text)

    echo "State: $INSTANCE_STATE"

    if [ "$INSTANCE_STATE" = "stopped" ]; then

        echo "Starting EC2..."

        aws ec2 start-instances \
            --region "$REGION" \
            --instance-ids "$INSTANCE_ID" \
            >/dev/null

    fi

fi

# ============================================================
# WAIT FOR EC2
# ============================================================

echo ""
echo "Waiting for EC2 to become running..."

aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

echo "EC2 is running."

# ============================================================
# GET PUBLIC IP
# ============================================================

PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "ERROR: EC2 does not have a public IP."
    exit 1
fi

echo ""
echo "EC2 Public IP: $PUBLIC_IP"

# ============================================================
# WAIT FOR SSH
# ============================================================

echo ""
echo "Waiting for SSH..."

SSH_OK=false

for i in {1..60}
do

    if ssh \
        -i "$KEY_PATH" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        ubuntu@"$PUBLIC_IP" \
        "echo SSH_OK" \
        >/dev/null 2>&1
    then

        echo "SSH connection successful."
        SSH_OK=true
        break

    fi

    echo "Waiting for SSH... $i/60"
    sleep 5

done

if [ "$SSH_OK" != "true" ]; then

    echo ""
    echo "ERROR: SSH connection failed."
    echo "EC2 IP: $PUBLIC_IP"
    exit 1

fi

# ============================================================
# SEND CONFIG TO EC2
# ============================================================

echo ""
echo "Sending configuration to EC2..."

ssh \
    -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    ubuntu@"$PUBLIC_IP" \
    "cat > /tmp/qa-config.sh" <<EOF
GITHUB_REPO_URL='$GITHUB_REPO_URL'
GITHUB_BRANCH='$GITHUB_BRANCH'
JENKINS_JOB_NAME='$JENKINS_JOB_NAME'
JENKINS_ADMIN_USER='$JENKINS_ADMIN_USER'
EOF

# ============================================================
# REMOTE SETUP
# ============================================================

echo ""
echo "============================================================"
echo " INSTALLING SOFTWARE"
echo "============================================================"

ssh \
    -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    ubuntu@"$PUBLIC_IP" <<'REMOTE'

set -e

source /tmp/qa-config.sh

echo ""
echo "Updating Ubuntu..."

sudo apt-get update -y

# ============================================================
# INSTALL BASIC SOFTWARE
# ============================================================

echo ""
echo "Installing Git, Java 21, Maven..."

sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    fontconfig \
    jq \
    openjdk-21-jre \
    maven

echo ""
echo "Java:"
java -version

echo ""
echo "Maven:"
mvn -version

echo ""
echo "Git:"
git --version

# ============================================================
# INSTALL JENKINS
# ============================================================

echo ""
echo "Installing Jenkins..."

if ! dpkg -l | grep -q "^ii.*jenkins"; then

    sudo mkdir -p /etc/apt/keyrings

    sudo wget -q \
        -O /etc/apt/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
        | sudo tee /etc/apt/sources.list.d/jenkins.list \
        >/dev/null

    sudo apt-get update -y

    sudo apt-get install -y jenkins

else

    echo "Jenkins already installed."

fi

# ============================================================
# JAVA FOR JENKINS
# ============================================================

JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))

echo "JAVA_HOME=$JAVA_HOME_PATH"

sudo mkdir -p /etc/systemd/system/jenkins.service.d

sudo tee /etc/systemd/system/jenkins.service.d/java.conf >/dev/null <<EOF
[Service]
Environment="JAVA_HOME=$JAVA_HOME_PATH"
EOF

sudo systemctl daemon-reload

# ============================================================
# JENKINS START
# ============================================================

echo ""
echo "Starting Jenkins..."

sudo systemctl enable jenkins
sudo systemctl restart jenkins

# ============================================================
# WAIT FOR JENKINS
# ============================================================

echo ""
echo "Waiting for Jenkins..."

JENKINS_READY=false

for i in {1..60}
do

    if curl -fsS http://127.0.0.1:8080/login \
        >/dev/null 2>&1
    then

        echo "Jenkins is responding."
        JENKINS_READY=true
        break

    fi

    echo "Waiting for Jenkins... $i/60"
    sleep 5

done

if [ "$JENKINS_READY" != "true" ]; then

    echo ""
    echo "ERROR: Jenkins did not start."

    sudo systemctl status jenkins --no-pager || true

    echo ""

    sudo journalctl \
        -u jenkins \
        -n 100 \
        --no-pager || true

    exit 1

fi

# ============================================================
# CHECK PORT
# ============================================================

echo ""
echo "Checking Jenkins port..."

if sudo ss -lntp | grep -q ":8080"; then

    echo "Jenkins is listening on port 8080."

else

    echo "ERROR: Jenkins is not listening on port 8080."
    sudo ss -lntp
    exit 1

fi

# ============================================================
# INSTALL JENKINS PLUGIN MANAGER
# ============================================================

echo ""
echo "Installing Jenkins Plugin Manager..."

PLUGIN_MANAGER_URL=$(
    curl -fsSL \
    https://api.github.com/repos/jenkinsci/plugin-installation-manager-tool/releases/latest \
    | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' \
    | head -1
)

if [ -z "$PLUGIN_MANAGER_URL" ] || [ "$PLUGIN_MANAGER_URL" = "null" ]; then

    echo "ERROR: Could not find Jenkins Plugin Manager."
    exit 1

fi

sudo mkdir -p /opt/jenkins-plugin-manager

sudo wget -q \
    -O /opt/jenkins-plugin-manager/jenkins-plugin-manager.jar \
    "$PLUGIN_MANAGER_URL"

echo "Plugin manager installed."

# ============================================================
# INSTALL REQUIRED PLUGINS
# ============================================================

echo ""
echo "Installing Jenkins plugins..."

sudo java -jar \
    /opt/jenkins-plugin-manager/jenkins-plugin-manager.jar \
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
        job-dsl

sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins

echo "Plugins installed."

# ============================================================
# CREATE JENKINS ADMIN USER
# ============================================================

echo ""
echo "Creating Jenkins admin configuration..."

sudo mkdir -p /var/lib/jenkins/init.groovy.d

sudo tee /var/lib/jenkins/init.groovy.d/01-security.groovy >/dev/null <<'GROOVY'

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)

if (hudsonRealm.getUser("admin") == null) {

    hudsonRealm.createAccount(
        System.getenv("JENKINS_ADMIN_USER") ?: "admin",
        System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin123"
    )
}

instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)

instance.setAuthorizationStrategy(strategy)

instance.save()

GROOVY

# ============================================================
# CREATE JENKINS JOB
# ============================================================

echo ""
echo "Creating Jenkins Pipeline job..."

sudo tee /var/lib/jenkins/init.groovy.d/02-create-job.groovy >/dev/null <<'GROOVY'

import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.*

def instance = Jenkins.get()

def jobName = System.getenv("JENKINS_JOB_NAME") ?: "e2e-automation"
def repoUrl = System.getenv("GITHUB_REPO_URL")
def branch = System.getenv("GITHUB_BRANCH") ?: "master"

def job = instance.getItem(jobName)

if (job == null) {

    job = instance.createProject(WorkflowJob.class, jobName)

    def gitSCM = new GitSCM(repoUrl)

    gitSCM.branches = [
        new BranchSpec("*/${branch}")
    ]

    gitSCM.userRemoteConfigs = [
        new UserRemoteConfig(repoUrl, null, null, null)
    ]

    def definition = new CpsScmFlowDefinition(
        gitSCM,
        "Jenkinsfile"
    )

    definition.setLightweight(true)

    job.setDefinition(definition)

    job.save()

    println("Created Jenkins job: " + jobName)

} else {

    println("Jenkins job already exists: " + jobName)

}

instance.save()

GROOVY

# ============================================================
# ENVIRONMENT FOR JENKINS
# ============================================================

sudo mkdir -p /etc/systemd/system/jenkins.service.d

sudo tee /etc/systemd/system/jenkins.service.d/environment.conf >/dev/null <<EOF
[Service]
Environment="JENKINS_ADMIN_USER=$JENKINS_ADMIN_USER"
Environment="JENKINS_ADMIN_PASSWORD=admin123"
Environment="GITHUB_REPO_URL=$GITHUB_REPO_URL"
Environment="GITHUB_BRANCH=$GITHUB_BRANCH"
Environment="JENKINS_JOB_NAME=$JENKINS_JOB_NAME"
EOF

sudo systemctl daemon-reload

# ============================================================
# RESTART JENKINS
# ============================================================

echo ""
echo "Restarting Jenkins..."

sudo systemctl restart jenkins

echo ""
echo "Waiting for Jenkins after restart..."

JENKINS_READY=false

for i in {1..60}
do

    if curl -fsS http://127.0.0.1:8080/login \
        >/dev/null 2>&1
    then

        echo "Jenkins is ready."
        JENKINS_READY=true
        break

    fi

    echo "Waiting... $i/60"
    sleep 5

done

if [ "$JENKINS_READY" != "true" ]; then

    echo "ERROR: Jenkins failed after restart."

    sudo systemctl status jenkins --no-pager || true

    sudo journalctl \
        -u jenkins \
        -n 100 \
        --no-pager || true

    exit 1

fi

# ============================================================
# VERIFY JENKINS PORT
# ============================================================

echo ""
echo "Verifying Jenkins port..."

sudo ss -lntp | grep 8080 || {

    echo "ERROR: Port 8080 is not listening."
    exit 1

}

# ============================================================
# SAVE CONFIGURATION
# ============================================================

sudo mkdir -p /opt/qa-automation

sudo tee /opt/qa-automation/jenkins-config.env >/dev/null <<EOF
GITHUB_REPO_URL="$GITHUB_REPO_URL"
GITHUB_BRANCH="$GITHUB_BRANCH"
JENKINS_JOB_NAME="$JENKINS_JOB_NAME"
EOF

sudo chown -R jenkins:jenkins /opt/qa-automation

echo ""
echo "Remote Jenkins setup completed."

REMOTE

# ============================================================
# EXTERNAL CONNECTION TEST
# ============================================================

echo ""
echo "============================================================"
echo " TESTING EXTERNAL JENKINS CONNECTION"
echo "============================================================"

echo ""
echo "Testing:"
echo "http://$PUBLIC_IP:8080"

EXTERNAL_OK=false

for i in {1..12}
do

    if curl -fsS \
        --connect-timeout 5 \
        "http://$PUBLIC_IP:8080/login" \
        >/dev/null 2>&1
    then

        echo ""
        echo "SUCCESS: Jenkins is reachable from your Mac."
        EXTERNAL_OK=true
        break

    fi

    echo "Waiting for external Jenkins connection... $i/12"
    sleep 5

done

# ============================================================
# FINAL
# ============================================================

echo ""
echo "============================================================"
echo "             SETUP COMPLETE"
echo "============================================================"
echo ""

echo "EC2 Instance:"
echo "$INSTANCE_ID"

echo ""

echo "Public IP:"
echo "$PUBLIC_IP"

echo ""

echo "Jenkins:"
echo "http://$PUBLIC_IP:8080"

echo ""

echo "Jenkins User:"
echo "$JENKINS_ADMIN_USER"

echo ""

echo "Jenkins Password:"
echo "admin123"

echo ""

echo "GitHub Repository:"
echo "$GITHUB_REPO_URL"

echo ""

echo "GitHub Branch:"
echo "$GITHUB_BRANCH"

echo ""

echo "Jenkins Job:"
echo "$JENKINS_JOB_NAME"

echo ""

echo "SSH:"
echo "ssh -i \"$KEY_PATH\" ubuntu@$PUBLIC_IP"

echo ""

if [ "$EXTERNAL_OK" = "true" ]; then

    echo "============================================================"
    echo " Jenkins connection: SUCCESS"
    echo "============================================================"

else

    echo "============================================================"
    echo " WARNING: Jenkins is running but external connection failed"
    echo "============================================================"

    echo ""
    echo "Check AWS Security Group port 8080."
    echo ""
    echo "Current Jenkins URL:"
    echo "http://$PUBLIC_IP:8080"

fi

echo ""
echo "============================================================"
