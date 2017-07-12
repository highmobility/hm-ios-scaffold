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

        // Logging options that are interesting to me
        LocalDevice.loggingOptions = [.bluetooth, .telematics]

        do {
            // Replace this with snippet from your developer account
            try LocalDevice.sharedDevice.initialise(
                deviceCertificate: "dGVzdF1c/i8NfIZSg0ASN9eqGUm33uO9QMplcmdp38sllFP71m/XJqbFBvjIjuUzlisSqb7S/z6VzA669ClOATberMQdLTEc7OQJFNIViwOh5Y4oLLo+mWEC20FtkyKbiDqQrjDLlncNiytQfdANchvHyua2nxWrmuKxf/iDx9UcYByX1qT9rMdwjbxFTGYNUwA/PNNg693O",
                devicePrivateKey: "IJhqWp5RHVnBww5v3C88U6zsYCiRnMb/IkB/RDyd2xU=",
                issuerPublicKey: "p+majvq75ISGpEDR+0GgXmhqucmDfP1pUNTE/sIaSbuPTA7o7kAbtRBwCfS2OPt8N9HBiLsYNsMl0ztzz9HX4A=="
            )
        }
        catch {
            //handle error
            print("Invalid initialisation parameters, please double check the snippet.")
        }

        LocalDevice.sharedDevice.delegate = self as LocalDeviceDelegate

        do {
            // Start Bluetooth broadcasting, so that the car can connect to this device
            try LocalDevice.sharedDevice.startBroadcasting()
        } catch {
            print("Start Broadcasting error: \(error)")
        }

        do {
            // Send command to the car through Telematics, make sure that the emulator is opened for this to work, otherwise "Vehicle asleep" will be returned
            // Replace token with Authorised Service token from the emulator according to tutorial https://developers.h-m.space/resources/tutorials/virtual-cars/using-telematics
            try Telematics.downloadAccessCertificate(accessToken: "Qe8_nLatDfWzQ1HCi30cUjRUZguZVPTHZ046zVXfkAxgj1bpvem_N752EcTd_6BN2xnT_bsGJhFjvB3Xuhh4jRrjKX2UG0_lVqGyTrFVFHbjXkb1DLdi95DnARO8fNTc-g") { result in

                if case Telematics.TelematicsRequestResult.success(let serial) = result {
                    print("Certificate downloaded, sending command through telematics.")

                    Telematics.sendCommand(Data(bytes: AutoAPI.DoorLocksCommand.lockDoorsBytes(.unlock)), vehicleSerial: serial) { response in

                        if case Telematics.TelematicsRequestResult.success(let data) = response {
                            guard let data = data else {
                                return // fail
                            }

                            guard let locks = AutoAPI.parseIncomingBytes(Array(data))?.value as? AutoAPI.DoorLocksCommand.Response else {
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
                else {
                    print("Failed to download certificate \(result).")
                }
            }
        } catch {
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
            try LocalDevice.sharedDevice.startBroadcasting()
        } catch {
            print("Start Broadcasting error: \(error)")
        }
    }

    func link(_ link: Link, didReceiveAuthorisationRequest serialNumber: [UInt8], approve: @escaping ((Void) throws -> Void), timeout: TimeInterval) {
        do {
            // Approving without user input
            try approve()
        } catch {
            print("Pairing timed out")
        }
    }

    func link(_ link: Link, stateDidChange oldState: LinkState) {
        if (link.state == .authenticated) {

            // Bluetooth link authenticated, ready to send a command
            link.sendCommand(AutoAPI.DoorLocksCommand.getStateBytes) { response, error in
                if (error == nil) {
                    print("Sent Get Door Locks")
                }
                else {
                    print("Error sending Get Door Locks")
                }
            }
        }
    }

    func link(_ link: Link, didReceiveCommand bytes: [UInt8]) {

        guard let locks = AutoAPI.parseIncomingBytes(bytes)?.value as? AutoAPI.DoorLocksCommand.Response else {
            print("Failed to parse Auto API")
            return
        }
        print("Got the lock state \(locks).")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

