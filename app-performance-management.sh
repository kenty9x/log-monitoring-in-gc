# Task 1. Download a pair of sample apps from GitHub
# Switch to your Cloud Shell terminal and enable the APIs for Cloud Build and the Container Registry as we will need them in a few steps.
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable run.googleapis.com

# We are going to deploy two applications we can use to explore the Google Cloud Operations suite of Application Performance Management (APM) products. Let's start by deploying the HelloLoggingNodeJS application we've used previously into Cloud Run. Clone the repo into Cloud Shell.
cd ~/
git clone https://github.com/haggman/HelloLoggingNodeJS.git

# Change into the HelloLoggingNodeJS folder and use the rebuildService.sh script to deploy the application into Cloud Run.
cd ~/HelloLoggingNodeJS
sh rebuildService.sh

# While that application is deploying, open a new tab in the Cloud Shell Terminal window using the ＋ at the top. Here we work on getting the second application deployed.
# Clone the haggman/gcp-debugging repository from GitHub into your Cloud Shell instance.
git clone https://github.com/haggman/gcp-debugging

# Change into the gcp-debugging folder containing the sample app.
cd ~/gcp-debugging

# Use the following command to open main.py in the Cloud Shell editor.
edit main.py

# Take a moment and explore the code. This is a simple Python Flask web app. Initially, the app displays a basic home page. When you click Convert Temp, you are sent to the /temp endpoint and the GET request presents a Convert Fahrenheit to Celsius page, prompting you for a temperature value. Submitting the form POSTs back to the same /temp endpoint. The code then returns a page displaying the converted value. Both pages are built from templates found in the templates folder.
# Before deploying the application to the cloud, test it locally in Cloud Shell. First, install the application dependencies using the Python requirements.txt file, and then execute main.py.
sudo pip3 install -r requirements.txt
python3 main.py

# You see that the terminal window is in a hold mode as the application runs in the background. To see the program running, click the Web Preview button in the toolbar of Google Cloud Shell, and then select Preview on port 8080.
# At the top of the page, click the Convert Temp link. The following screen is displayed.
# Delete the text in the text box, enter 212, and click the To Celsius button. The result should be 100.

Enter some garbage text like foo. How does the application handle this?

Close the browser tab for the running application and switch back to Cloud Shell. Press CTRL+C to stop the Flask application.

temp() Code

Take a moment to re-examine the above code, specifically the temp() function. When the button on the Convert Temp page is pressed, a POST is made. That is handled by the if block starting at line 20. At line 23 the user input is retrieved; this is the temperature in Fahrenheit. Notice below that the isnumeric() function is used to ensure a number was entered. If the input is valid, the conversion to celsius is done. If not, an error message is returned.

Task 2. Deploy the converter application to App Engine
The code is working, but only locally on the Cloud Shell VM. To test our code in a more production-like environment, deploy it to Google's fully-managed App Engine.

Open app.yaml in the Cloud Shell editor.

edit app.yaml
Take a moment to explore the file. This is a configuration file telling App Engine the type of environment the code needs when it runs.

App Engine needs an application created before it can be used. This is done just once using the gcloud app create command and specifying the region where you want the app to be created. This command takes a minute or so. Please wait for it to complete before moving on.

gcloud app create --region=us-central
Deploy the Flask application into App Engine. This command takes a minute or three to complete. Please wait for it before moving on.

gcloud app deploy --version=one --quiet
In the Google Cloud Console window, use the Navigation menu (Navigation menu) to navigate to App Engine | Dashboard.

In the upper-right corner of the dashboard, click the link (qwiklabs-gcp-???????.appspot.com) to your application.

Click the Convert Temp link and replace the text in the text box with 212. Click the button and it returns to 100.

Task 3. Debug the application
Even after all of the thorough testing, users have reported that the program doesn’t always return the correct answer. Use Google Clouds Debugging to investigate.

Take a moment and test the application with various possible numeric temperature values. Can you find any that won't work? If not, don't let that keep you from moving to the next step.

In the Google Cloud Console, use the Navigation menu to navigate to Debugger.

On the Debugger console, check mark the box for I consent to Google collecting and storing my OAuth token and then click AUTHORIZE.

authorize_code

Refresh the Debugger console page.

Since the Debugger is tightly integrated with App Engine, it has a copy of your application code and has your application. In the left-hand tree, select main.py.

Add a breakpoint so you have a snapshot of the application at the moment in time when it returns the temperature page. Locate the line which returns the rendered temp.html page (around line 34). Click the grey area next to code line number to set a breakpoint.

Add Breakpoint

Click CREATE SNAPSHOT.

Notice the window to the right of the debugger. We could set a condition that must be met before a snapshot is taken. At the bottom, we see a message that the Debugger is waiting to take a snapshot.

Snapshot Condition Pane

Go back to the temperature converter page and convert 212 (this should work). Switch back to the Debug screen and check the results.

Take a moment to explore the data available in the snapshot. The input was the string 212. That was converted to the numeric fahrenheit 212.0. The calculation was correct and resulted in the 100.0 in celsius.

Snapshot 212 to 100

In the Snapshot window, click the RETAKE to re-enable the breakpoint.
retake_snapshot

Go back to your app converter page, enter -40 in the text box, and click the button. Switch back to the Debugger and investigate the results.
Bug Snapshot

Notice that the input was correct, the string of -40, but clearly the value was not converted correctly to a number. The -40 indicates that it's still in a string format. Take a look at code lines 20 through 34 and speculate what might be wrong.

Task 4. Adding log data
In addition to seeing the code and current variable values using Debugger snapshots, it's also possible to easily add free-form logging information using Logpoints. Add some Logpoints to further explore our code.

The isnumeric() function is not working correctly. In the upper-right corner of the Debug screen, click the Logpoint link.
Logpoint Link

Click next to line 31 and then click CREATE LOGPOINT, the logpoint form appears.
New Logpoint

Set the log level from Info to Warning, then change the var = {var} placeholder to: {input} was cast to {fahrenheit}, and press the Add button.
log_level_warning

Go back to your app converter page, test the values 212, 32, -40, and 98.6.

Return to the Debugger screen and click the View logs link in the Logpoints window.

view_logs

Take a moment and explore the log values. It appears that the isnumeric() function, used in the test on line 24, is returning a false for negative numbers and numbers with a decimal. That isn't correct.
Logpoint Log Values

Task 5. Fix the bug and deploy a new version
Now that we have a fairly good idea where the bug is, fix the code, deploy a new version of the application, and test to make sure the bug is actually resolved.

Return to your Cloud Shell window, find the main.py file in the gcp-debugging folder, and open it in the Cloud Shell editor.

If you’re highly motivated (and a coder), try to fix the code yourself. If not, replace the if-else block on lines 24 through 29 with the following try-catch block. This is Python, so make sure you get the spacing correct.

        try:
            fahrenheit = float(input)
            celsius = int((fahrenheit - 32.0) * 5.0 / 9.0)
        except ValueError:
            fahrenheit = 'Enter a number'
            celsius = 'Invalid Input'
Make sure your finished code resembles the following screenshot:

Fixed Code

In the Cloud Shell terminal window, change into the ~/gcp-debugging directory and deploy a new version of the application to App Engine. It will take a few moments for this to complete; don't move on until it does.

cd ~/gcp-debugging
gcloud app deploy --version=two --quiet
After the command completes, go back to your temperature converter web page and test it. It should work now.

Task 6. Examine an error report coming out of Cloud Run in Error Reporting
Now that you've seen the debugger at work, let's see how it integrates with Error Reporting.

Switch back to the Cloud Shell tab you used to deploy the HelloLoggingNodeJS to Cloud Run. Open the index.js file in the Cloud Shell editor.

cd ~/HelloLoggingNodeJS
edit index.js
Notice that Error Reporting is already enabled in the code (look for the //Enable Error Reporting comment).

Use the Navigation menu navigate to Cloud Run. Select hello-logging and click the link to the application. We've see this before.

Modify the URL by adding /uncaught to the end. You might recall from an earlier module that the /uncaught route in our application throws an uncaught exception. Refresh the page a few times.

Use the Navigation menu to view Error Reporting. You should see the ReferenceError... message generated from hello-logging. Click the error to view the details.

Locate the stack trace and notice that the error is coming out of index.js. Click the link to the code and the view should switch to the Debugger. At the top of the Debugger, the hello-logging application is not selected by default, we have to select it manually.

Switch to the Cloud Shell terminal and make sure you are in the HelloLoggingNodeJS folder. Create a new Google Cloud Source Repository git repo named hello-world

cd ~/HelloLoggingNodeJS
gcloud source repos create hello-world
Push a copy of the code into the project Git repository.

git push --mirror \
https://source.developers.google.com/p/$GOOGLE_CLOUD_PROJECT/r/hello-world
Switch to the Google Cloud Console window and use the Navigation menu to pull up Error Reporting. Once again, drill in to the ReferenceError..., locate the Stack trace sample and click the /usr/src/app/index.js link to launch the Debugger.

Verify the project is your Qwiklabs project, thn select the hello-world repository, and choose the master branch, and then click Select source.

Refresh the Debugger console page. This time, click Select source in the Cloud Source Repositories section.

Once again, use the Navigation menu to pull up Error Reporting. Drill in to the ReferenceError..., locate the Stack trace sample and click the /usr/src/app/index.js link to launch the Debugger. What did it do this time?

Refresh the page generating the error. Debugger and you see it's taken a debugger snapshot. Take a moment to explore it.

Task 7. Examine a default and custom trace span
Now that you have spent some time with Debugger and Error Reporting, you examine a Trace.

Default trace
Switch back to the Cloud Shell tab and open the index.js file in the Cloud Shell editor. Examine the first statement in the application code and you see the Google Cloud trace agent has been loaded and started.

Use the Navigation menu to return to Cloud Run. Select your hello-logging application and visit its URL. The Hello World message should appear.

Back in the Console window, use the Navigation menu to select Trace.

Take a moment to explore some of the trace spans by selecting the dots under Select a trace.

Switch back to the browser tab where you viewed your application and modify the URL by adding /slow to the end. Wait for the page to load. It should take a couple of minutes.

Switch back to Trace. Use the switch at the top of the page to enable Auto Reload. Locate and select the latest, and highest, trace span. What information do you get from the trace?

Custom trace
By default, Trace only captures spans where services call each other. Since the /slow route does a calculation but doesn't call any other services, the telemetry Trace provides is limited. Fix that by adding a couple of manual trace spans. Switch back to the Cloud Shell tab and open the index.js file in the Cloud Shell editor.

Scroll down to the /slow route. Edit or replace the method so it resembles the following:

//Generates a slow request
app.get('/slow', (req, res) => {
    const span1 = tracer.createChildSpan({name: 'slowPi'});
    let pi1=slowPi();
    span1.endSpan();
    const span2 = tracer.createChildSpan({name: 'slowPi2'});
    let pi2=slowPi2();
    span2.endSpan();
    res.send(`Took it's time. pi to 1,000 places: ${pi1}, pi to 100,000 places: ${pi2}`);
});
Return to the Cloud Shell terminal window and rebuild/redeploy the application. Wait for the redeploy to complete before moving on.

sh rebuildService.sh
Return to the browser tab where you tested your application. Edit the URL and visit the application home page to verify that the application is up and running again. Modify the URL again back to /slow. Wait for the page load to complete.

In the Google Cloud Console, navigate back to Trace. Investigate the latest trace, what additional information can you see in the latest /slow span? Where it the majority of the code latency being spent?