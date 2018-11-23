//
//  ViewController.swift
//  Scaffold App
//
//  Created by Kevin Valdek on 2017-06-10.
//  Copyright © 2017 High-Mobility. All rights reserved.
//

import AutoAPI
import HMKit
import UIKit


class ViewController: UIViewController, HMLocalDeviceDelegate, HMLinkDelegate {

    @IBOutlet weak var status: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Logging options that are interesting to you
        HMLocalDevice.loggingOptions = [.bluetooth, .telematics]

        /*
         * Before using HMKit, you'll have to initialise the LocalDevice singleton
         * with a snippet from the Platform Workspace:
         *
         *   1. Sign in to the workspace
         *   2. Go to the LEARN section and choose iOS
         *   3. Follow the Getting Started instructions
         *
         * By the end of the tutorial you will have a snippet for initialisation
         * looking something like this:
         *
         *   do {
         *       try LocalDevice.shared.initialise(deviceCertificate: Base64String, devicePrivateKey: Base64String, issuerPublicKey: Base64String)
         *   }
         *   catch {
         *       // Handle the error
         *       print("Invalid initialisation parameters, please double-check the snippet: \(error)")
         *   }
         */


        <#Paste the SNIPPET here#>


        HMLocalDevice.shared.delegate = self


        guard HMLocalDevice.shared.certificate != nil else {
            fatalError("Please initialise the HMKit with the instrucions above, thanks")
        }


        do {
            // Start Bluetooth broadcasting, so that the car can connect to this device
            try HMLocalDevice.shared.startBroadcasting()
        }
        catch {
            print("Start Broadcasting error: \(error)")
        }

        do {
            let accessToken: String = "<#Paste the ACCESS TOKEN here#>"


            guard accessToken != "Paste the ACCESS TOKEN here" else {
                fatalError("Please get the ACCESS TOKEN with the instructions above, thanks")
            }


            // Send a command to the car through Telematics.
            // Make sure that the emulator is OPENED for this to work,
            // otherwise "Vehicle asleep" could be returned.
            try HMTelematics.downloadAccessCertificate(accessToken: accessToken) { result in
                if case HMTelematicsRequestResult.success(let serial) = result {
                    print("Certificate downloaded, sending command through telematics.")

                    do {
                        try HMTelematics.sendCommand(AADoorLocks.lockUnlock(.unlocked), serial: serial) { response in
                            if case HMTelematicsRequestResult.success(let data) = response {
                                guard let data = data else {
                                    return print("Missing response data")
                                }

                                guard let locks = AutoAPI.parseBinary(data) as? AADoorLocks else {
                                    return print("Failed to parse Auto API")
                                }

                                print("Got the new lock state \(locks).")
                            }
                            else {
                                print("Failed to lock the doors \(response).")
                            }
                        }
                    }
                    catch {
                        print("Failed to send command:", error)
                    }
                }
                else {
                    print("Failed to download certificate \(result).")
                }
            }
        }
        catch {
            print("Download cert error: \(error)")
        }
    }


    // MARK: LocalDeviceDelegate

    func localDevice(didReceiveLink link: HMLink) {
        // Bluetooth link to car created
        link.delegate = self
    }

    func localDevice(stateChanged state: HMLocalDeviceState, oldState: HMLocalDeviceState) {
        print("State changed to \(state)")
    }

    func localDevice(didLoseLink link: HMLink) {
        // Bluetooth link disconnected
        do {
            try HMLocalDevice.shared.startBroadcasting()
        }
        catch {
            print("Start Broadcasting error: \(error)")
        }
    }


    // MARK: LinkDelegate

    func link(_ link: HMLink, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping (() throws -> Void), timeout: TimeInterval) {
        do {
            // Approving without user input
            try approve()
        }
        catch {
            print("Pairing timed out")
        }
    }

    func link(_ link: HMLink, stateChanged oldState: HMLinkState) {
        if (link.state == .authenticated) {
            // Bluetooth link authenticated, ready to send a command
            do {
                try link.sendCommand(AADoorLocks.getLocksState, sent: { error in
                    if (error == nil) {
                        print("Sent Get Door Locks")
                    }
                    else {
                        print("Error sending Get Door Locks")
                    }
                })
            }
            catch {
                print("Error sending Get Door Locks: \(error)")
            }
        }
    }

    func link(_ link: HMLink, commandReceived bytes: [UInt8]) {
        guard let locks = AutoAPI.parseBinary(bytes) as? AADoorLocks else {
            return print("Failed to parse Auto API")
        }

        print("Got the lock state \(locks).")
    }

    func link(_ link: HMLink, revokeCompleted bytes: [UInt8]) {
        print("Received REVOKE:", bytes.hex)
    }
}
