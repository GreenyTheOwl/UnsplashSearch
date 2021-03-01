//
//  CollectionListScreenController.swift
//  RMR_test
//
//  Created by Павел Духовенко on 26.02.2021.
//

import UIKit

class CollectionListScreenController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var network = NetworkAccess(mode: .collections)
    private var searchResults: [UnsplashCollection] = []
    
    private var pagesLoaded = 0
    private var updatingNow = false {
        didSet {
            if updatingNow {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.stopAnimating()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name("collectionListImagesDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWithHighResData), name: Notification.Name("listCoverHighResDownloaded"), object: nil)
    }
    
    @objc private func reloadData() {
        guard let view = collectionView else {return}
        searchResults.append(contentsOf: network.collectionSearchResults)
        view.reloadData()
        pagesLoaded+=1
        updatingNow = false
    }
    
    @objc private func reloadWithHighResData() {
        guard let view = collectionView else {return}
        view.reloadData()
    }
    
    @IBAction func refreshData() {
        searchResults.removeAll()
        pagesLoaded = 0
        collectionView.reloadData()
        network.fetchData(term: nil, page: pagesLoaded+1)
        updatingNow = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is CollectionItemsController {
            guard let vc = segue.destination as? CollectionItemsController else {
                print("failed to open CollectionItemsController")
                return
            }
            vc.collectionID = searchResults[collectionView.indexPath(for: (sender as! collectionListCell))!.row].id
            vc.title = searchResults[collectionView.indexPath(for: (sender as! collectionListCell))!.row].name
        }
    }
}
// MARK: - CollectionView DataSource
extension CollectionListScreenController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionListCell", for: indexPath) as! collectionListCell
        cell.imageView.image = searchResults[indexPath.row].coverImage.visualRepresentation
        cell.titleLabel.text = searchResults[indexPath.row].name
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
}
// MARK: - CollectionView Delegate
extension CollectionListScreenController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
// MARK: - ScrollView Delegate
extension CollectionListScreenController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.bounds.size.height)) {
            if !updatingNow {
                updatingNow = true
                network.fetchData(term: nil, page: pagesLoaded+1)
            }
        }
    }
}
