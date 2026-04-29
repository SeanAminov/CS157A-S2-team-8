<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map, java.util.Set" %>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Map<String, Object>> completedCourses =
        (List<Map<String, Object>>) request.getAttribute("completedCourses");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> desiredCourses =
        (List<Map<String, Object>>) request.getAttribute("desiredCourses");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> roadmapCourses =
        (List<Map<String, Object>>) request.getAttribute("roadmapCourses");

    @SuppressWarnings("unchecked")
    Set<Integer> desiredCourseIds =
        (Set<Integer>) request.getAttribute("desiredCourseIds");

    String majorName = (String)  request.getAttribute("majorName");
    Integer majorId  = (Integer) request.getAttribute("majorId");
    String error     = (String)  request.getAttribute("error");

    int completedCount = completedCourses != null ? completedCourses.size() : 0;
    int desiredCount   = desiredCourses   != null ? desiredCourses.size()   : 0;
    int roadmapCount   = roadmapCourses   != null ? roadmapCourses.size()   : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Courses &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .courses-container {
            max-width: 960px;
            margin: 2rem auto;
            padding: 0 1.5rem;
        }

        /* Tab navigation */
        .tab-bar {
            display: flex;
            gap: 0;
            border-bottom: 2px solid var(--border);
            margin-bottom: 1.75rem;
        }
        .tab-btn {
            padding: 0.65rem 1.4rem;
            font-size: 0.9rem;
            font-weight: 600;
            color: var(--muted);
            background: none;
            border: none;
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            cursor: pointer;
            transition: color 0.15s, border-color 0.15s;
        }
        .tab-btn:hover { color: var(--blue); }
        .tab-btn.active {
            color: var(--blue);
            border-bottom-color: var(--blue);
        }
        .tab-badge {
            display: inline-block;
            background: var(--blue-light);
            color: var(--blue);
            border-radius: 999px;
            font-size: 0.72rem;
            font-weight: 700;
            padding: 0.1rem 0.55rem;
            margin-left: 0.35rem;
            vertical-align: middle;
        }
        .tab-panel { display: none; }
        .tab-panel.active { display: block; }

        /* Course table */
        .course-table {
            width: 100%;
            border-collapse: collapse;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            overflow: hidden;
            box-shadow: var(--shadow);
        }
        .course-table th,
        .course-table td {
            padding: 0.7rem 1rem;
            text-align: left;
            font-size: 0.88rem;
            border-bottom: 1px solid var(--border);
        }
        .course-table tr:last-child td { border-bottom: none; }
        .course-table th {
            background: var(--blue-light);
            font-weight: 600;
            color: var(--text);
        }
        .course-table tr:hover td { background: #f3f4f6; }

        .badge-done {
            display: inline-block;
            background: #dcfce7;
            color: #166534;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 700;
            padding: 0.15rem 0.6rem;
        }
        .badge-desired {
            display: inline-block;
            background: #fef9c3;
            color: #854d0e;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 700;
            padding: 0.15rem 0.6rem;
        }

        /* Roadmap grouping */
        .roadmap-group {
            margin-bottom: 1.5rem;
        }
        .roadmap-group-header {
            display: flex;
            align-items: center;
            gap: 0.6rem;
            font-size: 0.82rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.07em;
            color: var(--muted);
            margin-bottom: 0.5rem;
            padding-left: 0.25rem;
        }
        .roadmap-group-header .year-pill {
            background: var(--blue);
            color: white;
            border-radius: 999px;
            padding: 0.1rem 0.65rem;
            font-size: 0.75rem;
        }
        .roadmap-group-header .sem-pill {
            background: var(--blue-light);
            color: var(--blue);
            border-radius: 999px;
            padding: 0.1rem 0.65rem;
            font-size: 0.75rem;
        }

        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 3rem 1rem;
            color: var(--muted);
        }
        .empty-state .empty-icon { font-size: 2.5rem; margin-bottom: 0.75rem; }
        .empty-state p { font-size: 0.9rem; }
        .empty-state a { color: var(--blue); font-weight: 600; }

        /* Add / remove wish list buttons */
        .btn-wish {
            background: var(--blue);
            color: white;
            border: none;
            padding: 0.3rem 0.7rem;
            border-radius: var(--radius);
            font-size: 0.78rem;
            font-weight: 600;
            cursor: pointer;
            white-space: nowrap;
        }
        .btn-wish:hover { opacity: 0.88; }
        .btn-wished {
            background: var(--border);
            color: var(--muted);
            border: none;
            padding: 0.3rem 0.7rem;
            border-radius: var(--radius);
            font-size: 0.78rem;
            font-weight: 600;
            cursor: default;
            white-space: nowrap;
        }
        /* Remove button in Wanted Classes tab — always visible */
        .btn-remove {
            background: none;
            border: 1px solid #fca5a5;
            color: var(--red);
            padding: 0.28rem 0.6rem;
            border-radius: var(--radius);
            font-size: 0.75rem;
            font-weight: 600;
            cursor: pointer;
            white-space: nowrap;
        }
        .btn-remove:hover { background: #fef2f2; }

        /* Hover-to-remove toggle in Still Needed tab */
        .wished-toggle { display: inline-block; }
        .wished-toggle .btn-unwise {
            display: none;
            background: none;
            border: 1px solid #fca5a5;
            color: var(--red);
            padding: 0.28rem 0.6rem;
            border-radius: var(--radius);
            font-size: 0.75rem;
            font-weight: 600;
            cursor: pointer;
            white-space: nowrap;
        }
        .wished-toggle:hover .wished-label { display: none; }
        .wished-toggle:hover .btn-unwise   { display: inline-block; }
        .wished-toggle .btn-unwise:hover   { background: #fef2f2; }

        /* No-major callout */
        .callout {
            background: #fffbeb;
            border: 1px solid #fde68a;
            border-radius: var(--radius);
            padding: 1rem 1.25rem;
            font-size: 0.88rem;
            color: #92400e;
        }
        .callout a { color: #b45309; font-weight: 600; }
    </style>
</head>
<body>

    <nav class="navbar">
        <a href="dashboard.jsp" class="navbar-brand">
            <span class="icon">&#127979;</span>
            FindMyProfessors
        </a>
        <div class="navbar-links">
            <a href="dashboard.jsp">Dashboard</a>
            <a href="search">Search Courses</a>
            <a href="logout" class="btn btn-outline btn-sm">Log Out</a>
        </div>
    </nav>

    <div class="courses-container">
        <div class="page-header">
            <h1>My Courses</h1>
            <p>
                <% if (majorName != null) { %>
                    Your academic overview for <strong><%= majorName %></strong>.
                <% } else { %>
                    Track your completed courses, wish list, and remaining roadmap.
                <% } %>
            </p>
        </div>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <!-- Tabs -->
        <div class="tab-bar">
            <button class="tab-btn active" onclick="switchTab('completed', this)">
                Completed
                <span id="badge-completed" class="tab-badge"><%= completedCount %></span>
            </button>
            <button class="tab-btn" onclick="switchTab('desired', this)">
                Wanted Classes
                <span id="badge-desired" class="tab-badge"><%= desiredCount %></span>
            </button>
            <button class="tab-btn" onclick="switchTab('roadmap', this)">
                Still Needed
                <span id="badge-roadmap" class="tab-badge"><%= roadmapCount %></span>
            </button>
        </div>

        <!-- ===== Tab: Completed ===== -->
        <div id="tab-completed" class="tab-panel active">
            <% if (completedCourses == null || completedCourses.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-icon">&#128196;</div>
                    <p>No completed courses on record.<br>
                       <a href="uploadTranscript">Upload your transcript</a> to populate this list.</p>
                </div>
            <% } else { %>
                <table class="course-table">
                    <thead>
                        <tr>
                            <th>Course Code</th>
                            <th>Course Name</th>
                            <th>Credits</th>
                            <!-- <th>Status</th> -->
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Map<String, Object> c : completedCourses) { %>
                        <tr>
                            <td><strong><%= c.get("courseCode") %></strong></td>
                            <td><%= c.get("courseName") %></td>
                            <td><%= c.get("credits") %></td>
                            <!-- <td><span class="badge-done">&#10003; Completed</span></td> -->
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } %>
        </div>

        <!-- ===== Tab: Desired (Wish List) ===== -->
        <div id="tab-desired" class="tab-panel">
            <% if (desiredCourses == null || desiredCourses.isEmpty()) { %>
                <div id="desired-empty" class="empty-state">
                    <div class="empty-icon">&#128218;</div>
                    <p>Your wanted classes list is empty.<br>
                       <a href="search">Search for courses</a> and add them here.</p>
                </div>
            <% } else { %>
                <table id="desired-table" class="course-table">
                    <thead>
                        <tr>
                            <th>Course Code</th>
                            <th>Course Name</th>
                            <th>Credits</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Map<String, Object> c : desiredCourses) {
                               int desiredCid = (Integer) c.get("courseId"); %>
                        <tr data-course-id="<%= desiredCid %>">
                            <td><strong><%= c.get("courseCode") %></strong></td>
                            <td><%= c.get("courseName") %></td>
                            <td><%= c.get("credits") %></td>
                            <td>
                                <button class="btn-remove"
                                        data-cid="<%= desiredCid %>"
                                        onclick="removeFromWishList(this)">
                                    &#10005; Remove
                                </button>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } %>
        </div>

        <!-- ===== Tab: Roadmap (Still Needed) ===== -->
        <div id="tab-roadmap" class="tab-panel">
            <% if (majorId == null) { %>
                <div class="callout">
                    No major is set on your account. Please contact an advisor or update your profile
                    to see your degree roadmap.
                </div>
            <% } else if (roadmapCourses == null || roadmapCourses.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-icon">&#127881;</div>
                    <p>All roadmap courses are complete. Congratulations!</p>
                </div>
            <% } else { %>
                <%
                    // Group courses by year + semester as we iterate
                    int prevYear = -1;
                    String prevSemester = null;
                    for (Map<String, Object> c : roadmapCourses) {
                        int year = (Integer) c.get("year");
                        String semester = (String) c.get("semester");
                        boolean newGroup = (year != prevYear || !semester.equals(prevSemester));
                        if (newGroup) {
                            if (prevYear != -1) {
                                // close previous table
                %>
                            </tbody>
                        </table>
                    </div>
                <%
                            }
                %>
                    <div class="roadmap-group">
                        <div class="roadmap-group-header">
                            <span class="year-pill">Year <%= year %></span>
                            <span class="sem-pill"><%= semester %> Semester</span>
                        </div>
                        <table class="course-table">
                            <thead>
                                <tr>
                                    <th>Course Code</th>
                                    <th>Course Name</th>
                                    <th>Credits</th>
                                    <th></th>
                                </tr>
                            </thead>
                            <tbody>
                <%
                            prevYear = year;
                            prevSemester = semester;
                        }
                        int cid = (Integer) c.get("courseId");
                        boolean alreadyWanted = desiredCourseIds != null && desiredCourseIds.contains(cid);
                %>
                                <tr>
                                    <td><strong><%= c.get("courseCode") %></strong></td>
                                    <td><%= c.get("courseName") %></td>
                                    <td><%= c.get("credits") %></td>
                                    <td>
                                        <% if (alreadyWanted) { %>
                                            <div class="wished-toggle">
                                                <span class="btn-wished wished-label">&#10003; Added</span>
                                                <button class="btn-unwise"
                                                        data-cid="<%= cid %>"
                                                        onclick="removeFromRoadmap(this)">
                                                    &#10005; Remove
                                                </button>
                                            </div>
                                        <% } else { %>
                                            <button class="btn-wish"
                                                    data-cid="<%= cid %>"
                                                    onclick="addToWishList(this)">
                                                + Add
                                            </button>
                                        <% } %>
                                    </td>
                                </tr>
                <%
                    }
                    // close the last open group
                    if (prevYear != -1) {
                %>
                            </tbody>
                        </table>
                    </div>
                <%
                    }
                %>
            <% } %>
        </div>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

    <script>
        function switchTab(name, btn) {
            document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.getElementById('tab-' + name).classList.add('active');
            btn.classList.add('active');
        }

        function adjustBadge(id, delta) {
            const el = document.getElementById(id);
            if (el) el.textContent = Math.max(0, parseInt(el.textContent || '0') + delta);
        }

        function ajaxPost(url, courseId) {
            const params = new URLSearchParams();
            params.append('courseId', courseId);
            return fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params
            });
        }

        async function addToWishList(btn) {
            const courseId = parseInt(btn.dataset.cid, 10);
            btn.disabled = true;
            btn.textContent = '…';
            try {
                const res = await ajaxPost('addCourse', courseId);
                if (res.ok) {
                    const cell = btn.parentElement;
                    cell.innerHTML =
                        '<div class="wished-toggle">' +
                        '<span class="btn-wished wished-label">&#10003; Added</span>' +
                        '<button class="btn-unwise" data-cid="' + courseId + '" onclick="removeFromRoadmap(this)">&#10005; Remove</button>' +
                        '</div>';
                    adjustBadge('badge-desired', 1);
                } else {
                    btn.disabled = false;
                    btn.textContent = '+ Add';
                }
            } catch (e) {
                btn.disabled = false;
                btn.textContent = '+ Add';
            }
        }

        async function removeFromRoadmap(btn) {
            const courseId = parseInt(btn.dataset.cid, 10);
            try {
                const res = await ajaxPost('removeCourse', courseId);
                if (res.ok) {
                    const cell = btn.closest('td');
                    cell.innerHTML =
                        '<button class="btn-wish" data-cid="' + courseId + '" onclick="addToWishList(this)">+ Add</button>';
                    adjustBadge('badge-desired', -1);
                }
            } catch (e) { /* silently ignore */ }
        }

        async function removeFromWishList(btn) {
            const courseId = parseInt(btn.dataset.cid, 10);
            const row = btn.closest('tr');
            try {
                const res = await ajaxPost('removeCourse', courseId);
                if (res.ok) {
                    row.remove();
                    adjustBadge('badge-desired', -1);
                    // Show empty state if the tbody is now empty
                    const tbody = document.querySelector('#desired-table tbody');
                    if (tbody && tbody.children.length === 0) {
                        document.getElementById('desired-table').remove();
                        const panel = document.getElementById('tab-desired');
                        panel.innerHTML =
                            '<div class="empty-state">' +
                            '<div class="empty-icon">&#128218;</div>' +
                            '<p>Your wanted classes list is empty.<br>' +
                            '<a href="search">Search for courses</a> and add them here.</p>' +
                            '</div>';
                    }
                }
            } catch (e) { /* silently ignore */ }
        }
    </script>

</body>
</html>
