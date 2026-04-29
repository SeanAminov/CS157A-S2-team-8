<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map" %>
<%@ page isELIgnored="true" %>
<%!
    /** Escape a value for use inside a JavaScript string literal. */
    private String esc(Object o) {
        if (o == null) return "null";
        return "\"" + o.toString()
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r",  "")
            + "\"";
    }
%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) { response.sendRedirect("login.jsp"); return; }

    String userEmail = (String) session.getAttribute("userEmail");

    @SuppressWarnings("unchecked")
    List<List<Map<String, Object>>> schedules =
        (List<List<Map<String,Object>>>) request.getAttribute("schedules");
    @SuppressWarnings("unchecked")
    List<String> availableTerms =
        (List<String>) request.getAttribute("availableTerms");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> desiredCourses =
        (List<Map<String,Object>>) request.getAttribute("desiredCourses");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> missedCourses =
        (List<Map<String,Object>>) request.getAttribute("missedCourses");

    String selectedTerm  = (String)  request.getAttribute("selectedTerm");
    String error         = (String)  request.getAttribute("error");

    int scheduleCount = schedules    != null ? schedules.size()    : 0;
    int desiredCount  = desiredCourses != null ? desiredCourses.size() : 0;
    int missedCount   = missedCourses  != null ? missedCourses.size()  : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Build Schedule &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Page Layout ── */
        .sched-container {
            max-width: 1100px;
            margin: 2rem auto;
            padding: 0 1.5rem;
        }

        /* ── Term selector ── */
        .term-form {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            margin-bottom: 1.5rem;
            flex-wrap: wrap;
        }
        .term-form label {
            font-size: 0.88rem;
            font-weight: 600;
            color: var(--muted);
            white-space: nowrap;
        }
        .term-form select {
            width: auto;
            min-width: 160px;
        }

        /* ── Alerts ── */
        .alert-warning {
            background: #fffbeb;
            color: #92400e;
            border-color: #fcd34d;
        }
        .missed-tag {
            display: inline-block;
            background: #fef3c7;
            color: #92400e;
            border: 1px solid #fcd34d;
            border-radius: 999px;
            font-size: 0.78rem;
            font-weight: 700;
            padding: 0.1rem 0.55rem;
            margin: 0 0.2rem;
        }

        /* ── Empty state ── */
        .empty-state {
            text-align: center;
            padding: 4rem 2rem;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
        }
        .empty-icon { font-size: 2.5rem; margin-bottom: 0.75rem; }
        .empty-state h3 { font-size: 1.1rem; font-weight: 700; margin-bottom: 0.4rem; }
        .empty-state p  { color: var(--muted); font-size: 0.9rem; margin-bottom: 1.25rem; }

        /* ── Navigator bar ── */
        .sched-nav-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 0.75rem;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 0.75rem 1.25rem;
            box-shadow: var(--shadow);
            margin-bottom: 1.25rem;
        }
        .sched-count {
            font-size: 0.92rem;
            font-weight: 600;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .badge-capped {
            background: #f3f4f6;
            color: var(--muted);
            border-radius: 999px;
            font-size: 0.72rem;
            font-weight: 600;
            padding: 0.15rem 0.55rem;
        }
        .sched-nav-btns { display: flex; gap: 0.5rem; }

        /* ── Section detail table ── */
        .section-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.85rem;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 1.25rem;
        }
        .section-table thead th {
            background: var(--bg);
            padding: 0.6rem 0.9rem;
            text-align: left;
            font-size: 0.78rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--muted);
            border-bottom: 1px solid var(--border);
        }
        .section-table tbody td {
            padding: 0.65rem 0.9rem;
            border-bottom: 1px solid var(--border);
            vertical-align: middle;
        }
        .section-table tbody tr:last-child td { border-bottom: none; }
        .section-table tbody tr:hover { background: var(--bg); }
        .section-table .course-name-small {
            color: var(--muted);
            font-size: 0.78rem;
            display: block;
            margin-top: 0.15rem;
        }

        /* ── Calendar wrapper ── */
        .cal-outer {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow-x: auto;
        }
        .cal-wrap {
            min-width: 620px;
        }

        /* Day header row */
        .cal-header {
            display: flex;
            border-bottom: 2px solid var(--border);
        }
        .cal-time-gutter {
            width: 52px;
            flex-shrink: 0;
        }
        .cal-day-header {
            flex: 1;
            text-align: center;
            font-size: 0.78rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
            padding: 0.6rem 0;
            border-left: 1px solid var(--border);
        }
        .cal-day-header.today {
            color: var(--blue);
        }

        /* Body */
        .cal-body {
            display: flex;
            position: relative;
        }

        /* Left gutter: time labels */
        .cal-time-col {
            width: 52px;
            flex-shrink: 0;
            position: relative;
        }
        .cal-hour-label {
            position: absolute;
            right: 8px;
            transform: translateY(-50%);
            font-size: 0.7rem;
            color: var(--muted);
            white-space: nowrap;
            line-height: 1;
        }

        /* Day columns */
        .cal-day-col {
            flex: 1;
            position: relative;
            border-left: 1px solid var(--border);
        }
        .cal-gridline {
            position: absolute;
            left: 0;
            right: 0;
            border-top: 1px solid var(--border);
        }
        .cal-half-line {
            position: absolute;
            left: 0;
            right: 0;
            border-top: 1px dashed #f0f0f0;
        }

        /* Event blocks */
        .cal-event {
            position: absolute;
            left: 2px;
            right: 2px;
            border-radius: 4px;
            padding: 3px 5px;
            overflow: hidden;
            cursor: default;
            transition: filter 0.15s;
            border-left-width: 3px;
            border-left-style: solid;
        }
        .cal-event:hover { filter: brightness(0.95); }
        .cal-event-code {
            font-size: 0.72rem;
            font-weight: 700;
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .cal-event-detail {
            font-size: 0.65rem;
            opacity: 0.85;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            line-height: 1.3;
        }

        /* Async section list */
        .async-section {
            margin-top: 1.25rem;
            padding: 1rem 1.25rem;
            background: var(--bg);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            font-size: 0.85rem;
        }
        .async-section h4 {
            font-size: 0.8rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--muted);
            margin-bottom: 0.5rem;
        }
        .async-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 0.35rem 0.75rem;
            margin: 0.25rem;
            font-size: 0.82rem;
        }
        .async-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            flex-shrink: 0;
        }
    </style>
</head>
<body>

<nav class="navbar">
    <a href="dashboard.jsp" class="navbar-brand">
        <span class="icon">&#127979;</span>
        FindMyProfessors
    </a>
    <div class="navbar-links">
        <a href="search">Search</a>
        <a href="myCourses">My Courses</a>
        <a href="buildSchedule" style="color:var(--blue);font-weight:700;">Build Schedule</a>
        <span style="font-size:0.85rem;color:var(--muted);"><%= userEmail %></span>
        <a href="logout" class="btn btn-outline btn-sm">Log Out</a>
    </div>
</nav>

<div class="sched-container">

    <div class="page-header">
        <h1>Build Schedule</h1>
        <p>Every conflict-free combination of your desired courses for the selected term.</p>
    </div>

    <% if (error != null) { %>
    <div class="alert alert-error"><%= error %></div>
    <% } %>

    <%-- Term selector --%>
    <% if (availableTerms != null && !availableTerms.isEmpty()) { %>
    <form class="term-form" method="get" action="buildSchedule">
        <label for="termSelect">Semester:</label>
        <select name="term" id="termSelect" class="form-control" onchange="this.form.submit()">
            <% for (String t : availableTerms) { %>
            <option value="<%= t %>"<%= t.equals(selectedTerm) ? " selected" : "" %>><%= t %></option>
            <% } %>
        </select>
    </form>
    <% } %>

    <%-- No desired courses --%>
    <% if (desiredCount == 0) { %>
    <div class="empty-state">
        <div class="empty-icon">&#128218;</div>
        <h3>No desired courses yet</h3>
        <p>Add courses to your wish list first, then come back to build a schedule.</p>
        <a href="myCourses" class="btn btn-primary">Go to My Courses</a>
    </div>

    <% } else { %>

    <%-- Courses with no sections in this term --%>
    <% if (missedCount > 0) { %>
    <div class="alert alert-warning" style="margin-bottom:1rem;">
        <strong>Heads up:</strong> The following desired course<%= missedCount > 1 ? "s have" : " has" %>
        no sections offered in <strong><%= selectedTerm %></strong> and could not be scheduled:
        <% for (Map<String, Object> mc : missedCourses) { %>
        <span class="missed-tag"><%= mc.get("courseCode") %></span>
        <% } %>
    </div>
    <% } %>

    <%-- No valid schedules --%>
    <% if (scheduleCount == 0) { %>
    <div class="empty-state">
        <div class="empty-icon">&#128260;</div>
        <h3>No conflict-free schedules found</h3>
        <p>Every combination of available sections for <strong><%= selectedTerm %></strong> has at least one time conflict.
           Try removing a course or choosing a different term.</p>
        <a href="myCourses" class="btn btn-outline">Edit My Courses</a>
    </div>

    <% } else { %>

    <%-- Schedule navigator --%>
    <div class="sched-nav-bar">
        <div class="sched-count">
            <span id="scheduleCounter">Schedule 1 of <%= scheduleCount %></span>
            <% if (scheduleCount >= 50) { %>
            <span class="badge-capped">capped at 50</span>
            <% } %>
        </div>
        <div class="sched-nav-btns">
            <button id="prevBtn" class="btn btn-outline btn-sm" onclick="navigate(-1)" disabled>&#8592; Prev</button>
            <button id="nextBtn" class="btn btn-outline btn-sm" onclick="navigate(1)"
                    <%= scheduleCount <= 1 ? "disabled" : "" %>>Next &#8594;</button>
        </div>
    </div>

    <%-- Section detail table (JS-populated) --%>
    <div id="courseListContainer"></div>

    <%-- Weekly calendar (JS-populated) --%>
    <div class="cal-outer">
        <div id="calendarContainer"></div>
    </div>

    <%-- Async / online section notice (JS-populated) --%>
    <div id="asyncContainer"></div>

    <% } /* end scheduleCount > 0 */ %>
    <% } /* end desiredCount > 0 */ %>

</div>

<footer class="footer">
    &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
</footer>

<%-- Build JSON string in a scriptlet BEFORE the <script> tag so the JS
     linter does not see raw Java code inside the script block.           --%>
<%
    StringBuilder _sb = new StringBuilder("[");
    if (schedules != null) {
        for (int _i = 0; _i < scheduleCount; _i++) {
            List<Map<String, Object>> _sched = schedules.get(_i);
            if (_i > 0) _sb.append(",\n");
            _sb.append("[");
            for (int _j = 0; _j < _sched.size(); _j++) {
                Map<String, Object> _s = _sched.get(_j);
                if (_j > 0) _sb.append(",");
                _sb.append("{");
                _sb.append("\"courseCode\":")    .append(esc(_s.get("courseCode")))    .append(",");
                _sb.append("\"courseName\":")    .append(esc(_s.get("courseName")))    .append(",");
                _sb.append("\"days\":")          .append(esc(_s.get("days")))          .append(",");
                _sb.append("\"startTime\":")     .append(esc(_s.get("startTime")))     .append(",");
                _sb.append("\"endTime\":")       .append(esc(_s.get("endTime")))       .append(",");
                _sb.append("\"location\":")      .append(esc(_s.get("location")))      .append(",");
                _sb.append("\"format\":")        .append(esc(_s.get("format")))        .append(",");
                _sb.append("\"professorName\":") .append(esc(_s.get("professorName"))) .append(",");
                _sb.append("\"rating\":")        .append(esc(_s.get("rating")));
                _sb.append("}");
            }
            _sb.append("]");
        }
    }
    _sb.append("]");
    String schedulesJson = _sb.toString();
%>
<script id="schedule-data" type="application/json"><%= schedulesJson %></script>
<script>
// ── Data from server ────────────────────────────────────────────────────────
const schedules = JSON.parse(document.getElementById('schedule-data').textContent);

// ── Color palette for courses ────────────────────────────────────────────────
const PALETTE = [
    { bg: '#dbeafe', border: '#2563eb', text: '#1e40af' },
    { bg: '#dcfce7', border: '#16a34a', text: '#15803d' },
    { bg: '#fef3c7', border: '#d97706', text: '#92400e' },
    { bg: '#fce7f3', border: '#db2777', text: '#9d174d' },
    { bg: '#ede9fe', border: '#7c3aed', text: '#5b21b6' },
    { bg: '#ffedd5', border: '#ea580c', text: '#9a3412' },
    { bg: '#e0f2fe', border: '#0284c7', text: '#075985' },
    { bg: '#f0fdf4', border: '#15803d', text: '#14532d' },
];

// ── Calendar constants ───────────────────────────────────────────────────────
const GRID_START  = 7 * 60;   // 7:00 AM in minutes
const GRID_END    = 22 * 60;  // 10:00 PM in minutes
const PX_PER_MIN  = 0.9;      // scale factor → total height = 810px
const TOTAL_H     = (GRID_END - GRID_START) * PX_PER_MIN;

const DAY_MAP = { M: 0, T: 1, W: 2, R: 3, F: 4, S: 5 };
const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// ── Helpers ──────────────────────────────────────────────────────────────────
function parseTime(str) {
    if (!str) return 0;
    str = str.trim();
    const isPM = /pm/i.test(str);
    const isAM = /am/i.test(str);
    str = str.replace(/\s*(am|pm)\s*/gi, '').trim();
    const parts = str.split(':');
    let h = parseInt(parts[0], 10) || 0;
    const m = parseInt(parts[1], 10) || 0;
    if (isPM && h !== 12) h += 12;
    if (isAM && h === 12) h = 0;
    return h * 60 + m;
}

/** Returns day indices (0=Mon … 5=Sat) for a standard day-code string. */
function getDayIndices(days) {
    if (!days) return [];
    const result = [];
    for (const c of days) {
        if (c in DAY_MAP) result.push(DAY_MAP[c]);
    }
    return [...new Set(result)];
}

/** True only if every character is a recognized day code. */
function isInPerson(days) {
    return days != null && /^[MTWRFS]+$/.test(days);
}

function fmtHour(h) {
    if (h === 0 || h === 24) return '12 AM';
    if (h === 12) return '12 PM';
    return h > 12 ? `${h - 12} PM` : `${h} AM`;
}

function starRating(r) {
    if (r == null) return '—';
    const n = parseFloat(r);
    if (isNaN(n)) return '—';
    const stars = Math.round(n * 2) / 2;
    return `${n.toFixed(1)} ★`;
}

// ── State ────────────────────────────────────────────────────────────────────
let currentIdx = 0;

function navigate(dir) {
    const next = currentIdx + dir;
    if (next < 0 || next >= schedules.length) return;
    currentIdx = next;
    renderSchedule(currentIdx);
}

// ── Course-list table ────────────────────────────────────────────────────────
function renderCourseList(schedule) {
    let html = `<table class="section-table" style="margin-bottom:1.25rem;">
        <thead><tr>
            <th style="width:16px"></th>
            <th>Course</th>
            <th>Days</th>
            <th>Time</th>
            <th>Location</th>
            <th>Format</th>
            <th>Professor</th>
            <th>Rating</th>
        </tr></thead><tbody>`;

    schedule.forEach((s, i) => {
        const color = PALETTE[i % PALETTE.length];
        const time = (s.startTime && s.endTime)
            ? `${s.startTime} – ${s.endTime}` : '—';
        html += `<tr>
            <td><div style="width:12px;height:12px;border-radius:3px;background:${color.border};flex-shrink:0"></div></td>
            <td><strong>${s.courseCode || ''}</strong>
                <span class="course-name-small">${s.courseName || ''}</span></td>
            <td>${s.days || '—'}</td>
            <td style="white-space:nowrap">${time}</td>
            <td>${s.location || '—'}</td>
            <td>${s.format   || '—'}</td>
            <td>${s.professorName || '—'}</td>
            <td style="white-space:nowrap">${starRating(s.rating)}</td>
        </tr>`;
    });

    html += '</tbody></table>';
    document.getElementById('courseListContainer').innerHTML = html;
}

// ── Weekly calendar ──────────────────────────────────────────────────────────
function renderCalendar(schedule) {
    // Determine if Saturday is needed
    const needsSat = schedule.some(s => isInPerson(s.days) && s.days.includes('S'));
    const numDays  = needsSat ? 6 : 5;

    // ── Header row ──────────────────────────────────────────────────────────
    let header = `<div class="cal-header">
        <div class="cal-time-gutter"></div>`;
    for (let d = 0; d < numDays; d++) {
        header += `<div class="cal-day-header">${DAY_LABELS[d]}</div>`;
    }
    header += '</div>';

    // ── Body: time gutter + day columns ─────────────────────────────────────
    let timeGutter = `<div class="cal-time-col" style="height:${TOTAL_H}px">`;
    for (let h = GRID_START / 60; h <= GRID_END / 60; h++) {
        const top = (h * 60 - GRID_START) * PX_PER_MIN;
        timeGutter += `<div class="cal-hour-label" style="top:${top}px">${fmtHour(h)}</div>`;
    }
    timeGutter += '</div>';

    // Build one HTML fragment per day column
    let dayCols = '';
    for (let d = 0; d < numDays; d++) {
        let colHtml = `<div class="cal-day-col" style="height:${TOTAL_H}px">`;

        // Hourly grid lines + half-hour dashes
        for (let h = GRID_START / 60; h <= GRID_END / 60; h++) {
            const top = (h * 60 - GRID_START) * PX_PER_MIN;
            colHtml += `<div class="cal-gridline" style="top:${top}px"></div>`;
            if (h < GRID_END / 60) {
                const half = top + 30 * PX_PER_MIN;
                colHtml += `<div class="cal-half-line" style="top:${half}px"></div>`;
            }
        }

        // Events
        schedule.forEach((s, i) => {
            if (!isInPerson(s.days)) return;
            const dayIndices = getDayIndices(s.days);
            if (!dayIndices.includes(d)) return;

            const startMin = parseTime(s.startTime);
            const endMin   = parseTime(s.endTime);
            if (startMin < GRID_START || endMin > GRID_END || startMin >= endMin) return;

            const top    = (startMin - GRID_START) * PX_PER_MIN;
            const height = (endMin - startMin) * PX_PER_MIN;
            const color  = PALETTE[i % PALETTE.length];

            colHtml += `<div class="cal-event"
                style="top:${top}px;height:${height}px;background:${color.bg};
                       border-left-color:${color.border};color:${color.text}"
                title="${s.courseCode} – ${s.courseName}\n${s.startTime} – ${s.endTime}\n${s.professorName}">`;
            colHtml += `<div class="cal-event-code">${s.courseCode}</div>`;
            if (height >= 36) {
                colHtml += `<div class="cal-event-detail">${s.professorName || ''}</div>`;
            }
            if (height >= 52 && s.location) {
                colHtml += `<div class="cal-event-detail">${s.location}</div>`;
            }
            colHtml += '</div>';
        });

        colHtml += '</div>';
        dayCols += colHtml;
    }

    const calHtml = `<div class="cal-wrap">
        ${header}
        <div class="cal-body">${timeGutter}${dayCols}</div>
    </div>`;

    document.getElementById('calendarContainer').innerHTML = calHtml;
}

// ── Async / online sections ──────────────────────────────────────────────────
function renderAsync(schedule) {
    const asyncSections = schedule.filter(s => !isInPerson(s.days));
    const container = document.getElementById('asyncContainer');
    if (asyncSections.length === 0) { container.innerHTML = ''; return; }

    let html = `<div class="async-section">
        <h4>Online / Async Sections</h4>
        <div>`;
    asyncSections.forEach((s, idx) => {
        const realIdx = schedule.indexOf(s);
        const color   = PALETTE[realIdx % PALETTE.length];
        const time = (s.startTime && s.endTime && s.startTime !== s.endTime)
            ? ` &middot; ${s.startTime} – ${s.endTime}` : '';
        html += `<span class="async-pill">
            <span class="async-dot" style="background:${color.border}"></span>
            <strong>${s.courseCode}</strong>
            <span style="color:var(--muted)">${s.days || 'Async'}${time} &middot; ${s.professorName || ''}</span>
        </span>`;
    });
    html += '</div></div>';
    container.innerHTML = html;
}

// ── Main render ──────────────────────────────────────────────────────────────
function renderSchedule(idx) {
    if (!schedules || schedules.length === 0) return;
    const schedule = schedules[idx];

    document.getElementById('scheduleCounter').textContent =
        `Schedule ${idx + 1} of ${schedules.length}`;
    document.getElementById('prevBtn').disabled = idx === 0;
    document.getElementById('nextBtn').disabled = idx === schedules.length - 1;

    renderCourseList(schedule);
    renderCalendar(schedule);
    renderAsync(schedule);
}

// Initial render
if (schedules.length > 0) renderSchedule(0);
</script>

</body>
</html>
