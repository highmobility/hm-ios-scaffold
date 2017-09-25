# Overview

This sample app for iOS shows the basic use of the SDKs to authenticate with an emulator and send a command to it.

# Configuration

Before running the app, make sure to configure the following in `ViewController.swift`:

1. Initialise HMKit with a valid `Device Certiticate` from the Developer Center https://developers.high-mobility.com/
2. Find an `Access Token` in an emulator from https://developers.high-mobility.com/ and paste it in the source code to download `Access Certificates` from the server

# Run the app

Run the app on your phone, or simulator, to see the basic flow:
    - initialising the SDK
    - getting Access Certificates
    - connecting and authenticating with an emulator
    - sending commands.
