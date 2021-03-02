//
//  CollectionListScreenController.swift
//  RMR_test
//
//  Created by Павел Духовенко on 26.02.2021.
//

import UIKit

class CollectionListController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Properties
    private var network = NetworkAccess(mode: .collections)
    private var searchResults: [UnsplashCollection] = []
    private var updatingNow = false {
        didSet {
            if updatingNow {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    private var pagesLoaded = 0

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        network.delegate = self
        activityIndicator.stopAnimating()
    }
    
    // MARK: - @IBActions
    @IBAction func refreshData() {
        searchResults.removeAll()
        pagesLoaded = 0
        collectionView.reloadData()
        network.fetchData(term: nil, page: pagesLoaded+1)
        updatingNow = true
    }
    // MARK: - Utility
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is CollectionItemsController {
            guard let vc = segue.destination as? CollectionItemsController else {
                print("failed to open CollectionItemsController")
                return
            }
            vc.collectionID = searchResults[collectionView.indexPath(for: (sender as! collectionListCell))!.row].id
            vc.title = searchResults[collectionView.indexPath(for: (sender as! collectionListCell))!.row].name
            vc.backupSearchTerm = searchResults[collectionView.indexPath(for: (sender as! collectionListCell))!.row].name
        }
    }
}
// MARK: - CollectionView DataSource
extension CollectionListController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionListCell", for: indexPath) as! collectionListCell
        cell.imageView.image = searchResults[indexPath.row].coverImage.visualRepresentation
        cell.titleLabel.text = searchResults[indexPath.row].name
        cell.elementsCountLabel.text = "\(searchResults[indexPath.row].totalPhotos) photos"
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
}
// MARK: - CollectionView Delegate
extension CollectionListController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
// MARK: - ScrollView Delegate
extension CollectionListController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.bounds.size.height)) {
            if !updatingNow {
                updatingNow = true
                network.fetchData(term: nil, page: pagesLoaded+1)
            }
        }
    }
}
//MARK: - FlowLayout Delegate
extension CollectionListController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let height = collectionView.frame.size.height
        let width = collectionView.frame.size.width
        return CGSize(width: width, height: height/3 + 16)
    }
}

// MARK: - NetworkAccess Delegate
extension CollectionListController: NetworkAccessDelegate {
    func reloadData(imageSearchResults: [UnsplashImage]?, collectionSearchResults: [UnsplashCollection]?) {
        guard let _ = imageSearchResults, let collectionResults = collectionSearchResults, let view = collectionView else { return }
        if collectionResults.count>0{
            searchResults.append(contentsOf: collectionResults)
            pagesLoaded+=1
            view.reloadData()
        }
        updatingNow = false
    }
}
