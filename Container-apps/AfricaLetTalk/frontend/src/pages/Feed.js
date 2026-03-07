import React, { useState, useEffect, useRef, useCallback } from 'react';

function Feed({ user }) {
  const [posts, setPosts] = useState([]);
  const [newPost, setNewPost] = useState('');
  const [selectedImages, setSelectedImages] = useState([]);
  const [imagePreviews, setImagePreviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [posting, setPosting] = useState(false);
  const [error, setError] = useState('');
  const [news, setNews] = useState([]);
  const [newsLoading, setNewsLoading] = useState(true);
  const [newsSource, setNewsSource] = useState('live');
  const [trendingSource, setTrendingSource] = useState('live');
  const [trending, setTrending] = useState([]);
  const [trendingLoading, setTrendingLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('feed');
  const [expandedComments, setExpandedComments] = useState({});
  const [comments, setComments] = useState({});
  const [commentTexts, setCommentTexts] = useState({});
  const [commentLoading, setCommentLoading] = useState({});
  const fileInputRef = useRef(null);

  // Live stream state
  const [liveStreams, setLiveStreams] = useState([]);
  const [isLive, setIsLive] = useState(false);
  const [showGoLiveModal, setShowGoLiveModal] = useState(false);
  const [liveTitle, setLiveTitle] = useState('');
  const [myStream, setMyStream] = useState(null);
  const [liveElapsed, setLiveElapsed] = useState(0);
  const [viewingStream, setViewingStream] = useState(null);
  const videoRef = useRef(null);
  const viewerVideoRef = useRef(null);
  const selfViewRef = useRef(null);
  const mediaStreamRef = useRef(null);
  const timerRef = useRef(null);
  const viewerPollRef = useRef(null);

  // Self-view state
  const [selfViewMinimized, setSelfViewMinimized] = useState(false);

  // Feeling picker state
  const [showFeelingPicker, setShowFeelingPicker] = useState(false);
  const [selectedFeeling, setSelectedFeeling] = useState(null);

  // Location state
  const [postLocation, setPostLocation] = useState(null);
  const [locationLoading, setLocationLoading] = useState(false);
  const [showLocationModal, setShowLocationModal] = useState(false);
  const [manualLocation, setManualLocation] = useState('');

  // Share state
  const [shareToast, setShareToast] = useState('');

  // Live chat state
  const [liveChats, setLiveChats] = useState([]);
  const [liveChatText, setLiveChatText] = useState('');
  const chatPollRef = useRef(null);
  const chatEndRef = useRef(null);
  const lastChatIdRef = useRef(0);

  // Floating emoji reactions
  const [floatingEmojis, setFloatingEmojis] = useState([]);

  // Frame capture for live video streaming
  const frameCanvasRef = useRef(null);
  const frameIntervalRef = useRef(null);
  const [viewerFrameUrl, setViewerFrameUrl] = useState(null);
  const framePollingRef = useRef(null);

  // Friend & suggestion state
  const [suggestedUsers, setSuggestedUsers] = useState([]);
  const [friendRequests, setFriendRequests] = useState([]);
  const [friendsList, setFriendsList] = useState([]);
  const [friendSearchQuery, setFriendSearchQuery] = useState('');
  const [friendSearchResults, setFriendSearchResults] = useState([]);
  const [friendSearching, setFriendSearching] = useState(false);
  const [pendingSentRequests, setPendingSentRequests] = useState(new Set());

  // Friends feed state
  const [friendsPosts, setFriendsPosts] = useState([]);
  const [friendsPostsLoading, setFriendsPostsLoading] = useState(false);

  useEffect(() => {
    document.body.classList.add('feed-active');
    fetchPosts();
    fetchNews();
    fetchTrending();
    fetchLiveStreams();
    fetchSuggestedUsers();
    fetchFriendRequests();
    fetchFriendsList();
    // Poll live streams every 10 seconds
    const liveInterval = setInterval(fetchLiveStreams, 10000);
    return () => {
      document.body.classList.remove('feed-active');
      clearInterval(liveInterval);
      if (mediaStreamRef.current) {
        mediaStreamRef.current.getTracks().forEach(t => t.stop());
      }
      if (timerRef.current) clearInterval(timerRef.current);
      if (chatPollRef.current) clearInterval(chatPollRef.current);
      if (viewerPollRef.current) clearInterval(viewerPollRef.current);
      if (frameIntervalRef.current) clearInterval(frameIntervalRef.current);
      if (framePollingRef.current) clearInterval(framePollingRef.current);
    };
  }, []);

  const fetchPosts = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/posts/feed', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ limit: 20, offset: 0 })
      });

      if (response.ok) {
        const data = await response.json();
        setPosts(data.posts || []);
      } else {
        setError('Failed to load posts');
      }
    } catch (error) {
      console.error('Fetch posts error:', error);
      setError('Network error');
    } finally {
      setLoading(false);
    }
  };

  const fetchFriendsPosts = async () => {
    setFriendsPostsLoading(true);
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/posts/friends-feed', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ limit: 20, offset: 0 })
      });

      if (response.ok) {
        const data = await response.json();
        setFriendsPosts(data.posts || []);
      }
    } catch (error) {
      console.error('Fetch friends posts error:', error);
    } finally {
      setFriendsPostsLoading(false);
    }
  };

  const fetchNews = async () => {
    try {
      const response = await fetch('/api/news');
      if (response.ok) {
        const data = await response.json();
        setNews(data.articles || []);
        setNewsSource(data.source || 'live');
      }
    } catch (error) {
      console.error('Fetch news error:', error);
    } finally {
      setNewsLoading(false);
    }
  };

  const fetchTrending = async () => {
    try {
      const response = await fetch('/api/news/trending');
      if (response.ok) {
        const data = await response.json();
        setTrending(data.trending || []);
        setTrendingSource(data.source || 'live');
      }
    } catch (error) {
      console.error('Fetch trending error:', error);
    } finally {
      setTrendingLoading(false);
    }
  };

  const fetchLiveStreams = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/live/active', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (response.ok) {
        const data = await response.json();
        setLiveStreams(data.streams || []);
      }
    } catch (err) {
      console.error('Fetch live streams error:', err);
    }
  };

  const fetchSuggestedUsers = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/suggestions', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setSuggestedUsers(data.users || []);
      }
    } catch (err) {
      console.error('Fetch suggestions error:', err);
    }
  };

  const fetchFriendRequests = async () => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/requests', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setFriendRequests(data.requests || []);
      }
    } catch (err) {
      console.error('Fetch friend requests error:', err);
    }
  };

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

  const sendFriendRequest = async (toUserId) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/request', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ toUserId })
      });
      if (resp.ok) {
        setPendingSentRequests(prev => new Set([...prev, toUserId]));
        // Remove user from suggestions
        setSuggestedUsers(prev => prev.filter(u => u.id !== toUserId));
        setFriendSearchResults(prev => prev.map(u => u.id === toUserId ? { ...u, _requested: true } : u));
      }
    } catch (err) {
      console.error('Send friend request error:', err);
    }
  };

  const acceptFriendRequest = async (friendshipId) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/accept', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ friendshipId })
      });
      if (resp.ok) {
        fetchFriendRequests();
        fetchFriendsList();
        fetchSuggestedUsers();
      }
    } catch (err) {
      console.error('Accept friend error:', err);
    }
  };

  const rejectFriendRequest = async (friendshipId) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch('/api/friends/remove', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ friendshipId })
      });
      if (resp.ok) {
        fetchFriendRequests();
        fetchSuggestedUsers();
      }
    } catch (err) {
      console.error('Reject friend error:', err);
    }
  };

  const searchFriends = async (q) => {
    setFriendSearchQuery(q);
    if (q.length < 2) {
      setFriendSearchResults([]);
      return;
    }
    setFriendSearching(true);
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch(`/api/users?q=${encodeURIComponent(q)}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        // Filter out self
        setFriendSearchResults((data.users || []).filter(u => u.id !== user.id));
      }
    } catch (err) {
      console.error('Search friends error:', err);
    } finally {
      setFriendSearching(false);
    }
  };

  const startGoLive = async () => {
    try {
      // Request camera + microphone
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { width: 1280, height: 720, facingMode: 'user' },
        audio: true
      });
      mediaStreamRef.current = stream;

      setShowGoLiveModal(true);
      // Set video after modal renders
      setTimeout(() => {
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }
      }, 100);
    } catch (err) {
      console.error('Camera access error:', err);
      setError('Could not access camera. Please allow camera permissions.');
    }
  };

  const confirmGoLive = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/live/start', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ title: liveTitle || 'Live Stream' })
      });

      if (response.ok) {
        const data = await response.json();
        setMyStream(data.stream);
        setIsLive(true);
        setShowGoLiveModal(false);
        setSelfViewMinimized(false);
        setLiveElapsed(0);
        timerRef.current = setInterval(() => {
          setLiveElapsed(prev => prev + 1);
        }, 1000);
        startChatPolling(data.stream.id);
        startViewerPolling(data.stream.id);
        fetchLiveStreams();
        // Attach camera to self-view after render, then start frame capture
        setTimeout(() => {
          if (selfViewRef.current && mediaStreamRef.current) {
            selfViewRef.current.srcObject = mediaStreamRef.current;
          }
          // Start capturing video frames for viewers
          startFrameCapture(data.stream.id);
        }, 100);
      }
    } catch (err) {
      console.error('Go live error:', err);
      setError('Failed to start live stream');
    }
  };

  const stopLive = async () => {
    try {
      const token = localStorage.getItem('token');
      await fetch('/api/live/stop', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
    } catch (err) {
      console.error('Stop live error:', err);
    }

    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach(t => t.stop());
      mediaStreamRef.current = null;
    }
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    stopChatPolling();
    stopViewerPolling();
    stopFrameCapture();
    setIsLive(false);
    setMyStream(null);
    setLiveElapsed(0);
    fetchLiveStreams();
  };

  const cancelGoLive = () => {
    if (mediaStreamRef.current && !isLive) {
      mediaStreamRef.current.getTracks().forEach(t => t.stop());
      mediaStreamRef.current = null;
    }
    setShowGoLiveModal(false);
    setLiveTitle('');
  };

  const watchStream = async (stream) => {
    try {
      const token = localStorage.getItem('token');
      const resp = await fetch(`/api/live/${stream.id}/join`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setViewingStream(data.stream || stream);
      } else {
        setViewingStream(stream);
      }
      startChatPolling(stream.id);
      startViewerPolling(stream.id);
      startFramePolling(stream.id);
    } catch (err) {
      console.error('Watch stream error:', err);
    }
  };

  const leaveStream = async () => {
    if (viewingStream) {
      try {
        const token = localStorage.getItem('token');
        await fetch(`/api/live/${viewingStream.id}/leave`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${token}` }
        });
      } catch (err) {
        console.error('Leave stream error:', err);
      }
    }
    if (mediaStreamRef.current && !isLive) {
      mediaStreamRef.current.getTracks().forEach(t => t.stop());
      mediaStreamRef.current = null;
    }
    stopChatPolling();
    stopViewerPolling();
    stopFramePolling();
    setViewingStream(null);
    setFloatingEmojis([]);
  };

  const formatLiveTime = (seconds) => {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (hrs > 0) return `${hrs}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    return `${mins}:${String(secs).padStart(2, '0')}`;
  };

  // Start polling chat for a stream
  const startChatPolling = (streamId) => {
    setLiveChats([]);
    lastChatIdRef.current = 0;
    const poll = async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch(`/api/live/${streamId}/chat?since_id=${lastChatIdRef.current}`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (response.ok) {
          const data = await response.json();
          if (data.chats && data.chats.length > 0) {
            setLiveChats(prev => [...prev, ...data.chats]);
            lastChatIdRef.current = data.chats[data.chats.length - 1].id;
            // Show floating emojis for emoji-only messages from OTHER users
            data.chats.forEach(chat => {
              if (chat.user_id !== user.id && chat.message && chat.message.length <= 2) {
                const id = Date.now() + Math.random();
                const left = 10 + Math.random() * 80;
                setFloatingEmojis(prev => [...prev, { id, emoji: chat.message, left }]);
                setTimeout(() => {
                  setFloatingEmojis(prev => prev.filter(e => e.id !== id));
                }, 2500);
              }
            });
            setTimeout(() => {
              if (chatEndRef.current) chatEndRef.current.scrollIntoView({ behavior: 'smooth' });
            }, 50);
          }
        }
      } catch (err) {
        console.error('Chat poll error:', err);
      }
    };
    poll();
    chatPollRef.current = setInterval(poll, 2000);
  };

  const stopChatPolling = () => {
    if (chatPollRef.current) {
      clearInterval(chatPollRef.current);
      chatPollRef.current = null;
    }
    setLiveChats([]);
    setLiveChatText('');
    lastChatIdRef.current = 0;
  };

  const sendLiveChat = async (streamId) => {
    if (!liveChatText.trim()) return;
    try {
      const token = localStorage.getItem('token');
      await fetch(`/api/live/${streamId}/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ message: liveChatText })
      });
      setLiveChatText('');
    } catch (err) {
      console.error('Send chat error:', err);
    }
  };

  // Poll viewer count for broadcaster or viewer
  const startViewerPolling = (streamId) => {
    if (viewerPollRef.current) clearInterval(viewerPollRef.current);
    const poll = async () => {
      try {
        const token = localStorage.getItem('token');
        const resp = await fetch(`/api/live/${streamId}/info`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (resp.ok) {
          const data = await resp.json();
          if (data.stream) {
            // Always update both — whichever is non-null will get the new count
            setMyStream(prev => prev ? { ...prev, viewer_count: data.stream.viewer_count } : prev);
            setViewingStream(prev => prev ? { ...prev, viewer_count: data.stream.viewer_count } : prev);
          }
        }
      } catch (err) {
        // silent
      }
    };
    poll(); // Run immediately
    viewerPollRef.current = setInterval(poll, 3000);
  };

  const stopViewerPolling = () => {
    if (viewerPollRef.current) {
      clearInterval(viewerPollRef.current);
      viewerPollRef.current = null;
    }
  };

  // Send emoji reaction (sends as chat + shows floating emoji)
  const sendEmojiReaction = async (streamId, emoji) => {
    // Show floating emoji animation
    const id = Date.now() + Math.random();
    const left = 10 + Math.random() * 80;
    setFloatingEmojis(prev => [...prev, { id, emoji, left }]);
    setTimeout(() => {
      setFloatingEmojis(prev => prev.filter(e => e.id !== id));
    }, 2500);

    // Also send as a chat message
    try {
      const token = localStorage.getItem('token');
      await fetch(`/api/live/${streamId}/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ message: emoji })
      });
    } catch (err) {
      console.error('Send emoji error:', err);
    }
  };

  // Frame capture: streamer periodically captures video frames and uploads them
  const startFrameCapture = (streamId) => {
    if (frameIntervalRef.current) clearInterval(frameIntervalRef.current);
    const canvas = document.createElement('canvas');
    canvas.width = 640;
    canvas.height = 480;
    frameCanvasRef.current = canvas;
    let uploading = false;

    const captureAndUpload = () => {
      if (uploading) return; // skip if previous upload still in flight
      const video = selfViewRef.current;
      if (!video || !video.srcObject) return;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(async (blob) => {
        if (!blob) return;
        uploading = true;
        try {
          const token = localStorage.getItem('token');
          const formData = new FormData();
          formData.append('frame', blob, 'frame.jpg');
          await fetch(`/api/live/${streamId}/frame`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` },
            body: formData
          });
        } catch (err) {
          // silent - frame capture is best-effort
        } finally {
          uploading = false;
        }
      }, 'image/jpeg', 0.6);
    };

    // Start capturing after a short delay for video to initialize
    setTimeout(captureAndUpload, 300);
    frameIntervalRef.current = setInterval(captureAndUpload, 500);
  };

  const stopFrameCapture = () => {
    if (frameIntervalRef.current) {
      clearInterval(frameIntervalRef.current);
      frameIntervalRef.current = null;
    }
    frameCanvasRef.current = null;
  };

  // Frame polling: viewer polls for the latest video frame from the streamer
  // Uses image preloading to avoid flicker — old frame stays visible until new one loads
  const startFramePolling = (streamId) => {
    if (framePollingRef.current) clearInterval(framePollingRef.current);
    // Set initial frame URL
    setViewerFrameUrl(`/uploads/frames/stream-${streamId}.jpg?t=${Date.now()}`);
    framePollingRef.current = setInterval(() => {
      const newUrl = `/uploads/frames/stream-${streamId}.jpg?t=${Date.now()}`;
      const img = new Image();
      img.onload = () => setViewerFrameUrl(newUrl);
      img.onerror = () => { /* keep current frame on error */ };
      img.src = newUrl;
    }, 600);
  };

  const stopFramePolling = () => {
    if (framePollingRef.current) {
      clearInterval(framePollingRef.current);
      framePollingRef.current = null;
    }
    setViewerFrameUrl(null);
  };

  // Feeling options
  const feelings = [
    { emoji: '😊', label: 'Happy' },
    { emoji: '😍', label: 'Loved' },
    { emoji: '🥳', label: 'Celebrating' },
    { emoji: '😤', label: 'Frustrated' },
    { emoji: '😢', label: 'Sad' },
    { emoji: '🤔', label: 'Thoughtful' },
    { emoji: '😴', label: 'Tired' },
    { emoji: '🙏', label: 'Grateful' },
    { emoji: '💪', label: 'Motivated' },
    { emoji: '🤩', label: 'Excited' },
    { emoji: '😎', label: 'Cool' },
    { emoji: '🥰', label: 'Blessed' },
  ];

  const handleSelectFeeling = (feeling) => {
    setSelectedFeeling(feeling);
    setShowFeelingPicker(false);
  };

  const clearFeeling = () => {
    setSelectedFeeling(null);
  };

  // Location handler - auto-fetches city & state via GPS, falls back to manual modal
  const handleGetLocation = () => {
    if (postLocation) {
      setPostLocation(null);
      return;
    }
    if (navigator.geolocation) {
      setLocationLoading(true);
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          try {
            // Use backend proxy to avoid CORS/mixed-content issues
            const resp = await fetch(`/api/geocode/reverse?lat=${latitude}&lon=${longitude}`);
            if (resp.ok) {
              const data = await resp.json();
              const addr = data.address || {};
              const city = addr.city || addr.town || addr.village || addr.county || '';
              const state = addr.state || '';
              const country = addr.country || '';
              const locationName = [city, state, country].filter(Boolean).join(', ');
              if (locationName) {
                setPostLocation(locationName);
                setLocationLoading(false);
                return;
              }
            }
          } catch {
            // Geocoding failed
          }
          // If geocoding didn't produce a name, show manual modal
          setLocationLoading(false);
          setShowLocationModal(true);
        },
        () => {
          // GPS permission denied or failed — show manual modal
          setLocationLoading(false);
          setShowLocationModal(true);
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    } else {
      setShowLocationModal(true);
    }
  };

  const handleSetManualLocation = () => {
    if (manualLocation.trim()) {
      setPostLocation(manualLocation.trim());
      setManualLocation('');
      setShowLocationModal(false);
    }
  };

  // Popular African cities for quick selection
  const popularLocations = [
    'Lagos, Nigeria', 'Nairobi, Kenya', 'Johannesburg, South Africa',
    'Accra, Ghana', 'Addis Ababa, Ethiopia', 'Cairo, Egypt',
    'Dar es Salaam, Tanzania', 'Kinshasa, DRC', 'Casablanca, Morocco',
    'Kampala, Uganda', 'Dakar, Senegal', 'Kigali, Rwanda'
  ];

  // Sidebar profile photo upload
  const handleSidebarAvatarUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
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
        // Trigger App-level user update if prop available
        if (window.__updateUser) window.__updateUser(data.user);
        // Optimistically update avatar in UI via page reload workaround
        window.location.reload();
      } else {
        const err = await resp.json();
        alert(err.error || 'Failed to upload photo');
      }
    } catch (err) {
      alert('Failed to upload photo');
    }
    e.target.value = '';
  };

  // Share handler
  const handleSharePost = async (post) => {
    const shareText = `${post.full_name || post.username} on LetsConnect:\n\n${post.content}`;
    const shareUrl = window.location.origin + '/feed';

    if (navigator.share) {
      try {
        await navigator.share({
          title: 'LetsConnect Post',
          text: shareText,
          url: shareUrl,
        });
      } catch (err) {
        if (err.name !== 'AbortError') {
          console.error('Share error:', err);
        }
      }
    } else {
      try {
        await navigator.clipboard.writeText(shareText + '\n' + shareUrl);
        setShareToast('Link copied to clipboard!');
        setTimeout(() => setShareToast(''), 3000);
      } catch {
        setShareToast('Could not copy link');
        setTimeout(() => setShareToast(''), 3000);
      }
    }
  };

  const handleImageSelect = (e) => {
    const files = Array.from(e.target.files).slice(0, 4);
    setSelectedImages(files);

    const previews = files.map(file => URL.createObjectURL(file));
    setImagePreviews(previews);
  };

  const removeImage = (index) => {
    setSelectedImages(prev => prev.filter((_, i) => i !== index));
    setImagePreviews(prev => {
      URL.revokeObjectURL(prev[index]);
      return prev.filter((_, i) => i !== index);
    });
  };

  const handleCreatePost = async (e) => {
    e.preventDefault();
    if (!newPost.trim() && selectedImages.length === 0) return;

    setPosting(true);
    try {
      const token = localStorage.getItem('token');
      const formData = new FormData();
      let fullContent = newPost;
      if (selectedFeeling) {
        fullContent += ` — ${selectedFeeling.emoji} feeling ${selectedFeeling.label}`;
      }
      if (postLocation) {
        fullContent += ` — 📍 ${postLocation}`;
      }
      formData.append('content', fullContent);
      selectedImages.forEach(file => formData.append('images', file));

      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });

      if (response.ok) {
        setNewPost('');
        setSelectedImages([]);
        setSelectedFeeling(null);
        setPostLocation(null);
        imagePreviews.forEach(url => URL.revokeObjectURL(url));
        setImagePreviews([]);
        fetchPosts();
      } else {
        setError('Failed to create post');
      }
    } catch (error) {
      console.error('Create post error:', error);
      setError('Network error');
    } finally {
      setPosting(false);
    }
  };

  const handleLikePost = async (postId) => {
    try {
      const token = localStorage.getItem('token');
      await fetch(`/api/posts/${postId}/like`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      fetchPosts();
    } catch (error) {
      console.error('Like post error:', error);
    }
  };

  const toggleComments = async (postId) => {
    const isOpen = expandedComments[postId];
    setExpandedComments(prev => ({ ...prev, [postId]: !isOpen }));

    if (!isOpen && !comments[postId]) {
      setCommentLoading(prev => ({ ...prev, [postId]: true }));
      try {
        const token = localStorage.getItem('token');
        const response = await fetch(`/api/posts/${postId}/comments`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (response.ok) {
          const data = await response.json();
          setComments(prev => ({ ...prev, [postId]: data.comments || [] }));
        }
      } catch (err) {
        console.error('Fetch comments error:', err);
      } finally {
        setCommentLoading(prev => ({ ...prev, [postId]: false }));
      }
    }
  };

  const handleAddComment = async (postId) => {
    const text = commentTexts[postId];
    if (!text || !text.trim()) return;

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/posts/${postId}/comments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ content: text })
      });

      if (response.ok) {
        const data = await response.json();
        setComments(prev => ({
          ...prev,
          [postId]: [...(prev[postId] || []), data.comment]
        }));
        setCommentTexts(prev => ({ ...prev, [postId]: '' }));
        fetchPosts(); // refresh comment count
      }
    } catch (err) {
      console.error('Add comment error:', err);
    }
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

  const formatNewsDate = (dateStr) => {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const now = new Date();
    const diffHours = Math.floor((now - date) / (1000 * 60 * 60));
    if (diffHours < 1) return 'Just now';
    if (diffHours < 24) return `${diffHours}h ago`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="loading-spinner"></div>
        <p>Loading your feed...</p>
      </div>
    );
  }

  return (
    <>
    <div className="feed-page">
      <div className="feed-layout">
        {/* Left Sidebar */}
        <div className="feed-sidebar feed-sidebar-left">
          <div className="profile-card">
            <div className="profile-cover">
              <div className="profile-cover-pattern"></div>
            </div>
            <div className="profile-card-body">
              <div className="profile-card-avatar-wrapper">
                <div className="profile-card-avatar">
                  {user.avatar_url ? (
                    <img src={user.avatar_url} alt="avatar" className="profile-card-avatar-img" />
                  ) : (
                    user.username ? user.username[0].toUpperCase() : 'U'
                  )}
                </div>
                <label className="profile-card-avatar-upload" title="Change profile photo">
                  📷
                  <input
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={handleSidebarAvatarUpload}
                  />
                </label>
              </div>
              <h4>{user.full_name || user.username}</h4>
              <p className="profile-handle">@{user.username}</p>
              <div className="profile-stats">
                <div className="profile-stat">
                  <span className="profile-stat-num">{posts.filter(p => p.username === user.username).length}</span>
                  <span className="profile-stat-label">Posts</span>
                </div>
                <div className="profile-stat">
                  <span className="profile-stat-num">{friendsList.length}</span>
                  <span className="profile-stat-label">Friends</span>
                </div>
                <div className="profile-stat">
                  <span className="profile-stat-num">{posts.reduce((acc, p) => p.username === user.username ? acc + (parseInt(p.likes_count) || 0) : acc, 0)}</span>
                  <span className="profile-stat-label">Likes</span>
                </div>
              </div>
            </div>
          </div>

          <div className="sidebar-card sidebar-nav-card">
            <h4>Explore</h4>
            <button
              className={`sidebar-nav-btn ${activeTab === 'feed' ? 'active' : ''}`}
              onClick={() => setActiveTab('feed')}
            >
              <span className="sidebar-nav-icon">🏠</span> My Feed
            </button>
            <button
              className={`sidebar-nav-btn ${activeTab === 'friends' ? 'active' : ''}`}
              onClick={() => { setActiveTab('friends'); fetchFriendsPosts(); }}
            >
              <span className="sidebar-nav-icon">👥</span> Friends Feed
            </button>
            <button
              className={`sidebar-nav-btn ${activeTab === 'trending' ? 'active' : ''}`}
              onClick={() => setActiveTab('trending')}
            >
              <span className="sidebar-nav-icon">🔥</span> Trending
            </button>
            <button
              className={`sidebar-nav-btn ${activeTab === 'news' ? 'active' : ''}`}
              onClick={() => setActiveTab('news')}
            >
              <span className="sidebar-nav-icon">📰</span> Latest News
            </button>
          </div>

          <div className="sidebar-card">
            <h4>Trending Now</h4>
            {trendingLoading ? (
              <p className="news-loading-text">Loading...</p>
            ) : trending.length > 0 ? (
              trending.slice(0, 5).map((item, i) => (
                <a key={i} href={item.link} target="_blank" rel="noopener noreferrer" className="trending-item">
                  <span className="trending-category-badge">{item.category}</span>
                  <span className="trending-tag">{item.title.length > 50 ? item.title.substring(0, 50) + '...' : item.title}</span>
                  <span className="trending-count">{item.source}</span>
                </a>
              ))
            ) : (
              <p className="news-loading-text">No trending stories</p>
            )}
          </div>

          {/* Live Now Section */}
          {liveStreams.length > 0 && (
            <div className="sidebar-card live-now-card">
              <h4><span className="live-pulse"></span> Live Now</h4>
              {liveStreams.map(stream => (
                <div
                  key={stream.id}
                  className="live-stream-item"
                  onClick={() => stream.user_id !== user.id && watchStream(stream)}
                >
                  <div className="live-stream-avatar">
                    {stream.username ? stream.username[0].toUpperCase() : 'U'}
                    <span className="live-badge-mini">LIVE</span>
                  </div>
                  <div className="live-stream-info">
                    <span className="live-stream-name">{stream.full_name || stream.username}</span>
                    <span className="live-stream-title">{stream.title}</span>
                    <span className="live-stream-viewers">👁 {stream.viewer_count} watching</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Main Content */}
        <div className="feed-main">
          {error && <div className="error">{error}</div>}

          {/* Live Streams Row */}
          {liveStreams.length > 0 && activeTab === 'feed' && (
            <div className="live-streams-feed">
              {liveStreams.map(stream => (
                <div
                  key={stream.id}
                  className="live-feed-card"
                  onClick={() => stream.user_id !== user.id && watchStream(stream)}
                >
                  <div className="live-feed-card-avatar">
                    {stream.username ? stream.username[0].toUpperCase() : 'U'}
                  </div>
                  <span className="live-feed-card-name">{stream.full_name || stream.username}</span>
                  <span className="live-feed-card-viewers">👁 {stream.viewer_count} watching</span>
                </div>
              ))}
            </div>
          )}

          {/* Tab Content */}
          {activeTab === 'feed' && (
            <>
              {/* Create Post */}
              <div className="create-post">
                <div className="create-post-top">
                  <div className="create-post-avatar">
                    {user.username ? user.username[0].toUpperCase() : 'U'}
                  </div>
                  <span className="create-post-greeting">What's on your mind, {user.full_name || user.username}?</span>
                </div>
                <form onSubmit={handleCreatePost}>
                  <textarea
                    placeholder="Share your thoughts, stories, or photos..."
                    value={newPost}
                    onChange={(e) => setNewPost(e.target.value)}
                    rows={3}
                  />

                  {/* Image Previews */}
                  {imagePreviews.length > 0 && (
                    <div className="image-preview-grid">
                      {imagePreviews.map((preview, index) => (
                        <div key={index} className="image-preview-item">
                          <img src={preview} alt={`Preview ${index + 1}`} />
                          <button
                            type="button"
                            className="image-preview-remove"
                            onClick={() => removeImage(index)}
                          >
                            ✕
                          </button>
                        </div>
                      ))}
                    </div>
                  )}

                  <div className="create-post-actions">
                    <div className="create-post-buttons">
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept="image/*"
                        multiple
                        onChange={handleImageSelect}
                        style={{ display: 'none' }}
                      />
                      <button
                        type="button"
                        className="create-post-btn"
                        onClick={() => fileInputRef.current.click()}
                      >
                        📷 Photo
                      </button>
                      <button
                        type="button"
                        className={`create-post-btn ${selectedFeeling ? 'active' : ''}`}
                        onClick={() => setShowFeelingPicker(!showFeelingPicker)}
                      >
                        {selectedFeeling ? `${selectedFeeling.emoji} ${selectedFeeling.label}` : '😊 Feeling'}
                      </button>
                      <button
                        type="button"
                        className={`create-post-btn ${postLocation ? 'active' : ''}`}
                        onClick={handleGetLocation}
                        disabled={locationLoading}
                      >
                        {locationLoading ? '⏳ Getting...' : postLocation ? `📍 ${postLocation}` : '📍 Location'}
                      </button>
                      <button
                        type="button"
                        className="create-post-btn go-live-btn"
                        onClick={startGoLive}
                        disabled={isLive}
                      >
                        🔴 {isLive ? 'You\'re Live!' : 'Go Live'}
                      </button>
                    </div>
                    <button
                      type="submit"
                      className="btn-post"
                      disabled={posting || (!newPost.trim() && selectedImages.length === 0)}
                    >
                      {posting ? 'Posting...' : 'Post'}
                    </button>
                  </div>

                  {/* Feeling Picker Popup */}
                  {showFeelingPicker && (
                    <div className="feeling-picker">
                      <div className="feeling-picker-header">
                        <span>How are you feeling?</span>
                        <button type="button" className="feeling-picker-close" onClick={() => setShowFeelingPicker(false)}>✕</button>
                      </div>
                      <div className="feeling-picker-grid">
                        {feelings.map((f, i) => (
                          <button
                            key={i}
                            type="button"
                            className={`feeling-option ${selectedFeeling?.label === f.label ? 'selected' : ''}`}
                            onClick={() => handleSelectFeeling(f)}
                          >
                            <span className="feeling-emoji">{f.emoji}</span>
                            <span className="feeling-label">{f.label}</span>
                          </button>
                        ))}
                      </div>
                      {selectedFeeling && (
                        <button type="button" className="feeling-clear" onClick={clearFeeling}>Clear feeling</button>
                      )}
                    </div>
                  )}

                  {/* Selected feeling / location tags */}
                  {(selectedFeeling || postLocation) && (
                    <div className="post-tags-row">
                      {selectedFeeling && (
                        <span className="post-tag">
                          {selectedFeeling.emoji} {selectedFeeling.label}
                          <button type="button" onClick={clearFeeling}>✕</button>
                        </span>
                      )}
                      {postLocation && (
                        <span className="post-tag">
                          📍 {postLocation}
                          <button type="button" onClick={() => setPostLocation(null)}>✕</button>
                        </span>
                      )}
                    </div>
                  )}
                </form>
              </div>

              {/* Posts */}
              {posts.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-state-icon">✍️</div>
                  <h3>Your feed is empty</h3>
                  <p>Be the first to share something with the community!</p>
                </div>
              ) : (
                posts.map((post) => (
                  <div key={post.id} className="post-card">
                    <div className="post-header">
                      <div className="post-avatar">
                        {post.username ? post.username[0].toUpperCase() : 'U'}
                      </div>
                      <div className="post-info">
                        <h4>{post.full_name || post.username}</h4>
                        <span>@{post.username} · {formatDate(post.created_at)}</span>
                      </div>
                      <button className="post-menu-btn">⋯</button>
                    </div>
                    <div className="post-content">
                      <p>{post.content}</p>
                      {/* Post Images */}
                      {post.media_urls && post.media_urls.length > 0 && (
                        <div className={`post-images post-images-${Math.min(post.media_urls.length, 4)}`}>
                          {post.media_urls.map((url, i) => (
                            <img key={i} src={url} alt="Post media" className="post-image" />
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="post-engagement">
                      {(parseInt(post.likes_count) > 0 || parseInt(post.comments_count) > 0) && (
                        <div className="post-engagement-info">
                          {parseInt(post.likes_count) > 0 && (
                            <span>❤️ {post.likes_count} {parseInt(post.likes_count) === 1 ? 'like' : 'likes'}</span>
                          )}
                          {parseInt(post.comments_count) > 0 && (
                            <span>{post.comments_count} {parseInt(post.comments_count) === 1 ? 'comment' : 'comments'}</span>
                          )}
                        </div>
                      )}
                    </div>
                    <div className="post-actions">
                      <button
                        onClick={() => handleLikePost(post.id)}
                        className={post.is_liked ? 'liked' : ''}
                      >
                        {post.is_liked ? '❤️' : '🤍'} Like
                      </button>
                      <button onClick={() => toggleComments(post.id)}>
                        💬 Comment
                      </button>
                      <button onClick={() => handleSharePost(post)}>🔄 Share</button>
                      <button>🔖 Save</button>
                    </div>

                    {/* Comments Section */}
                    {expandedComments[post.id] && (
                      <div className="comments-section">
                        {commentLoading[post.id] ? (
                          <div className="comments-loading">Loading comments...</div>
                        ) : (
                          <>
                            {(comments[post.id] || []).map((c) => (
                              <div key={c.id} className="comment-item">
                                <div className="comment-avatar">
                                  {c.username ? c.username[0].toUpperCase() : 'U'}
                                </div>
                                <div className="comment-body">
                                  <div className="comment-bubble">
                                    <span className="comment-author">{c.full_name || c.username}</span>
                                    <p>{c.content}</p>
                                  </div>
                                  <span className="comment-time">{formatDate(c.created_at)}</span>
                                </div>
                              </div>
                            ))}
                            <div className="comment-input-row">
                              <div className="comment-input-avatar">
                                {user.username ? user.username[0].toUpperCase() : 'U'}
                              </div>
                              <input
                                type="text"
                                placeholder="Write a comment..."
                                value={commentTexts[post.id] || ''}
                                onChange={(e) => setCommentTexts(prev => ({ ...prev, [post.id]: e.target.value }))}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter' && !e.shiftKey) {
                                    e.preventDefault();
                                    handleAddComment(post.id);
                                  }
                                }}
                              />
                              <button
                                className="comment-send-btn"
                                onClick={() => handleAddComment(post.id)}
                                disabled={!commentTexts[post.id]?.trim()}
                              >
                                ➤
                              </button>
                            </div>
                          </>
                        )}
                      </div>
                    )}
                  </div>
                ))
              )}
            </>
          )}

          {activeTab === 'friends' && (
            <>
              <div className="friends-feed-header">
                <h3>👥 Friends Feed</h3>
                <p>See what your friends have been sharing</p>
              </div>
              {friendsPostsLoading ? (
                <div className="loading">
                  <div className="loading-spinner"></div>
                  <p>Loading friends' posts...</p>
                </div>
              ) : friendsPosts.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-state-icon">👥</div>
                  <h3>No posts from friends yet</h3>
                  <p>Add friends to see their posts here!</p>
                </div>
              ) : (
                friendsPosts.map((post) => (
                  <div key={post.id} className="post-card">
                    <div className="post-header">
                      <div className="post-avatar">
                        {post.username ? post.username[0].toUpperCase() : 'U'}
                      </div>
                      <div className="post-info">
                        <h4>{post.full_name || post.username} <span className="friend-badge">Friend</span></h4>
                        <span>@{post.username} · {formatDate(post.created_at)}</span>
                      </div>
                      <button className="post-menu-btn">⋯</button>
                    </div>
                    <div className="post-content">
                      <p>{post.content}</p>
                      {post.media_urls && post.media_urls.length > 0 && (
                        <div className={`post-images post-images-${Math.min(post.media_urls.length, 4)}`}>
                          {post.media_urls.map((url, i) => (
                            <img key={i} src={url} alt="Post media" className="post-image" />
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="post-engagement">
                      {(parseInt(post.likes_count) > 0 || parseInt(post.comments_count) > 0) && (
                        <div className="post-engagement-info">
                          {parseInt(post.likes_count) > 0 && (
                            <span>❤️ {post.likes_count} {parseInt(post.likes_count) === 1 ? 'like' : 'likes'}</span>
                          )}
                          {parseInt(post.comments_count) > 0 && (
                            <span>{post.comments_count} {parseInt(post.comments_count) === 1 ? 'comment' : 'comments'}</span>
                          )}
                        </div>
                      )}
                    </div>
                    <div className="post-actions">
                      <button
                        onClick={() => handleLikePost(post.id)}
                        className={post.is_liked ? 'liked' : ''}
                      >
                        {post.is_liked ? '❤️' : '🤍'} Like
                      </button>
                      <button onClick={() => toggleComments(post.id)}>
                        💬 Comment
                      </button>
                      <button onClick={() => handleSharePost(post)}>🔄 Share</button>
                      <button>🔖 Save</button>
                    </div>

                    {expandedComments[post.id] && (
                      <div className="comments-section">
                        {commentLoading[post.id] ? (
                          <div className="comments-loading">Loading comments...</div>
                        ) : (
                          <>
                            {(comments[post.id] || []).map((c) => (
                              <div key={c.id} className="comment-item">
                                <div className="comment-avatar">
                                  {c.username ? c.username[0].toUpperCase() : 'U'}
                                </div>
                                <div className="comment-body">
                                  <div className="comment-bubble">
                                    <span className="comment-author">{c.full_name || c.username}</span>
                                    <p>{c.content}</p>
                                  </div>
                                  <span className="comment-time">{formatDate(c.created_at)}</span>
                                </div>
                              </div>
                            ))}
                            <div className="comment-input-row">
                              <div className="comment-input-avatar">
                                {user.username ? user.username[0].toUpperCase() : 'U'}
                              </div>
                              <input
                                type="text"
                                placeholder="Write a comment..."
                                value={commentTexts[post.id] || ''}
                                onChange={(e) => setCommentTexts(prev => ({ ...prev, [post.id]: e.target.value }))}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter' && !e.shiftKey) {
                                    e.preventDefault();
                                    handleAddComment(post.id);
                                  }
                                }}
                              />
                              <button
                                className="comment-send-btn"
                                onClick={() => handleAddComment(post.id)}
                                disabled={!commentTexts[post.id]?.trim()}
                              >
                                ➤
                              </button>
                            </div>
                          </>
                        )}
                      </div>
                    )}
                  </div>
                ))
              )}
            </>
          )}

          {activeTab === 'news' && (
            <div className="news-feed">
              <div className="news-feed-header">
                <h3>📰 Latest News</h3>
                <p>Stay informed with the latest stories from around the world</p>
              </div>
              {newsSource === 'fallback' && (
                <div className="news-fallback-banner">
                  ⚠️ Live news feeds are temporarily unavailable. Showing curated stories. Check your ECS outbound network configuration.
                </div>
              )}
              {newsLoading ? (
                <div className="loading">
                  <div className="loading-spinner"></div>
                  <p>Loading news...</p>
                </div>
              ) : news.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-state-icon">📰</div>
                  <h3>No news available</h3>
                  <p>Check back later for the latest stories</p>
                </div>
              ) : (
                <div className="news-grid">
                  {news.map((article, index) => (
                    <a
                      key={index}
                      href={article.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={`news-card ${index === 0 ? 'news-card-featured' : ''}`}
                    >
                      {article.thumbnail && (
                        <div className="news-card-image">
                          <img src={article.thumbnail} alt="" onError={(e) => e.target.style.display = 'none'} />
                        </div>
                      )}
                      <div className="news-card-body">
                        <span className="news-source">{article.source}</span>
                        <h4>{article.title}</h4>
                        {(index === 0 && article.description) && (
                          <p className="news-desc">{article.description}</p>
                        )}
                        <span className="news-time">{formatNewsDate(article.pubDate)}</span>
                      </div>
                    </a>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'trending' && (
            <div className="trending-feed">
              <div className="news-feed-header">
                <h3>🔥 Trending Now</h3>
                <p>Top stories from Africa and around the world right now</p>
              </div>
              {trendingLoading ? (
                <div className="loading">
                  <div className="loading-spinner"></div>
                  <p>Loading trending stories...</p>
                </div>
              ) : trending.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-state-icon">🔥</div>
                  <h3>No trending stories</h3>
                  <p>Check back later for the latest trending topics</p>
                </div>
              ) : (
                <div className="trending-stories-grid">
                  {trending.map((story, index) => (
                    <a
                      key={index}
                      href={story.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={`trending-story-card ${index === 0 ? 'trending-story-featured' : ''}`}
                    >
                      {story.thumbnail && (
                        <div className="trending-story-image">
                          <img src={story.thumbnail} alt="" onError={(e) => e.target.style.display = 'none'} />
                        </div>
                      )}
                      <div className="trending-story-body">
                        <div className="trending-story-meta">
                          <span className="trending-story-category">{story.category}</span>
                          <span className="trending-story-source">{story.source}</span>
                        </div>
                        <h4>{story.title}</h4>
                        {(index === 0 && story.description) && (
                          <p className="trending-story-desc">{story.description}</p>
                        )}
                        <span className="trending-story-time">{formatNewsDate(story.pubDate)}</span>
                      </div>
                    </a>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Right Sidebar */}
        <div className="feed-sidebar feed-sidebar-right">
          {/* News Widget */}
          <div className="sidebar-card news-widget">
            <div className="news-widget-header">
              <h4>📰 Latest News</h4>
              <button className="news-see-all" onClick={() => setActiveTab('news')}>See all</button>
            </div>
            {newsLoading ? (
              <p className="news-loading-text">Loading...</p>
            ) : news.length > 0 ? (
              news.slice(0, 4).map((article, index) => (
                <a
                  key={index}
                  href={article.link}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="news-widget-item"
                >
                  <div className="news-widget-text">
                    <span className="news-widget-source">{article.source}</span>
                    <h5>{article.title}</h5>
                    <span className="news-widget-time">{formatNewsDate(article.pubDate)}</span>
                  </div>
                  {article.thumbnail && (
                    <img src={article.thumbnail} alt="" className="news-widget-thumb" onError={(e) => e.target.style.display = 'none'} />
                  )}
                </a>
              ))
            ) : (
              <p className="news-loading-text">No news available</p>
            )}
          </div>

          <div className="sidebar-card">
            <h4>🔍 Find Friends</h4>
            <input
              type="text"
              className="friend-search-input"
              placeholder="Search by name or username..."
              value={friendSearchQuery}
              onChange={e => searchFriends(e.target.value)}
            />
            {friendSearching && <p className="news-loading-text">Searching...</p>}
            {friendSearchResults.length > 0 && (
              <div className="friend-search-results">
                {friendSearchResults.map(u => {
                  const isFriend = friendsList.some(f => f.id === u.id);
                  const isPending = pendingSentRequests.has(u.id) || u._requested;
                  return (
                    <div key={u.id} className="suggested-user">
                      <div className="suggested-avatar" style={{ background: '#2D6A4F' }}>
                        {u.avatar_url ? (
                          <img src={u.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                        ) : (
                          (u.full_name || u.username || 'U')[0].toUpperCase()
                        )}
                      </div>
                      <div className="suggested-info">
                        <span className="suggested-name">{u.full_name || u.username}</span>
                        <span className="suggested-handle">@{u.username}</span>
                      </div>
                      {isFriend ? (
                        <span className="friend-status-badge">✓ Friends</span>
                      ) : isPending ? (
                        <span className="friend-status-badge pending">Pending</span>
                      ) : (
                        <button className="btn-add-friend" onClick={() => sendFriendRequest(u.id)}>+ Add</button>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
            {friendSearchQuery.length >= 2 && !friendSearching && friendSearchResults.length === 0 && (
              <p className="news-loading-text">No users found</p>
            )}
          </div>

          {/* Pending Friend Requests */}
          {friendRequests.length > 0 && (
            <div className="sidebar-card">
              <h4>👥 Friend Requests ({friendRequests.length})</h4>
              {friendRequests.map(req => (
                <div key={req.friendship_id} className="suggested-user friend-request-item">
                  <div className="suggested-avatar" style={{ background: '#6366F1' }}>
                    {req.avatar_url ? (
                      <img src={req.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                    ) : (
                      (req.full_name || req.username || 'U')[0].toUpperCase()
                    )}
                  </div>
                  <div className="suggested-info">
                    <span className="suggested-name">{req.full_name || req.username}</span>
                    <span className="suggested-handle">@{req.username}</span>
                  </div>
                  <div className="friend-request-actions">
                    <button className="btn-accept-friend" onClick={() => acceptFriendRequest(req.friendship_id)}>✓</button>
                    <button className="btn-reject-friend" onClick={() => rejectFriendRequest(req.friendship_id)}>✕</button>
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="sidebar-card">
            <h4>Suggested Connections</h4>
            {suggestedUsers.length === 0 ? (
              <p className="news-loading-text">No suggestions right now</p>
            ) : (
              suggestedUsers.slice(0, 5).map(u => (
                <div key={u.id} className="suggested-user">
                  <div className="suggested-avatar" style={{ background: '#2D6A4F' }}>
                    {u.avatar_url ? (
                      <img src={u.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                    ) : (
                      (u.full_name || u.username || 'U')[0].toUpperCase()
                    )}
                  </div>
                  <div className="suggested-info">
                    <span className="suggested-name">{u.full_name || u.username}</span>
                    <span className="suggested-handle">@{u.username}</span>
                  </div>
                  <button className="btn-add-friend" onClick={() => sendFriendRequest(u.id)}>+ Add</button>
                </div>
              ))
            )}
          </div>

          <div className="sidebar-card sidebar-footer">
            <div className="sidebar-footer-links">
              <a href="#">About LetsConnect</a>
              <a href="#">Privacy</a>
              <a href="#">Terms</a>
              <a href="#">Help</a>
            </div>
            <p className="sidebar-copyright">© 2026 LetsConnect</p>
          </div>
        </div>
      </div>
    </div>

      {/* Streamer Overlay - shows when you're live */}
      {isLive && (
        <div className="live-streamer-bar">
          <div className="live-streamer-bar-left">
            <span className="live-badge-animated">● LIVE</span>
            <span className="live-timer">{formatLiveTime(liveElapsed)}</span>
            <span className="live-viewer-count">👁 {myStream?.viewer_count || 0} viewers</span>
          </div>
          <div className="live-streamer-bar-right">
            <span className="live-stream-title-bar">{myStream?.title || 'Live Stream'}</span>
            <button className="end-live-btn" onClick={stopLive}>End Stream</button>
          </div>
        </div>
      )}

      {/* Self-View Camera Preview - picture-in-picture while live */}
      {isLive && mediaStreamRef.current && (
        <div className={`self-view-container ${selfViewMinimized ? 'self-view-minimized' : ''}`}>
          {!selfViewMinimized && (
            <>
              <video
                ref={selfViewRef}
                autoPlay
                muted
                playsInline
                className="self-view-video"
              />
              <div className="self-view-label">You</div>
            </>
          )}
          <div className="self-view-controls">
            <button
              className="self-view-toggle"
              onClick={() => setSelfViewMinimized(!selfViewMinimized)}
              title={selfViewMinimized ? 'Show camera' : 'Hide camera'}
            >
              {selfViewMinimized ? '📷 Show' : '👁‍🗨 Hide'}
            </button>
          </div>
        </div>
      )}

      {/* Streamer Chat Panel - floating bottom-right when live */}
      {isLive && myStream && (
        <div className="live-chat-panel streamer-chat">
          <div className="live-chat-header">
            <h4>💬 Live Chat</h4>
            <span className="live-chat-count">{liveChats.length} messages</span>
          </div>
          <div className="live-chat-messages">
            {liveChats.length === 0 ? (
              <p className="live-chat-empty">No messages yet. Your viewers will chat here!</p>
            ) : (
              liveChats.map((chat, i) => (
                <div key={chat.id || i} className={`live-chat-msg ${chat.message && chat.message.length <= 2 ? 'live-chat-emoji-msg' : ''}`}>
                  <span className="live-chat-name">{chat.full_name || chat.username}</span>
                  <span className="live-chat-text">{chat.message}</span>
                </div>
              ))
            )}
            <div ref={chatEndRef} />
          </div>
          <div className="live-chat-input-row">
            <input
              type="text"
              placeholder="Chat with viewers..."
              value={liveChatText}
              onChange={e => setLiveChatText(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  sendLiveChat(myStream.id);
                }
              }}
            />
            <button onClick={() => sendLiveChat(myStream.id)} disabled={!liveChatText.trim()}>Send</button>
          </div>
          <div className="streamer-emoji-bar">
            <button onClick={() => sendEmojiReaction(myStream.id, '❤️')}>❤️</button>
            <button onClick={() => sendEmojiReaction(myStream.id, '🔥')}>🔥</button>
            <button onClick={() => sendEmojiReaction(myStream.id, '👏')}>👏</button>
            <button onClick={() => sendEmojiReaction(myStream.id, '😍')}>😍</button>
            <button onClick={() => sendEmojiReaction(myStream.id, '💯')}>💯</button>
          </div>
        </div>
      )}

      {/* Go Live Setup Modal */}
      {showGoLiveModal && !isLive && (
        <div className="live-modal-overlay" onClick={cancelGoLive}>
          <div className="live-modal" onClick={e => e.stopPropagation()}>
            <div className="live-modal-header">
              <h3>🔴 Go Live</h3>
              <button className="live-modal-close" onClick={cancelGoLive}>✕</button>
            </div>
            <div className="live-modal-video-container">
              <video
                ref={videoRef}
                autoPlay
                muted
                playsInline
                className="live-video-preview"
              />
              <div className="live-video-overlay">
                <span className="live-preview-label">Preview</span>
              </div>
            </div>
            <div className="live-modal-body">
              <input
                type="text"
                placeholder="Give your stream a title..."
                value={liveTitle}
                onChange={e => setLiveTitle(e.target.value)}
                className="live-title-input"
                maxLength={100}
              />
              <div className="live-modal-tips">
                <p>💡 Tips for a great live stream:</p>
                <ul>
                  <li>Find good lighting</li>
                  <li>Check your internet connection</li>
                  <li>Engage with your viewers!</li>
                </ul>
              </div>
              <div className="live-modal-actions">
                <button className="live-cancel-btn" onClick={cancelGoLive}>Cancel</button>
                <button className="live-start-btn" onClick={confirmGoLive}>
                  🔴 Go Live Now
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Viewer Modal - watching someone's stream with chat */}
      {viewingStream && (
        <div className="live-modal-overlay" onClick={leaveStream}>
          <div className="live-viewer-modal" onClick={e => e.stopPropagation()}>
            <div className="live-viewer-header">
              <div className="live-viewer-header-left">
                <div className="live-viewer-avatar">
                  {viewingStream.avatar_url ? (
                    <img src={viewingStream.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                  ) : (
                    viewingStream.username ? viewingStream.username[0].toUpperCase() : 'U'
                  )}
                </div>
                <div className="live-viewer-info">
                  <h4>{viewingStream.full_name || viewingStream.username}</h4>
                  <span>@{viewingStream.username}</span>
                </div>
              </div>
              <div className="live-viewer-header-right">
                <span className="live-badge-animated">● LIVE</span>
                <span className="live-viewer-count-badge">👁 {viewingStream.viewer_count || 0} watching</span>
                <button className="live-modal-close" onClick={leaveStream}>✕</button>
              </div>
            </div>
            <div className="live-viewer-body">
              <div className="live-viewer-video-area">
                <div className="live-viewer-stream-content">
                  <div className="live-stream-visual">
                    {/* Live video frame from streamer */}
                    {viewerFrameUrl && (
                      <img
                        src={viewerFrameUrl}
                        alt="Live stream"
                        className="live-stream-frame"
                        onError={(e) => { e.target.style.display = 'none'; }}
                        onLoad={(e) => { e.target.style.display = 'block'; }}
                      />
                    )}
                    {/* Fallback visual when no frame available */}
                    <div className="live-stream-visual-bg">
                      <div className="live-stream-wave"></div>
                      <div className="live-stream-wave wave-2"></div>
                      <div className="live-stream-wave wave-3"></div>
                    </div>
                    <div className="live-stream-visual-center live-stream-visual-fallback">
                      <div className="live-stream-placeholder-avatar">
                        {viewingStream.avatar_url ? (
                          <img src={viewingStream.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                        ) : (
                          viewingStream.username ? viewingStream.username[0].toUpperCase() : 'U'
                        )}
                      </div>
                      <h3>{viewingStream.title}</h3>
                      <p className="live-stream-connected">🔴 Live now — {viewingStream.viewer_count || 0} viewers</p>
                      <div className="live-equalizer">
                        <span></span><span></span><span></span><span></span><span></span>
                      </div>
                    </div>
                    {/* Floating emoji reactions */}
                    {floatingEmojis.map(fe => (
                      <div
                        key={fe.id}
                        className="floating-emoji"
                        style={{ left: `${fe.left}%` }}
                      >
                        {fe.emoji}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <div className="live-chat-panel viewer-chat">
                <div className="live-chat-header">
                  <h4>💬 Live Chat</h4>
                </div>
                <div className="live-chat-messages">
                  {liveChats.length === 0 ? (
                    <p className="live-chat-empty">Be the first to say something!</p>
                  ) : (
                    liveChats.map((chat, i) => (
                      <div key={chat.id || i} className={`live-chat-msg ${chat.message && chat.message.length <= 2 ? 'live-chat-emoji-msg' : ''}`}>
                        <span className="live-chat-name">{chat.full_name || chat.username}</span>
                        <span className="live-chat-text">{chat.message}</span>
                      </div>
                    ))
                  )}
                  <div ref={chatEndRef} />
                </div>
                <div className="live-chat-input-row">
                  <input
                    type="text"
                    placeholder="Say something..."
                    value={liveChatText}
                    onChange={e => setLiveChatText(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        sendLiveChat(viewingStream.id);
                      }
                    }}
                  />
                  <button onClick={() => sendLiveChat(viewingStream.id)} disabled={!liveChatText.trim()}>Send</button>
                </div>
              </div>
            </div>
            <div className="live-viewer-footer">
              <div className="live-viewer-reactions">
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '❤️')}>❤️</button>
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '🔥')}>🔥</button>
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '👏')}>👏</button>
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '😍')}>😍</button>
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '🇿🇦')}>🇿🇦</button>
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '💯')}>💯</button>
                <button className="live-reaction-btn" onClick={() => sendEmojiReaction(viewingStream.id, '🙌')}>🙌</button>
              </div>
              <button className="leave-stream-btn" onClick={leaveStream}>Leave Stream</button>
            </div>
          </div>
        </div>
      )}

      {/* Share Toast */}
      {shareToast && (
        <div className="share-toast">{shareToast}</div>
      )}

      {/* Location Modal */}
      {showLocationModal && (
        <div className="live-modal-overlay" onClick={() => setShowLocationModal(false)}>
          <div className="location-modal" onClick={e => e.stopPropagation()}>
            <div className="location-modal-header">
              <h3>📍 Add Location</h3>
              <button className="live-modal-close" onClick={() => setShowLocationModal(false)}>✕</button>
            </div>
            <div className="location-modal-body">
              <div className="location-input-row">
                <input
                  type="text"
                  placeholder="Type your city or location..."
                  value={manualLocation}
                  onChange={e => setManualLocation(e.target.value)}
                  onKeyDown={e => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleSetManualLocation();
                    }
                  }}
                  autoFocus
                />
                <button
                  className="btn-post"
                  onClick={handleSetManualLocation}
                  disabled={!manualLocation.trim()}
                >
                  Add
                </button>
              </div>
              <div className="location-popular">
                <p className="location-popular-label">Popular locations</p>
                <div className="location-popular-grid">
                  {popularLocations.map((loc, i) => (
                    <button
                      key={i}
                      className="location-chip"
                      onClick={() => {
                        setPostLocation(loc);
                        setShowLocationModal(false);
                      }}
                    >
                      📍 {loc}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default Feed;
