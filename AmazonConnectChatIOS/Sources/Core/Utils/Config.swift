// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*
 Find InstanceId: https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html
 Find ContactFlowId: https://docs.aws.amazon.com/connect/latest/adminguide/find-contact-flow-id.html
 */

import Foundation
import AWSCore

// Temporary using this file untill we figure out how to separate sender and reciever based on thier name or role.

class Config {
    
    let startChatEndPoint: String = "https://3r4nj9r68b.execute-api.us-east-1.amazonaws.com/Prod/"
    let instanceId: String = "6ceda8ca-5e6e-4a60-9bfb-4994cc1fec79"
    let contactFlowId: String = "c8d90d07-a28c-4a97-9dfb-f4785b98d8d2"
    let region: AWSRegionType = .USEast1 // .USWest1 :https://docs.aws.amazon.com/general/latest/gr/rande.html
    let agentName = "A"
    let customerName = "C"
    
}
