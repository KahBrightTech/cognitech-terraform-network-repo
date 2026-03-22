import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

function Profile({ user }) {
  const { username } = useParams();
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [posts, setPosts] = useState([]);
  const [friendCount, setFriendCount] = useState(0);
  const [friendshipStatus, setFriendshipStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const isOwnProfile = user.username === username;

  useEffect(() => {
    fetchProfile();
  }, [username]);

  const fetchProfile = async () => {
    setLoading(true);
    setError(null);
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/users/profile/${encodeURIComponent(username)}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (response.ok) {
        const data = await response.json();
        setProfile(data.user);
        setPosts(data.posts || []);
        setFriendCount(data.friendCount || 0);
        setFriendshipStatus(data.friendshipStatus);
      } else if (response.status === 404) {
        setError('User not found');
      } else {
        setError('Failed to load profile');
      }
    } catch (err) {
      setError('Failed to load profile');
    } finally {
      setLoading(false);
    }
  };

  const handleFriendAction = async () => {
    if (!profile) return;
    setActionLoading(true);
    try {
      const token = localStorage.getItem('token');
      if (!friendshipStatus) {
        const resp = await fetch('/api/friends/request', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
          body: JSON.stringify({ toUserId: profile.id })
        });
        if (resp.ok) {
          setFriendshipStatus({ status: 'pending', user_id: user.id });
        }
      } else if (friendshipStatus.status === 'accepted') {
        const resp = await fetch('/api/friends/remove', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
          body: JSON.stringify({ friendshipId: friendshipStatus.id })
        });
        if (resp.ok) {
          setFriendshipStatus(null);
          setFriendCount(prev => Math.max(0, prev - 1));
        }
      }
    } catch (err) {
      console.error('Friend action error:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const getFriendButtonLabel = () => {
    if (!friendshipStatus) return '+ Add Friend';
    if (friendshipStatus.status === 'accepted') return '✓ Friends';
    if (friendshipStatus.status === 'pending') {
      return friendshipStatus.user_id === user.id ? 'Pending...' : 'Accept Request';
    }
    return '+ Add Friend';
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now - date) / 1000);
    if (diff < 60) return 'just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const isVideoUrl = (url) => /\.(mp4|mov|avi|webm|mkv)$/i.test(url);

  if (loading) {
    return (
      <div className="loading">
        <div className="loading-spinner"></div>
        <p>Loading profile...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="profile-page">
        <div className="profile-error">
          <p>{error}</p>
          <button className="btn-back" onClick={() => navigate(-1)}>← Go Back</button>
        </div>
      </div>
    );
  }

  return (
    <div className="profile-page">
      <div className="profile-page-inner">
        {/* Header */}
        <div className="profile-page-cover">
          <div className="profile-page-cover-pattern"></div>
          <button className="btn-back profile-back-btn" onClick={() => navigate(-1)}>← Back</button>
        </div>

        {/* Profile Info */}
        <div className="profile-page-info">
          <div className="profile-page-avatar-wrap">
            <div className="profile-page-avatar">
              {profile.avatar_url ? (
                <img src={profile.avatar_url} alt={profile.username} className="profile-page-avatar-img" />
              ) : (
                <span>{profile.username ? profile.username[0].toUpperCase() : 'U'}</span>
              )}
            </div>
          </div>

          <div className="profile-page-details">
            <h2 className="profile-page-name">{profile.full_name || profile.username}</h2>
            <p className="profile-page-handle">@{profile.username}</p>
            {profile.bio && <p className="profile-page-bio">{profile.bio}</p>}
            <p className="profile-page-joined">Joined {new Date(profile.created_at).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}</p>
          </div>

          <div className="profile-page-stats">
            <div className="profile-page-stat">
              <span className="profile-page-stat-num">{posts.length}</span>
              <span className="profile-page-stat-label">Posts</span>
            </div>
            <div className="profile-page-stat">
              <span className="profile-page-stat-num">{friendCount}</span>
              <span className="profile-page-stat-label">Friends</span>
            </div>
          </div>

          {!isOwnProfile && (
            <button
              className={`btn-friend-action ${friendshipStatus?.status === 'accepted' ? 'btn-friend-action--friends' : ''}`}
              onClick={handleFriendAction}
              disabled={actionLoading || friendshipStatus?.status === 'pending'}
            >
              {actionLoading ? '...' : getFriendButtonLabel()}
            </button>
          )}
        </div>

        {/* Posts */}
        <div className="profile-page-posts">
          <h3 className="profile-posts-title">Posts</h3>
          {posts.length === 0 ? (
            <div className="profile-no-posts">
              <p>No posts yet.</p>
            </div>
          ) : (
            posts.map(post => (
              <div key={post.id} className="post-card">
                <div className="post-header">
                  <div className="post-avatar">
                    {post.avatar_url ? (
                      <img src={post.avatar_url} alt={post.username} className="post-avatar-img" />
                    ) : (
                      post.username ? post.username[0].toUpperCase() : 'U'
                    )}
                  </div>
                  <div className="post-info">
                    <h4>{post.full_name || post.username}</h4>
                    <span>@{post.username} · {formatDate(post.created_at)}</span>
                  </div>
                </div>
                <div className="post-content">
                  <p>{post.content}</p>
                  {post.media_urls && post.media_urls.length > 0 && (
                    <div className={`post-media post-media-${Math.min(post.media_urls.length, 4)}`}>
                      {post.media_urls.map((url, idx) => (
                        isVideoUrl(url) ? (
                          <video key={idx} src={url} controls className="post-media-item" />
                        ) : (
                          <img key={idx} src={url} alt="Post media" className="post-media-item" />
                        )
                      ))}
                    </div>
                  )}
                </div>
                <div className="post-actions">
                  <button className="post-action-btn">
                    ❤️ {post.likes_count || 0}
                  </button>
                  <button className="post-action-btn">
                    💬 {post.comments_count || 0}
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}

export default Profile;
