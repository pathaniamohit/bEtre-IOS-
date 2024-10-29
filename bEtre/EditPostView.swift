import SwiftUI
import Firebase
import FirebaseDatabase

struct EditPostView: View {
    @State var post: Post
    @Environment(\.dismiss) var dismiss // To close the view after saving

    var body
