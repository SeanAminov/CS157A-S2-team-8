<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String userEmail = (String) session.getAttribute("userEmail");
    String userRole  = (String) session.getAttribute("userRole");
    String firstName = userEmail != null ? userEmail.split("@")[0] : "User";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <nav class="navbar">
        <a href="dashboard.jsp" class="navbar-brand">
            <span class="icon">&#127979;</span>
            FindMyProfessors
        </a>
        <div class="navbar-links">
            <span style="font-size:0.85rem;color:var(--muted);">
                <%= userEmail %>
            </span>
            <a href="logout" class="btn btn-outline btn-sm">Log Out</a>
        </div>
    </nav>

    <div class="dashboard">
        <div class="page-header">
            <h1>Welcome, <%= firstName %>!</h1>
            <p>Here's an overview of your academic planner.</p>
        </div>

        <!-- Quick stats -->
        <div class="dashboard-grid">
            <div class="dash-card">
                <h3>My Schedules</h3>
                <div class="value">0</div>
                <div class="desc">Saved schedules</div>
            </div>
            <div class="dash-card">
                <h3>Desired Courses</h3>
                <div class="value">0</div>
                <div class="desc">Courses queued</div>
            </div>
            <div class="dash-card">
                <h3>Credits Completed</h3>
                <div class="value">—</div>
                <div class="desc">Upload transcript to track</div>
            </div>
        </div>

        <!-- Quick actions -->
        <div class="dash-nav">
            <a href="buildSchedule" class="dash-nav-item">
                <span class="nav-icon">&#128197;</span>
                Build Schedule
            </a>
            <a href="search" class="dash-nav-item">
                <span class="nav-icon">&#128269;</span>
                Search Courses
            </a>
            <a href="myCourses" class="dash-nav-item">
                <span class="nav-icon">&#128218;</span>
                My Courses
            </a>
            <a href="uploadTranscript" class="dash-nav-item">
                <span class="nav-icon">&#128196;</span>
                Upload Transcript
            </a>
            <a href="changePassword" class="dash-nav-item">
                <span class="nav-icon">&#128274;</span>
                Change Password
            </a>
            <% if ("admin".equals(userRole)) { %>
            <a href="#" class="dash-nav-item" style="border-color:var(--blue);color:var(--blue);">
                <span class="nav-icon">&#9881;</span>
                Admin Panel
            </a>
            <% } %>
        </div>
    </div>

        <!-- delete account section -->
        <div style="margin-top:3rem; padding-top:2rem; border-top:1px solid var(--border);">
            <h3 style="color:var(--red); font-size:0.95rem; margin-bottom:0.5rem;">Danger Zone</h3>
            <p style="font-size:0.85rem; color:var(--muted); margin-bottom:1rem;">
                This will permanently delete your account and all saved data.
            </p>
            <form action="deleteAccount" method="post"
                  onsubmit="return confirm('Are you sure? This cannot be undone.');">
                <button type="submit" class="btn"
                        style="background:var(--red); color:white; border-color:var(--red);">
                    Delete My Account
                </button>
            </form>
        </div>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
