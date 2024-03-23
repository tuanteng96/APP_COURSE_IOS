//
//  DataCacheManager.swift
//  ezsspa
//
//  Created by HUNG on 22/03/2024.
//  Copyright © 2024 High Sierra. All rights reserved.
//

import Foundation
import ZIPFoundation
class DataCacheManager {
    
    private func getDocumentUrl () -> URL?{
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("cache")
    }
    
    private func getURLFromBundle(path: String) -> URL?{
        let separatedArray = path.split(separator: ".")
        print(separatedArray)
        if let cssFilePath = Bundle.main.url(forResource: String(separatedArray.first ?? ""), withExtension:  String(separatedArray.last ?? "")) {
            return cssFilePath
        } else {
            return nil
        }
    }
    
    func readDataJSONFromUnZippedFolder(paths: [String]) -> [String?]{
        var list = [String?]()
        guard let documentsURL = getDocumentUrl() else {
            return list
        }
        
        for img in paths {
            if checkExist(fileName: img) {
                if let data = dataFromFile(fileURL: documentsURL.appendingPathComponent(img))  {
                    list.append(data)
                    
                }else {
                    list.append(nil)
                    
                }
                
            }else{
                list.append(nil)
            }
        }
        return list
        
        
    }
    
    private func dataFromFile(fileURL : URL) -> String?{
        do {
            let jsonString = try String(contentsOf: fileURL,encoding: .utf8)
            return jsonString
        } catch {
            print("Lỗi khi đọc tệp tin: \(error)")
            return nil
        }
    }
    
    func getFileFromUnZipedFolder(images : [String]) -> [String?]{
        var list = [String?]()
        guard let documentsURL = getDocumentUrl() else {
            return list
        }
        
        for img in images {
            if checkExist(fileName: img) {
                list.append(documentsURL.appendingPathComponent(img).path)
            }else{
                list.append(nil)
            }
        }
        return list
    }
    
    func unZipFileFromAsset(fileName : String, success: @escaping (_ s : String?) ->Void, error: @escaping (_ url: String?) ->Void ){
        guard let zipURL = getURLFromBundle(path: fileName) else {
            print("NOT FOUND")
            error(fileName)
            return
        }
        let separatedArray = fileName.split(separator: ".")
        if checkExist(fileName: String(separatedArray.first ?? "")) {
            success("Đã tồn tại")
            return
        }
        unZipFile(zipURL: zipURL) {
            success("HÊ Hê")
        } e: {
            error(fileName)
        }
    }
    
    private func checkExist(fileName : String) -> Bool {
        guard let documentsURL = getDocumentUrl() else {
            return false
        }
        let destinationURL = documentsURL.appendingPathComponent(fileName)
        let fileManager = FileManager.default
        let isDestinationExists = fileManager.fileExists(atPath: destinationURL.path)
        return isDestinationExists
    }
    
    
    private func unZipFile(zipURL: URL, success: @escaping () ->Void, e: @escaping () ->Void ){
        guard let documentsURL = getDocumentUrl() else {
            e();
            return
        }
        print(documentsURL)
        do {
            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.unzipItem(at: zipURL, to: documentsURL)
            print("Đã giải nén tệp tin zip thành công")
            print(documentsURL)
            success()
        } catch {
            print("Lỗi khi giải nén tệp tin zip: \(error)")
            e()
        }
        
    }
    
    func downLoadAndUnzipFile(files: [String], errorDownloadCallback: @escaping (String?) -> Void, errorUnZipCallback: @escaping (String?) -> Void, success:  @escaping () -> Void){
        self.deleteAll()
        downloadListFile(files: files) { localUrls in
            print("listurrl : \(localUrls.count)")
            if(localUrls.isEmpty){
                errorDownloadCallback(nil)
                return
            }
            
            var i = 0;
            for url in localUrls {
                if url != nil {
                    self.unZipFile(zipURL: url!) {
                        i+=1
                    } e: {
                        errorUnZipCallback(url?.path)
                    }
                }
            }
            if(i == localUrls.count){
                success()
            }
        } errorCallback: { url in
            errorDownloadCallback(url)
        }
        
    }
    
    private func downloadListFile(files : [String], completion : @escaping ([URL?]) -> Void, errorCallback : @escaping (String?) -> Void ) {
        let dispatchGroup = DispatchGroup()
        var listURL = [URL?]()
        print("OOOO")
        for file in files {
            print(file)
            guard let fileUrl = URL(string: file) else {
                print("??")
                continue }
            
            dispatchGroup.enter()
            let task = URLSession.shared.downloadTask(with: fileUrl) { localURL, response, error in
                defer {
                    dispatchGroup.leave() // Kết thúc theo dõi khi hoàn thành việc tải xuống
                }

                if let error = error {
                    //                        completion(nil, error)
                    print("Error \(error)")
                    errorCallback(file)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let statusCodeError = NSError(domain:"", code:httpResponse.statusCode, userInfo:nil)
                    print("Error \(statusCodeError)")
                    errorCallback(file)
                    return
                }
                listURL.append(localURL)
            }
            task.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(listURL)
        }
        
    }
    
    func deleteAll(){
        guard let documentsURL = getDocumentUrl() else {
            return
        }
        deleteCache(path: documentsURL)
    }
    
    private  func deleteCache(path: URL) {
        do {
            try  FileManager.default.removeItem(at: path)
        }
        catch {
            print("Delete Error")
        }
    }
    
}
