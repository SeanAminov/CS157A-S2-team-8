<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Redirect logged-in users away from login page
    if (session.getAttribute("userId") != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log In &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <nav class="navbar">
        <a href="index.html" class="navbar-brand">
            <span class="icon">&#127979;</span>
            FindMyProfessors
        </a>
        <div class="navbar-links">
            <a href="register.jsp">Create account</a>
        </div>
    </nav>

    <div class="auth-page">
        <div class="auth-card">
            <h2>Welcome back</h2>
            <p class="subtitle">Log in to manage your schedule</p>

            <% if (error != null) { %>
                <div class="alert alert-error"><%= error %></div>
            <% } %>

            <% String successMsg = request.getParameter("registered"); if ("true".equals(successMsg)) { %>
                <div class="alert alert-success">Account created! You can now log in.</div>
            <% } %>

            <form action="login" method="post" novalidate>
                <div class="form-group">
                    <label for="email">Email address</label>
                    <input type="email" id="email" name="email" class="form-control"
                           placeholder="you@example.com" required autofocus>
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" class="form-control"
                           placeholder="••••••••" required>
                </div>
                <button type="submit" class="btn btn-primary btn-block" style="margin-top:0.5rem;">
                    Log In
                </button>
            </form>

            <p class="form-footer">
                Don't have an account? <a href="register.jsp">Sign up</a>
            </p>
        </div>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
