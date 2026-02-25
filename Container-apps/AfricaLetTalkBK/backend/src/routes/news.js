const express = require('express');
const router = express.Router();
const Parser = require('rss-parser');

const parser = new Parser({
    timeout: 10000,
    headers: {
        'User-Agent': 'OneAfrica/1.0'
    }
});

// Cache news for 15 minutes
let newsCache = { data: [], lastFetch: 0 };
const CACHE_TTL = 15 * 60 * 1000;

const RSS_FEEDS = [
    { url: 'https://feeds.bbci.co.uk/news/world/africa/rss.xml', source: 'BBC Africa' },
    { url: 'https://www.aljazeera.com/xml/rss/all.xml', source: 'Al Jazeera' },
];

const TRENDING_FEEDS = [
    { url: 'https://feeds.bbci.co.uk/news/world/africa/rss.xml', source: 'BBC Africa', category: 'Africa' },
    { url: 'https://feeds.bbci.co.uk/news/world/rss.xml', source: 'BBC World', category: 'World' },
    { url: 'https://feeds.bbci.co.uk/news/technology/rss.xml', source: 'BBC Tech', category: 'Technology' },
    { url: 'https://feeds.bbci.co.uk/news/business/rss.xml', source: 'BBC Business', category: 'Business' },
    { url: 'https://feeds.bbci.co.uk/sport/rss.xml', source: 'BBC Sport', category: 'Sports' },
    { url: 'https://www.aljazeera.com/xml/rss/all.xml', source: 'Al Jazeera', category: 'World' },
    { url: 'https://rss.nytimes.com/services/xml/rss/nyt/Africa.xml', source: 'NY Times Africa', category: 'Africa' },
    { url: 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml', source: 'NY Times World', category: 'World' },
];

let trendingCache = { data: [], lastFetch: 0 };

router.get('/', async (req, res) => {
    try {
        const now = Date.now();
        if (newsCache.data.length > 0 && (now - newsCache.lastFetch) < CACHE_TTL) {
            return res.json({ articles: newsCache.data });
        }

        const articles = [];

        for (const feed of RSS_FEEDS) {
            try {
                const result = await parser.parseURL(feed.url);
                const items = (result.items || []).slice(0, 8).map(item => ({
                    title: item.title || '',
                    link: item.link || '',
                    pubDate: item.pubDate || item.isoDate || '',
                    source: feed.source,
                    description: (item.contentSnippet || item.content || '').substring(0, 150),
                    thumbnail: extractImage(item) || null
                }));
                articles.push(...items);
            } catch (feedErr) {
                console.error(`Failed to fetch ${feed.source}:`, feedErr.message);
            }
        }

        // Sort by date descending, take top 12
        articles.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));
        const topArticles = articles.slice(0, 12);

        newsCache = { data: topArticles, lastFetch: now };
        res.json({ articles: topArticles });
    } catch (error) {
        console.error('News fetch error:', error);
        // Return cached data if available, otherwise empty
        res.json({ articles: newsCache.data || [] });
    }
});

function extractImage(item) {
    // Try enclosure
    if (item.enclosure && item.enclosure.url) return item.enclosure.url;
    // Try media:thumbnail or media:content
    if (item['media:thumbnail'] && item['media:thumbnail'].$) return item['media:thumbnail'].$.url;
    if (item['media:content'] && item['media:content'].$) return item['media:content'].$.url;
    // Try to extract from content
    if (item.content) {
        const match = item.content.match(/<img[^>]+src="([^"]+)"/);
        if (match) return match[1];
    }
    return null;
}

// Trending stories from multiple global & African sources
router.get('/trending', async (req, res) => {
    try {
        const now = Date.now();
        if (trendingCache.data.length > 0 && (now - trendingCache.lastFetch) < CACHE_TTL) {
            return res.json({ trending: trendingCache.data });
        }

        const articles = [];

        // Fetch all feeds in parallel
        const feedPromises = TRENDING_FEEDS.map(async (feed) => {
            try {
                const result = await parser.parseURL(feed.url);
                return (result.items || []).slice(0, 5).map(item => ({
                    title: item.title || '',
                    link: item.link || '',
                    pubDate: item.pubDate || item.isoDate || '',
                    source: feed.source,
                    category: feed.category,
                    description: (item.contentSnippet || item.content || '').substring(0, 120),
                    thumbnail: extractImage(item) || null
                }));
            } catch (feedErr) {
                console.error(`Trending: Failed to fetch ${feed.source}:`, feedErr.message);
                return [];
            }
        });

        const results = await Promise.all(feedPromises);
        results.forEach(items => articles.push(...items));

        // Sort by date descending, take top 20
        articles.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));
        const topTrending = articles.slice(0, 20);

        trendingCache = { data: topTrending, lastFetch: now };
        res.json({ trending: topTrending });
    } catch (error) {
        console.error('Trending fetch error:', error);
        res.json({ trending: trendingCache.data || [] });
    }
});

module.exports = router;
