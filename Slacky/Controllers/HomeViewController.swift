//
//  ViewController.swift
//  Slacky
//
//  Created by Kushal Ashok on 7/20/19.
//  Copyright © 2019 Kushal Ashok. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class HomeViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {

    // MARK: - Outlets
    
    @IBOutlet weak var wifiIdLabel: UILabel!
    @IBOutlet weak var bssidLabel: UILabel!
    @IBOutlet weak var statusTextField: UITextField!
    
    
    // MARK: - Properties
    
    var locationManager = CLLocationManager()
    var currentNetworkInfos: Array<NetworkInfo>? {
        get {
            return SSID.fetchNetworkInfo()
        }
    }
    
    
    // MARK: - View Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkWifi()
        statusTextField.delegate = self
    }
    
    // MARK: - Configuration
    
    private func checkWifi() {
        if #available(iOS 13.0, *) {
            let status = CLLocationManager.authorizationStatus()
            if status == .authorizedWhenInUse {
                updateWiFi()
            } else {
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
            updateWiFi()
        }
    }
    
    func updateWiFi() {
        wifiIdLabel.text = currentNetworkInfos?.first?.ssid ?? "Could not fetch Wifi details"
        bssidLabel.text = currentNetworkInfos?.first?.bssid ?? "You an still update the slack status manually"
    }
    
    // MARK: - User Actions
    
    @IBAction func getWifiButtonTapped(_ sender: Any) {
        checkWifi()
    }
    
    @IBAction func emojiButtonTapped(_ sender: Any) {
        let alert = getAlert("Coming soon", message: "We will soon allow you to select an emoji for your status updates")
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func updateButtonTapped(_ sender: Any) {
        if let statusString = statusTextField.text, !statusString.isEmpty {
            postSlackStatus(statusString)
        } else {
            let alert = getAlert("Missing Status", message: "Please enter a status string")
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            updateWiFi()
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // MARK: - Network interface
    
    func postSlackStatus(_ statusString: String) {
        guard let serviceUrl = URL(string: "https://slack.com/api/users.profile.set") else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //TODO: Allow user to set their token manually or implement authentication to get token
        request.setValue("Bearer \(myToken)", forHTTPHeaderField: "Authorization")
        
        let parameterDictionary = ["profile" : ["status_text": statusString, "status_emoji": ":books:", "status_expiration": 5]]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            return
        }
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                    if let jsonDictionary = json as? [String: Any] {
                        if let isOk = jsonDictionary["ok"] as? Bool, isOk {
                            if let profile = jsonDictionary["profile"] as? [String: Any],
                                let statusText = profile["status_text"] as? String,
                                let statusExpiration = profile["status_expiration"] as? Int {
                                DispatchQueue.main.async {
                                    print("\(statusExpiration) is not used as of now")
                                    self.showConfirmationAlert(statusText)
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            } else if let response = response {
                print(response)
            }
            }.resume()
    }
    
    // MARK: - Saving data
    
    func showConfirmationAlert(_ statusText: String) {
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [unowned self] action in
            guard let statusToSave = self.statusTextField.text else {
                return
            }
            self.save(statusToSave)
        }
        let alert = getAlert("Status Updated", message: "Your slack status has been updated to '\(statusText)'")
        alert.addAction(saveAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func save(_ status: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        //Get managed object context
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //Create new entry
        let entity =
            NSEntityDescription.entity(forEntityName: "WiFi",
                                       in: managedContext)!
        let newEntry = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        newEntry.setValue(status, forKeyPath: "status")
        if let ssid = currentNetworkInfos?.first?.ssid,
            let bssid = currentNetworkInfos?.first?.bssid {
            newEntry.setValue(ssid, forKeyPath: "ssid")
            newEntry.setValue(bssid, forKeyPath: "bssid")
        }
        
        //Save new entry
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
}
