<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map, java.math.BigDecimal" %>
<%
    // redirect to login if not signed in
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // search keyword and results from the servlet
    String keyword = (String) request.getAttribute("keyword");
    List<Map<String, Object>> results =
        (List<Map<String, Object>>) request.getAttribute("results");
    String error = (String) request.getAttribute("error");

    // filter dropdown options loaded from the database
    Map<Integer, String> departments =
        (Map<Integer, String>) request.getAttribute("departments");
    List<String> formats =
        (List<String>) request.getAttribute("formats");
    List<String> dayOptions =
        (List<String>) request.getAttribute("dayOptions");

    // currently selected filter values (so dropdowns stay selected after search)
    String selectedDept   = (String) request.getAttribute("selectedDept");
    String selectedFormat = (String) request.getAttribute("selectedFormat");
    String selectedDays   = (String) request.getAttribute("selectedDays");
    String selectedRating = (String) request.getAttribute("selectedRating");
    String hideTaken      = (String) request.getAttribute("hideTaken");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Search Courses &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* search page specific styles */
        .search-container {
            max-width: 1000px;
            margin: 2rem auto;
            padding: 0 1.5rem;
        }
        .search-bar {
            display: flex;
            gap: 0.75rem;
            margin-bottom: 1rem;
        }
        .search-bar input {
            flex: 1;
        }

        /* --- filter panel --- */
        .filter-toggle {
            background: none;
            border: 1.5px solid var(--border);
            border-radius: var(--radius);
            padding: 0.45rem 1rem;
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--muted);
            cursor: pointer;
            margin-bottom: 1rem;
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            transition: border-color 0.15s, color 0.15s;
        }
        .filter-toggle:hover {
            border-color: var(--blue);
            color: var(--blue);
        }
        .filter-toggle.active {
            border-color: var(--blue);
            color: var(--blue);
        }
        .filter-panel {
            display: none;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 1.25rem;
            margin-bottom: 1.5rem;
            box-shadow: var(--shadow);
        }
        .filter-panel.open {
            display: block;
        }
        .filter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 1rem;
            margin-bottom: 1rem;
        }
        .filter-group label {
            display: block;
            font-size: 0.8rem;
            font-weight: 600;
            color: var(--muted);
            margin-bottom: 0.3rem;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        .filter-group select {
            width: 100%;
            padding: 0.45rem 0.7rem;
            font-size: 0.85rem;
        }
        .filter-actions {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding-top: 0.5rem;
            border-top: 1px solid var(--border);
        }
        .filter-check {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            font-size: 0.85rem;
            color: var(--text);
        }
        .filter-check input[type="checkbox"] {
            width: 16px;
            height: 16px;
            cursor: pointer;
        }
        .btn-clear-filters {
            margin-left: auto;
            background: none;
            border: none;
            color: var(--muted);
            font-size: 0.82rem;
            cursor: pointer;
            text-decoration: underline;
        }
        .btn-clear-filters:hover {
            color: var(--red);
        }

        /* --- results table --- */
        .results-table {
            width: 100%;
            border-collapse: collapse;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            overflow: hidden;
            box-shadow: var(--shadow);
        }
        .results-table th,
        .results-table td {
            padding: 0.7rem 1rem;
            text-align: left;
            font-size: 0.88rem;
            border-bottom: 1px solid var(--border);
        }
        .results-table th {
            background: var(--blue-light);
            font-weight: 600;
            color: var(--text);
        }
        .results-table tr:hover {
            background: #f3f4f6;
        }
        .rating-badge {
            display: inline-block;
            padding: 0.15rem 0.5rem;
            border-radius: 4px;
            font-weight: 600;
            font-size: 0.82rem;
        }
        .rating-good { background: #dcfce7; color: #166534; }
        .rating-ok { background: #fef9c3; color: #854d0e; }
        .rating-low { background: #fef2f2; color: #991b1b; }
        .rating-none { background: #f3f4f6; color: #6b7280; }
        .btn-add {
            background: var(--green);
            color: white;
            border: none;
            padding: 0.35rem 0.75rem;
            border-radius: var(--radius);
            font-size: 0.8rem;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-add:hover { opacity: 0.9; }
        .btn-added {
            background: var(--border);
            color: var(--muted);
            border: none;
            padding: 0.35rem 0.75rem;
            border-radius: var(--radius);
            font-size: 0.8rem;
            font-weight: 600;
            cursor: default;
        }
        .no-results {
            text-align: center;
            padding: 3rem;
            color: var(--muted);
        }
        .result-count {
            font-size: 0.85rem;
            color: var(--muted);
            margin-bottom: 0.75rem;
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
            <a href="dashboard.jsp">Dashboard</a>
            <a href="logout" class="btn btn-outline btn-sm">Log Out</a>
        </div>
    </nav>

    <div class="search-container">
        <div class="page-header">
            <h1>Search Courses</h1>
            <p>Search by course code, course name, or professor name.</p>
        </div>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <!-- search form - all filters are GET params so they can be bookmarked -->
        <form action="search" method="get" id="searchForm">
            <div class="search-bar">
                <input type="text" name="keyword" class="form-control"
                       placeholder="e.g. CS157A, Data Structures, Turing..."
                       value="<%= keyword != null ? keyword : "" %>">
                <button type="submit" class="btn btn-primary">Search</button>
            </div>

            <!-- toggle button to show/hide the filter panel -->
            <%
                // auto-open filters if any filter is active
                boolean filtersActive = (selectedDept != null && !selectedDept.isEmpty())
                    || (selectedFormat != null && !selectedFormat.isEmpty())
                    || (selectedDays != null && !selectedDays.isEmpty())
                    || (selectedRating != null && !selectedRating.isEmpty())
                    || "on".equals(hideTaken);
            %>
            <button type="button" class="filter-toggle <%= filtersActive ? "active" : "" %>"
                    onclick="toggleFilters()">
                &#9881; Filters
                <% if (filtersActive) { %><span style="color:var(--blue);">&#8226;</span><% } %>
            </button>

            <!-- filter panel with dropdowns -->
            <div class="filter-panel <%= filtersActive ? "open" : "" %>" id="filterPanel">
                <div class="filter-grid">

                    <!-- department dropdown -->
                    <div class="filter-group">
                        <label>Department</label>
                        <select name="department" class="form-control">
                            <option value="">All Departments</option>
                            <% if (departments != null) {
                                for (Map.Entry<Integer, String> dept : departments.entrySet()) {
                                    String sel = String.valueOf(dept.getKey()).equals(selectedDept) ? "selected" : "";
                            %>
                                <option value="<%= dept.getKey() %>" <%= sel %>><%= dept.getValue() %></option>
                            <%  }
                            } %>
                        </select>
                    </div>

                    <!-- format dropdown -->
                    <div class="filter-group">
                        <label>Format</label>
                        <select name="format" class="form-control">
                            <option value="">All Formats</option>
                            <% if (formats != null) {
                                for (String fmt : formats) {
                                    String sel = fmt.equals(selectedFormat) ? "selected" : "";
                            %>
                                <option value="<%= fmt %>" <%= sel %>><%= fmt %></option>
                            <%  }
                            } %>
                        </select>
                    </div>

                    <!-- days dropdown -->
                    <div class="filter-group">
                        <label>Days</label>
                        <select name="days" class="form-control">
                            <option value="">All Days</option>
                            <% if (dayOptions != null) {
                                for (String day : dayOptions) {
                                    String sel = day.equals(selectedDays) ? "selected" : "";
                            %>
                                <option value="<%= day %>" <%= sel %>><%= day %></option>
                            <%  }
                            } %>
                        </select>
                    </div>

                    <!-- minimum rating dropdown -->
                    <div class="filter-group">
                        <label>Min Rating</label>
                        <select name="minRating" class="form-control">
                            <option value="">Any Rating</option>
                            <option value="3.0" <%= "3.0".equals(selectedRating) ? "selected" : "" %>>3.0+</option>
                            <option value="3.5" <%= "3.5".equals(selectedRating) ? "selected" : "" %>>3.5+</option>
                            <option value="4.0" <%= "4.0".equals(selectedRating) ? "selected" : "" %>>4.0+</option>
                            <option value="4.5" <%= "4.5".equals(selectedRating) ? "selected" : "" %>>4.5+</option>
                        </select>
                    </div>
                </div>

                <div class="filter-actions">
                    <!-- checkbox to hide courses the user already took -->
                    <label class="filter-check">
                        <input type="checkbox" name="hideTaken"
                               <%= "on".equals(hideTaken) ? "checked" : "" %>>
                        Hide courses I've already taken
                    </label>
                    <button type="button" class="btn-clear-filters" onclick="clearFilters()">
                        Clear Filters
                    </button>
                </div>
            </div>
        </form>

        <% if (results != null && !results.isEmpty()) { %>
            <p class="result-count"><%= results.size() %> result<%= results.size() != 1 ? "s" : "" %> found</p>
            <table class="results-table">
                <thead>
                    <tr>
                        <th>Course</th>
                        <th>Name</th>
                        <th>Professor</th>
                        <th>Rating</th>
                        <th>Days</th>
                        <th>Time</th>
                        <th>Format</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <% for (Map<String, Object> row : results) {
                    BigDecimal rating = (BigDecimal) row.get("rating");
                    String ratingClass = "rating-none";
                    String ratingText = "N/A";
                    if (rating != null) {
                        double r = rating.doubleValue();
                        ratingText = String.format("%.1f", r);
                        if (r >= 4.0) ratingClass = "rating-good";
                        else if (r >= 3.0) ratingClass = "rating-ok";
                        else ratingClass = "rating-low";
                    }
                    boolean added = (Boolean) row.get("alreadyAdded");
                %>
                    <tr>
                        <td><strong><%= row.get("courseCode") %></strong></td>
                        <td><%= row.get("courseName") %></td>
                        <td><%= row.get("professor") %></td>
                        <td><span class="rating-badge <%= ratingClass %>"><%= ratingText %></span></td>
                        <td><%= row.get("days") %></td>
                        <td><%= row.get("startTime") %> - <%= row.get("endTime") %></td>
                        <td><%= row.get("format") %></td>
                        <td>
                            <% if (added) { %>
                                <span class="btn-added">Added</span>
                            <% } else { %>
                                <form action="addCourse" method="post" style="display:inline;">
                                    <input type="hidden" name="courseId" value="<%= row.get("courseId") %>">
                                    <input type="hidden" name="keyword" value="<%= keyword != null ? keyword : "" %>">
                                    <button type="submit" class="btn-add">+ Add</button>
                                </form>
                            <% } %>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        <% } else if (keyword != null || (results != null && results.isEmpty())) { %>
            <div class="no-results">
                <p>No courses found. Try a different search or adjust your filters.</p>
            </div>
        <% } %>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

    <script>
        // toggle the filter panel open/closed
        function toggleFilters() {
            var panel = document.getElementById('filterPanel');
            var btn = document.querySelector('.filter-toggle');
            panel.classList.toggle('open');
            btn.classList.toggle('active');
        }

        // reset all filter dropdowns and uncheck the checkbox, then submit
        function clearFilters() {
            var form = document.getElementById('searchForm');
            form.querySelector('[name="department"]').value = '';
            form.querySelector('[name="format"]').value = '';
            form.querySelector('[name="days"]').value = '';
            form.querySelector('[name="minRating"]').value = '';
            form.querySelector('[name="hideTaken"]').checked = false;
            form.submit();
        }
    </script>

</body>
</html>
