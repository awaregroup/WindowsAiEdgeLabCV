# Hands-On-Lab: AI+Edge on Windows with Azure Custom Vision

For this lab, we will use the Azure Custom Vision service to train a machine learning model for image detection. We will use that model to create a .NET application to pull frames from a connected USB camera, use Windows ML to classify the image with GPU-accelerated inferencing, and send the result to Azure IoT Hub. We will deploy that application to a Windows IoT Core device using Azure IoT Edge. Finally, we will watch the results using Time Series Insights.

# Pre-requisites Overview

Here's a recap of the configuration you'll need before you get started with the lab.

## Azure Services

We will need to set up a number of Azure services to complete this lab.

1. A valid Azure subscription. [Create an account](https://azure.microsoft.com/free/) for free.
2. Azure Custom Vision Service
3. Azure Container Registry
4. Azure IoT Hub, with a single device set up for Edge
5. Azure Time Series Insights, tied to the above Azure IoT Hub.

You may be running this lab in an environment where the azure subscription and services have already been set up for you. In this case, you can skip the following sections and use the following information:


Item | Value
--- | ---
Subscription Username	| 
Subscription Password	| 
Container Registry Login Server	|
Container Registry Username	|
Container Registry Password	|
IoTHub Name	|
IoTHub Owner Connection String |
Edge Device Name |	
Edge Device Connection String |

## Development Environment

To set up our development environment, we will need:

1. A PC running Windows 10 version 1809.
2. The Windows SDK version 1809 (10.17763.0).
3. Visual Studio Code
4. Azure IoT Hub Toolkit for Visual Studio Code
7. [Git for Windows](https://git-scm.com/download/win)
8. [Windows 10 IoT Core Dashboard](https://docs.microsoft.com/en-us/windows/iot-core/connect-your-device/iotdashboard)
9. Connected via Ethernet to a network switch on the same subnet as the Target Machine.

## Target Machine

In this lab, we are using an UP Squared board running IoT Core using CPU evaluation. With just a little change, this can also be done on an AMD V1000 running IoT Core with GPU evaluation, or soon on a Raspberry Pi. With a bit more change, it can also be run on a Windows PC running Windows 10 IoT Enterprise.

To recap, for this lab we are using:

1. [UP Squared](https://www.aaeon.com/en/p/iot-gateway-maker-boards-up-squared)
2. Running [Windows 10 IoT Core LTSC 2019](https://developer.microsoft.com/en-us/windows/iot)
3. With a USB camera
4. [Azure IoT Edge 1.0.6](https://docs.microsoft.com/en-us/azure/iot-edge/quickstart) or higher
5. Connected via Ethernet to a network switch on the same subnet as the Development PC.

You may be running this lab in an environment where the target device has already been set up for you. In this case, you can skip the following sections and use the following information:

Item | Value
--- | ---
Device Name |
Device IP |
Administrator Password |

## Physical Environment

1. Create a consistent environment for recognition. Use a single-color background. Place the objects in the same place, and the camera in the same place.
2. Select four or five physical objects you'll use for the classification.
3. Obtain a small desk lamp to illuminate them. Having consistent lighting helps the classifier.

# Pre-requisites in Detail

Here is more detail on how to set up your pre-requisites for the lab:

## Azure Custom Vision Service

Refer to this guide: [How to build a classifier with Custom Vision](https://docs.microsoft.com/en-us/azure/cognitive-services/Custom-Vision-Service/getting-started-build-a-classifier).

1. Sign into the Azure Portal
2. Create a new "Custom Vision" resource.
3. Sign into the [Custom Vision Portal](https://www.customvision.ai/) with the same account as your azure subscription
4. From the profile menu (upper-left) choose the "directory" associated with your azure subscription.

Your custom vision portal is all set!

## Azure Container Registry

Refer to this guide: [Quickstart: Create a private container registry using the Azure portal](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal)

1. Sign into the Azure Portal
2. Create a new "Container Registry" resource
3. Once created, switch to the "Access Keys" pane.
4. Enable the "Admin User"
5. Make note of the Login Server, username, and password. You'll need these later.

## Azure IoT Hub

1. Sign into the Azure Portal
2. Create a new "IoT Hub" resource
3. Once created, switch to the "Shared access policies" pane, select the "iothubowner" policy.
4. Select the "Owner" role. 
5. Make note of the connection string for the iothubowner role. You'll need this later.
6. Now, we will create a device. Switch to the "IoT Edge" pane.
7. Choose "Add a new device"
8. Once created, select the device from the list.
9. Make note of the connection string for this device. You'll need this later.

## Azure Time Series Insights

Refer to this guide: [Add an IoT hub event source to your Time Series Insights environment](https://docs.microsoft.com/en-us/azure/time-series-insights/time-series-insights-how-to-add-an-event-source-iothub)

1. Sign into the Azure Portal
2. Create a new "Time Series Insights" resource.
3. Choose the "PAYG" (pay-as-you-go) pricing tier.
4. Choose "Next: Event Source"
5. For the event source, choose the existing Azure IoT Hub you configured above. For IoT Hub access policy, choose "iothubowner". For "consumer group", enter a unique name to use as the consumer group for events.

## Windows SDK

1. Download and install the 1809 version of the Windows SDK from the [Windows SDK Archive](https://developer.microsoft.com/en-us/windows/downloads/sdk-archive).
2. Determine the location of the Windows.winmd file. This is typically "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.17763.0\Windows.winmd".
3. Set the "WINDOWS_WINMD" environment variable to this location.

```
PS C:\> $env:WINDOWS_WINMD = "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.17763.0\Windows.winmd"
PS C:\> setx WINDOWS_WINMD "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.17763.0\Windows.winmd"

SUCCESS: Specified value was saved.
```

## Visual Studio Code

1. Download and install [Visual Studio Code](https://code.visualstudio.com/)
2. Download and install the [Azure IoT Hub Toolkit](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-toolkit) for Visual Studio Code
3. Connect VS Code to your IoT Hub as follows…
4. Return to the Explorer tab in VS Code
5. Hover over the "Azure IoT Hub Devices" pane.
6. Click the "…"
7. Choose "Set IoT Hub Connection String"
8. Enter the connection string for the IoT Hub Owner, from the steps above
9. You'll see the device show up which you created in the previous steps

## Azure IoT Edge

*** TODO: Finish this!

After installing Azure IoT Edge, deploy the simulated temperature sensor to the device, and ensure that 
you can connect to it using VS Code, and that you can see device-to-cloud (D2C) messages being transmitted.

# Step 1: Train the Model

1. Plug the USB camera into your development PC.
2. Using the Camera app on your development PC, take at least 5 pictures each of your objects. Store these pictures on your computer. Organize all the photos for each object into a folder named for this object. It will make them easier to upload.
3. Log into the Custom Vision Portal
4. Choose the Directory associated with your Azure account
5. Create a New Project. Be sure to choose a "compact" domain.
6. Upload them to your custom vision project. I recommend to upload one object at a time, so it's easy to apply a tag to all your images. Each time you upload all the images for a given object, specify the tag at that time.
7. Select "Train" to train the model
8. Select "Quick Test" to test the model.
9. Using the camera app on your PC, take one more picture of one of the objects
10. Upload the picture you took, verify that it was predicted correctly.
11. Export the model. From the "Performance" tab, select the "Export" command.
12. Choose "ONNX", then "ONNX1.2" version.
13. After downloading, rename the file "CustomVision.onnx"

# Step 2: Package the model into a C# .NET Application

## Get the code

If you are running this lab in an environment where this has already been set up, the initial sample will already be present in the directory C:\WindowsAiEdgeLabCV. Otherwise, clone the code as follows:

1. Open a Windows Powershell Prompt.
2. Change to a directory you'll use for the lab code. For example, C:\
3. Clone the lab repo https://github.com/jcoliz/WindowsAiEdgeLabCV.git

```
PS C:\> git clone https://github.com/jcoliz/WindowsAiEdgeLabCV.git 
Cloning into 'WindowsAiEdgeLabCV'...
remote: Azure Repos
remote: Found 78 objects to send. (51 ms)
Unpacking objects: 100% (78/78), done.
PS C:\> cd .\WindowsAiEdgeLabCV\
```

## Get your model file

Copy the CustomVision.onnx model file from your downloads directory where you exported it into the lab directory.

## Build & Test the sample

```
PS C:\WindowsAiEdgeLabCV> dotnet publish -r win-x64
Microsoft (R) Build Engine version 16.0.225-preview+g5ebeba52a1 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 43.29 ms for C:\WindowsAiEdgeLabCV\WindowsAiEdgeLabCV.csproj.
  WindowsAiEdgeLabCV -> C:\WindowsAiEdgeLabCV\bin\Debug\netcoreapp2.2\WindowsAiEdgeLabCV.dll
  WindowsAiEdgeLabCV -> C:\WindowsAiEdgeLabCV\bin\Debug\netcoreapp2.2\publish\
```

Run the sample to determine the name of the USB camera plugged in

```
PS C:\WindowsAiEdgeLabCV> dotnet run --list
Found 1 Cameras
Microsoftr LifeCam HD-6000 for Notebooks
```

Point the camera at one of your objects, still connected to your development PC

Run the sample locally to classify the object. This will test that the app is running correctly locally. For the 'device' parameter use a unique substring of the camera that came up. Here we can see that a "Mug" has been recognized.

```
PS C:\WindowsAiEdgeLabCV> dotnet run --model=CustomVision.onnx --device=LifeCam
4/24/2019 4:09:04 PM: Loading modelfile 'CustomVision.onnx' on the CPU...
4/24/2019 4:09:04 PM: ...OK 594 ticks
4/24/2019 4:09:05 PM: Running the model...
4/24/2019 4:09:05 PM: ...OK 47 ticks
4/24/2019 4:09:05 PM: Recognized {"results":[{"label":"Mug","confidence":1.0}],"metrics":{"evaltimeinms":47,"cycletimeinms":0}}
```

# Step 3: Build and push a moby container

## Find our IoT Core device

IoT Core container images must be built on an IoT Core device. 

First, let’s connect to our device. Launch the IoT Core Dashboard from your development PC, and identify the IoT Core device you're using. Right-click, and choose "Launch Powershell". Enter the password for your device, and wait for a shell to come up. We'll come back to that in a moment.

Now, notice the IP address for this device, for example "192.168.1.102". Back on our development PC, let's map the Q: drive so we can easily access files.

```
PS C:\WindowsAiEdgeLabCV> $ip="192.168.1.102"
PS C:\WindowsAiEdgeLabCV> net use q: \\$ip\c$ pw /USER:Administrator
The command completed successfully.
```

## Copy published files to target device

We will copy the 'publish' folder over to our device

```
PS C:\WindowsAiEdgeLabCV> robocopy .\bin\Debug\netcoreapp2.2\win-x64\publish\ q:\data\modules\customvision

-------------------------------------------------------------------------------
    ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

    Started : Wednesday, April 24, 2019 4:31:37 PM
    Source : D:\home\source\Repos\Windows-iotcore-samples\Samples\EdgeModules\SqueezeNetObjectDetection\cs\bin\Debug\netcoreapp2.2\win-x64\publish\
        Dest : q:\data\modules\customvision\

    Files : *.*

    Options : *.* /DCOPY:DA /COPY:DAT /R:1000000 /W:30

------------------------------------------------------------------------------
```

## Test the sample on the target device

Following the same approach as above, we will run the app on the target device to ensure we have the correct camera there, and it's working on that device.

Change to the "c:\data\modules\customvision" directory, then do a test run as we did previously:

```
[192.168.1.102]: PS C:\data\modules\customvision> .\WindowsAiEdgeLabCV.exe --list
4/27/2019 8:30:52 AM: Available cameras:
4/27/2019 8:30:53 AM: Microsoft® LifeCam HD-6000 for Notebooks
[192.168.1.102]: PS C:\data\modules\customvision> .\WindowsAiEdgeLabCV.exe --model=CustomVision.onnx --device=LifeCam
4/27/2019 8:31:31 AM: Loading modelfile 'CustomVision.onnx' on the CPU...
4/27/2019 8:31:32 AM: ...OK 1516 ticks
4/27/2019 8:31:36 AM: Running the model...
4/27/2019 8:31:38 AM: ...OK 1953 ticks
4/27/2019 8:31:42 AM: Recognized {"results":[{"label":"Mug","confidence":1.0}],"metrics":{"evaltimeinms":1953,"cycletimeinms":0}}
```

## Containerize the sample app

Build the container on the device. To make things easier in this lab, we will set the value of $Container to the address where we will push our container. This will be in the container repository we set up earlier. Find the "Container Registry Login Server" address from the steps above. For example, I am using "aiedgelabcr.azurecr.io" 
to test the lab, so I will do as follows:

```
[192.168.1.102]: PS C:\data\modules\customvision> $Container = "aiedgelabcr.azurecr.io/customvision:1.0-x64-iotcore"
```

Still in the "c:\data\modules\customvision" directory, we will now build the container on the IoT Core device.
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
[192.168.1.102]: PS C:\data\modules\customvision> docker login aiedgelabcr.azurecr.io -u aiedgelabcr -p {ACR_PASS}
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
2. Locate the device there named "ai-edge-lab-device". 
3. Right-click on that device, then select "Create deployment for single device".
4. Choose the deployment.json file you edited in the step above.
5. Press OK
6. Look for "deployment succeeded" in the output window.

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

Finally, beck on the development machine, we can monitor device to cloud (D2C) messages from VS Code to ensure the messages are going up.

1. In VS Code, open the "Azure IoT Hub Devices" pane. 
2. Locate the device there named "ai-edge-lab-device". 
3. Right-click on that device, then select "Start monitoring D2C message".
6. Look for inferencing results in the output window.

```
[IoTHubMonitor] [9:07:44 AM] Message received from [ai-edge-lab-device/squeezenet]:
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
