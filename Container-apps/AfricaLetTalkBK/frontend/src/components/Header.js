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
              <path d="M52 12 C50 12, 47 13, 45 14 C43 15, 41 16, 40 17 L38 18 C36 18, 35 19, 34 20 C33 21, 32 22, 31 24 C30 25, 30 27, 29 29 L28 31 C27 32, 27 34, 27 36 C27 38, 26 40, 26 42 L26 44 C26 46, 25 47, 25 49 L25 52 C25 54, 25 56, 26 58 L27 60 C27 62, 28 63, 28 65 C29 67, 30 68, 31 70 L33 72 C34 73, 35 75, 37 76 L39 78 C40 79, 42 80, 43 81 C44 82, 45 82, 46 83 L47 84 C47 85, 48 86, 48 86 L47 87 C47 88, 46 88, 46 88 L45 88 C44 87, 43 86, 42 86 L41 85 C40 84, 39 84, 38 85 C37 86, 38 87, 39 87 L40 88 C41 88, 42 89, 43 89 L45 89 C46 89, 47 89, 48 88 L50 86 C51 85, 52 84, 52 82 L52 80 C53 78, 54 76, 55 75 L56 73 C57 72, 58 70, 59 68 L60 66 C61 64, 62 62, 63 60 L64 58 C65 56, 66 54, 66 52 L66 50 C67 48, 68 46, 68 44 L68 42 C68 40, 68 38, 67 36 L66 34 C66 32, 65 30, 64 29 L62 27 C61 26, 60 24, 59 23 L57 20 C56 19, 55 17, 54 16 L53 14 C52 13, 52 12, 52 12 Z" fill="white" opacity="0.95"/>
              <ellipse cx="65" cy="72" rx="3" ry="7" fill="white" opacity="0.9" transform="rotate(-10,65,72)"/>
            </svg>
          </div>
          <h1>LetsConnect<span>Afrika</span></h1>
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
                    <div className="header-avatar-large">
                      {user.avatar_url ? (
                        <img src={user.avatar_url} alt="avatar" />
                      ) : (
                        <span>{getInitial()}</span>
                      )}
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
