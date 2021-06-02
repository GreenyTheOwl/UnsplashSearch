//
//  SearchScreenController.swift
//  UnsplashDemo
//
//  Created by Павел Духовенко on 26.02.2021.
//

import UIKit

final class SearchScreenController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private properties
    
    private var network = NetworkAccessService(mode: .byTerm)
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
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        network.delegate = self
        activityIndicator.stopAnimating()
    }
    
    // MARK: - IBActions
    
    @IBAction func refreshData() {
        searchResults.removeAll()
        pagesLoaded = 0
        collectionView.reloadData()
        network.fetchData(term: searchTerm, page: pagesLoaded+1)
        updatingNow = true
    }
    
    // MARK: - Segues
    
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

// MARK: - UICollectionViewDataSource

extension SearchScreenController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchResultCell", for: indexPath) as! imageCell
        cell.imageView.image = searchResults[indexPath.row].visualRepresentation
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SearchScreenController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension SearchScreenController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let term = searchBar.text else { return }
        searchResults.removeAll()
        searchTerm = term
        pagesLoaded = 0
        collectionView.reloadData()
        network.fetchData(term: searchTerm, page: pagesLoaded + 1)
        updatingNow = true
        searchBar.resignFirstResponder()
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

// MARK: - UIScrollViewDelegate

extension SearchScreenController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.bounds.size.height) {
            if !updatingNow {
                updatingNow = true
                network.fetchData(term: searchTerm, page: pagesLoaded+1)
            }
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension SearchScreenController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height = collectionView.frame.size.height
        let width = collectionView.frame.size.width
        return CGSize(width: width / 2 - 2, height: height / 3 - 8)
    }
}

// MARK: - NetworkAccess Delegate

extension SearchScreenController: NetworkAccessDelegate {
    
    func reloadData(imageSearchResults: [UnsplashImage]?, collectionSearchResults: [UnsplashCollection]?) {
        guard let imageResults = imageSearchResults, let view = collectionView else { return }
        if imageResults.count > 0 {
            searchResults.append(contentsOf: imageResults)
            pagesLoaded += 1
            view.reloadData()
        }
        updatingNow = false
    }
}
