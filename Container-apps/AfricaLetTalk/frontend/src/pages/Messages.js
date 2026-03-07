import React, { useState, useEffect, useRef } from 'react';

function Messages({ user }) {
  const [conversations, setConversations] = useState([]);
  const [activeConv, setActiveConv] = useState(null);
  const [messages, setMessages] = useState([]);
  const [messageText, setMessageText] = useState('');
  const [loading, setLoading] = useState(true);
  const [msgLoading, setMsgLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [showNewChat, setShowNewChat] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const [friendsList, setFriendsList] = useState([]);
  const messagesEndRef = useRef(null);
  const pollRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    document.body.classList.add('feed-active');
    fetchConversations();
    fetchFriendsList();
    return () => {
      document.body.classList.remove('feed-active');
      if (pollRef.current) clearInterval(pollRef.current);
    };
  }, []);

  const fetchFriendsList = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/list', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setFriendsList(data.friends || []);
      }
    } catch (err) {
      console.error('Fetch friends list error:', err);
    }
  };

  const fetchConversations = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/messages/conversations', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setConversations(data.conversations || []);
      }
    } catch (err) {
      console.error('Fetch conversations error:', err);
    } finally {
      setLoading(false);
    }
  };

  const openConversation = async (conv) => {
    setActiveConv(conv);
    setMsgLoading(true);
    if (pollRef.current) clearInterval(pollRef.current);

    await fetchMessages(conv.id);
    setMsgLoading(false);

    // Poll for new messages every 3 seconds
    pollRef.current = setInterval(() => fetchMessages(conv.id), 3000);

    setTimeout(() => {
      if (inputRef.current) inputRef.current.focus();
    }, 100);
  };

  const fetchMessages = async (convId) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch(`/api/messages/conversations/${convId}/messages`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setMessages(data.messages || []);
        // Refresh conversations to update unread counts
        fetchConversations();
        setTimeout(() => {
          if (messagesEndRef.current) {
            messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
          }
        }, 50);
      }
    } catch (err) {
      console.error('Fetch messages error:', err);
    }
  };

  const sendMessage = async () => {
    if (!messageText.trim() || !activeConv) return;
    setSending(true);
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch(`/api/messages/conversations/${activeConv.id}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ content: messageText })
      });
      if (resp.ok) {
        const data = await resp.json();
        setMessages(prev => [...prev, data.message]);
        setMessageText('');
        fetchConversations();
        setTimeout(() => {
          if (messagesEndRef.current) {
            messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
          }
        }, 50);
      }
    } catch (err) {
      console.error('Send message error:', err);
    } finally {
      setSending(false);
    }
  };

  const searchUsers = async (q) => {
    setSearchQuery(q);
    if (q.length < 2) {
      setSearchResults([]);
      return;
    }
    setSearchLoading(true);
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch(`/api/messages/search-users?q=${encodeURIComponent(q)}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setSearchResults(data.users || []);
      }
    } catch (err) {
      console.error('Search error:', err);
    } finally {
      setSearchLoading(false);
    }
  };

  const startConversation = async (otherUser) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/messages/conversations', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ otherUserId: otherUser.id })
      });
      if (resp.ok) {
        const data = await resp.json();
        setShowNewChat(false);
        setSearchQuery('');
        setSearchResults([]);
        await fetchConversations();
        openConversation(data.conversation);
      }
    } catch (err) {
      console.error('Start conversation error:', err);
    }
  };

  const formatTime = (dateStr) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now - date) / 1000);
    if (diff < 60) return 'now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
    if (diff < 604800) return `${Math.floor(diff / 86400)}d`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const formatMsgTime = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  return (
    <div className="messages-page">
      <div className="messages-layout">
        {/* Conversations Sidebar */}
        <div className={`messages-sidebar ${activeConv ? 'messages-sidebar-hidden-mobile' : ''}`}>
          <div className="messages-sidebar-header">
            <h3>💬 Messages</h3>
            <button className="new-chat-btn" onClick={() => setShowNewChat(true)}>
              ✏️ New
            </button>
          </div>

          {loading ? (
            <div className="messages-loading">
              <div className="loading-spinner"></div>
            </div>
          ) : conversations.length === 0 ? (
            <div className="messages-empty">
              <div className="messages-empty-icon">💬</div>
              <p>No conversations yet</p>
              <button className="btn-start-chat" onClick={() => setShowNewChat(true)}>
                Start a conversation
              </button>
            </div>
          ) : (
            <div className="conversations-list">
              {conversations.map(conv => (
                <div
                  key={conv.id}
                  className={`conversation-item ${activeConv?.id === conv.id ? 'active' : ''} ${parseInt(conv.unread_count) > 0 ? 'unread' : ''}`}
                  onClick={() => openConversation(conv)}
                >
                  <div className="conversation-avatar">
                    {conv.other_username ? conv.other_username[0].toUpperCase() : 'U'}
                  </div>
                  <div className="conversation-info">
                    <div className="conversation-top">
                      <span className="conversation-name">
                        {conv.other_full_name || conv.other_username}
                      </span>
                      <span className="conversation-time">
                        {formatTime(conv.last_message_at)}
                      </span>
                    </div>
                    <div className="conversation-preview">
                      {conv.last_sender_id === user.id && <span className="you-label">You: </span>}
                      {conv.last_message
                        ? (conv.last_message.length > 40 ? conv.last_message.substring(0, 40) + '...' : conv.last_message)
                        : 'Start chatting...'}
                    </div>
                  </div>
                  {parseInt(conv.unread_count) > 0 && (
                    <div className="unread-badge">{conv.unread_count}</div>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* Friends without conversations */}
          {(() => {
            const convUserIds = new Set(conversations.map(c => c.other_user_id));
            const friendsWithoutConv = friendsList.filter(f => !convUserIds.has(f.id));
            if (friendsWithoutConv.length === 0) return null;
            return (
              <div className="friends-no-conv">
                <div className="friends-no-conv-header">Friends</div>
                {friendsWithoutConv.map(f => (
                  <div key={f.id} className="conversation-item" onClick={() => startConversation(f)}>
                    <div className="conversation-avatar" style={{ background: '#2D6A4F' }}>
                      {f.avatar_url ? (
                        <img src={f.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                      ) : (
                        (f.full_name || f.username || 'U')[0].toUpperCase()
                      )}
                    </div>
                    <div className="conversation-info">
                      <div className="conversation-top">
                        <span className="conversation-name">{f.full_name || f.username}</span>
                      </div>
                      <div className="conversation-preview">Tap to start chatting</div>
                    </div>
                  </div>
                ))}
              </div>
            );
          })()}
        </div>

        {/* Chat Area */}
        <div className={`messages-chat ${!activeConv ? 'messages-chat-hidden-mobile' : ''}`}>
          {activeConv ? (
            <>
              <div className="chat-header">
                <button className="chat-back-btn" onClick={() => {
                  setActiveConv(null);
                  if (pollRef.current) clearInterval(pollRef.current);
                }}>
                  ← Back
                </button>
                <div className="chat-header-avatar">
                  {activeConv.other_username ? activeConv.other_username[0].toUpperCase() : 'U'}
                </div>
                <div className="chat-header-info">
                  <h4>{activeConv.other_full_name || activeConv.other_username}</h4>
                  <span>@{activeConv.other_username}</span>
                </div>
              </div>

              <div className="chat-messages">
                {msgLoading ? (
                  <div className="messages-loading">
                    <div className="loading-spinner"></div>
                  </div>
                ) : messages.length === 0 ? (
                  <div className="chat-empty">
                    <p>No messages yet. Say hello! 👋</p>
                  </div>
                ) : (
                  messages.map((msg, i) => {
                    const isMine = msg.sender_id === user.id;
                    const showAvatar = !isMine && (i === 0 || messages[i - 1].sender_id !== msg.sender_id);
                    return (
                      <div key={msg.id} className={`chat-msg ${isMine ? 'chat-msg-mine' : 'chat-msg-theirs'}`}>
                        {!isMine && showAvatar && (
                          <div className="chat-msg-avatar">
                            {msg.username ? msg.username[0].toUpperCase() : 'U'}
                          </div>
                        )}
                        {!isMine && !showAvatar && <div className="chat-msg-avatar-spacer" />}
                        <div className="chat-msg-bubble">
                          <p>{msg.content}</p>
                          <span className="chat-msg-time">
                            {formatMsgTime(msg.created_at)}
                            {isMine && (msg.is_read ? ' ✓✓' : ' ✓')}
                          </span>
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              <div className="chat-input-area">
                <input
                  ref={inputRef}
                  type="text"
                  placeholder="Type a message..."
                  value={messageText}
                  onChange={e => setMessageText(e.target.value)}
                  onKeyDown={e => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault();
                      sendMessage();
                    }
                  }}
                />
                <button
                  className="chat-send-btn"
                  onClick={sendMessage}
                  disabled={!messageText.trim() || sending}
                >
                  {sending ? '...' : '➤'}
                </button>
              </div>
            </>
          ) : (
            <div className="chat-placeholder">
              <div className="chat-placeholder-icon">💬</div>
              <h3>Your Messages</h3>
              <p>Select a conversation or start a new one</p>
              <button className="btn-start-chat" onClick={() => setShowNewChat(true)}>
                Start a conversation
              </button>
            </div>
          )}
        </div>
      </div>

      {/* New Chat Modal */}
      {showNewChat && (
        <div className="live-modal-overlay" onClick={() => { setShowNewChat(false); setSearchQuery(''); setSearchResults([]); }}>
          <div className="new-chat-modal" onClick={e => e.stopPropagation()}>
            <div className="new-chat-header">
              <h3>✏️ New Message</h3>
              <button className="live-modal-close" onClick={() => { setShowNewChat(false); setSearchQuery(''); setSearchResults([]); }}>✕</button>
            </div>
            <div className="new-chat-body">
              <input
                type="text"
                placeholder="Search for a person..."
                value={searchQuery}
                onChange={e => searchUsers(e.target.value)}
                autoFocus
                className="new-chat-search"
              />
              {searchLoading && <p className="search-status">Searching...</p>}
              {searchQuery.length >= 2 && !searchLoading && searchResults.length === 0 && (
                <p className="search-status">No users found</p>
              )}
              <div className="new-chat-results">
                {searchResults.map(u => (
                  <div key={u.id} className="new-chat-user" onClick={() => startConversation(u)}>
                    <div className="new-chat-user-avatar">
                      {u.username ? u.username[0].toUpperCase() : 'U'}
                    </div>
                    <div className="new-chat-user-info">
                      <span className="new-chat-user-name">{u.full_name || u.username}</span>
                      <span className="new-chat-user-handle">@{u.username}</span>
                    </div>
                  </div>
                ))}
              </div>
              {searchQuery.length < 2 && friendsList.length > 0 && (
                <div className="new-chat-friends">
                  <h4 className="new-chat-friends-title">Your Friends</h4>
                  {friendsList.map(f => (
                    <div key={f.id} className="new-chat-user" onClick={() => startConversation(f)}>
                      <div className="new-chat-user-avatar" style={{ background: '#2D6A4F' }}>
                        {f.avatar_url ? (
                          <img src={f.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                        ) : (
                          (f.full_name || f.username || 'U')[0].toUpperCase()
                        )}
                      </div>
                      <div className="new-chat-user-info">
                        <span className="new-chat-user-name">{f.full_name || f.username}</span>
                        <span className="new-chat-user-handle">@{f.username}</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Messages;
