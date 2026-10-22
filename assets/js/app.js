/* -----------------------------
   ShareBloom - Single Page App
-------------------------------- */

/* ✅ Real NGO Names List (Madurai + Tamil Nadu) */
const NGOs = [
  { name: "Madurai Care NGO", location: "Madurai", needs: ["Furniture", "Books", "Clothes", "Food"] },
  { name: "Madurai Hope Foundation", location: "Madurai", needs: ["Food", "Clothes", "Books"] },
  { name: "Madurai Seva Sangam", location: "Madurai", needs: ["Furniture", "Electronics", "Clothes"] },
  { name: "Madurai Helping Hands Trust", location: "Madurai", needs: ["Food", "Furniture", "Books"] },
  { name: "Madurai Children Welfare Society", location: "Madurai", needs: ["Books", "Clothes"] },

  { name: "Chennai Smile NGO", location: "Chennai", needs: ["Electronics", "Books", "Food"] },
  { name: "Coimbatore Green Hands", location: "Coimbatore", needs: ["Furniture", "Electronics", "Clothes"] },
  { name: "Trichy Uplift Foundation", location: "Trichy", needs: ["Food", "Clothes"] },
  { name: "Salem Care & Support Trust", location: "Salem", needs: ["Furniture", "Books"] }
];

let authMode = "login"; // login or register

function initApp() {
  // ✅ Make sure body class is correct on load
  applyAuthUIState();

  renderNavUser();
  updateSidebar();
  updateMenusByRole();
  updateHomeUX();

  setupSearchFilters(); // ✅ IMPORTANT

  showPage("home");
}

/* -----------------------------
   Auth UI State Controller
-------------------------------- */

function applyAuthUIState() {
  const user = getUser();

  // remove both first
  document.body.classList.remove("logged-in");
  document.body.classList.remove("logged-out");

  if (!user) {
    document.body.classList.add("logged-out");
  } else {
    document.body.classList.add("logged-in");
  }
}

/* -----------------------------
   Navigation
-------------------------------- */

function showPage(pageId) {
  document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
  const page = document.getElementById("page-" + pageId);
  if (page) page.classList.add("active");

  // Protect pages
  const user = getUser();
  const protectedPages = [
    "dashboard", "share", "ai", "senderRequests", "receiverRequestBoard",
    "receiverDashboard", "available", "myRequests", "notifications", "receiverPostRequest",
    "profile", "settings"
  ];

  if (protectedPages.includes(pageId) && !user) {
    toast("Please login first");
    showPage("login");
    return;
  }

  // Page refresh hooks
  if (pageId === "dashboard") refreshSenderDashboard();
  if (pageId === "receiverDashboard") refreshReceiverDashboard();

  if (pageId === "available") renderAvailableResources();
  if (pageId === "myRequests") renderMyRequests();
  if (pageId === "notifications") renderNotifications();

  if (pageId === "senderRequests") renderSenderRequests();
  if (pageId === "receiverRequestBoard") renderReceiverRequestBoard();

  if (pageId === "receiverPostRequest") prefillReceiverRequestCity();

  if (pageId === "profile") fillProfile();
}

function go(pageId) {
  showPage(pageId);
}

function renderNavUser() {
  const slot = document.getElementById("navUserSlot");
  const user = getUser();
  if (!slot) return;

  if (!user) {
    slot.innerHTML = `
      <button class="btn btn-ghost" onclick="go('login')">Login</button>
    `;
    return;
  }

  slot.innerHTML = `
    <button class="btn btn-soft" onclick="go('${user.role === "receiver" ? "receiverDashboard" : "dashboard"}')">
      Dashboard
    </button>
  `;
}

/* -----------------------------
   Auth
-------------------------------- */

function setAuthMode(mode) {
  authMode = mode;

  document.getElementById("tabLogin").classList.toggle("active", mode === "login");
  document.getElementById("tabRegister").classList.toggle("active", mode === "register");

  document.getElementById("registerExtra").classList.toggle("hidden", mode !== "register");
}

function authSubmit() {
  const email = document.getElementById("authEmail").value.trim();
  const pass = document.getElementById("authPass").value.trim();
  const role = document.getElementById("authRole").value;
  const city = document.getElementById("authCity").value.trim();

  const name = document.getElementById("authName")?.value.trim() || "";
  const phone = document.getElementById("authPhone")?.value.trim() || "";

  if (!email || !pass || !city) {
    toast("Please fill Email, Password, and City");
    return;
  }

  const users = getUsersDB();

  if (authMode === "register") {
    if (!name || !phone) {
      toast("Please fill Name and Phone for registration");
      return;
    }

    if (users[email]) {
      toast("Account already exists. Please login.");
      setAuthMode("login");
      return;
    }

    users[email] = {
      email,
      pass,
      role,
      city,
      name,
      phone,
      verified: true
    };

    saveUsersDB(users);

    setUser(users[email]);

    // ✅ IMPORTANT: Apply UI state AFTER login/register
    applyAuthUIState();

    toast("Registered successfully!");
    renderNavUser();
    updateSidebar();
    updateMenusByRole();
    updateHomeUX();

    showPage(role === "receiver" ? "receiverDashboard" : "dashboard");
    return;
  }

  // LOGIN
  if (!users[email]) {
    toast("No account found. Please register.");
    setAuthMode("register");
    return;
  }

  if (users[email].pass !== pass) {
    toast("Wrong password");
    return;
  }

  setUser(users[email]);

  // ✅ IMPORTANT: Apply UI state AFTER login
  applyAuthUIState();

  toast("Logged in successfully!");
  renderNavUser();
  updateSidebar();
  updateMenusByRole();
  updateHomeUX();

  showPage(users[email].role === "receiver" ? "receiverDashboard" : "dashboard");
}

function logout() {
  localStorage.removeItem("sb_current_user");

  // ✅ IMPORTANT: Apply UI state AFTER logout
  applyAuthUIState();

  toast("Logged out");

  renderNavUser();
  updateSidebar();
  updateMenusByRole();
  updateHomeUX();

  showPage("home");
}

/* -----------------------------
   Menus by role
-------------------------------- */

function updateMenusByRole() {
  const user = getUser();

  const senderMenu = document.getElementById("senderMenu");
  const receiverMenu = document.getElementById("receiverMenu");

  if (!senderMenu || !receiverMenu) return;

  if (!user) {
    senderMenu.classList.remove("hidden");
    receiverMenu.classList.add("hidden");
    return;
  }

  if (user.role === "receiver") {
    senderMenu.classList.add("hidden");
    receiverMenu.classList.remove("hidden");
  } else {
    senderMenu.classList.remove("hidden");
    receiverMenu.classList.add("hidden");
  }
}

/* -----------------------------
   Sidebar
-------------------------------- */

function updateSidebar() {
  const user = getUser();

  // ✅ Update body class always
  applyAuthUIState();

  const sideName = document.getElementById("sideName");
  const sideRole = document.getElementById("sideRole");
  const sideAvatar = document.getElementById("sideAvatar");

  // If not logged in, nothing else to update
  if (!user) return;

  // Update sidebar user details
  if (sideName) sideName.innerText = user.name || "User";
  if (sideRole) sideRole.innerText = (user.role || "").toUpperCase() + " • " + user.city;
  if (sideAvatar) sideAvatar.innerText = (user.name || "SB").slice(0, 2).toUpperCase();
}

function updateHomeUX() {
  const user = getUser();

  const quick = document.getElementById("homeQuickActions");
  const getStarted = document.getElementById("homeGetStartedBtn");
  const loginBtn = document.getElementById("homeLoginBtn");

  if (!quick || !getStarted || !loginBtn) return;

  if (!user) {
    quick.classList.add("hidden");
    getStarted.classList.remove("hidden");
    loginBtn.classList.remove("hidden");
  } else {
    quick.classList.remove("hidden");
    getStarted.classList.add("hidden");
    loginBtn.classList.add("hidden");
  }
}

/* -----------------------------
   Share Item + Photo Upload
-------------------------------- */

function toggleOtherType() {
  const type = document.getElementById("itemType").value;
  document.getElementById("itemTypeOther").classList.toggle("hidden", type !== "Others");
}

function toggleOtherCondition() {
  const c = document.getElementById("itemCondition").value;
  document.getElementById("itemConditionOther").classList.toggle("hidden", c !== "Others");
}

async function shareItem() {
  const user = getUser();
  if (!user) return;

  if (user.role !== "sender") {
    toast("Only senders can share items.");
    return;
  }

  let type = document.getElementById("itemType").value;
  if (type === "Others") {
    type = document.getElementById("itemTypeOther").value.trim();
  }

  let condition = document.getElementById("itemCondition").value;
  if (condition === "Others") {
    condition = document.getElementById("itemConditionOther").value.trim();
  }

  const qty = parseInt(document.getElementById("itemQty").value || "1", 10);
  const city = document.getElementById("itemCity").value.trim();
  const desc = document.getElementById("itemDesc").value.trim();

  const photoFile = document.getElementById("itemPhoto").files[0];

  if (!type || !condition || !city) {
    toast("Please fill Type, Condition, and City");
    return;
  }

  let photoBase64 = "";
  if (photoFile) {
    photoBase64 = await fileToBase64(photoFile);
  }

  const item = {
    id: "ITEM-" + Date.now(),
    senderEmail: user.email,
    senderName: user.name,
    senderCity: city,
    type,
    condition,
    qty,
    desc,
    photoBase64,
    createdAt: new Date().toISOString()
  };

  const items = getItemsDB();
  items.push(item);
  saveItemsDB(items);

  toast("Item submitted for AI matching!");
  runMatching(item);

  showPage("ai");
}

/* -----------------------------
   AI Matching (Strict city)
-------------------------------- */

function normalizeCity(text) {
  return (text || "")
    .toLowerCase()
    .replace(/[^a-z\s]/g, "")
    .trim();
}

function findBestNGO(item) {
  const senderCity = normalizeCity(item.senderCity);
  const cityNGOs = NGOs.filter(ngo => normalizeCity(ngo.location) === senderCity);
  if (!cityNGOs.length) return null;

  const itemType = (item.type || "").toLowerCase();

  const needed = cityNGOs.filter(ngo => {
    return ngo.needs.map(n => n.toLowerCase()).includes(itemType);
  });

  if (!needed.length) return cityNGOs[0];
  return needed[0];
}

function runMatching(item) {
  const ngo = findBestNGO(item);
  const box = document.getElementById("matchBox");

  if (!box) return;

  if (!ngo) {
    box.innerHTML = `
      <b>No NGO found in your city.</b><br/><br/>
      <span class="muted small">
        Try exact city name like: Madurai / Chennai / Coimbatore.
      </span>
    `;
    saveMatch(item.id, null);
    return;
  }

  saveMatch(item.id, ngo);

  box.innerHTML = `
    <div style="font-weight:900; font-size:18px;">✅ Match Found</div>
    <div style="margin-top:10px;">
      <b>Item:</b> ${item.type} (${item.condition}) × ${item.qty}<br/>
      <b>Sender City:</b> ${item.senderCity}<br/><br/>
      <b>Matched NGO:</b> ${ngo.name}<br/>
      <b>NGO Location:</b> ${ngo.location}<br/><br/>
      <span class="muted small">
        Receivers in your city can request this item.
      </span>
    </div>
  `;
}

/* -----------------------------
   Search + Filter Wiring
-------------------------------- */

function setupSearchFilters() {
  const availSearch = document.getElementById("availSearch");
  const availFilter = document.getElementById("availFilter");

  if (availSearch) availSearch.addEventListener("input", () => renderAvailableResources());
  if (availFilter) availFilter.addEventListener("change", () => renderAvailableResources());

  const senderReqSearch = document.getElementById("senderReqSearch");
  const senderReqFilter = document.getElementById("senderReqFilter");

  if (senderReqSearch) senderReqSearch.addEventListener("input", () => renderSenderRequests());
  if (senderReqFilter) senderReqFilter.addEventListener("change", () => renderSenderRequests());

  const myReqSearch = document.getElementById("myReqSearch");
  const myReqFilter = document.getElementById("myReqFilter");

  if (myReqSearch) myReqSearch.addEventListener("input", () => renderMyRequests());
  if (myReqFilter) myReqFilter.addEventListener("change", () => renderMyRequests());

  const notifySearch = document.getElementById("notifySearch");
  if (notifySearch) notifySearch.addEventListener("input", () => renderNotifications());
}

/* -----------------------------
   Receiver Side: Available Resources
-------------------------------- */

function renderAvailableResources() {
  const user = getUser();
  const list = document.getElementById("availableList");
  if (!list || !user) return;

  const items = getItemsDB();
  const myCity = normalizeCity(user.city);

  const cityItems = items.filter(i => normalizeCity(i.senderCity) === myCity);

  const q = (document.getElementById("availSearch")?.value || "").toLowerCase().trim();
  const typeFilter = document.getElementById("availFilter")?.value || "all";

  const filtered = cityItems.filter(i => {
    const matchesText =
      !q ||
      (i.type || "").toLowerCase().includes(q) ||
      (i.condition || "").toLowerCase().includes(q) ||
      (i.senderName || "").toLowerCase().includes(q) ||
      (i.desc || "").toLowerCase().includes(q) ||
      (i.senderCity || "").toLowerCase().includes(q);

    const matchesType = typeFilter === "all" ? true : i.type === typeFilter;

    return matchesText && matchesType;
  });

  if (!filtered.length) {
    list.innerHTML = `<div class="muted">No shared resources found (try changing search/filter).</div>`;
    return;
  }

  list.innerHTML = filtered.map(i => `
    <div class="list-item">
      <div style="font-weight:900;">${i.type} • ${i.condition} • Qty: ${i.qty}</div>
      <div class="muted small">City: ${i.senderCity} • Shared by: ${i.senderName}</div>

      ${i.photoBase64 ? `<img class="item-photo" src="${i.photoBase64}" alt="Item Photo"/>` : ""}

      <div style="margin-top:10px;">${i.desc || "No description added."}</div>

      <div style="margin-top:12px;">
        <button class="btn btn-primary" onclick="requestItem('${i.id}')">Request This</button>
      </div>
    </div>
  `).join("");
}

function requestItem(itemId) {
  const user = getUser();
  if (!user) return;

  if (user.role !== "receiver") {
    toast("Only receivers can request items.");
    return;
  }

  const requests = getRequestsDB();

  if (requests.some(r => r.itemId === itemId && r.receiverEmail === user.email)) {
    toast("You already requested this item.");
    return;
  }

  const req = {
    requestId: "REQ-" + Date.now(),
    itemId,
    receiverEmail: user.email,
    receiverName: user.name,
    receiverCity: user.city,
    status: "Pending",
    createdAt: new Date().toISOString()
  };

  requests.push(req);
  saveRequestsDB(requests);

  toast("Request sent to sender!");
  renderAvailableResources();
}

/* -----------------------------
   Sender Side: Requests Received
-------------------------------- */

function renderSenderRequests() {
  const user = getUser();
  const list = document.getElementById("senderRequestsList");
  if (!list || !user) return;

  const items = getItemsDB();
  const requests = getRequestsDB();

  const myItems = items.filter(i => i.senderEmail === user.email);
  const myItemIds = myItems.map(i => i.id);

  const myRequests = requests.filter(r => myItemIds.includes(r.itemId));

  const q = (document.getElementById("senderReqSearch")?.value || "").toLowerCase().trim();
  const statusFilter = document.getElementById("senderReqFilter")?.value || "all";

  const filtered = myRequests.filter(r => {
    const item = items.find(i => i.id === r.itemId);

    const searchBlob = `
      ${item?.type || ""} 
      ${item?.condition || ""} 
      ${item?.senderCity || ""} 
      ${r.receiverName || ""} 
      ${r.receiverCity || ""} 
      ${r.status || ""}
    `.toLowerCase();

    const matchesText = !q || searchBlob.includes(q);

    const matchesStatus =
      statusFilter === "all"
        ? true
        : (r.status || "").toLowerCase() === statusFilter;

    return matchesText && matchesStatus;
  });

  if (!filtered.length) {
    list.innerHTML = `<div class="muted">No requests found (try changing search/filter).</div>`;
    return;
  }

  list.innerHTML = filtered.map(r => {
    const item = items.find(i => i.id === r.itemId);

    return `
      <div class="list-item">
        <div style="font-weight:900;">
          ${item?.type || "Item"} • ${item?.condition || ""} • Qty: ${item?.qty || ""}
        </div>
        <div class="muted small">
          Requested by: ${r.receiverName} • City: ${r.receiverCity}
        </div>

        <div style="margin-top:10px;">
          <b>Status:</b> ${r.status}
        </div>

        <div style="margin-top:12px; display:flex; gap:10px; flex-wrap:wrap;">
          ${r.status === "Pending"
            ? `
              <button class="btn btn-primary" onclick="acceptReceiverRequest('${r.requestId}')">Accept</button>
              <button class="btn btn-ghost" onclick="rejectReceiverRequest('${r.requestId}')">Reject</button>
            `
            : `<button class="btn btn-soft" disabled>Done</button>`
          }
        </div>
      </div>
    `;
  }).join("");
}

function acceptReceiverRequest(requestId) {
  const requests = getRequestsDB();
  const req = requests.find(r => r.requestId === requestId);
  if (!req) return;

  req.status = "Accepted";
  saveRequestsDB(requests);

  createNotification(req.receiverEmail, `✅ Your request has been accepted for item: ${req.itemId}`);

  toast("Request accepted! Receiver notified.");
  renderSenderRequests();
}

function rejectReceiverRequest(requestId) {
  const requests = getRequestsDB();
  const req = requests.find(r => r.requestId === requestId);
  if (!req) return;

  req.status = "Rejected";
  saveRequestsDB(requests);

  createNotification(req.receiverEmail, `❌ Your request was rejected for item: ${req.itemId}`);

  toast("Request rejected. Receiver notified.");
  renderSenderRequests();
}

/* -----------------------------
   Receiver Side: My Requests
-------------------------------- */

function renderMyRequests() {
  const user = getUser();
  const list = document.getElementById("myRequestsList");
  if (!list || !user) return;

  const items = getItemsDB();
  const requests = getRequestsDB();
  const needs = getReceiverNeedsDB();

  const mineRequests = requests.filter(r => r.receiverEmail === user.email);
  const mineNeeds = needs.filter(n => n.receiverEmail === user.email);

  const q = (document.getElementById("myReqSearch")?.value || "").toLowerCase().trim();
  const statusFilter = document.getElementById("myReqFilter")?.value || "all";

  const filteredRequests = mineRequests.filter(r => {
    const item = items.find(i => i.id === r.itemId);

    const searchBlob = `
      ${item?.type || ""} 
      ${item?.condition || ""} 
      ${item?.senderName || ""} 
      ${r.status || ""}
    `.toLowerCase();

    const matchesText = !q || searchBlob.includes(q);

    const matchesStatus =
      statusFilter === "all"
        ? true
        : (r.status || "").toLowerCase() === statusFilter;

    return matchesText && matchesStatus;
  });

  const filteredNeeds = mineNeeds.filter(n => {
    const searchBlob = `
      ${n.type || ""} 
      ${n.condition || ""} 
      ${n.receiverCity || ""} 
      ${n.status || ""} 
      ${n.note || ""}
    `.toLowerCase();

    const matchesText = !q || searchBlob.includes(q);

    const matchesStatus =
      statusFilter === "all"
        ? true
        : (n.status || "").toLowerCase().includes(statusFilter);

    return matchesText && matchesStatus;
  });

  let html = "";

  if (!filteredRequests.length && !filteredNeeds.length) {
    list.innerHTML = `<div class="muted">No requests found (try changing search/filter).</div>`;
    return;
  }

  if (filteredRequests.length) {
    html += `<div style="font-weight:900; margin-bottom:10px;">📦 Requests for Shared Items</div>`;
    html += filteredRequests.map(r => {
      const item = items.find(i => i.id === r.itemId);
      return `
        <div class="list-item">
          <div style="font-weight:900;">
            ${item?.type || "Item"} • ${item?.condition || ""} • Qty: ${item?.qty || ""}
          </div>
          <div class="muted small">
            Sender: ${item?.senderName || ""}
          </div>
          <div style="margin-top:10px;">
            <b>Status:</b> ${r.status}
          </div>
        </div>
      `;
    }).join("");
  }

  if (filteredNeeds.length) {
    html += `<div style="font-weight:900; margin:18px 0 10px;">📝 My Posted Requests</div>`;
    html += filteredNeeds.map(n => `
      <div class="list-item">
        <div style="font-weight:900;">
          ${n.type} • ${n.condition} • Qty: ${n.qty}
        </div>
        <div class="muted small">
          City: ${n.receiverCity}
        </div>
        <div style="margin-top:10px;">
          ${n.note || "No notes"}
        </div>
        <div style="margin-top:10px;">
          <b>Status:</b> ${n.status}
        </div>
      </div>
    `).join("");
  }

  list.innerHTML = html;
}

/* -----------------------------
   Notifications
-------------------------------- */

function createNotification(receiverEmail, message) {
  const notifs = getNotificationsDB();
  notifs.push({
    id: "NOTIF-" + Date.now(),
    receiverEmail,
    message,
    createdAt: new Date().toISOString()
  });
  saveNotificationsDB(notifs);
}

function renderNotifications() {
  const user = getUser();
  const list = document.getElementById("notifyList");
  if (!list || !user) return;

  const notifs = getNotificationsDB();
  const mine = notifs.filter(n => n.receiverEmail === user.email);

  const q = (document.getElementById("notifySearch")?.value || "").toLowerCase().trim();

  const filtered = mine.filter(n => {
    if (!q) return true;
    return (n.message || "").toLowerCase().includes(q);
  });

  if (!filtered.length) {
    list.innerHTML = `<div class="muted">No notifications found (try changing search).</div>`;
    return;
  }

  list.innerHTML = filtered
    .slice()
    .reverse()
    .map(n => `
      <div class="list-item">
        <div style="font-weight:900;">${n.message}</div>
        <div class="muted small">Time: ${new Date(n.createdAt).toLocaleString()}</div>
      </div>
    `).join("");
}

/* -----------------------------
   Dashboards
-------------------------------- */

function refreshSenderDashboard() {
  const user = getUser();
  if (!user) return;

  const items = getItemsDB();
  const matches = getMatchesDB();
  const requests = getRequestsDB();

  const myItems = items.filter(i => i.senderEmail === user.email);
  const myItemIds = myItems.map(i => i.id);

  const myRequests = requests.filter(r => myItemIds.includes(r.itemId));

  document.getElementById("statShared").innerText = myItems.length;
  document.getElementById("statMatches").innerText = Object.keys(matches).length;
  document.getElementById("statRequests").innerText = myRequests.length;
}

function refreshReceiverDashboard() {
  const user = getUser();
  if (!user) return;

  const items = getItemsDB();
  const requests = getRequestsDB();
  const notifs = getNotificationsDB();

  const myCity = normalizeCity(user.city);

  const available = items.filter(i => normalizeCity(i.senderCity) === myCity);
  const myRequests = requests.filter(r => r.receiverEmail === user.email);
  const myNotifs = notifs.filter(n => n.receiverEmail === user.email);

  document.getElementById("statAvailable").innerText = available.length;
  document.getElementById("statMyRequests").innerText = myRequests.length;
  document.getElementById("statNotify").innerText = myNotifs.length;
}

/* -----------------------------
   Profile
-------------------------------- */

function fillProfile() {
  const user = getUser();
  if (!user) return;

  document.getElementById("profName").value = user.name || "";
  document.getElementById("profPhone").value = user.phone || "";
  document.getElementById("profEmail").value = user.email || "";
  document.getElementById("profCity").value = user.city || "";
}

function saveProfile() {
  const user = getUser();
  if (!user) return;

  const users = getUsersDB();

  user.name = document.getElementById("profName").value.trim();
  user.phone = document.getElementById("profPhone").value.trim();
  user.city = document.getElementById("profCity").value.trim();

  users[user.email] = user;
  saveUsersDB(users);
  setUser(user);

  updateSidebar();
  toast("Profile updated!");
}

/* -----------------------------
   Storage Helpers
-------------------------------- */

function getUser() {
  return JSON.parse(localStorage.getItem("sb_current_user") || "null");
}

function setUser(user) {
  localStorage.setItem("sb_current_user", JSON.stringify(user));
}

function getUsersDB() {
  return JSON.parse(localStorage.getItem("sb_users_db") || "{}");
}

function saveUsersDB(db) {
  localStorage.setItem("sb_users_db", JSON.stringify(db));
}

function getItemsDB() {
  return JSON.parse(localStorage.getItem("sb_items_db") || "[]");
}

function saveItemsDB(items) {
  localStorage.setItem("sb_items_db", JSON.stringify(items));
}

function getMatchesDB() {
  return JSON.parse(localStorage.getItem("sb_matches_db") || "{}");
}

function saveMatch(itemId, ngo) {
  const matches = getMatchesDB();
  matches[itemId] = ngo;
  localStorage.setItem("sb_matches_db", JSON.stringify(matches));
}

function getRequestsDB() {
  return JSON.parse(localStorage.getItem("sb_requests_db") || "[]");
}

function saveRequestsDB(reqs) {
  localStorage.setItem("sb_requests_db", JSON.stringify(reqs));
}

function getNotificationsDB() {
  return JSON.parse(localStorage.getItem("sb_notifications_db") || "[]");
}

function saveNotificationsDB(notifs) {
  localStorage.setItem("sb_notifications_db", JSON.stringify(notifs));
}

function getReceiverNeedsDB() {
  return JSON.parse(localStorage.getItem("sb_receiver_needs_db") || "[]");
}

function saveReceiverNeedsDB(needs) {
  localStorage.setItem("sb_receiver_needs_db", JSON.stringify(needs));
}

/* -----------------------------
   File Helper
-------------------------------- */

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

/* -----------------------------
   Toast
-------------------------------- */

function toast(msg) {
  const t = document.getElementById("toast");
  if (!t) return;

  t.innerText = msg;
  t.classList.add("show");

  setTimeout(() => t.classList.remove("show"), 2200);
}
