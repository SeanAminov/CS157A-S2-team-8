<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Password &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
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

    <div class="auth-page">
        <div class="auth-card">
            <h2>Change Password</h2>
            <p class="subtitle">Enter your current password and choose a new one.</p>

            <% if (error != null) { %>
                <div class="alert alert-error"><%= error %></div>
            <% } %>
            <% if (success != null) { %>
                <div class="alert alert-success"><%= success %></div>
            <% } %>

            <form action="changePassword" method="post">
                <div class="form-group">
                    <label for="currentPassword">Current Password</label>
                    <input type="password" id="currentPassword" name="currentPassword"
                           class="form-control" required>
                </div>
                <div class="form-group">
                    <label for="newPassword">New Password</label>
                    <input type="password" id="newPassword" name="newPassword"
                           class="form-control" required minlength="6">
                </div>
                <div class="form-group">
                    <label for="confirmPassword">Confirm New Password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword"
                           class="form-control" required>
                </div>
                <button type="submit" class="btn btn-primary btn-block">Update Password</button>
            </form>

            <div class="form-footer">
                <a href="dashboard.jsp">Back to Dashboard</a>
            </div>
        </div>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
