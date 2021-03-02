//
//  SearchScreenController.swift
//  RMR_test
//
//  Created by Павел Духовенко on 26.02.2021.
//

import UIKit

class SearchScreenController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Properties
    private var network = NetworkAccess(mode: .byTerm)
    private var searchResults: [UnsplashImage] = []
    private var updatingNow = false {
        didSet {
            if updatingNow {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    private var searchTerm = ""
    private var pagesLoaded = 0
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.stopAnimating()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name("searchImagesDownloaded"), object: nil)
    }
    
    // MARK: - Updaters
    @objc private func reloadData() {
        guard let view = collectionView else {return}
        if network.imageSearchResults.count>0 {
            searchResults.append(contentsOf: network.imageSearchResults)
            pagesLoaded+=1
            network.imageSearchResults.removeAll()
            view.reloadData()
        }
        updatingNow = false
    }
    
    @IBAction func refreshData() {
        searchResults.removeAll()
        pagesLoaded = 0
        collectionView.reloadData()
        network.fetchData(term: searchTerm, page: pagesLoaded+1)
        updatingNow = true
    }
    
    // MARK: - Utility
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ImageContentsController {
            guard let vc = segue.destination as? ImageContentsController else {
                print("failed to open ImageContentsController")
                return
            }
            vc.image = searchResults[collectionView.indexPath(for: (sender as! imageCell))!.row]
        }
    }
    
}
// MARK: CollectionView DataSource
extension SearchScreenController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchResultCell", for: indexPath) as! imageCell
        cell.imageView.image = searchResults[indexPath.row].visualRepresentation
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
}
// MARK: - CollectionView Delegate
extension SearchScreenController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
// MARK: - SearchBar Delegate
extension SearchScreenController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let term = searchBar.text else {
            return
        }
        searchResults.removeAll()
        searchTerm = term
        pagesLoaded = 0
        collectionView.reloadData()
        network.fetchData(term: searchTerm, page: pagesLoaded+1)
        updatingNow = true
        searchBar.resignFirstResponder()
        return
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.5) {
            if let cell = collectionView.cellForItem(at: indexPath) as? imageCell {
                cell.imageView.transform = .init(scaleX: 0.95, y: 0.95)
                cell.contentView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.5) {
            if let cell = collectionView.cellForItem(at: indexPath) as? imageCell {
                cell.imageView.transform = .identity
                cell.contentView.backgroundColor = .clear
            }
        }
    }
}
// MARK: - ScrollView Delegate
extension SearchScreenController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.bounds.size.height)) {
            if !updatingNow {
                updatingNow = true
                network.fetchData(term: searchTerm, page: pagesLoaded+1)
            }
        }
    }
}
//MARK: - FlowLayout Delegate
extension SearchScreenController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let height = collectionView.frame.size.height
        let width = collectionView.frame.size.width
        return CGSize(width: width/2 - 2, height: height/3 - 8)
    }
}
