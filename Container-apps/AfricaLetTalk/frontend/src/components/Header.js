import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';

function Header({ user, onLogout, onUserUpdate }) {
  const navigate = useNavigate();
  const [unreadCount, setUnreadCount] = useState(0);
  const [showAvatarMenu, setShowAvatarMenu] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [notifCount, setNotifCount] = useState(0);
  const [showNotifPanel, setShowNotifPanel] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const fileInputRef = useRef(null);
  const menuRef = useRef(null);
  const notifRef = useRef(null);

  useEffect(() => {
    if (user) {
      fetchUnread();
      fetchNotifCount();
      const interval = setInterval(() => { fetchUnread(); fetchNotifCount(); }, 10000);
      return () => clearInterval(interval);
    }
  }, [user]);

  const fetchUnread = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/messages/unread', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setUnreadCount(data.unread || 0);
      }
    } catch (err) {
      // silent
    }
  };

  // Close avatar menu on click outside
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setShowAvatarMenu(false);
      }
      if (notifRef.current && !notifRef.current.contains(e.target)) {
        setShowNotifPanel(false);
      }
    };
    if (showAvatarMenu || showNotifPanel) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showAvatarMenu, showNotifPanel]);

  const fetchNotifCount = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/notifications/unread-count', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setNotifCount(data.count || 0);
      }
    } catch (err) { /* silent */ }
  };

  const fetchNotifications = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/notifications', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setNotifications(data.notifications || []);
      }
    } catch (err) { /* silent */ }
  };

  const toggleNotifPanel = async () => {
    const opening = !showNotifPanel;
    setShowNotifPanel(opening);
    if (opening) {
      await fetchNotifications();
    }
  };

  const markAllRead = async () => {
    try {
      const token = localStorage.getItem('token');
      await fetch('/api/notifications/read-all', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      setNotifCount(0);
      setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
    } catch (err) { /* silent */ }
  };

  const formatNotifTime = (dateStr) => {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    const days = Math.floor(hrs / 24);
    return `${days}d ago`;
  };

  const getNotifIcon = (type) => {
    switch (type) {
      case 'friend_request': return '👋';
      case 'friend_accepted': return '🤝';
      case 'friend_post': return '📝';
      case 'friend_location': return '📍';
      default: return '🔔';
    }
  };

  const acceptFriendFromNotif = async (friendshipId, notifId) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/accept', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ friendshipId })
      });
      if (resp.ok) {
        setNotifications(prev => prev.map(n => n.id === notifId ? { ...n, _accepted: true } : n));
        fetchNotifCount();
      }
    } catch (err) {
      console.error('Accept friend from notif error:', err);
    }
  };

  const rejectFriendFromNotif = async (friendshipId, notifId) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/remove', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ friendshipId })
      });
      if (resp.ok) {
        setNotifications(prev => prev.map(n => n.id === notifId ? { ...n, _rejected: true } : n));
        fetchNotifCount();
      }
    } catch (err) {
      console.error('Reject friend from notif error:', err);
    }
  };

  const handleAvatarUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setUploadingAvatar(true);
    try {
      const token = localStorage.getItem('token');
      const formData = new FormData();
      formData.append('avatar', file);
      const resp = await fetch('/api/users/avatar', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
        body: formData
      });
      if (resp.ok) {
        const data = await resp.json();
        if (onUserUpdate) onUserUpdate(data.user);
      } else {
        const err = await resp.json();
        alert(err.error || 'Failed to upload avatar');
      }
    } catch (err) {
      alert('Failed to upload avatar');
    } finally {
      setUploadingAvatar(false);
      setShowAvatarMenu(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleRemoveAvatar = async () => {
    setUploadingAvatar(true);
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch(`/api/users/${user.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ avatarUrl: null })
      });
      if (resp.ok) {
        const data = await resp.json();
        if (onUserUpdate) onUserUpdate(data.user);
      }
    } catch (err) {
      alert('Failed to remove avatar');
    } finally {
      setUploadingAvatar(false);
      setShowAvatarMenu(false);
    }
  };

  const getInitial = () => {
    if (user.full_name) return user.full_name.charAt(0).toUpperCase();
    return user.username.charAt(0).toUpperCase();
  };

  return (
    <header className="header">
      <div className="header-content">
        <div className="logo" onClick={() => navigate('/')} style={{ cursor: 'pointer' }}>
          <div className="logo-icon">
            <svg viewBox="0 0 100 100" width="28" height="28" xmlns="http://www.w3.org/2000/svg">
              <circle cx="50" cy="50" r="48" fill="#E07A2F"/>
              <circle cx="35" cy="38" r="9" fill="white" opacity="0.95"/>
              <circle cx="65" cy="38" r="9" fill="white" opacity="0.95"/>
              <circle cx="50" cy="60" r="10" fill="white" opacity="0.95"/>
              <line x1="40" y1="42" x2="46" y2="54" stroke="white" strokeWidth="3" opacity="0.9"/>
              <line x1="60" y1="42" x2="54" y2="54" stroke="white" strokeWidth="3" opacity="0.9"/>
              <line x1="38" y1="36" x2="62" y2="36" stroke="white" strokeWidth="3" opacity="0.9"/>
            </svg>
          </div>
          <h1>Lets<span>Connect</span></h1>
        </div>
        {user ? (
          <div className="nav">
            <div className="header-avatar-wrapper" ref={menuRef}>
              <div className="header-avatar" onClick={() => setShowAvatarMenu(!showAvatarMenu)}>
                {user.avatar_url ? (
                  <img src={user.avatar_url} alt="avatar" className="header-avatar-img" />
                ) : (
                  <span className="header-avatar-initial">{getInitial()}</span>
                )}
              </div>
              <span className="greeting" onClick={() => setShowAvatarMenu(!showAvatarMenu)} style={{ cursor: 'pointer' }}>
                {user.full_name || user.username}
              </span>
              {showAvatarMenu && (
                <div className="header-avatar-menu">
                  <div className="header-avatar-menu-header">
                    <div className="header-avatar-large" onClick={() => fileInputRef.current?.click()} style={{ cursor: 'pointer', position: 'relative' }}>
                      {user.avatar_url ? (
                        <img src={user.avatar_url} alt="avatar" />
                      ) : (
                        <span>{getInitial()}</span>
                      )}
                      <div className="avatar-camera-overlay">📷</div>
                    </div>
                    <div className="header-avatar-info">
                      <strong>{user.full_name || user.username}</strong>
                      <small>@{user.username}</small>
                    </div>
                  </div>
                  <button
                    className="header-avatar-menu-btn"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploadingAvatar}
                  >
                    {uploadingAvatar ? '⏳ Uploading...' : '📷 Change Photo'}
                  </button>
                  {user.avatar_url && (
                    <button
                      className="header-avatar-menu-btn remove-photo-btn"
                      onClick={handleRemoveAvatar}
                      disabled={uploadingAvatar}
                    >
                      🗑️ Remove Photo
                    </button>
                  )}
                  <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={handleAvatarUpload}
                  />
                </div>
              )}
            </div>
            <button onClick={() => navigate('/feed')}>Feed</button>
            <div className="notif-wrapper" ref={notifRef}>
              <button className="nav-notif-btn" onClick={toggleNotifPanel}>
                🔔
                {notifCount > 0 && <span className="nav-unread-badge">{notifCount > 9 ? '9+' : notifCount}</span>}
              </button>
              {showNotifPanel && (
                <div className="notif-panel">
                  <div className="notif-panel-header">
                    <h4>Notifications</h4>
                    {notifCount > 0 && (
                      <button className="notif-mark-read" onClick={markAllRead}>Mark all read</button>
                    )}
                  </div>
                  <div className="notif-panel-body">
                    {notifications.length === 0 ? (
                      <p className="notif-empty">No notifications yet</p>
                    ) : (
                      notifications.slice(0, 20).map(n => (
                        <div key={n.id} className={`notif-item ${!n.is_read ? 'notif-unread' : ''}`}>
                          <div className="notif-item-avatar">
                            {n.avatar_url ? (
                              <img src={n.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                            ) : (
                              <span>{getNotifIcon(n.type)}</span>
                            )}
                          </div>
                          <div className="notif-item-body">
                            <p className="notif-item-text">{n.content}</p>
                            {n.type === 'friend_request' && n.related_id && !n._accepted && !n._rejected && (
                              <div className="notif-friend-actions">
                                <button className="notif-accept-btn" onClick={(e) => { e.stopPropagation(); acceptFriendFromNotif(n.related_id, n.id); }}>Accept</button>
                                <button className="notif-reject-btn" onClick={(e) => { e.stopPropagation(); rejectFriendFromNotif(n.related_id, n.id); }}>Decline</button>
                              </div>
                            )}
                            {n._accepted && <span className="notif-action-done">✓ Accepted</span>}
                            {n._rejected && <span className="notif-action-done">Declined</span>}
                            <span className="notif-item-time">{formatNotifTime(n.created_at)}</span>
                          </div>
                          {!n.is_read && <div className="notif-unread-dot" />}
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>
            <button className="nav-messages-btn" onClick={() => navigate('/messages')}>
              💬 Messages
              {unreadCount > 0 && <span className="nav-unread-badge">{unreadCount}</span>}
            </button>
            <button onClick={onLogout}>Logout</button>
          </div>
        ) : (
          <div className="nav">
            <button onClick={() => navigate('/login')}>Sign In</button>
            <button className="btn-nav-primary" onClick={() => navigate('/register')}>Get Started</button>
          </div>
        )}
      </div>
    </header>
  );
}

export default Header;
