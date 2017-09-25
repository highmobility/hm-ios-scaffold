//
//  ViewController.swift
//  Scaffold App
//
//  Created by Kevin Valdek on 2017-06-10.
//  Copyright © 2017 High-Mobility. All rights reserved.
//

import UIKit
import HMKit
import AutoAPI


class ViewController: UIViewController, LocalDeviceDelegate, LinkDelegate {

    @IBOutlet weak var status: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Logging options that are interesting to you
        LocalDevice.loggingOptions = [.bluetooth, .telematics]

        /*

         Before using the HMKit, you must initialise the LocalDevice with a snippet from the Developer Center:
         - go to https://developers.high-mobility.com
         - LOGIN
         - choose DEVELOP (in top-left, the (2nd) button with a spanner)
         - choose APPLICATIONS (in the left)
         - look for SANDBOX app
         - click on the "Device Certificates" on the app
         - choose the SANDBOX DEVICE
         - copy the whole snippet
         - paste it below this comment box
         - you made it!

         Bonus steps after completing the above:
         - relax
         - celebrate
         - explore the APIs


         An example of a snippet copied from the Developer Center (do not use, will obviously not work):

         do {
            try LocalDevice.sharedDevice.initialise(deviceCertificate: Base64String,
                                                    devicePrivateKey: Base64String,
                                                    issuerPublicKey: Base64String)
         }
         catch {
            // Handle the error
            print("Invalid initialisation parameters, please double-check the snippet: \(error)")
         }

         */

        // PASTE THE SNIPPET HERE

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
            /*

             Before using Telematics in HMKit, you must get the Access Certificate for the car / emualator:
             - go to https://developers.high-mobility.com
             - LOGIN
             - go to Tutorials ›› SDK ›› iOS for instructions to connect a service to the car
             - find and do the tutorial for connecting a Service to the car
             - authorise the service
             - take a good look into the mirror, you badass
             - open the SANDBOX car emulator
             - on the left, in the Authorised Services list, choose the Service you used before
             - copy the ACCESS TOKEN
             - paste it below to the appropriately named variable

             Bonus steps again:
             - get a beverage
             - quench your thirst
             - change the world with your mind
             - explore the APIs


             An example of an access token:

             awb4oQwMHxomS926XHyqdx1d9nYLYs94GvlJYQCblbP_wt-aBrpNpmSFf2qvhj18GWXXQ-aAtSaa4rnwBAHs5wpe1aK-3bD4xfQ3qtOS1QNV3a3iJVg03lTdNOLjFxlIOA
             
             */
            
            
            let accessToken: String = "PASTE ACCESS TOKEN HERE"


            guard accessToken != "PASTE ACCESS TOKEN HERE" else {
                fatalError("Please get the ACCESS TOKEN with the instructions above, thanks")
            }


            // Send command to the car through Telematics, make sure that the emulator is opened for this to work, otherwise "Vehicle asleep" will be returned
            try Telematics.downloadAccessCertificate(accessToken: accessToken) { result in

                if case Telematics.TelematicsRequestResult.success(let serial) = result {
                    print("Certificate downloaded, sending command through telematics.")


                    do {
                        try Telematics.sendCommand(AutoAPI.DoorLocksCommand.lockDoorsBytes(.unlock), vehicleSerial: serial) { response in

                            if case Telematics.TelematicsRequestResult.success(let data) = response {
                                guard let data = data else {
                                    return // fail
                                }

                                guard let locks = AutoAPI.parseIncomingCommand(data)?.value as? AutoAPI.DoorLocksCommand.Response else {
                                    print("Failed to parse Auto API")
                                    return
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

    func link(_ link: Link, didReceiveAuthorisationRequest serialNumber: [UInt8], approve: @escaping (() throws -> Void), timeout: TimeInterval) {
        do {
            // Approving without user input
            try approve()
        }
        catch {
            print("Pairing timed out")
        }
    }

    func link(_ link: Link, stateDidChange oldState: LinkState) {
        if (link.state == .authenticated) {

            // Bluetooth link authenticated, ready to send a command
            do {
                try link.sendCommand(AutoAPI.DoorLocksCommand.getStateBytes, commandSent: { error in
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

    func link(_ link: Link, didReceiveCommand bytes: [UInt8]) {

        guard let locks = AutoAPI.parseIncomingCommand(bytes)?.value as? AutoAPI.DoorLocksCommand.Response else {
            print("Failed to parse Auto API")
            return
        }
        print("Got the lock state \(locks).")
    }
}
