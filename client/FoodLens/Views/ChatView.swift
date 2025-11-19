import SwiftUI
import UIKit

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "I'm FoodLens, your virtual food assistant. How can I help you today?", isUser: false)
    ]
    @State private var conversationHistory: [[String: String]] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let apiService = APIService()
    
    var body: some View {
        VStack(spacing: 0) {
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.leading, 12)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .onChange(of: messages.count) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            
            Divider().background(Color.gray)
            
            HStack(spacing: 12) {
                TextField("Ask a nutrition question...", text: $messageText, axis: .vertical)
                    .background(Color.black)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .disabled(isLoading)
                    .foregroundColor(.white)
                    .tint(.blue)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty || isLoading ? .gray : .blue)
                }
                .disabled(messageText.isEmpty || isLoading)
            }
            .padding()
            .background(Color.black)
        }
        .background(Color.black)
        .navigationTitle("Nutrition Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        messages.append(ChatMessage(text: userMessage, isUser: true))
        messageText = ""
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let response = try await apiService.chat(
                    message: userMessage,
                    conversationHistory: conversationHistory.isEmpty ? nil : conversationHistory
                )
                
                conversationHistory = response.conversation_history
                
                await MainActor.run {
                    messages.append(ChatMessage(text: response.response, isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.isUser {
                Spacer(minLength: 60)
                
                Text(message.text)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            } else {
                Text(message.text)
                    .padding(12)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
}
