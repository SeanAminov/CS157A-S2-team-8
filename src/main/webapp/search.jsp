<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map, java.math.BigDecimal" %>
<%
    // redirect to login if not signed in
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String keyword = (String) request.getAttribute("keyword");
    List<Map<String, Object>> results =
        (List<Map<String, Object>>) request.getAttribute("results");
    String error = (String) request.getAttribute("error");
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
            margin-bottom: 1.5rem;
        }
        .search-bar input {
            flex: 1;
        }
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

        <!-- search form sends GET to SearchCoursesServlet -->
        <form action="search" method="get" class="search-bar">
            <input type="text" name="keyword" class="form-control"
                   placeholder="e.g. CS157A, Data Structures, Turing..."
                   value="<%= keyword != null ? keyword : "" %>">
            <button type="submit" class="btn btn-primary">Search</button>
        </form>

        <% if (results != null && !results.isEmpty()) { %>
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
        <% } else if (keyword != null) { %>
            <div class="no-results">
                <p>No courses found for "<strong><%= keyword %></strong>". Try a different search.</p>
            </div>
        <% } %>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
