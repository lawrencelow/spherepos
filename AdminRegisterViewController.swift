//
//  AdminRegisterViewController.swift
//  POS
//
//  Created by iMac 4 on 21/5/15.
//  Copyright (c) 2015 Web Imp Pte Ltd. All rights reserved.
//

import UIKit

class AdminRegisterViewController: UIViewController {
    
    @IBOutlet weak var txtAdminEmail: UITextField!;
    @IBOutlet weak var btnRegister: UIButton!;
    
    let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true);
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1);
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor();
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()];
        
        txtAdminEmail.layer.cornerRadius = 4;
        txtAdminEmail.layer.borderWidth = 0.5;
        txtAdminEmail.layer.borderColor = UIColor.grayColor().CGColor;
        
        btnRegister.layer.cornerRadius = 4;
        btnRegister.layer.borderWidth = 0.5;
        btnRegister.layer.borderColor = UIColor.grayColor().CGColor;
        
        let deviceId = UIDevice.currentDevice().identifierForVendor.UUIDString;
        var device: Device!;
        var company: Company = Company();
        device = DeviceDataManager.getDeviceOutlet(deviceId);
        if device.return_code == 1 {
            prefs.setObject("online", forKey: "CONNECTION_MODE");
            if device.number_record > 0 {
                var validatedLogin = LoginDataManager.validateLogin("", udid: deviceId);
                company.company_name = validatedLogin["company_name"] as String!;
                company.company_address = validatedLogin["company_address"] as String!;
                
                prefs.setObject(company.company_name, forKey: "COMPANY_NAME");
                prefs.setObject(company.company_address, forKey: "COMPANY_ADDRESS");
                prefs.setObject(device.active, forKey: "DEVICE_ACTIVE");
                self.performSegueWithIdentifier("goto_login", sender: self);
                
            } else {
                Utilities.showDialog("Info", message: "Need to register this iPad!");
                return;
            }
            
        } else if device.return_code == -999 {
            // offline mode
            prefs.setObject("offline", forKey: "CONNECTION_MODE");
            self.performSegueWithIdentifier("goto_login", sender: self);
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "registerOutlet" {
            if txtAdminEmail.text != "" {
                let controller = segue.destinationViewController as! OutletRegisterViewController;
                controller.outlets = getAdminOutlets(txtAdminEmail.text);
                controller.company = company;
                
            } else {
                Utilities.showDialog("Error", message: "Admin Email is required!");
            }
        }
    }
    
    var company:String!;
    
    @IBAction func btnBackTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil);
        
    }
    
    func getAdminOutlets (email: NSString) -> [Outlet]! {
        var request = POSDataRequest.adminRegiterDeviceRequest(email);
        var reponseError: NSError?;
        var response: NSURLResponse?;
        
        var urlData: NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&reponseError);
        
        var outlets: [Outlet]!;
        
        if ( urlData != nil ) {
            let res = response as! NSHTTPURLResponse!;
            
            NSLog("Response code: %ld", res.statusCode);
            
            if (res.statusCode >= 200 && res.statusCode < 300) {
                var responseData:NSString  = NSString(data:urlData!, encoding:NSUTF8StringEncoding)!;
                
                NSLog("Response ==> %@", responseData);
                
                var error: NSError?;
                
                let jsonData:NSDictionary = NSJSONSerialization.JSONObjectWithData(urlData!, options:NSJSONReadingOptions.MutableContainers , error: &error) as! NSDictionary;
                let data:AnyObject = jsonData.valueForKey("outlets") as AnyObject!;
                company = jsonData.valueForKey("company") as! String!;
                
                outlets =  self.parseJson(data);
                
            } else {
                Utilities.showDialog("Error", message: "Connection Failed!");
            }
        } else {
            Utilities.showDialog("Error", message: "Network Failure!");
        }
        
        return outlets;
    }
    
    func parseJson(anyObj:AnyObject) -> [Outlet]! {
        var outlets:Array<Outlet> = Array<Outlet>();
        if  anyObj is Array<AnyObject> {
            for json in anyObj as! Array<AnyObject> {
                var o:Outlet = Outlet();
                
                /*[{"id":"1","name":"Yishun","address":"1 Yishun Industrial Street 1 Singapore 768160","telephone":"98798789","fax":"97879879","email":"yishun@apple.com.sg","company_id":"2","active":"1","receipt_prefix":"Y"}]}*/
                
                o.outlet_id = (json["id"]  as AnyObject? as? String) ?? "";
                o.outlet_name = (json["name"]  as AnyObject? as? String) ?? "";
                o.address = (json["address"]  as AnyObject? as? String) ?? "";
                o.telephone = (json["telephone"]  as AnyObject? as? String) ?? "";
                o.fax = (json["fax"]  as AnyObject? as? String) ?? "";
                o.email = (json["email"]  as AnyObject? as? String) ?? "";
                o.company = (json["company_id"]  as AnyObject? as? String) ?? "";
                o.active = (json["active"]  as AnyObject? as? String) ?? "";
                o.receipt_prefix = (json["receipt_prefix"]  as AnyObject? as? String) ?? "";
                
                var temp:Array<Outlet> = [];
                temp.append(o);
                
                if (outlets.count == 0) {
                    outlets = temp;
                } else {
                    outlets += temp;
                }
            }
        }
        
        return outlets;
    }
}
