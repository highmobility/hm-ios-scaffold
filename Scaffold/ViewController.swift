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


class ViewController: UIViewController, LocalDeviceDelegate, LinkDelegate {

    @IBOutlet weak var status: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Logging options that are interesting to you
        LocalDevice.loggingOptions = [.bluetooth, .telematics]

        /*
         * Before using HMKit, you'll have to initialise the LocalDevice singleton
         * with a snippet from the Platform Workspace:
         *
         *   1. Sign in to the workspace
         *   2. Go to the LEARN section and choose iOS
         *   3. Follow the Getting Started instructions
         *
         * By the end of the tutorial you will have a snippet for initialisation,
         * that looks something like this:
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


        LocalDevice.shared.delegate = self


        guard LocalDevice.shared.certificate != nil else {
            fatalError("Please initialise the HMKit with the instrucions above, thanks")
        }


        do {
            // Start Bluetooth broadcasting, so that the car can connect to this device
            try LocalDevice.shared.startBroadcasting()
        }
        catch {
            print("Start Broadcasting error: \(error)")
        }

        do {
            let accessToken: String = "<#Paste the ACCESS TOKEN here#>"


            guard accessToken != "PASTE ACCESS TOKEN HERE" else {
                fatalError("Please get the ACCESS TOKEN with the instructions above, thanks")
            }


            // Send command to the car through Telematics, make sure that the emulator is opened for this to work, otherwise "Vehicle asleep" will be returned
            try Telematics.downloadAccessCertificate(accessToken: accessToken) { result in
                if case TelematicsRequestResult.success(let serial) = result {
                    print("Certificate downloaded, sending command through telematics.")

                    do {
                        try Telematics.sendCommand(DoorLocks.lockUnlock(.unlock), serial: serial) { response in
                            if case TelematicsRequestResult.success(let data) = response {
                                guard let data = data else {
                                    return // fail
                                }

                                guard let locks = AutoAPI.parseBinary(data) as? DoorLocks else {
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
                        print("Failed to send command")
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

    func localDevice(didReceiveLink link: Link) {
        // Bluetooth link to car created
        link.delegate = self
    }

    func localDevice(stateChanged state: LocalDeviceState, oldState: LocalDeviceState) {
        print("State changed to \(state)")
    }

    func localDevice(didLoseLink link: Link) {
        // Bluetooth link disconnected
        do {
            try LocalDevice.shared.startBroadcasting()
        }
        catch {
            print("Start Broadcasting error: \(error)")
        }
    }


    // MARK: LinkDelegate

    func link(_ link: Link, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping (() throws -> Void), timeout: TimeInterval) {
        do {
            // Approving without user input
            try approve()
        }
        catch {
            print("Pairing timed out")
        }
    }

    func link(_ link: Link, stateChanged oldState: LinkState) {
        if (link.state == .authenticated) {
            // Bluetooth link authenticated, ready to send a command
            do {
                try link.sendCommand(DoorLocks.getLockState, sent: { error in
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

    func link(_ link: Link, commandReceived bytes: [UInt8]) {
        guard let locks = AutoAPI.parseBinary(bytes) as? DoorLocks else {
            return print("Failed to parse Auto API")
        }

        print("Got the lock state \(locks).")
    }
}
