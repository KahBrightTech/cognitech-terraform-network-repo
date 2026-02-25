const express = require('express');
const router = express.Router();
const Parser = require('rss-parser');

const parser = new Parser({
    timeout: 8000,
    headers: { 'User-Agent': 'LetsConnect/1.0' }
});

let newsCache = { data: [], lastFetch: 0, source: 'none' };
let trendingCache = { data: [], lastFetch: 0, source: 'none' };
const CACHE_TTL = 15 * 60 * 1000;

const RSS_FEEDS = [
    { url: 'https://feeds.bbci.co.uk/news/world/africa/rss.xml', source: 'BBC Africa' },
    { url: 'https://www.aljazeera.com/xml/rss/all.xml', source: 'Al Jazeera' },
    { url: 'https://rss.nytimes.com/services/xml/rss/nyt/Africa.xml', source: 'NY Times Africa' },
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

// Static fallback articles shown when ECS has no outbound internet (no NAT Gateway)
const FALLBACK_NEWS = [
    { title: 'African Union Advances Continental Free Trade Area Implementation', link: 'https://au.int/en/pressreleases', pubDate: new Date().toISOString(), source: 'African Union', description: 'The AfCFTA continues to expand, connecting 54 countries in the world largest free trade zone by number of participating nations.', thumbnail: 'https://images.unsplash.com/photo-1566140967404-b8b3932483f5?w=600&q=80' },
    { title: 'Tech Innovation Hubs Flourishing Across Sub-Saharan Africa', link: 'https://disrupt-africa.com', pubDate: new Date(Date.now() - 3600000).toISOString(), source: 'Tech Africa', description: 'From Lagos to Nairobi, tech startups are reshaping African economies with homegrown solutions in fintech, agritech, and healthtech.', thumbnail: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&q=80' },
    { title: 'East Africa Records Strong Economic Growth in Latest Quarter', link: 'https://www.reuters.com/world/africa', pubDate: new Date(Date.now() - 7200000).toISOString(), source: 'Reuters Africa', description: 'Kenya, Tanzania, and Rwanda lead East Africa economic expansion driven by tourism recovery, infrastructure investment, and digital services.', thumbnail: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=600&q=80' },
    { title: 'Renewable Energy Projects Power Communities Across the Continent', link: 'https://www.irena.org/africa', pubDate: new Date(Date.now() - 10800000).toISOString(), source: 'IRENA', description: 'Solar and wind energy investments reach record levels across Africa, bringing electricity to millions of previously off-grid households.', thumbnail: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=600&q=80' },
    { title: 'African Champions League Final Set for Historic Showdown', link: 'https://www.cafonline.com', pubDate: new Date(Date.now() - 14400000).toISOString(), source: 'CAF Online', description: 'Football fans across the continent prepare for the most anticipated club match of the season as two powerhouse teams compete for the title.', thumbnail: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=600&q=80' },
    { title: 'New Wildlife Conservation Initiative Protects Endangered Species', link: 'https://www.awf.org', pubDate: new Date(Date.now() - 18000000).toISOString(), source: 'African Wildlife Foundation', description: 'A landmark conservation agreement between six nations creates one of Africa largest protected wildlife corridors safeguarding elephants and lions.', thumbnail: 'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=600&q=80' },
    { title: 'African Fashion Week Celebrates Designers From 30 Countries', link: 'https://www.africanfashionweek.com', pubDate: new Date(Date.now() - 21600000).toISOString(), source: 'Fashion Africa', description: 'The continent premier fashion event showcases the vibrant creativity of African designers blending traditional craftsmanship with contemporary global styles.', thumbnail: 'https://images.unsplash.com/photo-1549062573-edc78a53ffa0?w=600&q=80' },
    { title: 'Pan-African University Network Expands Digital Learning Access', link: 'https://pau.ac', pubDate: new Date(Date.now() - 25200000).toISOString(), source: 'Pan-African University', description: 'New online education platforms connect students from Cape Town to Cairo, offering quality higher education in STEM, humanities, and business.', thumbnail: 'https://images.unsplash.com/photo-1484318571209-661cf29a69c3?w=600&q=80' },
];

const FALLBACK_TRENDING = [
    { title: 'AfCFTA Trade Volumes Surge 40% Year-on-Year', link: 'https://au.int', pubDate: new Date().toISOString(), source: 'African Union', category: 'Business', description: '', thumbnail: null },
    { title: 'Nairobi Named Top African Startup Ecosystem 2025', link: 'https://disrupt-africa.com', pubDate: new Date(Date.now() - 3600000).toISOString(), source: 'Disrupt Africa', category: 'Technology', description: '', thumbnail: null },
    { title: 'Nigeria Wins AFCON in Dramatic Penalty Shootout', link: 'https://cafonline.com', pubDate: new Date(Date.now() - 7200000).toISOString(), source: 'CAF Online', category: 'Sports', description: '', thumbnail: null },
    { title: 'South Africa GDP Growth Beats Forecasts at 3.2%', link: 'https://reuters.com/africa', pubDate: new Date(Date.now() - 10800000).toISOString(), source: 'Reuters', category: 'Business', description: '', thumbnail: null },
    { title: 'Sahel Region Solar Grid Connects 2 Million Homes', link: 'https://irena.org', pubDate: new Date(Date.now() - 14400000).toISOString(), source: 'IRENA', category: 'Africa', description: '', thumbnail: null },
    { title: 'East African Community Launches Common Currency Pilot', link: 'https://eac.int', pubDate: new Date(Date.now() - 18000000).toISOString(), source: 'EAC', category: 'World', description: '', thumbnail: null },
    { title: 'African Space Agency Launches First Satellite Constellation', link: 'https://au.int', pubDate: new Date(Date.now() - 21600000).toISOString(), source: 'AU Space', category: 'Technology', description: '', thumbnail: null },
    { title: 'Morocco Tourism Hits Record 15 Million Visitors', link: 'https://reuters.com', pubDate: new Date(Date.now() - 25200000).toISOString(), source: 'Reuters', category: 'Africa', description: '', thumbnail: null },
    { title: 'Kenya Leads Africa in Mobile Money Innovations', link: 'https://disrupt-africa.com', pubDate: new Date(Date.now() - 28800000).toISOString(), source: 'Disrupt Africa', category: 'Technology', description: '', thumbnail: null },
    { title: 'Rwanda Ranked Top African Country for Ease of Business', link: 'https://worldbank.org', pubDate: new Date(Date.now() - 32400000).toISOString(), source: 'World Bank', category: 'Business', description: '', thumbnail: null },
];

function extractImage(item) {
    if (item.enclosure && item.enclosure.url) return item.enclosure.url;
    if (item['media:thumbnail'] && item['media:thumbnail'].$) return item['media:thumbnail'].$.url;
    if (item['media:content'] && item['media:content'].$) return item['media:content'].$.url;
    if (item.content) {
        const match = item.content.match(/<img[^>]+src="([^"]+)"/);
        if (match) return match[1];
    }
    return null;
}

async function fetchFeedSafe(feed, maxItems = 8) {
    try {
        const result = await parser.parseURL(feed.url);
        return (result.items || []).slice(0, maxItems).map(item => ({
            title: item.title || '',
            link: item.link || '',
            pubDate: item.pubDate || item.isoDate || '',
            source: feed.source,
            category: feed.category || 'Africa',
            description: (item.contentSnippet || item.content || '').substring(0, 150),
            thumbnail: extractImage(item) || null
        }));
    } catch (err) {
        console.error(`Feed fetch failed [${feed.source}]: ${err.message}`);
        return [];
    }
}

router.get('/', async (req, res) => {
    try {
        const now = Date.now();
        if (newsCache.data.length > 0 && (now - newsCache.lastFetch) < CACHE_TTL) {
            return res.json({ articles: newsCache.data, source: newsCache.source });
        }
        const articles = [];
        for (const feed of RSS_FEEDS) {
            const items = await fetchFeedSafe(feed, 8);
            articles.push(...items);
        }
        if (articles.length > 0) {
            articles.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));
            const top = articles.slice(0, 12);
            newsCache = { data: top, lastFetch: now, source: 'live' };
            console.log(`News: ${top.length} live articles`);
            return res.json({ articles: top, source: 'live' });
        }
        console.warn('News: RSS unreachable - using fallback');
        newsCache = { data: FALLBACK_NEWS, lastFetch: now, source: 'fallback' };
        return res.json({ articles: FALLBACK_NEWS, source: 'fallback' });
    } catch (error) {
        console.error('News error:', error);
        res.json({ articles: newsCache.data.length > 0 ? newsCache.data : FALLBACK_NEWS, source: 'fallback' });
    }
});

router.get('/trending', async (req, res) => {
    try {
        const now = Date.now();
        if (trendingCache.data.length > 0 && (now - trendingCache.lastFetch) < CACHE_TTL) {
            return res.json({ trending: trendingCache.data, source: trendingCache.source });
        }
        const results = await Promise.all(TRENDING_FEEDS.map(f => fetchFeedSafe(f, 5)));
        const articles = results.flat();
        if (articles.length > 0) {
            articles.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));
            const top = articles.slice(0, 20);
            trendingCache = { data: top, lastFetch: now, source: 'live' };
            console.log(`Trending: ${top.length} live articles`);
            return res.json({ trending: top, source: 'live' });
        }
        console.warn('Trending: RSS unreachable - using fallback');
        trendingCache = { data: FALLBACK_TRENDING, lastFetch: now, source: 'fallback' };
        return res.json({ trending: FALLBACK_TRENDING, source: 'fallback' });
    } catch (error) {
        console.error('Trending error:', error);
        res.json({ trending: trendingCache.data.length > 0 ? trendingCache.data : FALLBACK_TRENDING, source: 'fallback' });
    }
});

module.exports = router;
