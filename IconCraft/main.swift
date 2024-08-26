//
//  main.swift
//  IconCraft
//
//  Created by Andriyanto Halim on 26/8/24.
//

import Foundation
import AppKit

enum DeviceType: String {
    case iPhone, iPad, macOS, watchOS, tvOS, carOS
}

func printHelp() {
    let helpMessage = """
    iconcraft: A CLI tool to generate app icons for various Apple platforms.
    
    Usage:
      iconcraft <reference icon filename> -d <device type>
    
    Options:
      -d    Specify the device type (iPhone, iPad, macOS, watchOS, tvOS, carOS).
      -h    Show help information.
    
    Examples:
      iconcraft icon.png -d iPhone
      iconcraft icon.png -d macOS
    
    Notes:
    - The reference icon file must be at least 1024x1024 pixels.
    """
    print(helpMessage)
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

    let sizes: [Int]
    
    switch deviceType {
    case .iPhone:
        sizes = [20, 40, 60, 29, 58, 87, 80, 120, 180, 76, 152, 167]
    case .iPad:
        sizes = [20, 40, 29, 58, 40, 80, 76, 152, 167, 83]
    case .macOS:
        sizes = [16, 32, 64, 128, 256, 512, 1024]
    case .watchOS:
        sizes = [48, 55, 58, 87, 80, 88, 172, 196, 216, 1024]
    case .tvOS:
        sizes = [400, 800, 1200, 2400]
    case .carOS:
        sizes = [200, 400, 800, 1600]
    }

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



