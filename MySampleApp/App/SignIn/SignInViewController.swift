//
//  SignInViewController.swift
//  MySampleApp
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.4
//
//

import UIKit
import AWSMobileHubHelper
import FBSDKLoginKit
import GoogleSignIn

class SignInViewController: UIViewController {
    @IBOutlet weak var anchorView: UIView!

    @IBOutlet weak var facebookButton: UIButton!

    @IBOutlet weak var googleButton: UIButton!

// Support code for custom sign-in provider UI.
    @IBOutlet weak var customProviderButton: UIButton!
    @IBOutlet weak var customCreateAccountButton: UIButton!
    @IBOutlet weak var customForgotPasswordButton: UIButton!
    @IBOutlet weak var customUserIdField: UITextField!
    @IBOutlet weak var customPasswordField: UITextField!
    @IBOutlet weak var leftHorizontalBar: UIView!
    @IBOutlet weak var rightHorizontalBar: UIView!
    @IBOutlet weak var orSignInWithLabel: UIView!
    
    
    var didSignInObserver: AnyObject!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
         print("Sign In Loading.")
        
            didSignInObserver =  NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignIn,
                object: AWSIdentityManager.defaultIdentityManager(),
                queue: OperationQueue.main,
                using: {(note: Notification) -> Void in
                    // perform successful login actions here
            })

                // Facebook login permissions can be optionally set, but must be set
                // before user authenticates.
                AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile"]);
                
                // Facebook login behavior can be optionally set, but must be set
                // before user authenticates.
//                AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.Web.rawValue)
                
                // Facebook UI Setup
                facebookButton.addTarget(self, action: #selector(SignInViewController.handleFacebookLogin), for: .touchUpInside)
                let facebookButtonImage: UIImage? = UIImage(named: "FacebookButton")
                if let facebookButtonImage = facebookButtonImage{
                    facebookButton.setImage(facebookButtonImage, for: UIControlState())
                } else {
                     print("Facebook button image unavailable. We're hiding this button.")
                    facebookButton.isHidden = true
                }
                view.addConstraint(NSLayoutConstraint(item: facebookButton, attribute: .top, relatedBy: .equal, toItem: anchorViewForFacebook(), attribute: .bottom, multiplier: 1, constant: 8.0))

                // set up google button if needed
                setUpGoogleButton()
        
                customProviderButton.removeFromSuperview()
                customCreateAccountButton.removeFromSuperview()
                customForgotPasswordButton.removeFromSuperview()
                customUserIdField.removeFromSuperview()
                customPasswordField.removeFromSuperview()
                leftHorizontalBar.removeFromSuperview()
                rightHorizontalBar.removeFromSuperview()
                orSignInWithLabel.removeFromSuperview()
                customProviderButton.setImage(UIImage(named: "LoginButton"), for: UIControlState())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(didSignInObserver)
    }
    
    func dimissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setUpGoogleButton(){
        // Google login scopes can be optionally set, but must be set
        // before user authenticates.
        AWSGoogleSignInProvider.sharedInstance().setScopes(["profile", "openid"])
        
        // Sets up the view controller that the Google signin will be launched from.
        AWSGoogleSignInProvider.sharedInstance().setViewControllerForGoogleSignIn(self)
        
        // Google UI Setup
        googleButton.addTarget(self, action: #selector(SignInViewController.handleGoogleLogin), for: .touchUpInside)
        let googleButtonImage: UIImage? = UIImage(named: "GoogleButton")
        if let googleButtonImage = googleButtonImage {
            googleButton.setImage(googleButtonImage, for: UIControlState())
        } else {
            print("Google button image unavailable. We're hiding this button.")
            googleButton.isHidden = true
        }
        view.addConstraint(NSLayoutConstraint(item: googleButton, attribute: .top, relatedBy: .equal, toItem: anchorViewForGoogle(), attribute: .bottom, multiplier: 1, constant: 8.0))
    }
    
    // MARK: - Utility Methods
    
    func handleLoginWithSignInProvider(_ signInProvider: AWSSignInProvider) {
        AWSSignInManager.sharedInstance().login(signInProviderKey: signInProvider.identityProviderName, completionHandler: {(result: Any?, authState: AWSIdentityManagerAuthState, error: Error?) in
            print("result = \(result), error = \(error)")
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true, completion: nil)
                    // handle logic here after logged in
                    
                })
                return
            }
            self.showErrorDialog(signInProvider.identityProviderName, withError: error as! NSError)
        })
    }

    func showErrorDialog(_ loginProviderName: String, withError error: NSError) {
         print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label to cancel sign-in failure."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - IBActions
    func handleFacebookLogin() {
        handleLoginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance())
    }
    
    
    func handleGoogleLogin() {
        handleLoginWithSignInProvider(AWSGoogleSignInProvider.sharedInstance())
    }

    func anchorViewForFacebook() -> UIView {
        return anchorView
    }
    
    func anchorViewForGoogle() -> UIView {
            return facebookButton
        
    }
}
