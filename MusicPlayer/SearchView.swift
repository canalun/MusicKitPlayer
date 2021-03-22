//
//  SearchView.swift
//  MusicPlayer
//
//  Created by Sai Kambampati on 3/18/20.
//  Copyright © 2020 Sai Kambmapati. All rights reserved.
//

import SwiftUI
import StoreKit
import MediaPlayer
import SDWebImageSwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults = [Song]()
    @Binding var musicPlayer: MPMusicPlayerController
    @Binding var currentSong: Song
    
    var body: some View {
        VStack {
            TextField("Search Songs", text: $searchText, onCommit: {
                UIApplication.shared.resignFirstResponder()
                if self.searchText.isEmpty {
                    self.searchResults = []
                } else {
                    print("request")
                    SKCloudServiceController.requestAuthorization { (status) in
                        if status == .authorized {
                            print("authorized")
                            print(status)
                            //self.searchResults = AppleMusicAPI().searchAppleMusic(self.searchText)
                            AppleMusicAPI().getUserToken(completion: {usertoken in
                                AppleMusicAPI().fetchStorefrontID(usertoken: usertoken, completion: {storefrontID in
                                    AppleMusicAPI().searchAppleMusic(self.searchText, usertoken: usertoken, storefrontID: storefrontID, completion: {songs in
                                        self.searchResults = songs
                                    })
                                })
                            })
                        }
                    }
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal, 16)
            .accentColor(.pink)
            
            List {
                ForEach(searchResults, id:\.id) { song in
                    HStack {
                        WebImage(url: URL(string: song.artworkURL.replacingOccurrences(of: "{w}", with: "80").replacingOccurrences(of: "{h}", with: "80")))
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(5)
                            .shadow(radius: 2)

                        VStack(alignment: .leading) {
                            Text(song.name)
                                .font(.headline)
                            Text(song.artistName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            self.currentSong = song
                            self.musicPlayer.setQueue(with: [song.id])
                            self.musicPlayer.play()
                        }) {
                            Image(systemName: "play.fill")
                                .foregroundColor(.pink)
                        }
                    }
                }
            }
            .accentColor(.pink)
        }
    }
}
