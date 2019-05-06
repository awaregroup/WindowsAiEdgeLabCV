# Hands-On-Lab: Azure IoT Edge + AI on Windows IoT

For this lab, we will use [Azure Cognitive Services](https://azure.microsoft.com/en-us/services/cognitive-services/) - [Custom Vision](https://customvision.ai) to train a machine learning model for image classification. 

We will download the ONNX model from Custom Vision, add some .NET components and deploy the model in a docker container to a device running [Azure IoT Edge](https://azure.microsoft.com/en-us/services/iot-edge/) on [Windows 10 IoT Core](https://www.microsoft.com/en-us/windowsforbusiness/windows-iot).

Images will be captured from a camera on our edge device with inferencing happening at the edge using [Windows ML](https://docs.microsoft.com/en-us/windows/ai/windows-ml/) and sending our results through [Azure IoT Hub](https://azure.microsoft.com/en-us/services/iot-hub/). Finally, we will visualize the results using [Azure Time Series Insights](https://azure.microsoft.com/en-us/services/time-series-insights/).

![Architecture Diagram](./assets/winmliot.png)

## Pre-requisites

Before starting this lab, make sure you have the following open:

1. This lab guide
1. Desktop app: [Visual Studio Code](https://code.visualstudio.com)
1. Browser tab: [Custom Vision Service](https://www.customvision.ai/)
1. PowerShell **running as Administrator**

**NOTE: You can find all username and password details in the __credentials.txt__ file in the Desktop > WindowsIoT folder.**

# Step 1 - Train the Model
## 1.1 - Gathering Training data
1. Plug the USB camera into your lab PC
1. Open the Windows Camera app from the Start Menu
1. Take between 10-15 photos of each object you'd like to recognize with your model. **NOTE: More photos with different rotations and focal length should theoretically make for a better model!**
1. Confirm your photos are in the ```Pictures > Camera Roll``` folder

## 1.2 - Creating a Custom Vision Service Project
1. Log into the [Custom Vision Service portal](https://www.customvision.ai/) using the provided Azure credentials (found in the credentials.txt file - see above)
1. Click 'New Project'
1. Enter the following values and click 'Create Project'

|Name                 |Value                |
|---------------------|---------------------|
|Project Name         |[your choice]        |
|Project Types        |Classification       |
|Classification Types |Multiclass           |
|Domains              |General **(compact)**|

## 1.3 - Importing Images into Custom Vision Service
1. Click the 'Add Images' button and browse to the ```Pictures > Camera Roll``` directory
1. Select the 10-15 image set for each a object type
1. Enter a tag name - this is what your model will predict when it sees this object
1. Repeat this until each set of images is uploaded into Custom Vision

## 1.4 - Train and test your model
1. Click the green 'Train' button in the top right corner. After your model has trained, you can see the rated performance
1. Click 'Quick Test' next to the 'Train' button and upload an extra image of your item that **was not** included in the original 10-15 images

## 1.5 - Export ONNX model
1. Return to the Performance tab
1. Click the 'Export' to start the download process
1. Select ONNX as the model format and ONNX 1.2 as the format version
1. Click 'Download' and rename to CustomVision.onnx in the ```Downloads``` folder


# Step 2 - Package the model into a C# .NET Application

## 2.1 - Find the code

1. Open a Windows PowerShell Prompt **as Administrator**
1. Type the following to prepare your environment:
```powershell
cd c:\Users\Admin\Desktop\WindowsIoT\WindowsAiEdgeLabCV
git clean -xdf
git reset --hard
git pull
```

## 2.2 - Prepare your model file
1. Copy your CustomVision.onnx to ```c:\Users\Admin\Desktop\WindowsIoT\WindowsAiEdgeLabCV``` either through Explorer, or with the following command: 

```powershell
copy c:\Users\Admin\Downloads\CustomVision.onnx .\
```

## 2.3 - Build and test the code
1. Run the following code:

```powershell
dotnet restore -r win-x64
dotnet publish -r win-x64
```
2. Point the camera at one of your objects and test by running the following:

```powershell
dotnet run --model=CustomVision.onnx --device=LifeCam
```

If the model is successful, you will see a prediction label show in the console.


# Step 3 - Build and push a container

## 3.1 - Connect to IoT Core device

In this lab, we will build and push the container from the IoT Core device. 

We will need a way to copy files to our device and a Windows PowerShell window from our development PC connected to that device.

First, we will map the Q: drive to our device so we can access files. 

You'll need the Device IP Address. To get the IP Address open the "IoT Dashboard" from the desktop of your surface and select "My Devices".
 
The name of your device is written on the underside of the IoT device case in white ink.

Right click on your device and select "Copy IPv4 Address".

Run the following commands in your PowerShell terminal:

```powershell
$ip = "ENTER YOUR DEVICE IP ADDRESS HERE"
net use q: \\$ip\c$ "p@ssw0rd" /USER:Administrator
```

## 3.2 - Copy binaries to IoT device

We will copy the 'publish' folder over to our device

```powershell
cd "C:\Users\Admin\Desktop\WindowsIoT\WindowsAiEdgeCV"
robocopy .\bin\Debug\netcoreapp2.2\win-x64\publish\ q:\data\modules\customvision
```


## 3.3 - Test the binaries on IoT device

Next we will run the binaries on the target device.

1. Connect the camera to the IoT Core device
1. Establish a remote PowerShell session on the IoT Core device by typing the following in the PowerShell terminal:

**NOTE: This remote PowerShell command requires you to be running your PowerShell terminal as Administrator.**

```powershell
Enter-PSSession -ComputerName $ip -Credential ~\Administrator
cd "C:\data\modules\customvision"
.\WindowsAiEdgeLabCV.exe --model=CustomVision.onnx --device=LifeCam
```

Again, if the test is successful, you should see objects recognized in the console.

## Containerize the sample app

Build the container on the device. To make things easier in this lab, we will set the value of $Container to the address where we will push our container. This will be in the container repository we set up earlier. Find the "Container Registry Login Server" address from the steps above. For example, I am using "aiedgelabcr.azurecr.io" 
to test the lab, so I will do as follows:

```
[192.168.1.102]: PS C:\data\modules\customvision> $Container = "aiedgelabcr.azurecr.io/customvision:1.0-x64-iotcore"
```

Still in the "C:\data\modules\customvision" directory, we will now build the container on the IoT Core device.
Note that if we were building for an IoT Enterprise device, we could just do this on our development machine.

```
[192.168.1.102]: PS C:\data\modules\customvision> docker build . -t $Container
Sending build context to Docker daemon  90.54MB

Step 1/5 : FROM mcr.microsoft.com/windows/iotcore:1809
 ---> b292a83fe7c1
Step 2/5 : ARG EXE_DIR=.
 ---> Using cache
 ---> cccdd52d4b4f
Step 3/5 : WORKDIR /app
 ---> Using cache
 ---> 3e071099a8a8
Step 4/5 : COPY $EXE_DIR/ ./
 ---> 951c8a6e96bc
Step 5/5 : CMD [ "WindowsAiEdgeLabCV.exe", "-mCustomVision.onnx", "-dLifeCam", "-ef" ]
 ---> Running in ae981c4d8819
Removing intermediate container ae981c4d8819
 ---> fee066f14f2c
Successfully built fee066f14f2c
Successfully tagged aiedgelabcr.azurecr.io/customvision:1.0-x64-iotcore
```

## Push the container

Now that we are sure the app is working correctly within the container, we will push it to our registry.

Before that, we will need to login to the container registry using the Container Registry Username and Container Registry Password obtained in previous steps.

```
PS C:\WindowsAiEdgeLabCV> docker login $ContainerRegistryLoginServer -u $ContainerRegistryUsername -p $ContainerRegistryPassword
Login Succeeded
```

Then we'll push the container into our registry.

```
[192.168.1.102]: PS C:\data\modules\customvision> docker push $Container
The push refers to repository [aiedgelabcr.azurecr.io/customvision]
c1933e4141d1: Preparing
ecdb3e0bf60d: Preparing
b7f45a54f179: Preparing
6bd44acbda1a: Preparing
13e7d127b442: Preparing
13e7d127b442: Skipped foreign layer
c1933e4141d1: Pushed
b7f45a54f179: Pushed
6bd44acbda1a: Pushed
ecdb3e0bf60d: Pushed
1.0-x64-iotcore: digest: sha256:7ba0ac77a29d504ce19ed2ccb2a2c67addb24533e4e3b66476ca018566b58086 size: 1465
```

# Step 4: Create an Azure IoT Edge deployment to the target device

## Author a deployment.json file

Now that we have a container with our inferencing logic safely up in our container registry, it's time to create an Azure IoT Edge deployment to our device.

We will do this back on the development PC.

Amongst the lab files, you will find a deployment json file named deployment.win-x64.json. Open this file in VS Code. We must fill in the details for the container image we just built above, along with our container registry credentials.

Search for "{ACR_*}" and replace those values with the correct values for your container repository.
The ACR_IMAGE must exactly match what you pushed, e.g. aiedgelabcr.azurecr.io/customvision:1.0-x64-iotcore

```
    "$edgeAgent": {
      "properties.desired": {
        "runtime": {
          "settings": {
            "registryCredentials": {
              "{ACR_NAME}": {
                "username": "{ACR_USER}",
                "password": "{ACR_PASSWORD}",
                "address": "{ACR_NAME}.azurecr.io"
              }
            }
          }
        }
...
        "modules": {
            "squeezenet": {
            "settings": {
              "image": "{ACR_IMAGE}",
              "createOptions": "{\"HostConfig\":{\"Devices\":[{\"CgroupPermissions\":\"\",\"PathInContainer\":\"\",\"PathOnHost\":\"class/E5323777-F976-4f5b-9B55-B94699C46E44\"},{\"CgroupPermissions\":\"\",\"PathInContainer\":\"\",\"PathOnHost\":\"class/5B45201D-F2F2-4F3B-85BB-30FF1F953599\"}],\"Isolation\":\"Process\"}}"
            }
          }
```

## Deploy edge modules to device

Refer to this guide: [Deploy Azure IoT Edge modules from Visual Studio Code](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-deploy-modules-vscode)

1. In VS Code, open the "Azure IoT Hub Devices" pane. 
1. Locate the device there named according to the edge device name from when you created it in the hub. 
1. Right-click on that device, then select "Create deployment for single device".
1. Choose the deployment.json file you edited in the step above.
1. Press OK
1. Look for "deployment succeeded" in the output window.

```
[Edge] Start deployment to device [ai-edge-lab-device]
[Edge] Deployment succeeded.
```

## Verify the deployment on device

Wait a few minutes for the deployment to go through. On the target device you can inspect the running modules. Success looks like this:

```
[192.168.1.102]: PS C:\data\modules\customvision> iotedge list
NAME             STATUS           DESCRIPTION      CONFIG
customvision     running          Up 32 seconds    aiedgelabcr.azurecr.io/customvision:1.0-x64-iotcore
edgeAgent        running          Up 2 minutes     mcr.microsoft.com/azureiotedge-agent:1.0
edgeHub          running          Up 1 second      mcr.microsoft.com/azureiotedge-hub:1.0
```

Once the modules are up, you can inspect that the "customvision" module is operating correctly:

```
[192.168.1.102]: PS C:\data\modules\customvision> iotedge logs customvision
4/27/2019 9:04:59 AM: WindowsAiEdgeLabCV module starting.
4/27/2019 9:04:59 AM: Initializing Azure IoT Edge...
4/27/2019 9:06:11 AM: IoT Hub module client initialized.
4/27/2019 9:06:11 AM: ...OK 71516 ticks
4/27/2019 9:06:11 AM: Loading modelfile 'CustomVision.onnx' on the CPU...
4/27/2019 9:06:15 AM: ...OK 4140 ticks
4/27/2019 9:06:25 AM: Running the model...
4/27/2019 9:06:27 AM: ...OK 1500 ticks
4/27/2019 9:06:27 AM: Recognized {"results":[{"label":"Mug","confidence":1.0}],"metrics":{"evaltimeinms":1500,"cycletimeinms":0}}
```

Finally, back on the development machine, we can monitor device to cloud (D2C) messages from VS Code to ensure the messages are going up.

1. In VS Code, open the "Azure IoT Hub Devices" pane. 
1. Locate the device there named "ai-edge-lab-device". 
1. Right-click on that device, then select "Start monitoring D2C message".
1. Look for inferencing results in the output window.

```
[IoTHubMonitor] [9:07:44 AM] Message received from [ai-edge-lab-device/customvision]:
{
  "results": [
    {
      "label": "Mug",
      "confidence": 1
    }
  ],
  "metrics": {
    "evaltimeinms": 1484,
    "cycletimeinms": 0
  }
}
```

Once you see this, you can be certain the inferencing is happening on the target device and flowing up to the Azure IoT Hub.

# Step 5: View the results in Time Series Insights

1. Open the [Time Series Insights explorer](https://insights.timeseries.azure.com/) in a browser tab.
1. Choose the environment name you chose when creating the Time Series Insights resource in the portal.
1. Set "Quick Times" to "Last 30 minutes"
1. Click the "Auto On/Off" button until it reads "Auto On"
1. Press the search icon to update the data set
1. Set the Interval Size to 4 seconds (lowest possible)
1. In the "Events" section of the left panel, set "Measure" to "Count" of "Events", and "Split by" to "results.label"
1. Press the "Refresh" button to refresh data

Now you can change the object in front of the camera, and wait 10 seconds or so for the data to propagate, then press "Refresh" again. 
You'll see the graph change to indicate more of the new object at the current time.

![Time Series Insights Explorer](assets/tsi.jpg)
