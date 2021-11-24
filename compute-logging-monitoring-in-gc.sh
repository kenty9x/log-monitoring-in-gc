# Task 1. Set up a VM and a GKE cluster

# In this task, you:
# Set up a VM running Nginx.
# Create a GKE cluster.

# Set up a VM to host Nginx
# Open the Google Cloud Navigation menu (Navigation menu) in the upper-left corner of the console, then click the link to the Compute Engine.
# Create a new VM instance. Give it the name web-server-vm and tick the box to Allow HTTP traffic. Create and then move onto the next step.

# Create a GKE cluster
# To explore a little of what Google Kubernetes Engine offers in the way of logging and monitoring, let's add a cluster, which will come with logging and monitoring enabled by default.

# Use the Navigation menu to navigate to the Kubernetes Engine > Clusters page.
# Select Create and then click on the Configure button for Standard option.
# Set the Name to gke-cluster, then under the Cluster settings on the left, select Features.
# Verify that Enable Cloud Operations for GKE is Checked and that the choice in the dropbox is set to System and workload logging and monitoring, and then press Create.
# Once you see the cluster creation start, move on to the next step.

# Install Nginx
# Switch back to Compute Engine and SSH in to the web-server-vm.
# Use APT to install Nginx.

sudo apt-get update
sudo apt-get install nginx

# Verify that Nginx installed and is running.
sudo nginx -v

# Switch back to Compute Engine and if you enabled the HTTP access firewall rule, then you should be able to click the external IP. Do so and make sure the Nginx server is up and running. Copy the URL to the server.
# Change to the Cloud Shell terminal window. Create a URL environmental variable and set it equal to the URL to your server.
URL=URL_to_your_server

# Use a bash while loop to place some load on the server. Make sure you are seeing the Welcome to nginx responses.
while true; do curl -s $URL | grep -oP "<title>.*</title>"; \
sleep .1s;done

# Task 2. Install and use the logging and monitoring agents for Compute Engine

# In this task, you:
# Examine the logs and see some data that isn't included.
# Install the logging and monitoring agents in the Compute Engine instance.
# Re-examine the logs to see the new data.
# Examine the logs and see some data that isn't included
# A standard Debian Linux image from Google will not have the logging or monitoring agents installed, so you won't have access to metrics from googleapis.com/nginx/ such as:
# connections/accepted_count
# connections/current
# connections/handled_count
# request_count

# Switch to the Google Console window and navigate to Monitoring > Overview. Wait for the monitoring workspace to create, and then navigate to Metrics explorer.
# Set the Metrics explorer Resource type to VM Instance, the Metric to CPU utilization, and the Filter to instance name = web-server-vm
# You may not see a spike when you applied the load, since it's not a big load, but you are able to access the metric.
# Delete the Filter and the Metric.

# In the Select a metric box, enter nginx and select Requests.

# Why is there no data?

# Install the logging and monitoring agents in the Compute Engine instance
# The data for Nginx requests is missing because without the logging and monitoring agents being installed, the best Google Cloud can do is black-box monitoring. If you want to see more details, then you need to enable white-box monitoring by installing the agents.

# Use the Navigation menu to navigate to Compute Engine > VM instances.
# Click the SSH link for the web-server-vm
# Check to see if the logging agent is installed/running.

sudo service google-fluentd status
sudo service stackdriver-agent status

# Not surprisingly, the services could not be found. Check to make sure you have the requisite scopes to perform logging and monitoring.

curl --silent --connect-timeout 1 -f -H "Metadata-Flavor: Google" \
http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes

# Note in the response the logging.write and monitoring.write scopes.
# Download the script, add the monitoring agent repo to apt, and install the agent.

curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
sudo bash add-monitoring-agent-repo.sh
sudo apt-get update
sudo apt-get install stackdriver-agent

# Start the monitoring agent.
sudo service stackdriver-agent start

# Install the logging agent.
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Retest the two agents again and verify they are both active. If you see any "can not take infinite value" warnings, ignore them and if the status is active (running), press Crtl+c and move on to the next step.
sudo service google-fluentd status
sudo service stackdriver-agent status

# To fully integrate the server, you enable the status information handler in Nginx by adding a configuration file to the Nginx configuration directory.
(cd /etc/nginx/conf.d/ && sudo curl -O https://raw.githubusercontent.com/Stackdriver/stackdriver-agent-service-configs/master/etc/nginx/conf.d/status.conf)

# Reload the Nginx service.
sudo service nginx reload

# Enable the Nginx monitoring plugin.
(cd /opt/stackdriver/collectd/etc/collectd.d/ && sudo curl -O https://raw.githubusercontent.com/Stackdriver/stackdriver-agent-service-configs/master/etc/collectd.d/nginx.conf)

# Restart the monitoring agent.
sudo service stackdriver-agent restart

# Re-examine the metrics to see the new data
# Now that the agents are installed and the Nginx plugins have been added, retest the Nginx metric that we examined earlier.
# Check the Cloud Shell window and verify that the test loop is still running, and that you are still receiving responses. If not, reset the URL property and restart the while.
# Navigate to the Monitoring > Metrics explorer.
# Set the Resource type to VM Instance, in the Select a metric box enter nginx, and then select Requests.
# You may have to wait a few minutes and refresh the page, but you should soon see metric data coming in from Nginx. The monitoring agent is working as it should.

# Task 3. Add a service to the GKE cluster and examine its logs and metrics

# You created a GKE cluster with logging and monitoring enabled earlier in this exercise. Now, load the HelloLoggingNodeJS application to it, put it behind a load balancer service, and view some metrics for your cluster.
# Switch to or reopen the Cloud Shell console. Break the running test loop with CTRL+C.
# Enable the Cloud Build API as it is needed it in a few steps.
gcloud services enable cloudbuild.googleapis.com 

# Clone the https://github.com/haggman/HelloLoggingNodeJS.git repo.
git clone https://github.com/haggman/HelloLoggingNodeJS.git

# This repository contains a basic Node.js web application that is used for testing. Change into the HelloLoggingNodeJS folder and open the index.js in the Cloud Shell editor.
cd HelloLoggingNodeJS
edit index.js

# Take a few minutes to peruse the code.
# In the editor, also take a look at the package.json file which contains the dependencies, and the Dockerfile which plans the Docker container we generate and deploy to GKE.

# Submit the Dockerfile to Google's Cloud Build to generate a container and store it in your Container Registry.
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/hello-logging-js .

# Open the k8sapp.yaml file and explore the instructions to Kubernetes to create three hello-logging pods, and then expose them through a LoadBalancer service.
# In the k8sapp.yaml file, replace the $GCLOUD_PROJECT with your actual project ID. Remember, your project ID is located on the Home page of your Google Cloud Console and in Qwiklabs just below your temporary Google Cloud password.
# Use the Navigation menu to navigate to Kubernetes Engine. Click on the triple dot icon for your cluster and select Connect. Copy the command line to configure kubectl.
# Switch back to Cloud Shell and execute the command.
# Use kubectl to apply your k8sapp.yaml.
kubectl apply -f k8sapp.yaml

# Get a list of your services. It may take a minute or two for the new hello-logging-service to appear, and for it to get an External IP.
kubectl get services

# Once the service appears with the external IP, copy the external IP value.
# Open a tab in the browser and paste in the IP. Make sure you see the Hello World message.
# Copy the page URL from the browser and switch back to Cloud Shell. Update the URL environmental variable and restart the while loop. Make sure you are seeing the Hello World responses.
URL=url_to_k8s_app
while true; do curl -s $URL -w "\n"; sleep .1s;done

# Navigate to the Monitoring > Dashboards and open the GKE dashboard.
# On the GKE dashboard, for gke-cluster scroll horizontally and see the charts. If all of the small charts are reading No Data, refresh the page until they start showing readings for CPU and Memory Utilization. You might also want to toggle Off to On to enable auto-refresh of the data.
# If you want to examine the different cluster nodes, you can scroll horizontally in Nodes tab and see that the three hello-logging-js-deployments are spread across the nodes. This tab focuses on what's running where, from Cluster, to Node, to Pod.
# Switch to the Workloads tab. This is focused on the deployed workloads, grouped by namespace.
# Finally, scroll to the Kubernetes Services tab and expand hello-logging-service. This view is more about how services relate to their pods.
# In any of the views, if you drill all the way down to one of our hello-logging-js-containers, a right-hand window appears with details. Investigate Incidents, Metrics, and Logs.