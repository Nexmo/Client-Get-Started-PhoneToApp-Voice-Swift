//
//  MainViewController.swift
//  GetStartedPhoneToApp
//
//  Created by Paul Ardeleanu on 11/02/2019.
//  Copyright © 2019 Nexmo. All rights reserved.
//

import UIKit
import NexmoClient


enum CallStatus {
    case unknown
    case inProgress
    case error
    case rejected
    case completed
}


class MainViewController: UIViewController {
    var client: NXMClient?
    var call: NXMCall?
    var callStatus: CallStatus = .unknown
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var endCallButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateInterface()
        setupNexmoClient()
    }
    
    //MARK: - Setup Nexmo Client
    func setupNexmoClient() {
        client = NXMClient(token: Constant.userToken)
        client?.setDelegate(self)
        client?.login()
    }

    @IBAction func endCall(_ sender: Any) {
        guard let call = call else {
            updateInterface()
            return
        }
        call.myCallMember.hangup()
    }
    
}


extension MainViewController: NXMClientDelegate {
    
    func connectionStatusChanged(_ status: NXMConnectionStatus, reason: NXMConnectionStatusReason) {
        print("👁👁👁 connectionStatusChanged - status: \(status.description()) - reason: \(reason.description())")
        updateInterface()
    }
    
    func incomingCall(_ call: NXMCall) {
        print("📲 📲 📲 Incoming Call: \(call)")
        DispatchQueue.main.async { [weak self] in
            self?.displayIncomingCallAlert(call: call)
        }
    }
    
    func displayIncomingCallAlert(call: NXMCall) {
        var from = "Unknown"
        if let otherParty = call.otherCallMembers.firstObject as? NXMCallMember {
            print("Type: \(String(describing: otherParty.channel?.from.type))")
            print("Number: \(String(describing: otherParty.channel?.from.data))")
            from = otherParty.channel?.from.data ?? "Unknown"
        }
        let alert = UIAlertController(title: "Incoming call from", message: from, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Answer", style: .default, handler: { _ in
            self.answer(call: call)
        }))
        alert.addAction(UIAlertAction(title: "Reject", style: .default, handler: { _ in
            self.reject(call: call)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Incoming call - Accept
    private func answer(call: NXMCall) {
        self.call = call
        self.call?.setDelegate(self)
        call.answer(self) { [weak self] error in
            if let error = error {
                print("error answering call: \(error.localizedDescription)")
            }
            self?.updateInterface()
        }
    }
    
    //MARK: Incoming call - Reject
    private func reject(call: NXMCall) {
        call.reject { [weak self] error in
            if let error = error {
                print("error declining call: \(error.localizedDescription)")
            }
            self?.updateInterface()
        }
    }
    
}



//MARK:- Call Delegate

extension MainViewController: NXMCallDelegate {
    
    func statusChanged(_ member: NXMCallMember) {
        print("🤙🤙🤙 Call Status changed | member: \(String(describing: member.user.name))")
        print("🤙🤙🤙 Call Status changed | member status: \(String(describing: member.status.description()))")
        
        guard let call = call else {
            // this should never happen
            self.callStatus = .unknown
            self.updateInterface()
            return
        }
        
        // call ended before it could be answered
        if member == call.myCallMember, member.status == .answered, let otherMember = call.otherCallMembers.firstObject as? NXMCallMember, [NXMCallMemberStatus.completed, NXMCallMemberStatus.cancelled].contains(otherMember.status)  {
            self.callStatus = .completed
            self.call?.myCallMember.hangup()
            self.call = nil
        }
        
        // call rejected
        if call.otherCallMembers.contains(member), member.status == .cancelled {
            self.callStatus = .rejected
            self.call?.myCallMember.hangup()
            self.call = nil
        }
        
        // call ended
        if member.status == .completed {
            self.callStatus = .completed
            self.call?.myCallMember.hangup()
            self.call = nil
        }
        
        updateInterface()
    }
    
}

