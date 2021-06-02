//
//  UnsplashImage.swift
//  UnsplashDemo
//
//  Created by Павел Духовенко on 27.02.2021.
//

import UIKit

final class UnsplashImage {
    
    // MARK: - Types
    
    enum Resolution {
        case byDefault
        case full
    }
    
    // MARK: - Public properties
    
    var visualRepresentation: UIImage? = nil
    var highResVisualRepresentation: UIImage? = nil
    var description: String = "none"
    var width: Int = 0
    var height: Int = 0
    var defaultSizeURL: URL = URL(string: "empty")!
    var fullSizeURL: URL = URL(string: "empty")!
    
    // MARK: - Public methods
    
    func loadVisuals (resolution: Resolution, session: URLSession?, completionHandler: @escaping (_ success: Bool) -> Void) {
        guard let urlSession = session else { return }
        let urlToLoad: URL = resolution == .byDefault ? defaultSizeURL : fullSizeURL
        urlSession.dataTask(with: urlToLoad) { [weak self] data, _, error in
            if let _ = error { return }
            guard let data = data, let imageVisualRepresentation = UIImage(data: data) else { return }
            switch resolution {
            case .byDefault:
                self?.visualRepresentation = imageVisualRepresentation
                if self?.highResVisualRepresentation == nil {
                    self?.highResVisualRepresentation = imageVisualRepresentation
                }
            case .full: self?.highResVisualRepresentation = imageVisualRepresentation
            }
            completionHandler(true)
        }.resume()
    }
}
