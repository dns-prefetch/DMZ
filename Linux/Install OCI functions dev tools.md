
# Install OCI command line interface

# Configure OCI CLI profile
https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsquickstartlocalhost.htm#functionsquickstartlocalhosts_topic_set_up_signing_key

# Install docker

	log_info "Install Docker"
		dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
		dnf remove -y runc
		dnf install -y docker-ce --nobest

		systemctl enable docker.service
		systemctl start docker.service
		systemctl status docker.service

# Test the docker installation

  docker run hello-world

# Install Fn Project
		curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh
    /usr/local/bin/fn --version

# Switch back to your non-root user

# Configure Fn Command Line Tool

rm -rf .fn
fn create context --provider oracle uk-cardiff-1
fn use context uk-cardiff-1
fn update context api-url https://functions.uk-cardiff-1.oci.oraclecloud.com
fn update context oracle.compartment-id ocid1.compartment.oc1..aaaaaaaaavtrsv62k4odwaybdpdettgs7fldnwrcxmflkcwwxdnxg362uega
fn update context oracle.image-compartment-id ocid1.compartment.oc1..aaaaaaaaavtrsv62k4odwaybdpdettgs7fldnwrcxmflkcwwxdnxg362uega
fn update context registry cwl.ocir.io/ax3j71guy48g/func-repo
fn update context oracle.profile DEFAULT
fn list context

cat ~/.fn/contexts/uk-cardiff-1.yaml

# Generate auth token for docker

# Log in to docker repository

echo "${userAuthToken}" | docker login -u ${userName} ${RegionKey}.ocir.io --password-stdin

# Test Python function
fn init --runtime python hello-python
fn -v deploy --app TestApp1
fn invoke helloworld-app hello-java
echo -n 'John' | fn invoke helloworld-app hello-java

fn list apps

