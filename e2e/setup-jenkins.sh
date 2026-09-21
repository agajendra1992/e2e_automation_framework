
#!/bin/bash

set -e

# ============================================================
# JENKINS + GITHUB CONFIGURATION
# Run this script INSIDE the EC2 Ubuntu instance
# ============================================================

JENKINS_URL="http://localhost:8080"

# ============================================================
# CHANGE THESE VALUES
# ============================================================

GITHUB_REPO_URL="https://github.com/agajendra1992/e2e_automation_framework.git"
GITHUB_BRANCH="master"

JOB_NAME="e2e-automation"

# ============================================================
# CHECK ROOT / SUDO
# ============================================================

echo ""
echo "============================================"
echo " Jenkins EC2 Setup"
echo "============================================"

if ! sudo -n true 2>/dev/null; then
    echo "ERROR: Passwordless sudo is not available."
    echo "Run this script as the ubuntu EC2 user with sudo access."
    exit 1
fi

echo "Sudo access: OK"

# ============================================================
# CHECK JENKINS
# ============================================================

echo ""
echo "============================================"
echo " Checking Jenkins"
echo "============================================"

if ! systemctl is-active --quiet jenkins; then

    echo "Jenkins is not running."
    echo "Starting Jenkins..."

    sudo systemctl start jenkins
fi

sudo systemctl enable jenkins

echo "Jenkins service: RUNNING"

# ============================================================
# WAIT FOR JENKINS
# ============================================================

echo ""
echo "============================================"
echo " Waiting for Jenkins"
echo "============================================"

for i in {1..30}
do
    if curl -s "$JENKINS_URL/login" >/dev/null 2>&1; then
        echo "Jenkins is ready."
        break
    fi

    echo "Waiting for Jenkins... ($i/30)"
    sleep 5
done

if ! curl -s "$JENKINS_URL/login" >/dev/null 2>&1; then
    echo "ERROR: Jenkins did not start."
    sudo systemctl status jenkins --no-pager
    exit 1
fi

# ============================================================
# INSTALL REQUIRED PLUGINS
# ============================================================

echo ""
echo "============================================"
echo " Installing Jenkins Plugins"
echo "============================================"

sudo jenkins-plugin-cli --plugins \
    git \
    github \
    github-api \
    workflow-aggregator \
    pipeline-stage-view \
    junit \
    ws-cleanup \
    credentials-binding

echo "Plugins installed successfully."

# ============================================================
# RESTART JENKINS
# ============================================================

echo ""
echo "============================================"
echo " Restarting Jenkins"
echo "============================================"

sudo systemctl restart jenkins

echo "Waiting for Jenkins..."

sleep 15

# ============================================================
# DISPLAY JENKINS PASSWORD LOCATION
# ============================================================

echo ""
echo "============================================"
echo " Jenkins Initial Admin Password"
echo "============================================"

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then

    INITIAL_PASSWORD=$(sudo -n cat /var/lib/jenkins/secrets/initialAdminPassword)

    echo ""
    echo "Initial Admin Password:"
    echo "$INITIAL_PASSWORD"
    echo ""

else

    echo "Initial admin password file not found."
    echo "Jenkins may already be configured."
fi

# ============================================================
# CREATE JOB XML
# ============================================================

echo ""
echo "============================================"
echo " Creating Jenkins Pipeline Job"
echo "============================================"

cat > /tmp/job-config.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">

    <description>
        E2E Automation Pipeline - Selenium / API / Maven
    </description>

    <keepDependencies>false</keepDependencies>

    <properties>

        <org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty/>

    </properties>

    <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition"
                plugin="workflow-cps">

        <scm class="hudson.plugins.git.GitSCM"
             plugin="git">

            <configVersion>2</configVersion>

            <userRemoteConfigs>

                <hudson.plugins.git.UserRemoteConfig>

                    <url>${GITHUB_REPO_URL}</url>

                </hudson.plugins.git.UserRemoteConfig>

            </userRemoteConfigs>

            <branches>

                <hudson.plugins.git.BranchSpec>

                    <name>*/${GITHUB_BRANCH}</name>

                </hudson.plugins.git.BranchSpec>

            </branches>

            <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>

        </scm>

        <scriptPath>Jenkinsfile</scriptPath>

        <lightweight>true</lightweight>

    </definition>

    <triggers>

        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">

            <spec></spec>

        </com.cloudbees.jenkins.GitHubPushTrigger>

    </triggers>

</flow-definition>
EOF

echo "Job configuration created."

# ============================================================
# IMPORTANT
# ============================================================

echo ""
echo "============================================"
echo " IMPORTANT"
echo "============================================"

echo ""
echo "Jenkins must be unlocked once from the browser."
echo ""
echo "Open from your Mac:"
echo ""
echo "http://YOUR_EC2_PUBLIC_IP:8080"
echo ""

echo "Use the Initial Admin Password printed above."
echo ""

echo "After Jenkins unlock/setup:"
echo ""
echo "1. Install suggested plugins"
echo "2. Create Jenkins admin account"
echo "3. Configure GitHub credentials"
echo "4. Configure GitHub webhook"
echo ""

# ============================================================
# SHOW CONFIGURATION
# ============================================================

echo ""
echo "============================================"
echo " Configuration"
echo "============================================"

echo "Jenkins URL     : $JENKINS_URL"
echo "GitHub Repo     : $GITHUB_REPO_URL"
echo "GitHub Branch   : $GITHUB_BRANCH"
echo "Pipeline Job    : $JOB_NAME"

echo ""
echo "============================================"
echo " Setup Script Completed"
echo "============================================"
```
