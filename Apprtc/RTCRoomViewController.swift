//
//  ViewController.swift
//  Apprtc
//
//  Created by Mahabali on 9/5/15.
//  Copyright (c) 2015 Mahabali. All rights reserved.
//

import UIKit

class RTCRoomViewController: UITableViewController,RTCRoomTextInputViewCellDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell:UITableViewCell
    if (indexPath.row == 0){
    var cell:RTCRoomTextInputViewCell
    cell=tableView.dequeueReusableCell(withIdentifier: "RoomInputCell", for: indexPath) as! RTCRoomTextInputViewCell
    cell.delegate=self
    return cell
    }
    else {
      cell = tableView.dequeueReusableCell(withIdentifier: "MahabaliCell")!
    }
      return cell
  }
  
  func shouldJoinRoom(_ room: NSString, textInputCell: RTCRoomTextInputViewCell) {
    self.performSegue(withIdentifier: "RTCVideoChatViewController", sender: room)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    print(" to string \(type(of: segue.destination))")
    let viewController:RTCVideoChatViewController=segue.destination as! RTCVideoChatViewController
    viewController.roomName=sender as! String as NSString?
  }
  
  override var  shouldAutorotate : Bool {
    return false
  }
  
  override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.portrait
  }
}

