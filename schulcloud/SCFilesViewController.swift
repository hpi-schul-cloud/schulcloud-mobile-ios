//
//  SCFilesViewController.swift
//  schulcloud
//
//  Created by Carl Gödecken on 08.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import Alamofire
import FileBrowser
import ObjectMapper

class SCFilesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        showFileViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func showFileViewController() {
        let fileBrowser = FileBrowser(dataSource: SCFileBrowserDataSource())
        fileBrowser.downloadDelegate = SCFileDownloadDelegate()
        addChildViewController(fileBrowser)
        view.addSubview(fileBrowser.view)
        fileBrowser.didMove(toParentViewController: self)
        
    }

}

class SCFileBrowserDataSource: FileBrowserDataSource {
    
    let fileStorageRoot = Constants.backend.url.appendingPathComponent("fileStorage", isDirectory: false)
    
    public var rootDirectory: FBFile {
        let userId = Globals.account.userId
        let rootUrl = URL(string: "/users/\(userId)/")!
        let file = FBFile(path: rootUrl)
        file.displayName = "Meine Dateien"
        return file
    }
    
    open func provideContents(ofDirectory directory: FBFile, callback: @escaping (FBResult<[FBFile]>) -> ()) {
        //typealias JSON = [String: Any]
        
        let path = fileStorageRoot.absoluteString + "?path=\(directory.path.absoluteString)"
        let headers: HTTPHeaders = [
            "Authorization": Globals.account.accessToken!
        ]
        Alamofire.request(path, headers: headers).responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                let filesJson = json["files"] as? [[String: Any]] ?? [[String: Any]]()
                let files = filesJson.map { fileJson -> FBFile in
                    let relativePath = (fileJson["key"] as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    let url = URL(string: relativePath)!
                    let file = FBFile(path: url)
                    file.displayName = fileJson["name"] as! String
                    return file
                }
                
                guard let directoriesJson = json["directories"] as? [[String: Any]] else {
                    log.error("Could not find directories in \(json)")
                    //callback(.error())
                    return
                }
                let directories = directoriesJson.map { value -> FBFile in
                    let name = value["name"] as! String
                    let dir = FBFile(path: directory.path.appendingPathComponent(name, isDirectory: true))
                    dir.displayName = name
                    return dir
                }
                
                let contents = files + directories
                callback(.success(contents))
            } else {
                callback(.error(response.error!))
            }
        }
        
        return
    }
    
    public func attributes(ofItemWithUrl fileUrl: URL) -> NSDictionary? {
        return nil
    }
    
    
    public func dataURL(forFile file: FBFile) throws -> URL {
        return fileStorageRoot.appendingPathComponent("?path=\(file.path.absoluteString)")
    }
    
    var excludesFileExtensions: [String]? = nil
    var excludesFilepaths: [URL]? = nil
    
}

class SCFileDownloadDelegate: FileBrowserDownloadDelegate {
    func provideCustomDownloadUrl(for file: FBFile, completionHandler: @escaping (FBResult<URL>) -> ()) {
        let signedUrlEndpoint = Constants.backend.url.appendingPathComponent("fileStorage/signedUrl", isDirectory: false)
        let parameters: Parameters = [
            "path": file.path.absoluteString.removingPercentEncoding!,
            //"fileType": mime.lookup(file),
            "action": "getObject"
        ]
        Alamofire.request(signedUrlEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: ["Authorization": Globals.account.accessToken!]).responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                if let urlString = json["url"] as? String,
                    let url = URL(string: urlString) {
                    completionHandler(.success(url))
                } else {
                    completionHandler(.error(SCFileError.badRequest(json["message"] as? String)))
                }
            } else {
                completionHandler(.error(response.error ?? SCFileError.couldNotSerializeJson))
            }
        }
    }

    func willPerformDownloadTask(for file: FBFile, using request: inout URLRequest) {
        request.allHTTPHeaderFields = ["Authorization": Globals.account.accessToken!]
    }
    
    func didFinishDownloading(data: Data, for file: FBFile, for task: URLSessionDownloadTask) throws {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            
        }
    }
}

enum SCFileError: Error {
    case couldNotSerializeJson
    case badRequest(String?)
}
