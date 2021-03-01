//
//  NetworkAccess.swift
//  RMR_test
//
//  Created by Павел Духовенко on 26.02.2021.
//

import Foundation
import os
import UIKit


class NetworkAccess {
    // MARK: - Required Properties
    private let accessKey: String = "fX71BFbg805A-lu8jfsTN-w7EuOWzXrrfS2wnfBfZzo"
    private let  selectedLoadMode: LoadMode
    private let loadCompletedNotification: Notification.Name
    private let loadFullResCompletedNotification: Notification.Name
    private var apiRequestBones: String
    
    // MARK: - Containers for results
    lazy var imageSearchResults: [UnsplashImage] = []
    lazy var collectionSearchResults: [UnsplashCollection] = []
    
    // MARK: - Load Properties
    private let primarySession: URLSession = URLSession(configuration: .default)
    private let secondarySession: URLSession = URLSession(configuration: .default)
    private lazy var totalPagesNumber = 1 {
        didSet {
            if totalPagesNumber==0 {
                totalPagesNumber = 1
            }
        }
    }
    private lazy var totalImagesFound = 0
    private lazy var downloaded = 0
    private lazy var estimatedDownload = 0
    var collectionID: Int = 0
    
    // MARK: - Initialization
    enum LoadMode {
        case random
        case byTerm
        case collections
        case byCollection
    }
    
    init(mode: LoadMode) {
        selectedLoadMode = mode
        switch mode {
        case .random:
            loadCompletedNotification = Notification.Name("randomImageDownloaded")
            loadFullResCompletedNotification = Notification.Name("randomImageHighResDownloaded")
            apiRequestBones = "https://api.unsplash.com/photos/random"
            
        case .byTerm:
            loadCompletedNotification = Notification.Name("searchImagesDownloaded")
            loadFullResCompletedNotification = Notification.Name("searchImageHighResDownloaded")
            apiRequestBones = "https://api.unsplash.com/search/photos"
            
        case .collections:
            loadCompletedNotification = Notification.Name("collectionListImagesDownloaded")
            loadFullResCompletedNotification = Notification.Name("listCoverHighResDownloaded")
            apiRequestBones = "https://api.unsplash.com/collections"
            
        case .byCollection:
            loadCompletedNotification = Notification.Name("collectionImagesDownloaded")
            loadFullResCompletedNotification = Notification.Name("collectionImageHighResDownloaded")
            apiRequestBones = "https://api.unsplash.com/collections/\(collectionID)/photos"
        }
    }
    
    //MARK: - Load Methods
    public func fetchData(term: String?, page: Int?) {
        if let pg = page, pg > totalPagesNumber { return }
        imageSearchResults.removeAll()
        collectionSearchResults.removeAll()
        downloaded = 0
        guard let urlRequest = imageURLRequestWithAuthentication(for: apiRequestBones, page: page, term: term) else {           return }
        loadDataByMode(mode: selectedLoadMode, with: urlRequest)
    }
    
    private func loadDataByMode(mode: LoadMode, with urlRequest: URLRequest) {
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, _, error) in
            guard let selfPresent = self else { return }
            if let error = error { return os_log("%@", log: .default, type: .error, error.localizedDescription) }
            guard let dataChecked = data else { return }
            switch mode {
            case .random:
                guard let imageData = selfPresent.decodeRandomImage(from: dataChecked, defaultSize: "thumb") else { return }
                selfPresent.imageSearchResults.append(imageData)
                selfPresent.estimatedDownload = 1
                selfPresent.loadImageVisuals(for: imageData)
            case .byTerm:
                guard let imagesData = selfPresent.decodeSearchImages(from: dataChecked, defaultSize: "thumb") else { return }
                selfPresent.imageSearchResults = imagesData
                selfPresent.estimatedDownload = imagesData.count
                for image in selfPresent.imageSearchResults {
                    selfPresent.loadImageVisuals(for: image)
                }
            case .collections:
                guard let collectionsData = selfPresent.decodeCollectionList(from: dataChecked, defaultSize: "regular") else { return }
                selfPresent.collectionSearchResults = collectionsData
                selfPresent.estimatedDownload = collectionsData.count
                for collection in selfPresent.collectionSearchResults {
                    selfPresent.imageSearchResults.append(collection.coverImage)
                    selfPresent.loadImageVisuals(for: collection.coverImage)
                }
            case .byCollection:
                guard let imagesData = selfPresent.decodeCollectionImages(from: dataChecked, defaultSize: "thumb") else { return }
                selfPresent.imageSearchResults = imagesData
                selfPresent.estimatedDownload = imagesData.count
                for image in selfPresent.imageSearchResults {
                    selfPresent.loadImageVisuals(for: image)
                }
            }
        }
        dataTask.resume()
    }
    
    //loads image
    private func loadImageVisuals(for image: UnsplashImage) {
        image.loadVisuals(resolution: .byDefault, session: primarySession) { [weak self] success in
            guard let selfPresent = self else { return }
            selfPresent.downloaded+=1
            if selfPresent.downloaded==selfPresent.estimatedDownload {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: selfPresent.loadCompletedNotification, object: nil)
                }
            }
            DispatchQueue.global(qos: .userInitiated).async {
                image.loadVisuals(resolution: .full, session: selfPresent.secondarySession) { [weak self] success in
                    guard let selfStillPresent = self else { return }
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: selfStillPresent.loadFullResCompletedNotification, object: nil)
                    }
                }
            }
        }
    }
    //MARK: - Utility
    //constructs url with query parameters
    private func imageURLRequestWithAuthentication(for source: String, page: Int?, term: String?) -> URLRequest? {
        guard var components = URLComponents(string: source) else { return nil }
        
        components.queryItems = []
        
        if let pageToLoad = page {
            components.queryItems?.append(URLQueryItem(name: "page", value: "\(pageToLoad)"))
        }
        if let searchTerm = term {
            components.queryItems?.append(URLQueryItem(name: "query", value: searchTerm))
        }
        
        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.addValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        print(request)
        return request
    }
    
    //MARK: - JSON Decoders
    private func decodeCollectionList(from data: Data, defaultSize: String) -> [UnsplashCollection]? {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                var output: [UnsplashCollection] = []
                for result in jsonObject {
                    let collection = UnsplashCollection()
                    collection.coverImage = UnsplashImage()
                    collection.id = result["id"] as? Int ?? 0
                    collection.totalPhotos = result["total_photos"] as? Int ?? 0
                    collection.name = result["title"] as? String ?? ""
                    if  let coverPhoto = result["cover_photo"] as? [String: Any],
                        let urls = coverPhoto["urls"] as? [String: Any],
                        let defaultURLString = urls[defaultSize] as? String,
                        let defaultSizeURL = URL(string: defaultURLString) {
                        totalPagesNumber = jsonObject.count
                        collection.coverImage.defaultSizeURL = defaultSizeURL
                        let fullURLString = urls["full"] as? String
                        collection.coverImage.fullSizeURL = URL(string: fullURLString ?? "empty")!
                        collection.coverImage.description = coverPhoto["description"] as? String ?? ""
                        collection.coverImage.width = coverPhoto["width"] as? Int ?? 0
                        collection.coverImage.height = coverPhoto["height"] as? Int ?? 0
                    }
                    output.append(collection)
                }
                return output
            }
        } catch {
            os_log("%@", log: .default, type: .error, error.localizedDescription)
        }
        return nil
    }
    
    private func decodeCollectionImages(from data: Data, defaultSize: String) -> [UnsplashImage]? {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                var output: [UnsplashImage] = []
                for result in jsonObject {
                    if  let urls = result["urls"] as? [String: Any],
                        let defaultURLString = urls[defaultSize] as? String,
                        let defaultSizeURL = URL(string: defaultURLString) {
                        totalPagesNumber = jsonObject.count
                        let image = UnsplashImage()
                        image.defaultSizeURL = defaultSizeURL
                        let fullURLString = urls["full"] as? String
                        image.fullSizeURL = URL(string: fullURLString ?? "empty")!
                        image.description = result["description"] as? String ?? ""
                        image.width = result["width"] as? Int ?? 0
                        image.height = result["height"] as? Int ?? 0
                        output.append(image)
                    }
                }
                return output
            }
        } catch {
            os_log("%@", log: .default, type: .error, error.localizedDescription)
        }
        return nil
    }
    
    private func decodeSearchImages(from data: Data, defaultSize: String) -> [UnsplashImage]? {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let results = jsonObject["results"] as? [[String: Any]] {
                totalPagesNumber = jsonObject["total_pages"] as? Int ?? 0
                totalImagesFound = jsonObject["total"] as? Int ?? 0
                var output: [UnsplashImage] = []
                for result in results {
                    if  let urls = result["urls"] as? [String: Any],
                        let defaultURLString = urls[defaultSize] as? String,
                        let defaultSizeURL = URL(string: defaultURLString) {
                        let image = UnsplashImage()
                        image.defaultSizeURL = defaultSizeURL
                        let fullURLString = urls["full"] as? String
                        image.fullSizeURL = URL(string: fullURLString ?? "empty")!
                        image.description = result["description"] as? String ?? ""
                        image.width = result["width"] as? Int ?? 0
                        image.height = result["height"] as? Int ?? 0
                        output.append(image)
                    }
                }
                return output
            }
        } catch {
            os_log("%@", log: .default, type: .error, error.localizedDescription)
        }
        return nil
    }
    
    private func decodeRandomImage(from data: Data, defaultSize: String) -> UnsplashImage? {
        do {
            if
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let urls = jsonObject["urls"] as? [String: Any],
                let defaultURLString = urls[defaultSize] as? String,
                let defaultSizeURL = URL(string: defaultURLString) {
                totalPagesNumber = 1
                let image = UnsplashImage()
                image.defaultSizeURL = defaultSizeURL
                let fullURLString = urls["full"] as? String
                image.fullSizeURL = URL(string: fullURLString ?? "empty")!
                image.description = jsonObject["description"] as? String ?? ""
                image.width = jsonObject["width"] as? Int ?? 0
                image.height = jsonObject["height"] as? Int ?? 0
                return image
            }
        } catch {
            os_log("%@", log: .default, type: .error, error.localizedDescription)
        }
        return nil
    }
}


