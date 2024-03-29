# spooky_phish 👻
MAST OffSecOps Phishing Infrastructure

This is built on Red Ira, a cloud automation system scheme for Red Teams by [Joe Minicucci](https://joeminicucci.com). That framework was built on the original work done in [Red Baron](https://github.com/Coalfire-Research/Red-Baron). It currently supports AWS only. The accompanying blog post can be [found here](https://blog.joeminicucci.com/2021/redira).
 
## Design Philosophy

- Deployments only require modification of cut-and-dry configuration JSON templates.
- All configuration is done by Ansible, automatically.
    - In-line scripts remain an option (recommended against).
- Publicly facing assets only expose ports & services necessary for their core offensive function to the internet.
    - All administrative functions are exposed to the internal operators' network only.
        - Obscures the underlying operations infrasturcture to curious Blue teams.

## Improvements to RedIra
- ACME provider upgrade
- Fixed several bugs in the code and introduced updates in Cobalt Strike Ansible playbooks
    - Refactored CS download
    - Fixed JDK dependency and Keystore Javastore issues
    - Altered instance deployments to work better with Cobalt Strike system requirements
- Pwndrop implementation for facilitating payload hosting on C2 server

## Versioning
This following components were leveraged for development and are stable for this release:
- Terraform v0.14.4
- Ansible v2.10.4
- Cobalt Strike 4.2
    - Oracle JDK jdk-8u261-linux-x64.tar.gz
- gophish 0.11.0

The Ansible Playbooks are currently built for and tested on the latest Amazon Debian Buster AMIs.


## Install 
### First Run - Dependencies
    apt-get -y install ansible terraform python3-pip
    ansible-galaxy install -r ./data/playbooks/requirements.yml

After Installing Dependencies:

Replace the playbooks "setup-cobaltstrike.yml" and "configure-teamserver.yml" on the Terraform controller's "~/.ansible/roles/joeminicucci.cobalt_strike/tasks" directory with the updated playbooks in this repo.

### First Run - AWS SES Verification

SES requires verification before the relays can be used for Phishing. See the instructions in [the README](./modules/aws/smtp/README.md#initial-setup) 
### First Run - AWS Environment Preparation
Since this framework will isolate back-end operator actions from the internet, some manual setup is required in AWS before the framework can be deployed.

In the root directory, copy the [environment variables template file](environment_variables.auto.tfvars.json.template) as:

```cp ./environment_variables.auto.tfvars.json.template ./environment_variables.auto.tfvars.json```

Then add the following properties:
#### VPC
Pick an existing VPC or create new one. Record `the vpc_id`.

        "vpc_id" : "vpc-aabbccdd",
#### Private Subnet
Create or select an existing subnet which will be used for the back-end infrastructure, and which is intended to be accessed by operators only. Record the `private_subnet_id`.

        "private_subnet_id" : "subnet-aabbccdd",
#### Public Subnet
Create a subnet in which publicly facing redirectors & assets will be placed. Record the `public_subnet_id`.
    
        "public_subnet_id" : "subnet-aabbccdd",
#### Public Security Groups
This will be the Security Group(s) which redirectors and publicly facing assets will inherit. They only need to define incoming traffic from internal sources to the public subnet, as public sources are resolved through Terraform at runtime depending on the chosen deployment.  

Create the SG or multiple, which allows incoming traffic from the private subnet you just created and optionally anywhere in the VPC which you would like to access the publicly facing assets from. 
 
 The following is an example which additionally allows the required private subnet total access for managing redirectors, as well as the Terraform controller's subnet prefix from which to ssh in:
 
| Type        | Protocol | Port Range | Source          | Description                                                                    |
|-------------|----------|------------|-----------------|--------------------------------------------------------------------------------|
| All traffic | All      | All        | 172.14.130.0/24 | Private Subnet (required)                                                      |
| SSH         | TCP      | 22         | 172.1.111.0/24  | Internal SSH access (from Terraform controller's subnet)                       |
|             |          |            |                 |                                                                                |
	

Record these SG(s) as `base-public-security-groups`.

        "base-public-security_groups" : ["sg-12345678912345678"]
#### Internal Security Groups
This will be the security group that allows operators to access the back-end infrastructure (the private subnet).  

The public SG is required (the one created above), as it allows all incoming traffic from the redirectors/public assets to communicate inbound. The VPN server addition in the example below is an example of how one may allow operators to connect to the internal red team assets from a VPN server.

| Type        | Protocol | Port Range | Source               | Description            |
|-------------|----------|------------|----------------------|------------------------|
| All traffic | All      | All        | sg-12345678912345678 | Public SG (required)   |
| All traffic | All      | All        | 172.12.130.101/32    | VPN Server             |
|             |          |            |                      |                        |


Record this SG as the `base-internal-security-groups`.

    "base-internal-security_groups" : ["sg-12345678912345678"],

### Additional lab deployment steps:
1) Create a NAT gateway with public connectivity and an EIN. Place it in the public subnet created above. 
2) Add a route table associated with the private subnet with 0.0.0.0/0 as destination and the NAT created above as the target.
3) Create an AWS Client VPN Endpoint utilizing mutual authentication following the steps listed [here](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html). This allows operators to connect to the backend Gophish and C2 instances. Associate this VPN endpoint with the default VPC SG.
4) Modify the SG of the private subnet to allow inbound traffic from the SG of the default VPC (in order to make the client VPN work) and to allow inbound SSH traffic in order to allow the Terraform controller the ability to perform remote-execs. 

## Deployment
### Prepare the environment for Terraform - please see your technical lead for credentials if needed
```shell script
export AWS_SECRET_ACCESS_KEY="<secret_key>"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="<key_id>"
```
### Deployment Prep (steps 1-4 are likely already done, so double check before removing any Terraform state files on the Controller)
1. Reference the [AWS Deployment README](./deployments/aws/README.md) to select the desired deployment.
 
2. Clean the root of the previous deployment.
    > :warning: Be careful as to not clear out someone's pre-existing environment!
    ```shell script
    rm -f ./aws_*
    ```

3. Copy the desired deployment folder from the [AWS Deployments folder](./deployments/aws/) to the root.
    ```shell script
    cp ./deployments/aws/complete/* ./
    ``` 

4. Rename the `auto.tfvars.json.template` file to `.json` for that deployment, and fill in the json variables with target values: 
    ```shell script
    mv ./aws_complete.auto.tfvars.json.template ./aws_complete.auto.tfvars.json
    ```

5. If working with Cobalt Strike, retrieve an Oracle JDK gz tar from the Oracle website and copy it to the [./data/oracle](./data/oracle) folder. This is necessary due to Oracle's licensing restrictions. NOTE - you will also need to copy over jdk-17_linux-x64_bin.tar.gz to the directory, in addition to jdk-8u261-linux-x64.tar.gz

    ```cp jdk-8u261-linux-x64.tar.gz ./data/oracle/```

    6. If a custom c2 profile file is desired, copy the file to [./data/c2_profiles](./data/c2_profiles) fill in the filename within the c2-profile variable in the respective `.auto.tfvars.json` deployment config file you created. Otherwise, the default CS profile will be used (not recommended).
        
        ```cp <profile filename> ./data/c2_profiles/```
    
### Deploy with Terraform
From the root directory:
```shell script
terraform init
terraform plan -out <plan file>
terraform apply <plan file>
```

## Known Issues
### Terraform Outputs
Run `terraform output -json` after the Terraform apply finishes in order to view the credentials, which are obfuscated by Terraform at plan runtime.
### Locals & Provisioners
If the locals are changed, the paths in the destroy provisioners will need to be updated due to a limitation in terraform
`https://github.com/hashicorp/terraform/issues/23675`
### Relative Paths
Terraform doesn't support variables in module source paths, meaning that core modules must remain in place, and deployments must be copied to the root folder or else the module sources will not resolve properly. If Hashicorp implements it in the future, dynamic path resolution could be accomplished by modifying base variables.

## Credit
- [t00r0](https://github.com/t00r0) - Project bug fixes and improvements, pwndrop implementation.
- [Joe Minicucci](https://joeminicucci.com) - Original Author of RedIra project.
- [Red Baron](https://github.com/Coalfire-Research/Red-Baron) - Used as a starting point for RedIra, built on Terraform architecture and coding style.
- [ansible-role-cobalt-strike](https://github.com/chryzsh/ansible-role-cobalt-strike) - Built on with several additions.

## TODO 

### Future Needs and Ideas
#### Needs
- SSO for VPN login
- RedELK Implementation
- Hosted Zone / Create VPC implementation
