//
// Created by maks on 16.11.17.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol QRCaptureDelegate: class {
    func qrCaptureDidDetect(object: AVMetadataMachineReadableCodeObject)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var square: UIImageView!
    var video = AVCaptureVideoPreviewLayer()
    var delegate: QRCaptureDelegate?

    let infoButton = UIBarButtonItem(image: UIImage(named: "info_circle"), style: .plain, target: self, action: #selector(onInfoClick))
    let leftButton = UIBarButtonItem(image: UIImage(named: "nav_bar_item_arrow_left"), style: .plain, target: self, action: #selector(onNavBarItemLeftClicked))

    func onNavBarItemLeftClicked() {
        dismiss(animated: true)
    }


    func onInfoClick() {
        let infoAlertController = UIAlertController(title: "QR-Code scan".localized, message:
        "If you want to scan the QR-code, direct the scan area to the image of the QR-code".localized,
                preferredStyle: UIAlertControllerStyle.alert)

        infoAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
            infoAlertController.dismiss(animated: true, completion: nil)
        }))

        self.present(infoAlertController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = infoButton
        navigationItem.leftBarButtonItem = leftButton
        navigationBar.setItems([navigationItem], animated: true)


        let session = AVCaptureSession()

//         let captureDevice = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDevice.DeviceType.builtInDualCamera, mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.back)
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            session.addInput(input)
        } catch {
            print("ERROR")
        }

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

        video = AVCaptureVideoPreviewLayer(session: session)

        video.videoGravity = AVLayerVideoGravityResizeAspectFill

        video.frame = view.layer.bounds

        view.layer.addSublayer(video)

        view.bringSubview(toFront: square)
        view.bringSubview(toFront: navigationBarView)

        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if metadataObjects != nil && metadataObjects.count != 0 {
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                if object.type == AVMetadataObjectTypeQRCode {
                    let scan = object.stringValue
                    print("Scan: \(scan!)")

                    if scan!.starts(with: Config.BITCOIN_WALLET) {
                        Config.QR_CODE_VALUE = String(scan!.dropFirst(8))
                        self.dismiss(animated: true)
                    } else if scan!.starts(with: Config.BITCOIN_WALLET_2) {
                        Config.QR_CODE_VALUE = String(scan!.dropFirst(9))
                        self.dismiss(animated: true)
                    } else if scan!.starts(with: Config.BITCOIN_WALLET_3) || scan!.starts(with: Config.BITCOIN_WALLET_4) || scan!.starts(with: Config.BITCOIN_WALLET_5){
                        Config.QR_CODE_VALUE = scan!
                        self.dismiss(animated: true)
                    } else if scan!.starts(with: Config.ETHEREUM_WALLET) {
                        Config.QR_CODE_VALUE = String(scan!.dropFirst(9))
                        delegate?.qrCaptureDidDetect(object: object)
                        self.dismiss(animated: true)
                    } else if scan!.starts(with: Config.ETHEREUM_WALLET_2) {
                        Config.QR_CODE_VALUE = String(scan!.dropFirst(1))
                        delegate?.qrCaptureDidDetect(object: object)
                        self.dismiss(animated: true)
                    } else if scan!.starts(with: Config.ETHEREUM_WALLET_3) {
                        Config.QR_CODE_VALUE = scan!
                        delegate?.qrCaptureDidDetect(object: object)
                        self.dismiss(animated: true)
                    } else if scan!.starts(with: Config.WEB_CONTENT) || scan!.starts(with: Config.WEB_CONTENT_2){
                        let alert = UIAlertController(title: "Open in browser?".localized, message: scan!, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .default, handler: { (action) in

                        }))
                        alert.addAction(UIAlertAction(title: "Open".localized, style: .default, handler: { (nil) in
                            UIApplication.shared.open(URL(string: object.stringValue)! as URL, options: [:], completionHandler: nil)                        }))

                        present(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: "Paymon does not know what is written in this QR-code".localized, message: scan!, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in

                        }))

                        present(alert, animated: true, completion: nil)

                    }

                    print("QR_CODE VALUE: \(Config.QR_CODE_VALUE)")

                }
            }
        }
    }
}
