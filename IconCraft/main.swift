//
//  main.swift
//  IconCraft
//
//  Created by Andriyanto Halim on 26/8/24.
//

import Foundation
import AppKit

enum DeviceType: String, CaseIterable {
    case iPhone, iPad, macOS, watchOS, tvOS, carOS
    
    var sizes: [Int] {
        switch self {
        case .iPhone:
            return [20, 40, 60, 29, 58, 87, 80, 120, 180, 76, 152, 167]
        case .iPad:
            return [20, 40, 29, 58, 40, 80, 76, 152, 167, 83]
        case .macOS:
            return [16, 32, 64, 128, 256, 512, 1024]
        case .watchOS:
            return [48, 55, 58, 87, 80, 88, 172, 196, 216, 1024]
        case .tvOS:
            return [400, 800, 1200, 2400]
        case .carOS:
            return [200, 400, 800, 1600]
        }
    }
}

func printHelp() {
    let helpMessage = """
    iconcraft: A CLI tool to generate app icons for various Apple platforms.
    
    Usage:
      iconcraft <reference icon filename> -d <device type>
    
    Options:
      -d    Specify the device type (iPhone, iPad, macOS, watchOS, tvOS, carOS).
            Use '-d' alone to list supported devices and their resolutions.
            Use '-d <device type>' to list the resolutions for a specific device.
      -h    Show help information.
    
    Examples:
      iconcraft icon.png -d iPhone
      iconcraft icon.png -d macOS
      iconcraft -d
      iconcraft -d iPhone
    
    Notes:
    - The reference icon file must be at least 1024x1024 pixels and must be square.
    """
    print(helpMessage)
}

func listSupportedDevices() {
    print("Supported devices and their icon resolutions:")
    for device in DeviceType.allCases {
        print("\n\(device.rawValue):")
        for size in device.sizes {
            print("  - \(size)x\(size) pixels")
        }
    }
}

func listDeviceResolutions(for deviceType: DeviceType) {
    print("\(deviceType.rawValue) supports the following icon resolutions:")
    for size in deviceType.sizes {
        print("  - \(size)x\(size) pixels")
    }
}

func generateIcons(referenceIconPath: String, for deviceType: DeviceType) {
    guard let image = NSImage(contentsOfFile: referenceIconPath) else {
        print("Error: Unable to load the reference icon file.")
        return
    }

    guard let tiffData = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData) else {
        print("Error: Unable to process the reference icon file.")
        return
    }

    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh

    guard width >= 1024, height >= 1024 else {
        print("Error: The reference icon file must be at least 1024x1024 pixels.")
        return
    }

    guard width == height else {
        print("Error: The reference icon file must be square (width and height must be equal).")
        return
    }

    let sizes = deviceType.sizes

    let directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(deviceType.rawValue, isDirectory: true)

    do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Error: Unable to create output directory.")
        return
    }

    for size in sizes {
        let newSize = NSSize(width: size, height: size)
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        bitmap.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()

        if let imageData = resizedImage.tiffRepresentation,
           let imageRep = NSBitmapImageRep(data: imageData),
           let pngData = imageRep.representation(using: .png, properties: [:]) {
            let outputFileName = "Icon-\(deviceType.rawValue)-\(size)x\(size).png"
            let outputURL = directoryURL.appendingPathComponent(outputFileName)
            do {
                try pngData.write(to: outputURL)
                print("Generated \(outputURL.path)")
            } catch {
                print("Error: Unable to save resized icon at \(outputURL.path)")
            }
        }
    }
}

let arguments = CommandLine.arguments

if arguments.count == 2 && arguments[1] == "-d" {
    listSupportedDevices()
    exit(0)
}

if arguments.count == 3 && arguments[1] == "-d" {
    if let deviceType = DeviceType(rawValue: arguments[2]) {
        listDeviceResolutions(for: deviceType)
    } else {
        print("Error: Invalid device type specified.")
        printHelp()
    }
    exit(0)
}

guard arguments.count == 4 else {
    if arguments.count == 2 && arguments[1] == "-h" {
        printHelp()
    } else {
        print("Error: Invalid arguments.")
        printHelp()
    }
    exit(1)
}

let referenceIconPath = arguments[1]
let deviceOption = arguments[2]
let deviceTypeArgument = arguments[3]

guard deviceOption == "-d", let deviceType = DeviceType(rawValue: deviceTypeArgument) else {
    print("Error: Invalid device type specified.")
    printHelp()
    exit(1)
}

generateIcons(referenceIconPath: referenceIconPath, for: deviceType)
