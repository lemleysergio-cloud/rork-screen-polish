import { api } from '../convex/_generated/api';
import './community.css';
import { escapeHtml, sanitizeImageSrc } from '../utils/security.js';
import {
  communityErrorMessage,
  saveCommunityUsername,
  uploadCommunityAvatar,
  validateCommunityUsername,
} from '../services/community-profile.js';

const TIMEFRAMES = [
  ['week', '7D', 'Last 7 days'],
  ['month', '30D', 'Last 30 days'],
  ['year', '365D', 'Last 365 days'],
  ['ytd', 'YTD', 'Year to date'],
  ['allTime', 'All', 'All time'],
];

let view = { tab: 'public', timeframe: 'week', direction: 'up', communityId: null };
let currentData = null;
let olderMessages = [];
let loadingOverview = false;
let modalKeyboardCleanup = null;

function money(value, cents = false) {
  const amount = Number(value) || 0;
  return `${amount >= 0 ? '+' : '-'}$${Math.abs(amount).toLocaleString(undefined, {
    minimumFractionDigits: cents ? 2 : 0,
    maximumFractionDigits: cents ? 2 : 0,
  })}`;
}

function initials(value) {
  return String(value || 'Player').replace(/[^a-z0-9]/gi, '').slice(0, 2).toUpperCase() || 'P';
}

/** Short, human timestamp for chat rows. Full date stays in the title attribute. */
function relativeTime(value) {
  const then = new Date(value).getTime();
  if (!Number.isFinite(then)) return '';
  const minutes = Math.round((Date.now() - then) / 60000);
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.round(hours / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(then).toLocaleDateString([], { month: 'short', day: 'numeric' });
}

function fullTime(value) {
  const date = new Date(value);
  return Number.isFinite(date.getTime())
    ? date.toLocaleString([], { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })
    : '';
}

function avatar(profile, className = 'community-avatar') {
  const src = sanitizeImageSrc(profile?.pendingAvatarUrl || profile?.avatarUrl || '');
  return src
    ? `<img class="${className}" src="${src}" alt="${escapeHtml(profile.username)} profile picture">`
    : `<span class="${className} is-initials" aria-hidden="true">${escapeHtml(profile?.initials || initials(profile?.username))}</span>`;
}

function distinction(badge, compact = false) {
  const safe = badge || { shape: 'circle', color: '#8C7A43', value: 0, label: 'No verified distinction yet' };
  return `<span class="community-distinction shape-${escapeHtml(safe.shape)} ${compact ? 'is-compact' : ''}" style="--distinction-color:${escapeHtml(safe.color)}" title="${escapeHtml(safe.label)}"><span>${escapeHtml(safe.value)}</span></span>`;
}

function identityCard(data) {
  const pending = data.me.avatarStatus === 'pending';
  const rejected = data.me.avatarStatus === 'rejected';
  return `<section class="community-identity-card">
    <button type="button" id="community-avatar-button" class="community-avatar-button" aria-label="Upload profile picture">
      ${avatar(data.me, 'community-avatar is-large')}
      <span aria-hidden="true">+</span>
    </button>
    <div class="community-identity-copy">
      <span class="community-identity-label">Your profile</span>
      <button type="button" id="community-edit-username" class="community-username-button" aria-label="Edit username, currently ${escapeHtml(data.me.username)}"><span class="community-username-text">@${escapeHtml(data.me.username)}</span><svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="m15 5 4 4M4 20l4-1L20 7a2.8 2.8 0 0 0-4-4L4 15z"/></svg></button>
    </div>
    <span class="community-identity-state ${data.tab === 'public' ? (data.me.publicSharing ? 'is-live' : 'is-quiet') : 'is-quiet'}">${data.tab === 'public' ? (data.me.publicSharing ? 'Sharing on' : 'Browsing only') : 'Invite-only'}</span>
    ${pending ? '<p class="community-identity-note">Profile picture awaiting approval</p>' : ''}
    ${rejected ? `<p class="community-identity-note is-warning">${escapeHtml(data.me.avatarModerationNote || 'Picture was not approved')}</p>` : ''}
    <input type="file" id="community-avatar-input" accept="image/jpeg,image/png,image/webp" hidden>
  </section>`;
}

function sharingRow(data) {
  const enabled = Boolean(data.me.publicSharing);
  return `<section class="community-sharing-row ${enabled ? 'is-on' : ''}">
    <div class="community-sharing-copy">
      <b id="community-sharing-label">Public sharing</b>
      <small>${enabled ? 'Your username, results, and comments are visible to Community.' : 'Turn on to appear on the board and post comments. You can switch it off any time.'}</small>
    </div>
    <button type="button" id="community-sharing-toggle" class="community-switch ${enabled ? 'is-on' : ''}" role="switch" aria-checked="${enabled}" aria-labelledby="community-sharing-label"><span></span><b>${enabled ? 'On' : 'Off'}</b></button>
  </section>`;
}

/** Top-of-page status strip: restriction, guidelines, or the read-only invitation. */
function statusNotice(data) {
  if (data.me.moderationStatus === 'restricted') {
    return `<div class="community-safety-notice is-restricted" role="status"><strong>Community participation is restricted.</strong><span>You can still browse. Contact Support if you believe this is a mistake.</span></div>`;
  }
  const sharingAllowed = data.tab === 'public' ? data.me.publicSharing : data.selectedCommunity?.sharingEnabled;
  if (sharingAllowed && !data.me.guidelinesAccepted) {
    return `<div class="community-safety-notice" role="status"><strong>One step left before you can post.</strong><button type="button" id="community-review-guidelines">Read &amp; accept Guidelines</button></div>`;
  }
  if (data.tab === 'public' && !sharingAllowed) {
    return `<div class="community-safety-notice is-invite" role="status"><strong>You’re browsing read-only.</strong><span>Rankings and comments stay visible. Sharing publishes your results.</span><button type="button" id="community-enable-sharing">Turn on sharing</button></div>`;
  }
  return '';
}

function controls(data) {
  return `<div class="community-controls">
    <div class="community-direction" role="group" aria-label="Ranking direction">
      <button type="button" data-community-direction="up" aria-pressed="${data.direction === 'up'}" class="${data.direction === 'up' ? 'active' : ''}"><span aria-hidden="true">↗</span> Most Up</button>
      <button type="button" data-community-direction="down" aria-pressed="${data.direction === 'down'}" class="${data.direction === 'down' ? 'active' : ''}"><span aria-hidden="true">↘</span> Most Down</button>
    </div>
    <div class="community-timeframes" role="group" aria-label="Ranking timeframe">
      ${TIMEFRAMES.map(([id, label, long]) => `<button type="button" data-community-timeframe="${id}" aria-pressed="${data.timeframe === id}" aria-label="${escapeHtml(long)}" class="${data.timeframe === id ? 'active' : ''}">${label}</button>`).join('')}
    </div>
  </div>`;
}

function rankingRows(data) {
  if (!data.leaderboard.length) {
    return `<div class="community-empty">
      <span class="community-empty-lines" aria-hidden="true"><i></i><i></i><i></i></span>
      <h3>No shared rankings yet</h3>
      <p>${data.tab === 'public' ? 'Shared results appear here as soon as players opt in. Browsing never publishes anything.' : 'Invite friends and confirm sharing for this group to build the board.'}</p>
      ${data.tab === 'public' && !data.me.publicSharing ? '<button type="button" id="community-empty-share" class="community-primary">Turn on sharing</button>' : ''}
      ${data.tab === 'private' ? '<button type="button" id="community-empty-invite" class="community-primary">Invite friends</button>' : ''}
    </div>`;
  }
  return `<div class="community-ranking-list">${data.leaderboard.map((row) => {
    const isYou = row.profileId === data.me.profileId;
    return `<button type="button" class="community-ranking-row ${isYou ? 'is-you' : ''} ${row.rank <= 3 ? `is-podium rank-${escapeHtml(row.rank)}` : ''}" data-community-profile="${escapeHtml(row.profileId)}" aria-label="Rank ${escapeHtml(row.rank)}, ${escapeHtml(row.username)}${isYou ? ', you' : ''}, ${money(row.amount, true)}. View profile">
      <span class="community-rank">${escapeHtml(row.rank)}</span>
      <span class="community-ranked-avatar">${avatar(row)}${distinction(row.distinction, true)}</span>
      <span class="community-row-name"><span class="community-name-line"><strong>@${escapeHtml(row.username)}</strong>${isYou ? '<em>You</em>' : ''}</span><small>${escapeHtml(row.distinction.label)}</small></span>
      <span class="community-row-amount ${row.amount >= 0 ? 'is-positive' : 'is-negative'}">${money(row.amount, true)}</span>
      <span class="community-row-chevron" aria-hidden="true">›</span>
    </button>`;
  }).join('')}</div>`;
}

function leaderboard(data) {
  const period = TIMEFRAMES.find(([id]) => id === data.timeframe)?.[2] || 'Last 7 days';
  return `<section class="community-board" id="community-rankings">
    <div class="community-section-heading">
      <div><span class="community-kicker">Verified casino cash flow</span><h2>Rankings</h2></div>
      <span class="community-board-period">${escapeHtml(period)}</span>
    </div>
    ${controls(data)}
    <div class="community-column-labels"><span>${data.leaderboard.length} shared ${data.leaderboard.length === 1 ? 'profile' : 'profiles'}</span><span>Net cash flow</span></div>
    ${rankingRows(data)}
    <details class="community-ranking-note">
      <summary>How these rankings work</summary>
      <p>Rankings use settled imported casino transactions only. They are not a measure of skill and do not predict future results.</p>
    </details>
  </section>`;
}

function privateHeader(data) {
  const group = data.selectedCommunity;
  if (!data.groups.length) {
    return `<section class="community-private-empty">
      <span class="community-private-mark" aria-hidden="true"><svg viewBox="0 0 48 48" width="40" height="40" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="18" cy="16" r="6"/><path d="M5 37v-4a13 13 0 0 1 26 0v4M32 11a6 6 0 0 1 0 12m3 5a10 10 0 0 1 8 9"/></svg></span>
      <span class="community-kicker">Invite-only boards</span>
      <h2>Compete with people you know</h2>
      <p>Create a private community or enter a friend’s seven-day invite code. Sharing consent is separate for every group.</p>
      <div><button type="button" id="community-create-group" class="community-primary">Create community</button><button type="button" id="community-join-group" class="community-secondary">Join with code</button></div>
    </section>`;
  }
  return `<section class="community-group-card">
    <div class="community-group-top">
      <div class="community-group-select-wrap">
        <label for="community-group-select">Private community</label>
        <select id="community-group-select">${data.groups.map((item) => `<option value="${escapeHtml(item.communityId)}" ${group?.communityId === item.communityId ? 'selected' : ''}>${escapeHtml(item.name)} · ${item.memberCount}</option>`).join('')}</select>
      </div>
      <button type="button" id="community-group-menu" class="community-icon-button" aria-label="Community options"><span aria-hidden="true">•••</span></button>
    </div>
    <div class="community-group-actions">
      <button type="button" id="community-invite-friends" class="community-primary">Invite friends</button>
      <button type="button" id="community-members">Members</button>
      <button type="button" id="community-create-group">New</button>
      <button type="button" id="community-join-group">Join</button>
    </div>
    <label class="community-private-consent"><input type="checkbox" id="community-private-sharing" ${group?.sharingEnabled ? 'checked' : ''}><span><b>Share my results in this group</b><small>Turning this off immediately removes your profile and results from this private board.</small></span></label>
  </section>`;
}

function messageRow(message, group) {
  const isOwn = message.author.profileId === currentData?.me?.profileId;
  return `<article class="community-message ${isOwn ? 'is-own' : ''}">
    <button type="button" data-community-profile="${escapeHtml(message.author.profileId)}" class="community-message-avatar" aria-label="View ${escapeHtml(message.author.username)}'s profile">${avatar(message.author)}</button>
    <div><header><strong>@${escapeHtml(message.author.username)}</strong>${isOwn ? '<em>You</em>' : ''}<time datetime="${escapeHtml(message.createdAt)}" title="${escapeHtml(fullTime(message.createdAt))}">${escapeHtml(relativeTime(message.createdAt))}</time></header><p>${escapeHtml(message.body)}</p></div>
    <button type="button" class="community-message-menu" data-message-id="${escapeHtml(message.messageId)}" data-profile-id="${escapeHtml(message.author.profileId)}" data-username="${escapeHtml(message.author.username)}" data-is-own="${isOwn}" data-can-delete="${message.canDelete}" data-group-owner="${group?.role === 'owner'}" aria-label="Message options for ${escapeHtml(message.author.username)}"><span aria-hidden="true">•••</span></button>
  </article>`;
}

function composer(data, allowed, sharingAllowed) {
  if (allowed) {
    return `<form id="community-message-form" class="community-composer">
      <textarea id="community-message-input" aria-label="Message to ${data.tab === 'public' ? 'the Community' : 'your private group'}" maxlength="500" rows="1" placeholder="Add to the conversation…"></textarea>
      <button type="submit" aria-label="Send message"><span aria-hidden="true">↑</span></button>
    </form>
    <p class="community-chat-note"><span id="community-message-count" aria-live="polite">0 / 500</span><span aria-hidden="true">·</span><span>5 per minute</span><span aria-hidden="true">·</span><a href="mailto:${escapeHtml(data.supportEmail)}">Support</a></p>`;
  }
  const locked = data.me.moderationStatus === 'restricted';
  return `<div class="community-composer-locked">
    <p>${locked ? 'Commenting is unavailable while your participation is restricted.' : !sharingAllowed ? data.tab === 'public' ? 'Turn on public sharing to comment. Reading is always open.' : 'Confirm sharing for this group to comment.' : 'Accept the Community Guidelines to comment.'}</p>
    ${locked ? `<a class="community-secondary" href="mailto:${escapeHtml(data.supportEmail)}">Contact Support</a>`
      : !sharingAllowed
        ? data.tab === 'public'
          ? '<button type="button" id="community-composer-share" class="community-primary">Turn on sharing</button>'
          : '<button type="button" id="community-composer-private-share" class="community-primary">Share in this group</button>'
        : '<button type="button" id="community-composer-guidelines" class="community-primary">Read &amp; accept Guidelines</button>'}
  </div>`;
}

function discussion(data) {
  const messages = [...olderMessages, ...(data.messages?.items || [])];
  const sharingAllowed = data.tab === 'public' ? data.me.publicSharing : data.selectedCommunity?.sharingEnabled;
  const allowed = sharingAllowed && data.me.guidelinesAccepted && data.me.moderationStatus !== 'restricted';
  return `<section class="community-discussion" id="community-comments">
    <div class="community-section-heading">
      <div><span class="community-kicker">${data.tab === 'public' ? 'Public discussion' : 'Group chat'}</span><h2>${data.tab === 'public' ? 'Comments' : escapeHtml(data.selectedCommunity?.name || 'Private chat')}</h2></div>
      <button type="button" id="community-guidelines" class="community-guidelines-link">Guidelines</button>
    </div>
    <div class="community-message-list">
      ${data.messages?.nextCursor ? '<button type="button" id="community-load-messages" class="community-load-more">Load earlier messages</button>' : ''}
      ${messages.length ? messages.map((message) => messageRow(message, data.selectedCommunity)).join('') : '<div class="community-chat-empty"><strong>No comments yet</strong><span>Keep it useful, respectful, and free of personal information.</span></div>'}
    </div>
    ${composer(data, allowed, sharingAllowed)}
  </section>`;
}

function selectedData(incoming) {
  if (!incoming) return currentData;
  const matches = incoming.tab === view.tab && incoming.timeframe === view.timeframe && incoming.direction === view.direction
    && (view.tab !== 'private' || !view.communityId || incoming.selectedCommunity?.communityId === view.communityId);
  if (!currentData || matches) currentData = incoming;
  return currentData || incoming;
}

export function renderCommunitySkeleton() {
  const block = (className) => `<span class="sk-block ${className}"></span>`;
  return `<section class="community-shell community-refined community-skeleton" aria-busy="true" aria-label="Loading Community">
    <span class="sr-only" role="status">Preparing your Community profile…</span>
    <div aria-hidden="true">
      <header class="community-hero">${block('community-sk-eyebrow')}${block('community-sk-title')}${block('community-sk-subtitle')}</header>
      <div class="community-identity-card">${block('community-sk-avatar')}<div>${block('community-sk-label')}${block('community-sk-name')}</div>${block('community-sk-chip')}</div>
      <div class="community-sharing-row">${block('community-sk-sharing')}${block('community-sk-switch')}</div>
      <div class="community-tabs">${block('community-sk-tab')}${block('community-sk-tab')}</div>
      <section class="community-board"><div class="community-section-heading"><div>${block('community-sk-eyebrow')}${block('community-sk-heading')}</div>${block('community-sk-label')}</div>
        <div class="community-sk-controls">${block('community-sk-control')}${block('community-sk-control')}</div>
        <div class="community-sk-timeframes">${Array.from({ length: 5 }, () => block('community-sk-timeframe')).join('')}</div>
        <div class="community-column-labels">${block('community-sk-label')}${block('community-sk-label')}</div>
        ${Array.from({ length: 4 }, () => `<div class="community-ranking-row">${block('community-sk-rank')}${block('community-sk-avatar')}<div>${block('community-sk-name')}${block('community-sk-detail')}</div>${block('community-sk-amount')}</div>`).join('')}
        ${block('community-sk-note')}
      </section>
      <section class="community-discussion"><div class="community-section-heading">${block('community-sk-heading')}</div>${Array.from({ length: 2 }, () => `<div class="community-message">${block('community-sk-avatar')}<div>${block('community-sk-name')}${block('community-sk-message')}${block('community-sk-detail')}</div></div>`).join('')}</section>
    </div>
  </section>`;
}

export function renderCommunity(incoming) {
  const data = selectedData(incoming);
  if (!data) return renderCommunitySkeleton();
  return `<section class="community-shell community-refined">
    <header class="community-hero">
      <span class="community-kicker">Bankroll Board</span>
      <h1>Community</h1>
      <p>Verified progress, shared on your terms.</p>
    </header>
    ${identityCard(data)}
    ${data.tab === 'public' ? sharingRow(data) : ''}
    <div class="community-tabs-bar">
      <nav class="community-tabs" aria-label="Community type"><button type="button" data-community-tab="public" aria-pressed="${data.tab === 'public'}" class="${data.tab === 'public' ? 'active' : ''}">Public</button><button type="button" data-community-tab="private" aria-pressed="${data.tab === 'private'}" class="${data.tab === 'private' ? 'active' : ''}">Private ${data.groups.length ? `<span>${data.groups.length}</span>` : ''}</button></nav>
    </div>
    ${statusNotice(data)}
    ${data.tab === 'private' ? privateHeader(data) : ''}
    ${(data.tab === 'public' || data.selectedCommunity) ? `${leaderboard(data)}${discussion(data)}` : ''}
    <footer class="community-responsible">
      <strong>Cash-flow rankings are context, not social credit.</strong>
      <p>Use Community to support accountability. Never pressure someone to wager, chase a loss, or reveal personal financial information.</p>
    </footer>
  </section>`;
}

function renderCurrent() {
  const content = document.getElementById('page-content');
  if (!content || !currentData) return;
  content.innerHTML = renderCommunity(currentData);
  initCommunity(currentData);
}

async function loadOverview(overrides = {}) {
  if (loadingOverview) return;
  loadingOverview = true;
  Object.assign(view, overrides);
  olderMessages = [];
  try {
    const data = await window.convex.query(api.community.getOverview, {
      tab: view.tab,
      timeframe: view.timeframe,
      direction: view.direction,
      communityId: view.tab === 'private' && view.communityId ? view.communityId : undefined,
    });
    currentData = data;
    if (data?.selectedCommunity) view.communityId = data.selectedCommunity.communityId;
    renderCurrent();
  } catch (error) {
    alert(error?.message || 'Unable to load Community');
  } finally {
    loadingOverview = false;
  }
}

function modal(content) {
  const root = document.getElementById('modal-root');
  if (!root) return null;
  modalKeyboardCleanup?.();
  const previousFocus = document.activeElement;
  root.classList.add('is-open');
  document.body.classList.add('modal-open');
  root.innerHTML = `<div class="community-modal-backdrop"><section class="community-modal community-refined-modal" role="dialog" aria-modal="true"><span class="community-modal-grip" aria-hidden="true"></span>${content}</section></div>`;
  const panel = root.querySelector('.community-modal');
  const heading = panel.querySelector('h2');
  if (heading) {
    heading.id = 'community-dialog-title';
    panel.setAttribute('aria-labelledby', heading.id);
  }
  const close = () => {
    if (!panel.isConnected) return;
    modalKeyboardCleanup?.();
    modalKeyboardCleanup = null;
    root.innerHTML = '';
    root.classList.remove('is-open');
    document.body.classList.remove('modal-open');
    if (previousFocus?.isConnected) previousFocus.focus({ preventScroll: true });
  };
  const keydown = (event) => {
    if (event.key === 'Escape') { event.preventDefault(); close(); return; }
    if (event.key !== 'Tab') return;
    const controls = [...panel.querySelectorAll('button:not(:disabled), input:not(:disabled), select:not(:disabled), textarea:not(:disabled), a[href]')].filter(element => element.getClientRects().length);
    const first = controls[0], last = controls[controls.length - 1];
    if (event.shiftKey && (document.activeElement === first || !panel.contains(document.activeElement))) {
      event.preventDefault(); last?.focus();
    } else if (!event.shiftKey && (document.activeElement === last || !panel.contains(document.activeElement))) {
      event.preventDefault(); first?.focus();
    }
  };
  document.addEventListener('keydown', keydown);
  modalKeyboardCleanup = () => document.removeEventListener('keydown', keydown);
  panel.querySelector('[data-community-close]')?.focus({ preventScroll: true });
  root.querySelector('[data-community-close]')?.addEventListener('click', close);
  root.querySelector('.community-modal-backdrop')?.addEventListener('click', (event) => { if (event.target === event.currentTarget) close(); });
  return { root, close };
}

function consentModal(kind, onConfirm) {
  const isPublic = kind === 'public';
  const needsGuidelines = !currentData?.me?.guidelinesAccepted;
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">Explicit consent</span><h2>${isPublic ? 'Join the public board?' : 'Share in this private group?'}</h2><p>Enabling this publishes the following to ${isPublic ? 'all Community users' : 'members of this group'}:</p><ul><li>Your username and approved profile picture</li><li>Exact 7-day, 30-day, 365-day, YTD, and all-time results</li><li>Your all-time Bankroll Board cash-flow balance</li><li>Your verified Journey progress and distinction</li></ul><label class="community-consent-check"><input type="checkbox" id="community-consent-check"><span>I understand this is optional and can be turned off immediately.</span></label>${needsGuidelines ? '<label class="community-consent-check"><input type="checkbox" id="community-guidelines-consent"><span>I have read and agree to the <button type="button" id="community-consent-guidelines">Community Guidelines</button>.</span></label>' : ''}<button type="button" id="community-consent-confirm" class="community-primary" disabled>Enable sharing</button><p class="community-modal-footnote">Bankroll Board never publishes your legal name, email, phone, DOB, bank connections, or raw transactions.</p>`);
  if (!sheet) return;
  const check = sheet.root.querySelector('#community-consent-check');
  const guidelinesCheck = sheet.root.querySelector('#community-guidelines-consent');
  const confirm = sheet.root.querySelector('#community-consent-confirm');
  const updateDisabled = () => { confirm.disabled = !check.checked || (needsGuidelines && !guidelinesCheck?.checked); };
  check?.addEventListener('change', updateDisabled);
  guidelinesCheck?.addEventListener('change', updateDisabled);
  sheet.root.querySelector('#community-consent-guidelines')?.addEventListener('click', () => window.open(currentData?.guidelinesUrl, '_blank'));
  confirm?.addEventListener('click', async () => {
    confirm.disabled = true;
    try {
      if (needsGuidelines) await acceptCurrentGuidelines();
      await onConfirm(); sheet.close(); await loadOverview();
    }
    catch (error) { alert(error?.message || 'Unable to update sharing'); confirm.disabled = false; }
  });
}

/** Single entry point for enabling public sharing, shared by every CTA. */
function enablePublicSharing() {
  consentModal('public', () => window.convex.mutation(api.community.setPublicSharing, { enabled: true, consentAccepted: true }));
}

function enablePrivateSharing() {
  if (!view.communityId) return;
  consentModal('private', () => window.convex.mutation(api.community.setPrivateSharing, { communityId: view.communityId, enabled: true, consentAccepted: true }));
}

async function acceptCurrentGuidelines() {
  const version = currentData?.guidelinesVersion;
  if (!version) throw new Error('Community Guidelines are unavailable. Please try again.');
  await window.convex.mutation(api.community.acceptGuidelines, { version });
  currentData = { ...currentData, me: { ...currentData.me, guidelinesAccepted: true } };
}

function guidelinesModal(requireAcceptance = false) {
  const alreadyAccepted = Boolean(currentData?.me?.guidelinesAccepted);
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">Community safety</span><h2>Community Guidelines</h2><p>Community is for accountability and mutual support—not pressure, wagering advice, or proof of skill.</p><div class="community-guidelines-summary"><section><strong>Respect people</strong><p>No harassment, threats, hate speech, bullying, sexual exploitation, or encouragement of self-harm.</p></section><section><strong>Protect privacy</strong><p>Do not post names, addresses, contact details, financial account information, or anyone’s private content.</p></section><section><strong>Keep it genuine</strong><p>No spam, scams, impersonation, illegal content, deceptive claims, or pressure to gamble or chase a loss.</p></section></div><p>You can report content and block another user from any profile or message menu. Reports enter the protected moderation queue for prompt review.</p><a class="community-policy-link" href="${escapeHtml(currentData?.guidelinesUrl || '#')}" target="_blank" rel="noopener">Read the complete Guidelines</a><a class="community-policy-link" href="mailto:${escapeHtml(currentData?.supportEmail || '')}">Contact Community Support</a>${alreadyAccepted ? '<p class="community-accepted-mark">✓ Current Guidelines accepted</p>' : `<label class="community-consent-check"><input type="checkbox" id="community-guidelines-accept-check"><span>I have read and agree to follow these Guidelines.</span></label><button type="button" id="community-guidelines-accept" class="community-primary" disabled>${requireAcceptance ? 'Accept and continue' : 'Accept Guidelines'}</button>`}`);
  if (!sheet || alreadyAccepted) return sheet;
  const check = sheet.root.querySelector('#community-guidelines-accept-check');
  const accept = sheet.root.querySelector('#community-guidelines-accept');
  check?.addEventListener('change', () => { accept.disabled = !check.checked; });
  accept?.addEventListener('click', async () => {
    accept.disabled = true;
    try { await acceptCurrentGuidelines(); sheet.close(); await loadOverview(); }
    catch (error) { alert(error?.message || 'Unable to accept the Guidelines'); accept.disabled = false; }
  });
  return sheet;
}

function simpleForm({ kicker, title, body, inputLabel, placeholder, initialValue = '', confirmLabel, consentText, maxLength = 80, validate, onConfirm }) {
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">${escapeHtml(kicker)}</span><h2>${escapeHtml(title)}</h2><p>${escapeHtml(body)}</p><label class="community-modal-field"><span>${escapeHtml(inputLabel)}</span><input id="community-modal-input" value="${escapeHtml(initialValue)}" placeholder="${escapeHtml(placeholder)}" maxlength="${maxLength}" autocapitalize="none" spellcheck="false" aria-describedby="community-modal-error"></label><p id="community-modal-error" class="community-modal-error" role="alert" hidden></p>${consentText ? `<label class="community-consent-check"><input type="checkbox" id="community-form-consent"><span>${escapeHtml(consentText)}</span></label>` : ''}<button type="button" id="community-modal-confirm" class="community-primary" ${consentText ? 'disabled' : ''}>${escapeHtml(confirmLabel)}</button>`);
  if (!sheet) return;
  const input = sheet.root.querySelector('#community-modal-input');
  const confirm = sheet.root.querySelector('#community-modal-confirm');
  const errorText = sheet.root.querySelector('#community-modal-error');
  const consent = sheet.root.querySelector('#community-form-consent');
  consent?.addEventListener('change', () => { confirm.disabled = !consent.checked; });
  input?.addEventListener('input', () => {
    errorText.hidden = true;
    input.removeAttribute('aria-invalid');
  });
  setTimeout(() => { input?.focus(); input?.select(); }, 50);
  confirm?.addEventListener('click', async () => {
    const value = input.value.trim();
    const validation = validate?.(value);
    if (validation && !validation.valid) {
      errorText.textContent = validation.message;
      errorText.hidden = false;
      input.setAttribute('aria-invalid', 'true');
      input.focus();
      return;
    }
    confirm.disabled = true;
    try { await onConfirm(value); sheet.close(); await loadOverview(); }
    catch (error) {
      errorText.textContent = communityErrorMessage(error, 'Unable to save. Please try again.');
      errorText.hidden = false;
      input.setAttribute('aria-invalid', 'true');
      confirm.disabled = false;
    }
  });
}

async function showProfile(profileId) {
  try {
    const profile = await window.convex.query(api.community.getPublicProfile, {
      profileId,
      communityId: view.tab === 'private' && view.communityId ? view.communityId : undefined,
    });
    if (!profile) throw new Error('Profile is not available');
    const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><div class="community-profile-sheet-head">${avatar(profile, 'community-avatar is-xl')}${distinction(profile.distinction)}<div><span class="community-kicker">Community profile</span><h2>@${escapeHtml(profile.username)}</h2><p>${escapeHtml(profile.distinction.label)}</p></div></div><div class="community-profile-metrics"><div><small>All-time balance</small><strong class="${profile.allTimeBalance >= 0 ? 'is-positive' : 'is-negative'}">${money(profile.allTimeBalance, true)}</strong></div><div><small>Verified Journey offers</small><strong>${escapeHtml(profile.journeyVerified)}</strong></div><div><small>Verified Journey profit</small><strong class="${profile.journeyVerifiedProfit >= 0 ? 'is-positive' : 'is-negative'}">${money(profile.journeyVerifiedProfit, true)}</strong></div><div><small>Journey ROI</small><strong>${profile.journeyRoiPercent === undefined ? '—' : `${Number(profile.journeyRoiPercent).toFixed(1)}%`}</strong></div></div><p class="community-modal-footnote">Balance means verified casino/sportsbook cash flow inside Bankroll Board, not a bank-account balance.</p>${profileId !== currentData.me.profileId ? '<div class="community-profile-actions"><button type="button" id="community-report-profile">Report</button><button type="button" id="community-block-profile">Block</button></div>' : ''}`);
    sheet?.root.querySelector('#community-report-profile')?.addEventListener('click', () => reportTarget('profile', profileId));
    sheet?.root.querySelector('#community-block-profile')?.addEventListener('click', async () => {
      if (!confirm(`Block @${profile.username}? Their rankings and comments will disappear for you.`)) return;
      await window.convex.mutation(api.community.blockProfile, { profileId });
      sheet.close(); await loadOverview();
    });
  } catch (error) { alert(error?.message || 'Unable to open profile'); }
}

function reportTarget(targetType, targetId) {
  const reasons = [
    ['harassment', 'Harassment or threats', 'Bullying, intimidation, or encouragement of harm'],
    ['hate', 'Hate or discrimination', 'Attacks based on a protected characteristic'],
    ['spam', 'Spam or scam', 'Repetitive promotion, fraud, or misleading claims'],
    ['privacy', 'Private information', 'Contact, identity, account, or location details'],
    ['impersonation', 'Impersonation', 'Pretending to be another person or Bankroll Board'],
    ['other', 'Something else', 'Another Community Guidelines concern'],
  ];
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">Safety report</span><h2>What’s happening?</h2><p>Reports are confidential and go to the protected moderation queue.</p><fieldset class="community-report-reasons"><legend>Choose the best reason</legend>${reasons.map(([value, label, description]) => `<label><input type="radio" name="community-report-reason" value="${value}"><span><strong>${label}</strong><small>${description}</small></span></label>`).join('')}</fieldset><label class="community-modal-field"><span>Additional details <small>(optional)</small></span><textarea id="community-report-details" maxlength="500" rows="3" placeholder="Add context that will help the moderator review this report"></textarea></label><button type="button" id="community-report-submit" class="community-primary" disabled>Submit report</button><p id="community-report-status" class="community-modal-error" role="status" aria-live="polite" hidden></p>`);
  if (!sheet) return;
  const submit = sheet.root.querySelector('#community-report-submit');
  sheet.root.querySelectorAll('input[name="community-report-reason"]').forEach((input) => input.addEventListener('change', () => { submit.disabled = false; }));
  submit.addEventListener('click', async () => {
    const reason = sheet.root.querySelector('input[name="community-report-reason"]:checked')?.value;
    if (!reason) return;
    const status = sheet.root.querySelector('#community-report-status');
    submit.disabled = true;
    try {
      const result = await window.convex.mutation(api.community.report, {
        targetType, targetId, reason,
        details: sheet.root.querySelector('#community-report-details')?.value.trim() || undefined,
      });
      status.textContent = result.duplicate ? 'This is already in the moderation queue.' : 'Report submitted. Thank you for helping keep Community safe.';
      status.classList.add('is-success');
      status.hidden = false;
      setTimeout(() => sheet.close(), 1100);
    } catch (error) {
      status.textContent = error?.message || 'Unable to submit the report.';
      status.hidden = false;
      submit.disabled = false;
    }
  });
}

function messageActions(button) {
  const canDelete = button.dataset.canDelete === 'true' || button.dataset.groupOwner === 'true';
  const isOwn = button.dataset.isOwn === 'true';
  const username = button.dataset.username;
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">Comment actions</span><h2>@${escapeHtml(username)}</h2><div class="community-action-list">${canDelete ? '<button type="button" id="community-action-delete" class="is-danger">Delete comment<span>Remove it from the conversation</span></button>' : ''}${!isOwn ? '<button type="button" id="community-action-report">Report comment<span>Send it to the moderation queue</span></button><button type="button" id="community-action-block" class="is-danger">Block user<span>Hide each other’s rankings and comments</span></button>' : ''}</div>`);
  if (!sheet) return;
  sheet.root.querySelector('#community-action-delete')?.addEventListener('click', async () => {
    if (!confirm('Delete this comment?')) return;
    await window.convex.mutation(api.community.deleteMessage, { messageId: button.dataset.messageId });
    sheet.close(); await loadOverview();
  });
  sheet.root.querySelector('#community-action-report')?.addEventListener('click', () => reportTarget('message', button.dataset.messageId));
  sheet.root.querySelector('#community-action-block')?.addEventListener('click', async () => {
    if (!confirm(`Block @${username}? You will no longer see each other’s rankings or comments.`)) return;
    await window.convex.mutation(api.community.blockProfile, { profileId: button.dataset.profileId });
    sheet.close(); await loadOverview();
  });
}

async function shareInvite(invite) {
  const text = `Join my Bankroll Board community. Code: ${invite.code}\n${invite.link}`;
  try {
    const { Share } = await import('@capacitor/share');
    await Share.share({ title: 'Bankroll Board Community', text, url: invite.link, dialogTitle: 'Invite friends' });
  } catch {
    if (navigator.share) await navigator.share({ title: 'Bankroll Board Community', text });
    else { await navigator.clipboard.writeText(text); alert('Invite copied to your clipboard.'); }
  }
}

async function showMembers() {
  if (!view.communityId) return;
  const members = await window.convex.query(api.community.listCommunityMembers, { communityId: view.communityId });
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">${escapeHtml(currentData.selectedCommunity.name)}</span><h2>${members.length} members</h2><div class="community-member-list">${members.map((member) => `<div>${avatar(member)}<span><strong>@${escapeHtml(member.username)}</strong><small>${member.role}${member.sharingEnabled ? ' · sharing' : ' · hidden'}</small></span>${member.canRemove ? `<button type="button" data-remove-member="${escapeHtml(member.profileId)}">Remove</button>` : ''}</div>`).join('')}</div>`);
  sheet?.root.querySelectorAll('[data-remove-member]').forEach((button) => button.addEventListener('click', async () => {
    if (!confirm('Remove this member from the private community?')) return;
    await window.convex.mutation(api.community.removeMember, { communityId: view.communityId, profileId: button.dataset.removeMember });
    sheet.close(); await loadOverview();
  }));
}

async function showInvites() {
  if (!view.communityId) return;
  const invites = await window.convex.query(api.community.listCommunityInvites, { communityId: view.communityId });
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">Invite management</span><h2>${escapeHtml(currentData.selectedCommunity.name)}</h2><p>Invite codes are shown only when created. Active invitations can be revoked here.</p><div class="community-member-list">${invites.length ? invites.map((invite) => {
    const expiry = new Date(invite.expiresAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
    return `<div><span class="community-invite-status is-${escapeHtml(invite.status)}">${escapeHtml(invite.status.slice(0, 1).toUpperCase())}</span><span><strong>${escapeHtml(invite.status[0].toUpperCase() + invite.status.slice(1))} invitation</strong><small>Expires ${escapeHtml(expiry)}</small></span>${invite.status === 'active' ? `<button type="button" data-revoke-invite="${escapeHtml(invite.inviteId)}">Revoke</button>` : ''}</div>`;
  }).join('') : '<div class="community-invite-empty"><span><strong>No invitations yet</strong><small>Create one with Invite friends.</small></span></div>'}</div>`);
  sheet?.root.querySelectorAll('[data-revoke-invite]').forEach((button) => button.addEventListener('click', async () => {
    if (!confirm('Revoke this invitation? Its link and code will stop working immediately.')) return;
    await window.convex.mutation(api.community.revokeInvite, { inviteId: button.dataset.revokeInvite });
    sheet.close();
    await showInvites();
  }));
}

/** Replaces the old typed prompt with a tappable action sheet. Same mutations. */
function groupMenu(group) {
  if (!group) return;
  const isOwner = group.role === 'owner';
  const sheet = modal(`<button type="button" data-community-close class="community-modal-close" aria-label="Close">×</button><span class="community-kicker">Community options</span><h2>${escapeHtml(group.name)}</h2><div class="community-action-list">${isOwner ? `
    <button type="button" id="community-group-rename">Rename community<span>Members see the new name immediately</span></button>
    <button type="button" id="community-group-invites">Manage invitations<span>Review or revoke active invite codes</span></button>
    <button type="button" id="community-group-delete" class="is-danger">Delete community<span>Removes the board, invitations, and chat</span></button>`
    : `<button type="button" id="community-group-leave" class="is-danger">Leave community<span>Your profile and results are removed right away</span></button>`}</div>`);
  if (!sheet) return;
  sheet.root.querySelector('#community-group-rename')?.addEventListener('click', () => {
    sheet.close();
    simpleForm({
      kicker: 'Private community', title: 'Rename community', body: 'Pick something your friends will recognize.', inputLabel: 'Community name', placeholder: 'Friday Night Crew', initialValue: group.name, confirmLabel: 'Save name',
      onConfirm: (name) => window.convex.mutation(api.community.renameCommunity, { communityId: view.communityId, name }),
    });
  });
  sheet.root.querySelector('#community-group-invites')?.addEventListener('click', () => { sheet.close(); showInvites().catch((error) => alert(error.message)); });
  sheet.root.querySelector('#community-group-delete')?.addEventListener('click', async () => {
    if (!confirm(`Permanently delete ${group.name}, its invitations, and chat?`)) return;
    await window.convex.mutation(api.community.deleteCommunity, { communityId: view.communityId });
    view.communityId = null; sheet.close(); await loadOverview();
  });
  sheet.root.querySelector('#community-group-leave')?.addEventListener('click', async () => {
    if (!confirm(`Leave ${group.name}? Your profile and results will be removed immediately.`)) return;
    await window.convex.mutation(api.community.leaveCommunity, { communityId: view.communityId });
    view.communityId = null; sheet.close(); await loadOverview();
  });
}

function setupComposer() {
  const input = document.getElementById('community-message-input');
  const count = document.getElementById('community-message-count');
  if (!input) return;
  const resize = () => {
    input.style.height = 'auto';
    input.style.height = `${Math.min(input.scrollHeight, 132)}px`;
    if (count) count.textContent = `${input.value.length} / 500`;
  };
  input.addEventListener('input', resize);
  resize();
}

export function initCommunity(incoming) {
  const data = selectedData(incoming);
  if (!data) return;
  currentData = data;
  if (data.selectedCommunity) view.communityId = data.selectedCommunity.communityId;

  const pendingInvite = localStorage.getItem('pendingCommunityInvite');
  if (pendingInvite) {
    localStorage.removeItem('pendingCommunityInvite');
    setTimeout(() => simpleForm({
      kicker: 'Friend invitation', title: 'Join this private community?', body: 'Joining shares your verified Community profile and results only with this group.', inputLabel: 'Invite link', placeholder: pendingInvite, confirmLabel: 'Join and share',
      consentText: 'I agree to the Community Guidelines and consent to share my exact results, Bankroll Board balance, Journey progress, username, approved picture, and distinction with this private group.',
      onConfirm: async (invite) => { if (!currentData.me.guidelinesAccepted) await acceptCurrentGuidelines(); const result = await window.convex.mutation(api.community.redeemInvite, { invite: invite || pendingInvite, sharingConsent: true }); view.tab = 'private'; view.communityId = result.communityId; },
    }), 50);
  }

  document.querySelectorAll('[data-community-tab]').forEach((button) => button.addEventListener('click', () => loadOverview({ tab: button.dataset.communityTab, communityId: button.dataset.communityTab === 'private' ? view.communityId : null })));
  document.querySelectorAll('[data-community-timeframe]').forEach((button) => button.addEventListener('click', () => loadOverview({ timeframe: button.dataset.communityTimeframe })));
  document.querySelectorAll('[data-community-direction]').forEach((button) => button.addEventListener('click', () => loadOverview({ direction: button.dataset.communityDirection })));
  document.querySelectorAll('[data-community-profile]').forEach((button) => button.addEventListener('click', () => showProfile(button.dataset.communityProfile)));
  document.getElementById('community-guidelines')?.addEventListener('click', () => guidelinesModal(false));
  document.getElementById('community-review-guidelines')?.addEventListener('click', () => guidelinesModal(true));
  document.getElementById('community-composer-guidelines')?.addEventListener('click', () => guidelinesModal(true));

  document.getElementById('community-sharing-toggle')?.addEventListener('click', async () => {
    if (data.me.publicSharing) {
      if (!confirm('Turn off public sharing? Your ranking, profile, and prior public comments will disappear immediately.')) return;
      await window.convex.mutation(api.community.setPublicSharing, { enabled: false, consentAccepted: false });
      await loadOverview();
    } else enablePublicSharing();
  });
  ['community-enable-sharing', 'community-empty-share', 'community-composer-share'].forEach((id) => {
    document.getElementById(id)?.addEventListener('click', enablePublicSharing);
  });
  document.getElementById('community-composer-private-share')?.addEventListener('click', enablePrivateSharing);

  document.getElementById('community-edit-username')?.addEventListener('click', () => simpleForm({
    kicker: 'Community identity', title: 'Choose a username', body: '3–20 characters. Start with a letter; use letters, numbers, and underscores. Spaces are not allowed.', inputLabel: 'Username', placeholder: 'Big_Serg', initialValue: data.me.username, maxLength: 20, confirmLabel: 'Save username', validate: validateCommunityUsername,
    onConfirm: saveCommunityUsername,
  }));
  document.getElementById('community-avatar-button')?.addEventListener('click', () => document.getElementById('community-avatar-input')?.click());
  document.getElementById('community-avatar-input')?.addEventListener('change', async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    try {
      await uploadCommunityAvatar(file);
      alert('Your new picture is pending review. You can see it now; others continue seeing your approved picture or initials.');
      await loadOverview();
    } catch (error) {
      alert(communityErrorMessage(error, 'Unable to upload the profile picture.'));
    } finally {
      event.target.value = '';
    }
  });

  document.getElementById('community-group-select')?.addEventListener('change', (event) => loadOverview({ tab: 'private', communityId: event.target.value }));
  document.getElementById('community-create-group')?.addEventListener('click', () => simpleForm({
    kicker: 'Private community', title: 'Create a friends board', body: 'You can own up to five communities with 50 members each.', inputLabel: 'Community name', placeholder: 'Friday Night Crew', confirmLabel: 'Create and share',
    consentText: 'I agree to the Community Guidelines and consent to share my exact results, Bankroll Board balance, Journey progress, username, approved picture, and distinction with this private group.',
    onConfirm: async (name) => { if (!currentData.me.guidelinesAccepted) await acceptCurrentGuidelines(); const result = await window.convex.mutation(api.community.createCommunity, { name, sharingConsent: true }); view.tab = 'private'; view.communityId = result.communityId; },
  }));
  document.getElementById('community-join-group')?.addEventListener('click', () => simpleForm({
    kicker: 'Private invitation', title: 'Join a community', body: 'Paste the invite link or enter its code. Joining enables sharing only for this group.', inputLabel: 'Invite code or link', placeholder: '8H5K2M7QPX', confirmLabel: 'Join and share',
    consentText: 'I agree to the Community Guidelines and consent to share my exact results, Bankroll Board balance, Journey progress, username, approved picture, and distinction with this private group.',
    onConfirm: async (invite) => { if (!currentData.me.guidelinesAccepted) await acceptCurrentGuidelines(); const result = await window.convex.mutation(api.community.redeemInvite, { invite, sharingConsent: true }); view.tab = 'private'; view.communityId = result.communityId; },
  }));
  const inviteFriends = async () => {
    const invite = await window.convex.mutation(api.community.createInvite, { communityId: view.communityId });
    await shareInvite(invite);
  };
  document.getElementById('community-invite-friends')?.addEventListener('click', inviteFriends);
  document.getElementById('community-empty-invite')?.addEventListener('click', inviteFriends);
  document.getElementById('community-members')?.addEventListener('click', () => showMembers().catch((error) => alert(error.message)));
  document.getElementById('community-private-sharing')?.addEventListener('change', (event) => {
    const enabled = event.target.checked;
    if (enabled) {
      event.target.checked = false;
      enablePrivateSharing();
    }
    else window.convex.mutation(api.community.setPrivateSharing, { communityId: view.communityId, enabled: false, consentAccepted: false }).then(() => loadOverview()).catch((error) => alert(error.message));
  });
  document.getElementById('community-group-menu')?.addEventListener('click', () => groupMenu(data.selectedCommunity));

  document.getElementById('community-message-form')?.addEventListener('submit', async (event) => {
    event.preventDefault();
    const input = document.getElementById('community-message-input');
    const body = input?.value?.trim();
    if (!body) return;
    const button = event.currentTarget.querySelector('button');
    button.disabled = true;
    try {
      await window.convex.mutation(api.community.sendMessage, { body, communityId: view.tab === 'private' ? view.communityId : undefined });
      input.value = '';
      await loadOverview();
    } catch (error) { alert(error?.message || 'Unable to send message'); }
    finally { button.disabled = false; }
  });
  setupComposer();
  document.querySelectorAll('.community-message-menu').forEach((button) => button.addEventListener('click', () => messageActions(button)));
  document.getElementById('community-load-messages')?.addEventListener('click', async () => {
    const result = await window.convex.query(api.community.listMessages, { communityId: view.tab === 'private' ? view.communityId : undefined, before: data.messages.nextCursor });
    olderMessages = [...result.items, ...olderMessages];
    currentData = { ...currentData, messages: { ...currentData.messages, nextCursor: result.nextCursor } };
    renderCurrent();
  });
}
