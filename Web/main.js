import { ChatClient, VoiceEvents } from 'dyna-ai-voice-rtc';

const INTERRUPT_CODES = {
  TERMINAL_SENTENCE: 900007,
  RISK_WORD_SENTENCE: 900008
};

const LS_ROBOT_KEY = 'dyna-ai-voice-rtc-demo:robot-key';
const LS_ROBOT_TOKEN = 'dyna-ai-voice-rtc-demo:robot-token';

function generateDefaultUserName() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let suffix = '';
  for (let i = 0; i < 8; i += 1) {
    suffix += chars[Math.floor(Math.random() * chars.length)];
  }
  return `user_${Date.now()}_${suffix}`;
}

const $ = id => document.getElementById(id);

const logBox = $('logBox');
const btnStart = $('btnStart');
const btnStop = $('btnStop');
const btnMute = $('btnMute');
const btnUnmute = $('btnUnmute');
const btnInterrupt = $('btnInterrupt');
const btnClear = $('btnClear');
const sessionLine = $('sessionLine');
const sessionIdText = $('sessionIdText');
const chatMessages = $('chatMessages');
const chatStatusBadge = $('chatStatusBadge');

/** @type {ChatClient | null} */
let client = null;
/** @type {string | null} */
let sessionId = null;

function log(msg, data) {
  const line = document.createElement('div');
  line.className = 'line';
  const t = new Date().toISOString().slice(11, 23);
  const text =
    typeof data === 'undefined'
      ? msg
      : `${msg} ${JSON.stringify(data, null, 0)}`;
  line.innerHTML = `<span class="time">[${t}]</span> ${escapeHtml(text)}`;
  logBox.appendChild(line);
  logBox.scrollTop = logBox.scrollHeight;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function setRunning(running) {
  btnStart.disabled = running;
  btnStop.disabled = !running;
  btnMute.disabled = !running;
  btnUnmute.disabled = !running;
  btnInterrupt.disabled = !running;
}

function setChatBadge(text, live = false) {
  chatStatusBadge.textContent = text;
  chatStatusBadge.classList.toggle('is-live', live);
}

const bubbleElBySegment = new Map();

function segmentMapKey(role, segmentId) {
  return `${role}:${String(segmentId)}`;
}

function clearChatMessages() {
  chatMessages.innerHTML = '';
  bubbleElBySegment.clear();
}

function appendOrMergeSubtitle(role, content, segmentId) {
  const text = content == null ? '' : String(content);

  if (segmentId === undefined || segmentId === null) {
    createChatRow(role, text);
    return;
  }

  const key = segmentMapKey(role, segmentId);
  const bubbleEl = bubbleElBySegment.get(key);

  if (bubbleEl) {
    if (role === 'user') {
      bubbleEl.textContent = text;
    } else {
      const prev = bubbleEl.textContent;
      if (text.startsWith(prev) && text.length >= prev.length) {
        bubbleEl.textContent = text;
      } else {
        bubbleEl.textContent += text;
      }
    }
  } else {
    const bubble = createChatRow(role, text);
    bubbleElBySegment.set(key, bubble);
  }

  chatMessages.scrollTop = chatMessages.scrollHeight;
}

/** @returns {HTMLDivElement} */
function createChatRow(role, text) {
  const row = document.createElement('div');
  row.className = `chat-row chat-row--${role}`;

  const av = document.createElement('span');
  av.className = `chat-avatar chat-avatar--${role}`;
  av.textContent = role === 'bot' ? 'AI' : 'You';

  const bubble = document.createElement('div');
  bubble.className = `chat-bubble chat-bubble--${role}`;
  bubble.textContent = text;

  if (role === 'bot') {
    row.appendChild(av);
    row.appendChild(bubble);
  } else {
    row.appendChild(bubble);
    row.appendChild(av);
  }

  chatMessages.appendChild(row);
  return bubble;
}

function appendChatSystem(text) {
  const div = document.createElement('div');
  div.className = 'chat-system';
  div.textContent = text;
  chatMessages.appendChild(div);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

/** @param {{ server?: boolean }} [opts] */
function appendChatAction(text, opts = {}) {
  const div = document.createElement('div');
  div.className = opts.server
    ? 'chat-action chat-action--server'
    : 'chat-action';
  const mark = document.createElement('span');
  mark.className = 'chat-action-mark';
  mark.textContent = opts.server ? 'Server' : 'Local action';
  const body = document.createElement('span');
  body.className = 'chat-action-body';
  body.textContent = text;
  div.appendChild(mark);
  div.appendChild(body);
  chatMessages.appendChild(div);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

function saveAuthToStorage(robotKey, robotToken) {
  try {
    localStorage.setItem(LS_ROBOT_KEY, robotKey);
    localStorage.setItem(LS_ROBOT_TOKEN, robotToken);
  } catch (e) {
    console.warn('[demo] localStorage write failed', e);
  }
}

function restoreAuthFromStorage() {
  let restored = false;
  try {
    const rk = localStorage.getItem(LS_ROBOT_KEY);
    const rt = localStorage.getItem(LS_ROBOT_TOKEN);
    if (rk) {
      $('robotKey').value = rk;
      restored = true;
    }
    if (rt) {
      $('robotToken').value = rt;
      restored = true;
    }
  } catch (e) {
    console.warn('[demo] localStorage read failed', e);
  }
  return restored;
}

function bindClientEvents() {
  if (!client) return;

  client.on(VoiceEvents.ALL, (eventName, data) => {
    log(`[ALL] ${eventName}`, data);
  });

  client.on(VoiceEvents.ERROR, data => {
    log('[ERROR]', data);
  });

  client.on(VoiceEvents.SESSION_CREATED, () => {
    setChatBadge('In call', true);
    appendChatSystem('Session established. You can start speaking.');
  });

  client.on(VoiceEvents.SESSION_STARTED, () => {
    appendChatSystem('SESSION_STARTED (same timing and payload as SESSION_CREATED)');
  });

  client.on(VoiceEvents.AUDIO_MUTED, data => {
    if (data.sessionId !== sessionId) return;
    appendChatAction('AUDIO_MUTED (local microphone muted)');
  });

  client.on(VoiceEvents.AUDIO_UNMUTED, data => {
    if (data.sessionId !== sessionId) return;
    appendChatAction('AUDIO_UNMUTED (local microphone enabled)');
  });

  client.on(VoiceEvents.USER_MESSAGE, data => {
    if (data.sessionId !== sessionId) return;
    appendOrMergeSubtitle('user', data.content, data.segmentId);
    if (data.raw) {
      log('[USER_MESSAGE] raw (full server object)', data.raw);
    }
  });

  client.on(VoiceEvents.ROBOT_MESSAGE, data => {
    if (data.sessionId !== sessionId) return;
    appendOrMergeSubtitle('bot', data.content, data.segmentId);
    if (data.raw) {
      log('[ROBOT_MESSAGE] raw (full server object)', data.raw);
    }
  });

  client.on(VoiceEvents.INTERRUPT, data => {
    if (data.sessionId !== sessionId) return;
    const interruptCode = Number(data.code);
    let shouldStop = false;
    if (interruptCode === INTERRUPT_CODES.TERMINAL_SENTENCE) {
      shouldStop = true;
      appendChatAction('Terminal sentence received. Ending the call.', {
        server: true
      });
    } else if (interruptCode === INTERRUPT_CODES.RISK_WORD_SENTENCE) {
      shouldStop = true;
      appendChatAction(data.message || 'The conversation ended because the server reported risk content.', {
        server: true
      });
    } else {
      appendChatAction(data.message || 'Received a voice stream interrupt.', { server: true });
    }
    log('[INTERRUPT] raw (full server object)', data.raw);
    if (shouldStop) {
      void client
        .stopVoiceChat()
        .catch(error => log('[INTERRUPT] stop failed', error?.message));
    }
  });

  client.on(VoiceEvents.SESSION_ENDED, data => {
    appendChatSystem(`Session ended (${data.reason || 'unknown'})`);
    setChatBadge('Disconnected', false);
    sessionLine.hidden = true;
    setRunning(false);
    client = null;
    sessionId = null;
  });
}

btnClear.addEventListener('click', () => {
  logBox.innerHTML = '';
});

btnStart.addEventListener('click', async () => {
  const robotKey = $('robotKey').value.trim();
  const robotToken = $('robotToken').value.trim();
  let userNameRaw = $('userName').value.trim();

  if (!robotKey || !robotToken) {
    log('Enter Robot-Key and Robot-Token.');
    return;
  }
  if (!userNameRaw) {
    userNameRaw = generateDefaultUserName();
    $('userName').value = userNameRaw;
    log('Generated userName automatically', userNameRaw);
  }

  saveAuthToStorage(robotKey, robotToken);

  try {
    client = new ChatClient(
      {
        robotKey,
        robotToken
      },
      {
        userName: userNameRaw
      }
    );
    bindClientEvents();

    clearChatMessages();
    setChatBadge('Connecting...', false);

    sessionId = await client.startVoiceChat();
    sessionIdText.textContent = sessionId;
    sessionLine.hidden = false;
    setRunning(true);
    log('startVoiceChat succeeded', { sessionId });
  } catch (e) {
    log('Start failed', { message: e?.message || String(e) });
    clearChatMessages();
    setChatBadge('Disconnected', false);
    client = null;
    sessionId = null;
    sessionLine.hidden = true;
    setRunning(false);
  }
});

btnStop.addEventListener('click', async () => {
  if (!client || !sessionId) return;
  const sid = sessionId;
  try {
    await client.stopVoiceChat();
    log('stopVoiceChat completed', { sessionId: sid });
  } catch (e) {
    log('stopVoiceChat failed (the RTC connection may already be closed)', {
      message: e?.message || String(e)
    });
  }
});

btnMute.addEventListener('click', async () => {
  if (!client || !sessionId) return;
  try {
    await client.setAudioEnabled({ bool: false });
    log('Microphone muted');
    appendChatAction('Muted (microphone capture is disabled)');
  } catch (e) {
    log('Mute failed', { message: e?.message || String(e) });
  }
});

btnUnmute.addEventListener('click', async () => {
  if (!client || !sessionId) return;
  try {
    await client.setAudioEnabled({ bool: true });
    log('Microphone enabled');
    appendChatAction('Unmuted (microphone capture is enabled)');
  } catch (e) {
    log('Unmute failed', { message: e?.message || String(e) });
  }
});

btnInterrupt.addEventListener('click', () => {
  if (!client || !sessionId) return;
  try {
    client.interrupt();
    log('Interrupt command sent');
    appendChatAction('Interrupt command sent with sendStreamMessage');
  } catch (e) {
    log('Interrupt failed', { message: e?.message || String(e) });
  }
});

const hadAuthCache = restoreAuthFromStorage();
setRunning(false);
if (hadAuthCache) {
  log('Restored Robot-Key / Robot-Token from localStorage');
}
log('Ready. Enter credentials and click “Start voice”. Valid credentials are cached locally.');
