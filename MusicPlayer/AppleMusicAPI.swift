//
//  AppleMusicAPI.swift
//  MusicPlayer
//
//  Created by Sai Kambampati on 5/30/20.
//  Copyright © 2020 Sai Kambmapati. All rights reserved.
//

import Foundation
import StoreKit

class AppleMusicAPI {
    let developerToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiIsImtpZCI6IlFQV0c5N0FIMkcifQ.eyJpc3MiOiI0TFQ5N0FKTDdEIiwiZXhwIjoxNjMxNTgwNTQ0LCJpYXQiOjE2MTU4MTI1NDR9.d0frn-3UYkZVCGARqRTtmZY9ayzTeBHjTDjZDN20RCE0e43tpJEonwBYNlovSuOhi85-KUMrLfvHJl4QyToZHw"
    
    func getUserToken(completion:@escaping (String) -> Void) {
        var userToken = String()
        print("getusertoken starting")
        
        SKCloudServiceController().requestUserToken(forDeveloperToken: self.developerToken) { (receivedToken, error) in
            // 3
            print("getusertoken requesting")
            guard error == nil else { return }
            if let token = receivedToken {
                userToken = token
                completion(userToken)
            }
        }
    }
    
    func fetchStorefrontID(usertoken:String, completion:@escaping (String) -> Void ) {
        var storefrontID: String! 
        
        print("fetchstoreid starting")
        
        let musicURL = URL(string: "https://api.music.apple.com/v1/me/storefront")!
        var musicRequest = URLRequest(url: musicURL)
        musicRequest.httpMethod = "GET"
        musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        musicRequest.addValue(usertoken, forHTTPHeaderField: "Music-User-Token")
        
        URLSession.shared.dataTask(with: musicRequest) { (data, response, error) in
            guard error == nil else { return }
            
            if let json = try? JSON(data: data!) {
                let result = (json["data"]).array!
                let id = (result[0].dictionaryValue)["id"]!
                storefrontID = id.stringValue
                completion(storefrontID)
                print("fetchstoreid communicating")
            }
        }.resume()
    }
    
    func searchAppleMusic(_ searchTerm: String!, usertoken: String, storefrontID: String, completion: @escaping ([Song]) -> Void) {
        var songs = [Song]()

        let musicURL = URL(string: "https://api.music.apple.com/v1/catalog/\(storefrontID)/search?term=\(searchTerm.replacingOccurrences(of: " ", with: "+"))&types=songs&limit=25")!
        var musicRequest = URLRequest(url: musicURL)
        musicRequest.httpMethod = "GET"
        musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        musicRequest.addValue(usertoken, forHTTPHeaderField: "Music-User-Token")
        
        URLSession.shared.dataTask(with: musicRequest) { (data, response, error) in
            guard error == nil else { return }
            print("searchAppleMusicrequesting")
            if let json = try? JSON(data: data!) {
                let result = (json["results"]["songs"]["data"]).array!
                var count = 0
                for song in result {
                    count += 1
                    let attributes = song["attributes"]
                    let currentSong = Song(id: attributes["playParams"]["id"].string!, name: attributes["name"].string!, artistName: attributes["artistName"].string!, artworkURL: attributes["artwork"]["url"].string!)
                    songs.append(currentSong)
                    if count == result.count {
                        completion(songs)
                    }
                }
            } else {
                completion(songs)
            }
        }.resume()
    }
    
    
    //original
    /*
    //DispatchSemaphore can be the root cause of connection error.
    //Let's change this into a form of closure.
    func getUserToken() -> String {
        var userToken = String()
        
        print("getusertoken starting")
        
        // 1
        let lock2 = DispatchSemaphore(value: 0)
        
        
        SKCloudServiceController.requestAuthorization { status in
            print("requestAuthorization")
            guard status == .authorized else { return }
        
            // 2
            SKCloudServiceController().requestUserToken(forDeveloperToken: self.developerToken) { (receivedToken, error) in
                // 3
                print("getusertoken requesting")
                guard error == nil else { return }
                if let token = receivedToken {
                    userToken = token
                    lock2.signal()
                }
            }
        }
        // 4
        lock2.wait()
        return userToken
    }
     
     func fetchStorefrontID() -> String {
         let lock = DispatchSemaphore(value: 0)
         var storefrontID: String!
         
         print("fetchstoreid starting")
         
         let musicURL = URL(string: "https://api.music.apple.com/v1/me/storefront")!
         var musicRequest = URLRequest(url: musicURL)
         musicRequest.httpMethod = "GET"
         musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
         musicRequest.addValue(getUserToken(), forHTTPHeaderField: "Music-User-Token")
         
         URLSession.shared.dataTask(with: musicRequest) { (data, response, error) in
             guard error == nil else { return }
             
             if let json = try? JSON(data: data!) {
                 let result = (json["data"]).array!
                 let id = (result[0].dictionaryValue)["id"]!
                 storefrontID = id.stringValue
                 print("fetchstoreid communicating")
                 lock.signal()
             }
         }.resume()
         
         lock.wait()
         print("fetchstoreid works")
         return storefrontID
     }
     
     func searchAppleMusic(_ searchTerm: String!) -> [Song] {
         let lock = DispatchSemaphore(value: 0)
         var songs = [Song]()

         let musicURL = URL(string: "https://api.music.apple.com/v1/catalog/\(fetchStorefrontID())/search?term=\(searchTerm.replacingOccurrences(of: " ", with: "+"))&types=songs&limit=25")!
         var musicRequest = URLRequest(url: musicURL)
         musicRequest.httpMethod = "GET"
         musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
         musicRequest.addValue(getUserToken(), forHTTPHeaderField: "Music-User-Token")
         
         URLSession.shared.dataTask(with: musicRequest) { (data, response, error) in
             guard error == nil else { return }
             print("searchAppleMusicrequesting")
             if let json = try? JSON(data: data!) {
                 let result = (json["results"]["songs"]["data"]).array!
                 for song in result {
                     let attributes = song["attributes"]
                     let currentSong = Song(id: attributes["playParams"]["id"].string!, name: attributes["name"].string!, artistName: attributes["artistName"].string!, artworkURL: attributes["artwork"]["url"].string!)
                     songs.append(currentSong)
                 }
                 lock.signal()
             } else {
                 lock.signal()
             }
         }.resume()
         
         lock.wait()
         return songs
     }
     
     */
    
    
    
    
}
