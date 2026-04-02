//
//  FriendsView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var selectedTab = 0
    @State private var showingSearch = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker("", selection: $selectedTab) {
                    Text("Feed").tag(0)
                    Text("Friends").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    OutfitFeedView(viewModel: viewModel)
                } else {
                    FriendsListView(viewModel: viewModel)
                }
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                FriendSearchView(viewModel: viewModel)
            }
        }
    }
}

struct OutfitFeedView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        if viewModel.outfitFeed.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No posts yet")
                    .font(.headline)
                Text("Add friends to see their daily outfits!")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.outfitFeed) { post in
                        OutfitPostCard(post: post, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
    }
}

struct OutfitPostCard: View {
    let post: OutfitPost
    @ObservedObject var viewModel: FriendsViewModel
    @State private var showingComments = false
    @State private var commentText = ""
    @EnvironmentObject var themeManager: ThemeManager
    
    var isLiked: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return post.likes.contains(currentUserId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with profile picture
            HStack {
                ProfilePictureView(
                    imageURL: nil,
                    displayName: post.userName,
                    size: 40
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.headline)
                    Text(timeAgo(from: post.datePosted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Post image
            if let urlString = post.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    default:
                        postImagePlaceholder
                    }
                }
            } else {
                postImagePlaceholder
            }
            
            // Caption
            Text(post.caption)
                .font(.body)
            
            // Actions
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.toggleLike(post: post)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(post.likes.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    showingComments.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.gray)
                        Text("\(post.comments.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            // Comments section
            if showingComments {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            ProfilePictureView(
                                imageURL: nil,
                                displayName: comment.userName,
                                size: 24
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(comment.userName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text(timeAgo(from: comment.datePosted))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Text(comment.text)
                                    .font(.caption)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        TextField("Add a comment...", text: $commentText)
                            .font(.caption)
                        Button("Post") {
                            if !commentText.isEmpty {
                                viewModel.addComment(to: post, text: commentText)
                                commentText = ""
                            }
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                        .disabled(commentText.isEmpty)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private var postImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(themeManager.currentTheme.lightBackground)
            .frame(height: 300)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.4))
            )
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        if viewModel.friends.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "person.2")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No friends yet")
                    .font(.headline)
                Text("Search and connect with friends to share outfits!")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        } else {
            List {
                if !viewModel.friendRequests.isEmpty {
                    Section(header: Text("Friend Requests")) {
                        ForEach(viewModel.friendRequests) { user in
                            HStack {
                                ProfilePictureView(
                                    imageURL: user.profileImageURL,
                                    displayName: user.displayName,
                                    size: 40
                                )
                                
                                VStack(alignment: .leading) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button("Accept") {
                                    viewModel.acceptFriendRequest(from: user)
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(themeManager.currentTheme.color)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section(header: Text("Friends (\(viewModel.friends.count))")) {
                    ForEach(viewModel.friends) { friend in
                        NavigationLink(destination: FriendProfileView(user: friend)) {
                            HStack {
                                ProfilePictureView(
                                    imageURL: friend.profileImageURL,
                                    displayName: friend.displayName,
                                    size: 40
                                )
                                
                                VStack(alignment: .leading) {
                                    Text(friend.displayName)
                                        .font(.headline)
                                    Text("\(friend.closetItemCount) items")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FriendSearchView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by email or username", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { _, newValue in
                        viewModel.searchUsers(query: newValue)
                    }
                
                if viewModel.searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Search for friends")
                            .font(.headline)
                        Text("Enter an email or username to find friends")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(viewModel.searchResults) { user in
                        HStack {
                            ProfilePictureView(
                                imageURL: user.profileImageURL,
                                displayName: user.displayName,
                                size: 40
                            )
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("Add") {
                                viewModel.sendFriendRequest(to: user)
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(themeManager.currentTheme.color)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FriendProfileView: View {
    let user: User
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            Section {
                HStack {
                    ProfilePictureView(
                        imageURL: user.profileImageURL,
                        displayName: user.displayName,
                        size: 60
                    )
                    
                    VStack(alignment: .leading) {
                        Text(user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading)
                }
                .padding(.vertical)
            }
            
            Section(header: Text("Stats")) {
                HStack {
                    Text("Closet Items")
                    Spacer()
                    Text("\(user.closetItemCount)")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Sustainability Score")
                    Spacer()
                    Text("\(user.sustainabilityScore)")
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("Recent Outfits")) {
                Text("Coming soon!")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import FirebaseAuth
