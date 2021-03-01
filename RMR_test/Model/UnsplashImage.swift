//
//  UnsplashImage.swift
//  RMR_test
//
//  Created by Павел Духовенко on 27.02.2021.
//

import UIKit

class UnsplashImage {
    var visualRepresentation: UIImage? = nil
    var highResVisualRepresentation: UIImage? = nil
    var description: String = "none"
    var width: Int = 0
    var height: Int = 0
    var defaultSizeURL: URL = URL(string: "empty")!
    var fullSizeURL: URL = URL(string: "empty")!

    func loadVisuals (resolution: Resolution, session: URLSession?, completionHandler: @escaping (_ success:Bool) -> Void) {
        guard let urlSession = session else {
            return
        }
        let urlToLoad: URL
        
        switch resolution {
        case .byDefault:
            urlToLoad = defaultSizeURL
        case .full:
            urlToLoad = fullSizeURL
        }
        
        let dataTask = urlSession.dataTask(with: urlToLoad) { [weak self] (data, _, error) in
            guard let selfPresent = self else { return }
            if let _ = error { return }
            guard let data = data, let imageVisualRepresentation = UIImage(data: data) else { return }
            switch resolution {
            case .byDefault:
                selfPresent.visualRepresentation = imageVisualRepresentation
                if selfPresent.highResVisualRepresentation == nil {
                    selfPresent.highResVisualRepresentation = imageVisualRepresentation
                }
            case .full: selfPresent.highResVisualRepresentation = imageVisualRepresentation
            }
            completionHandler(true)
        }
        dataTask.resume()
    }
    
    enum Resolution {
        case byDefault
        case full
    }
}
