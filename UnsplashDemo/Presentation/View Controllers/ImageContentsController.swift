//
//  ImageView.swift
//  UnsplashDemo
//
//  Created by Павел Духовенко on 27.02.2021.
//

import UIKit

final class ImageContentsController: UIViewController {
    
    // MARK: - Public properties
    
    var image = UnsplashImage()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionLeftLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var fullSizeURLLabel: UILabel!
    @IBOutlet weak var copyURLButton: UIButton!
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        imageView.image = image.highResVisualRepresentation
        descriptionLabel.text = image.description
        if image.description.isEmpty {
            descriptionLeftLabel.isHidden = true
        }
        widthLabel.text = "\(image.width)"
        heightLabel.text = "\(image.height)"
        fullSizeURLLabel.text = image.fullSizeURL.absoluteString
    }
    
    // MARK: - IBActions
    
    @IBAction func copyURL(_ sender: Any) {
        UIPasteboard.general.string = fullSizeURLLabel.text
        copyURLButton.setTitle("Copied!", for: .normal)
    }
}
