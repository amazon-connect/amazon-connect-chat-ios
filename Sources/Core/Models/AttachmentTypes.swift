// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


import Foundation

public enum AttachmentTypes: String {
    case csv = "text/csv"
    case doc = "application/msword"
    case docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    case heic = "image/heic"
    case jpg =  "image/jpeg"
    case mov = "video/quicktime"
    case mp4 = "video/mp4"
    case pdf = "application/pdf"
    case png = "image/png"
    case ppt = "application/vnd.ms-powerpoint"
    case pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    case rtf = "application/rtf"
    case txt = "text/plain"
    case wav = "audio/wav"
    case xls = "application/vnd.ms-excel"
    case xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
}
