//
//  MainScreenController.swift
//  RMR_test
//
//  Created by Павел Духовенко on 26.02.2021.
//

import UIKit

class MainScreenController: UIViewController, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var network = NetworkAccess(mode: .random)
    private var searchResults: [UnsplashImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name("randomImageDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name("randomImageHighResDownloaded"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        network.fetchData(term: nil, page: nil)
    }
    
    @objc private func reloadData() {
        guard let view = collectionView else {
            return
        }
        searchResults = network.imageSearchResults
        view.reloadData() 
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ImageContentsController {
            guard let vc = segue.destination as? ImageContentsController else {
                print("failed to open ImageContentsController")
                return
            }
            vc.image = network.imageSearchResults[collectionView.indexPath(for: (sender as! imageCell))!.row]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return network.imageSearchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mainScreenCell", for: indexPath) as! imageCell
        cell.imageView.image = network.imageSearchResults[indexPath.row].highResVisualRepresentation
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! imageCell
        UIView.transition(with: collectionView, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            cell.imageView.image = self.searchResults[indexPath.row].highResVisualRepresentation
        }, completion: nil)
    }
}

extension MainScreenController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
