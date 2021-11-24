# Task 1. Deploy a test application

# In this task, you:
# Deploy a test application to App Engine.
# To have something for Service Monitoring to connect to, deploy a basic Node.js application to App Engine standard.
# In your Cloud Shell terminal, clone https://github.com/haggman/HelloLoggingNodeJS.git repo.
git clone https://github.com/haggman/HelloLoggingNodeJS.git

# This repository contains a basic Node.js web application used for testing. This is the same application you saw pieces of in the lecture module. Change into the HelloLoggingNodeJS folder and open the index.js in the Cloud Shell code editor.
# Note: If an error indicates that the code editor could not be loaded because third-party cookies are disabled, click Open in New Window and switch to the new tab.
cd HelloLoggingNodeJS
edit index.js

# Take a few minutes to peruse the code.
# In the cloud shell code editor, look at the app.yaml file. App Engine standard uses this file to define the runtime required by the application.
# In the cloud shell code editor, look at the package.json file. Not only does this define the Node.js application dependencies, but it also defines the start script App Engine uses to serve requests.
# Return to the Cloud Shell window. If the Cloud Shell is not visible, click Open Terminal.
# In the Cloud Shell terminal, create a new App Engine app. This must be done once in each new project that is running App Engine applications. App Engine is a regional technology, thus the region switch.
gcloud app create --region=us-central

# Deploy the Hello Logging app to App Engine. Wait until the deploy completes before moving on.
gcloud app deploy

# When prompted, type y and press Enter.
# Copy the URL to your newly deployed app from the console (https://qwiklabs-gcp-****************.appspot.com) and open it in a new browser tab. Verify a Hello World! response.

# Task 2. Use Service Monitoring to create an availability SLO

# In this task, you:
# Use Service Monitoring to create an availability SLO.
# Create an alert tied to your SLO.
# Trigger the alert.
# Place some load on the application
# At the top of the Cloud Shell interface, press the ＋ to Open a new tab.
# In the new tab, use a simple bash while loop to generate load on your application. The loop below generates ten requests per second. The URL is to the /random-error route, which generates an error about every 1000 requests, so you should see approximately 1 error every 100s.

while true; \
do curl -s https://$DEVSHELL_PROJECT_ID.appspot.com/random-error \
-w '\n' ;sleep .1s;done
Leave the loop running in its Cloud Shell tab and move on to the next step.

# Use Service Monitoring to create an availability SLO
# We have a working App Engine application that is currently throwing an error approximately every 1000 requests. Imagine we want to create an availability SLO with a target of 99.5%, and an alert that will notify us if our SLO is in danger. That's exactly what Service Monitoring makes easy.
# In the Google Cloud Console, use the Navigation menu to navigate to App Engine | Dashboard. You can already see information on your running service and the load you are placing on it.
# Scroll down to the Application Errors section. Have any errors been generated yet? If not, wait a couple of minutes and refresh the page. You should see one every few minutes.
# Use the Navigation menu to navigate to Error Reporting. Notice the error is also being caught here. We will discuss Error Reporting in a later module.
# Use the Navigation menu to navigate to Monitoring. It takes a moment for the monitoring workspace to create. Once it does, click Services.
# Notice that Service Monitoring already sees your default App Engine application. If it doesn't, wait a minute and refresh the page until it appears in the table.
# Click the default App Engine application to drill into it.
# Click +Create SLO to start the new SLO dialog.
# Select the Availability metric, leave the evaluation method set to Request-based, and then click Continue.
# Take a moment to investigate the details the SLI details displayed, then click Continue.
# To define the SLO, set the Period type to Rolling and the Period length to 7 days to calculate the SLO on a constantly moving 7-day window of time.
# Set the Goal to 99.5% and the charts fill in, though it's typically difficult to see that 99.5 to 99.9 difference. Click the red dashed line, and the chart will zoom in to make things easier to see.
# Click Continue, notice the default name, and submit the new SLO by clicking Create SLO.
# Investigate the new SLO and create an alert for it
# Under the Current status of 1 SLO section, expand the new SLO and investigate the information it displays. Move between the three tabs, Service level indicator, Error budget, and Alerts firing, investigating each.
# Working SLO

# Create an alert tied to the availability SLO
# The SLO has been created and so far, you are well within your objective. Since the SLO target is 99.5%, and the SLI should be showing a current measurement level of about 99.9%, that means that your application is using approximately 1/5 of its error budget, so the error budget should be displaying about 80%. If you start to burn through your error budget at an unexpectedly fast rate, it would be nice for an alert to fire to let you know.

# There are several ways to create an alert for an SLO in Service Monitoring. Because you are looking at the expanded SLO interface, click the Alerts firing tab and select CREATE SLO ALERT.
# SLOALERT

# Set the Display name to Really short window test. Because you are doing a test and not setting values, that would make sense in production.
# Set the Lookback duration to 10 minutes and the burn rate threshold to 1.5.

# Click Next.

# Click on drop down arrow next to Notification Channels, then click on Manage Notification Channels.

# A Notification channels page will open in new tab.
# Scroll down the page and click on ADD NEW for Email.
# In Create Email Channel dialog box, enter your personal email address in the Email Address field and a Display name.
# Click on Save.

# For Who should be notified, use the Manage notification channels link to add your email address as a notification channel and select that. Remember, this link opens a new tab so close it once your email address has been added, and then Save the new alert.
# Click on Notification Channels again, then click on the Refresh icon to get the display name you mentioned in the previous step.
# Now, select your Display name and click OK.
# Click Next.

# Skip What are the steps to fix the issue? (optional) and click Save.
# On the SLO page, switch back to the Service level indicator tab. It should not display our alert as a red dotted line. Once again, clicking the line will zoom in the view. In the upper-right corner of the page, click Auto Refresh so the charts update automatically.
# Trigger the alert
# Modify our application and trigger the alert. Switch back to your Cloud Shell view and Open Editor, if it's not already displayed, and re-open index.js.
# Scroll to the /random-error route found at approximately line 126 and modify the value next to Math.random from 1000 to 20. So instead of generating an error every 1000 requests, we are not going to get an error every 20 requests. That will drop our availability from 99.9$ to about 95%, which should trigger the alert.
# Close the Cloud Shell code editor and switch to the terminal window. You have two tabs, one that's running the test loop and one that's standard. In the standard (non-busy) tab, redeploy the change to App Engine.
gcloud app deploy

# When prompted, type y and press Enter.
# Once the redeploy completes, switch to the tab running the test loop and verify the uptick in errors.
# Switch back to the your Service Monitoring page and in the upper-right corner, verify a green check next to auto refresh. Verify that your SLO is expanded and that you can see the Service level indicator. After a few minutes, the SLI value and chart should show clearly the decrease in performance down to about the 95% level. Within a few minutes, you should also receive the alert notification email.
# SLO Violation
# Note:You may see your error budget quickly drop disproportionately. The error budget calculation is made over the whole SLO window, which should be a rolling period of 7 days, but because you just started the application, your total dataset is very small, thus causing the SLO interface to display a much larger decrease in your error budget than is really happening. If you fixed the problem, the error budget would rapidly fill back up and you would see you actually have budget remaining, though it might take a couple of days to show that.