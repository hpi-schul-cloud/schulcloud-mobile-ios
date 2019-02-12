//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit
import Common

class StoreViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private var resources: Resources? {
        didSet {
//            self.resourceCollectionView.reloadData()
//            self.resourceCollectionView.collectionViewLayout.invalidateLayout()
//            self.resourceCollectionView.layoutSubviews()
            self.collectionView.reloadData()
        }
    }
    private let reuseIdentifier = "ResourceCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    // Nicht notwendig wenn von UICollectionViewController geerbt wird
//    @IBOutlet weak var resourceCollectionView: UICollectionView! {
//        didSet {
//            resourceCollectionView.dataSource = self
//            resourceCollectionView.delegate = self
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let session = URLSession.shared
        let request_blueprint = request(for: URL(string: "https://api.schul-cloud.org/content/resources")!)
        getData(using: request_blueprint, with: session)
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resources?.data.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "resourceCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ResourceCell
        
        let resource = (resources!.data)[indexPath.item]
        cell.configure(for: resource)
        return cell
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        return request
    }
    
    private func getData(using request_blueprint: URLRequest, with session: URLSession) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.dataTask(with: request_blueprint, completionHandler: {
                [weak self]
                (data: Data?, response: URLResponse?, error: Error?) in

                if let data = data {
                    let decoder = JSONDecoder()
                    let resources = try! decoder.decode(Resources.self, from: data)
                    DispatchQueue.main.async {
                        self?.resources = resources
                    }
                }
            }).resume()
        }
    }
    
    @objc
    func foobar() {
        print("hast du nicht gesehen")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//private extension StoreViewController {
//    func resource(for indexPath: IndexPath) -> Resource {
//        return resources![indexPath]
//    }
//}

