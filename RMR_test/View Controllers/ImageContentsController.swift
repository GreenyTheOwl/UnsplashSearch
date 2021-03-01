//
//  ImageView.swift
//  RMR_test
//
//  Created by Павел Духовенко on 27.02.2021.
//

import UIKit

class ImageContentsController: UIViewController {
    var image = UnsplashImage()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionLeftLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var fullSizeURLLabel: UILabel!
    @IBOutlet weak var copyURLButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        imageView.image = image.highResVisualRepresentation
        descriptionLabel.text = image.description
        if image.description=="" {
            descriptionLeftLabel.isHidden = true
        }
        widthLabel.text = "\(image.width)"
        heightLabel.text = "\(image.height)"
        fullSizeURLLabel.text = image.fullSizeURL.absoluteString
    }
    
    @IBAction func copyURL(_ sender: Any) {
        UIPasteboard.general.string = fullSizeURLLabel.text
        copyURLButton.setTitle("Copied!", for: .normal)
    }
    
}
