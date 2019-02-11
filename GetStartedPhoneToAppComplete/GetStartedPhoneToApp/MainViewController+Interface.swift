//
//  MainViewController+Interface.swift
//  GetStartedPhoneToApp
//
//  Created by Paul Ardeleanu on 11/02/2019.
//  Copyright © 2019 Nexmo. All rights reserved.
//

import Foundation
import NexmoClient


enum InterfaceState {
    case notAuthenticated
    case connecting
    case disconnected
    case loggedIn
    case callError
    case inCall
    case callRejected
    case callEnded
}


extension MainViewController {
    
    var interfaceState: InterfaceState {
        // not authenticated if no client present
        guard let client = client else {
            return .notAuthenticated
        }
        // Disconnected or currently Connecting
        switch client.connectionStatus {
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .connected: break
        }
        
        guard let call = call else {
            switch callStatus {
            case .unknown:
                return .loggedIn
            case .inProgress:
                return .loggedIn
            case .error:
                return .callError
            case .rejected:
                return .callRejected
            case .completed:
                return .callEnded
            }
        }
        switch call.status  {
        case .disconnected:
            return .callEnded
        case .connected:
            return .inCall
        }
    }
    
    
    func updateInterface() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            self.statusLabel.text = "Ready."
            self.endCallButton.alpha = 0
            
            switch self.interfaceState {
                
            case .notAuthenticated:
                self.call = nil
                self.statusLabel.text = "Not Authenticated."
                
            case .connecting:
                self.activityIndicator.startAnimating()
                self.statusLabel.text = "Connecting..."
                
            case .disconnected:
                self.statusLabel.text = "Disconnected"
                
            case .loggedIn:
                self.statusLabel.text = "Logged in as \(Constant.userName)"
                
            case .inCall:
                self.statusLabel.text = "Speaking..."
                self.endCallButton.alpha = 1
                self.endCallButton.setTitle("End call", for: .normal)
                
            case .callError:
                self.statusLabel.text = "Call error"
                self.endCallButton.alpha = 1
                
            case .callRejected:
                self.statusLabel.text = "Call rejected "
                
            case .callEnded:
                self.statusLabel.text = "Call ended."
            
            }
        }
    }
    
}
