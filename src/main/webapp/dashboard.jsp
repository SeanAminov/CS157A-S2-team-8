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
        <a href="dashboard" class="navbar-brand">
            <span class="icon">&#127979;</span>
            FindMyProfessors
        </a>
        <div class="navbar-links">
            <a href="dashboard">Dashboard</a>
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
            <!-- <div class="dash-card">
                <h3>My Schedules</h3>
                <div class="value">0</div>
                <div class="desc">Saved schedules</div>
            </div> -->
            <div class="dash-card">
                <h3>Desired Courses</h3>
                <div class="value"><%= request.getAttribute("desiredCount") %></div>
                <div class="desc">Courses queued</div>
            </div>
            <div class="dash-card">
                <h3>Credits Completed</h3>
                <div class="value"><%= request.getAttribute("creditsCompleted") %></div>
                <div class="desc">Based on uploaded transcript</div>
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
            <a href="adminPanel" class="dash-nav-item" style="border-color:var(--blue);color:var(--blue);">
                <span class="nav-icon">&#128736;</span>
                Admin Panel
            </a>
            <% } %>
            <form id="deleteAccountForm" action="deleteAccount" method="post" style="display:none;"></form>
            <a href="#" class="dash-nav-item" style="border-color:var(--red); color:var(--red);"
               onclick="if(confirm('Are you sure? This cannot be undone.')) document.getElementById('deleteAccountForm').submit(); return false;">
                <span class="nav-icon">&#128465;</span>
                Delete My Account
            </a>
        </div>
   

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
