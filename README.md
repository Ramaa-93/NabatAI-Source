# NabatAI

NabatAI is an AI-powered tourism application designed to improve the tourist experience in Jordan by providing intelligent planning, cultural exploration, crowd-awareness features, and interactive assistance through a mobile application.

This repository contains the **executable release of the project for academic evaluation**.

## Release

Current version:

`NabatAI v1.0.0`

Android application:

`NabatAI-v1.0.0.apk`

## Main Features

NabatAI includes several smart tourism features, including:

* AI-assisted trip planning based on user preferences, budget, interests, and trip duration.
* Tourist place exploration and recommendations.
* Crowd monitoring and prediction.
* Interactive tourist guidance.
* Heritage reconstruction prototype.
* Personalized tourism experience through user-selected preferences.

## Heritage Reconstruction – Prototype Implementation

The Heritage Reconstruction feature is currently implemented as a **prototype / proof of concept**.

The proposed full implementation is designed to integrate a generative AI image model capable of dynamically producing historical reconstructions of heritage locations from modern images.

During the prototype development stage, continuous use of commercial generative image APIs would require paid subscriptions and significant API usage costs.

For this reason, the current academic prototype uses prepared demonstration reconstruction outputs to simulate the complete user flow.

The prototype therefore demonstrates:

* Image selection and upload flow.
* Communication between the mobile application and reconstruction feature.
* Reconstruction result presentation.
* Intended user experience.
* Overall architecture and feasibility of the proposed AI-based reconstruction system.

The generative model can be integrated into the same workflow in a production version once an appropriate generative AI service or deployment infrastructure is available.

## Backend Requirement

Some NabatAI features depend on the project's backend service.

The backend must be running before testing features that communicate with the API.

## API URL Configuration

The API URL depends on the environment used to run the Android application.

### Android Emulator

Use:

```text id="4q1cyw"
http://10.0.2.2:8000
```

`10.0.2.2` allows the Android Emulator to access the localhost of the development computer.

### Physical Android Device

When running NabatAI on a physical Android device, use the local network IP address of the computer running the backend.

Example:

```text id="u2m4td"
http://192.168.x.x:8000
```

The Android device and development computer should be connected to the same local network.

Before testing backend-dependent functionality, verify that the configured API base URL corresponds to the environment being used.

## Installation

1. Download `NabatAI-v1.0.0.apk` from the GitHub Release.
2. Transfer the APK to an Android device if necessary.
3. Allow installation from the required source when prompted by Android.
4. Install the application.
5. Start the NabatAI backend before testing API-dependent features.
6. Verify the API URL configuration.
7. Launch the application.

## Notes

This version represents the current **academic prototype release** of NabatAI.

The application is intended to demonstrate the functionality, architecture, AI integration concepts, and overall user experience proposed by the project.

Some production-level services, particularly real-time generative image reconstruction, are represented through prototype implementations due to external API and infrastructure costs.

## Version

**NabatAI v1.0.0**

Academic Prototype Release
