require('dotenv').config();
const { Client, GatewayIntentBits, ChannelType, PermissionsBitField, Events } = require('discord.js');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
    ],
});

const FORUM_CHANNELS = [
    process.env.FORUM_CHANNEL_ID_GAMES,
    process.env.FORUM_CHANNEL_ID_EXPERIENCES,
    process.env.FORUM_CHANNEL_ID_NSFW
].filter(id => id);

const JSON_FILE = path.join(__dirname, 'discord_profiles.json');
const CSV_FILE = path.join(__dirname, 'discord_profiles.csv');
const STATE_FILE = path.join(__dirname, 'bot_state.json');

const args = process.argv.slice(2);
const limitArg = args.find(a => a.startsWith('--limit='));
const PROFILE_LIMIT = limitArg ? parseInt(limitArg.split('=')[1]) : Infinity;

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
const getDiscordUrl = (guildId = "@me", channelId = "", messageId = "") => {
    let url = `https://discord.com/channels/${guildId}`;
    if (channelId) url += `/${channelId}`;
    if (messageId) url += `/${messageId}`;
    return url;
};
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

async function askToContinue(message) {
    return new Promise((resolve) => {
        rl.question(`\n[!] ${message}\n[?] Press ENTER to continue, or Ctrl+C to stop... `, () => {
            resolve();
        });
    });
}

function loadState() {
    if (fs.existsSync(STATE_FILE)) {
        try {
            return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
        } catch (e) {
            console.error(`Error loading state: ${e.message}`);
        }
    }
    return { threads: {} };
}

function saveState(state) {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function loadResults() {
    if (fs.existsSync(JSON_FILE)) {
        try {
            return JSON.parse(fs.readFileSync(JSON_FILE, 'utf8'));
        } catch (e) {
            console.error(`Error loading existing results: ${e.message}`);
        }
    }
    return [];
}

function saveFullResults(results) {
    // 1. Save exhaustive JSON
    fs.writeFileSync(JSON_FILE, JSON.stringify(results, null, 2));
    
    // 2. Save minimal CSV (just links)
    if (results.length > 0) {
        const csvContent = ["sourceUrl", ...results.map(r => r.sourceUrl)].join("\n");
        fs.writeFileSync(CSV_FILE, csvContent, 'utf8');
    }
}

async function fetchNewMessages(thread, afterId) {
    let allMessages = [];
    let lastId = afterId;

    while (true) {
        const options = { limit: 100 };
        if (lastId) options.after = lastId;

        try {
            const messages = await thread.messages.fetch(options);
            if (!messages || messages.size === 0) break;

            const batch = [...messages.values()];
            allMessages.push(...batch);
            lastId = batch[batch.length - 1].id;

            if (messages.size < 100) break;
            await sleep(500);
        } catch (e) {
            if (e.code === 50001) {
                console.warn(`    [!] Missing Access to fetch messages in "${thread.name}"`);
            } else {
                console.error(`    [!] Error fetching messages in "${thread.name}": ${e.message}`);
                await askToContinue(`Failed to fetch messages for "${thread.name}".`);
            }
            break;
        }
    }

    return allMessages;
}

client.once(Events.ClientReady, async () => {
    console.log(`Logged in as ${client.user.tag}!`);
    
    let results = loadResults();
    let state = loadState();
    let newFoundTotal = 0;
    console.log(`Loaded ${results.length} existing profiles from ${path.basename(JSON_FILE)}`);
    const existingIds = new Set(results.map(r => r.id));

    for (const channelId of FORUM_CHANNELS) {
        try {
            const channel = await client.channels.fetch(channelId);
            if (!channel || channel.type !== ChannelType.GuildForum) continue;

            const me = channel.guild.members.me;
            const perms = channel.permissionsFor(me);
            if (!perms.has(PermissionsBitField.Flags.ViewChannel) || !perms.has(PermissionsBitField.Flags.ReadMessageHistory)) {
                console.error(`FATAL: Missing permissions in #${channel.name}`);
                process.exit(1);
            }

            console.log(`\n--- Forum: ${channel.name} ---`);
            const activeThreads = await channel.threads.fetchActive();
            const archivedThreads = await channel.threads.fetchArchived();
            const allThreads = [...activeThreads.threads.values(), ...archivedThreads.threads.values()];
            let threadIndex = 0;

            for (const thread of allThreads) {
                threadIndex++;
                if (newFoundTotal >= PROFILE_LIMIT) break;
                const lastScrapedId = state.threads[thread.id];
                
                if (lastScrapedId && thread.lastMessageId === lastScrapedId) {
                    continue;
                }

                console.log(`  [${threadIndex}/${allThreads.length}] Scraping: ${thread.name} (ID: ${thread.id})`);
                
                let messages = [];
                if (!lastScrapedId) {
                    try {
                        const starter = await thread.fetchStarterMessage().catch(() => null);
                        if (starter) messages.push(starter);
                    } catch (e) {}
                    messages.push(...(await fetchNewMessages(thread, null)));
                } else {
                    messages = await fetchNewMessages(thread, lastScrapedId);
                }

                await sleep(500);
                if (messages.length === 0) {
                    state.threads[thread.id] = thread.lastMessageId;
                    continue;
                }

                let gameBanner = null;
                const starterMsg = messages.find(m => m.id === thread.id) || (await thread.fetchStarterMessage().catch(() => null));
                if (starterMsg) {
                    const img = starterMsg.attachments.find(a => a.contentType?.startsWith('image/'));
                    if (img) gameBanner = img.url;
                }

                let newFound = 0;
                for (const msg of messages) {
                    const zips = msg.attachments.filter(a => a.name.endsWith('.zip') || a.name.endsWith('.7z') || a.name.endsWith('.rar'));
                    for (const zip of zips.values()) {
                        const uniqueId = msg.id + "_" + zip.id;
                        if (existingIds.has(uniqueId)) continue;

                        const msgUrl = getDiscordUrl(thread.guildId, thread.id, msg.id);
                        console.log(`    [${newFoundTotal + 1}] Found: ${zip.name} (${msg.author.username}) -> ${msgUrl}`);

                        results.push({
                            id: uniqueId,
                            gameName: thread.name,
                            archive: zip.name,
                            authorName: msg.author.username,
                            createdDate: msg.createdAt.toISOString(),
                            description: msg.content || "",
                            gameBanner: gameBanner,
                            sourceChannel: channel.name,
                            sourceUrl: msgUrl,
                            sourceDownloadUrl: zip.url
                        });
                        existingIds.add(uniqueId);
                        newFound++;
                        newFoundTotal++;
                        if (newFoundTotal >= PROFILE_LIMIT) {
                            console.log(`\n[!] Reached profile limit of ${PROFILE_LIMIT}. Stopping.`);
                            break;
                        }
                    }
                    if (newFoundTotal >= PROFILE_LIMIT) break;
                }

                state.threads[thread.id] = thread.lastMessageId;
                if (newFound > 0) {
                    saveFullResults(results);
                    saveState(state);
                }
            }
        } catch (err) {
            console.error(`Error in channel ${channelId}:`, err);
            await askToContinue(`Continue?`);
        }
        saveState(state);
        await sleep(2000);
    }

    saveFullResults(results);
    console.log(`\nDone! Total profiles in JSON: ${results.length}`);
    process.exit(0);
});

client.login(process.env.TOKEN);
