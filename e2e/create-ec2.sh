
#!/bin/bash

set -e

# ==============================
# AWS CONFIGURATION
# ==============================

REGION="ap-south-1"
INSTANCE_TYPE="t3.small"

KEY_NAME="qa-automation-key"
#KEY_FILE="$HOME/e2e/src/test/resources/config/qa-automation-key.pem"
KEY_FILE="$HOME/Documents/e2e_automation_framework/e2e/src/test/resources/config/qa-automation-key.pem"

SECURITY_GROUP_ID="sg-0210eaa2ee3f10e55"
SUBNET_ID="subnet-03b4b6bb7818c3bbf"
AMI_ID="ami-01a00762f46d584a1"

INSTANCE_NAME="QA-Automation-Server"


# ==============================
# CHECK AWS LOGIN
# ==============================

echo "Checking AWS login..."

aws sts get-caller-identity --region "$REGION"

echo "AWS login successful."


# ==============================
# CHECK SSH KEY
# ==============================

if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: SSH key not found:"
    echo "$KEY_FILE"
    exit 1
fi

chmod 400 "$KEY_FILE"


# ==============================
# CREATE EC2 INSTANCE
# ==============================

echo ""
echo "Creating EC2 instance..."

INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --subnet-id "$SUBNET_ID" \
    --count 1 \
    --tag-specifications \
    "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "EC2 Instance Created:"
echo "$INSTANCE_ID"


# ==============================
# WAIT FOR INSTANCE
# ==============================

echo ""
echo "Waiting for EC2 to start..."

aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

echo "EC2 is RUNNING."


# ==============================
# GET PUBLIC IP
# ==============================

PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)


# ==============================
# OUTPUT DETAILS
# ==============================

echo ""
echo "======================================"
echo "EC2 INSTANCE CREATED"
echo "======================================"

echo "Instance ID : $INSTANCE_ID"
echo "Public IP   : $PUBLIC_IP"
echo "Region      : $REGION"

echo ""
echo "SSH command:"
echo "ssh -i $KEY_FILE ubuntu@$PUBLIC_IP"

echo "======================================"
```

### 1. Create the file

On your Mac:

```bash
cd ~/Documents
mkdir -p aws-automation
cd aws-automation

nano create-ec2.sh
```

Paste the script, then:

```text
CTRL + O
ENTER
CTRL + X
```

### 2. Make it executable

```bash
chmod +x create-ec2.sh
```

### 3. Before running

Replace these three values:

```bash
SECURITY_GROUP_ID="sg-0210eaa2ee3f10e55"
SUBNET_ID="subnet-03b4b6bb7818c3bbf"
AMI_ID="ami-01a00762f46d584a1"
```

For example:

```bash
SECURITY_GROUP_ID="sg-0210eaa2ee3f10e55"
SUBNET_ID="subnet-0123456789abcdef"
AMI_ID="ami-01a00762f46d584a1"
```

Also make sure your AWS CLI is configured:

```bash
aws configure
```

Then verify:

```bash
aws sts get-caller-identity
```

### 4. Run

```bash
./create-ec2.sh
```

You should eventually get:

```text
EC2 INSTANCE CREATED
======================================
Instance ID : i-0123456789abcdef
Public IP   : 13.xx.xx.xx
Region      : ap-south-1

SSH command:
ssh -i /Users/gajendra/Downloads/qa-automation-key.pem ubuntu@13.xx.xx.xx
======================================
```

Then you can connect:

```bash
ssh -i ~/Downloads/qa-automation-key.pem ubuntu@13.xx.xx.xx