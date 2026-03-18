<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
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
    <title>Create Account &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <nav class="navbar">
        <a href="index.html" class="navbar-brand">
            <span class="icon">&#127979;</span>
            FindMyProfessors
        </a>
        <div class="navbar-links">
            <a href="login.jsp">Log In</a>
        </div>
    </nav>

    <div class="auth-page">
        <div class="auth-card">
            <h2>Create an account</h2>
            <p class="subtitle">Start planning your perfect schedule</p>

            <% if (error != null) { %>
                <div class="alert alert-error"><%= error %></div>
            <% } %>

            <form action="register" method="post" novalidate>
                <div class="form-group">
                    <label for="email">Email address</label>
                    <input type="email" id="email" name="email" class="form-control"
                           placeholder="you@example.com" required autofocus>
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" class="form-control"
                           placeholder="At least 6 characters" required>
                </div>
                <div class="form-group">
                    <label for="confirmPassword">Confirm password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" class="form-control"
                           placeholder="Re-enter your password" required>
                </div>
                <div class="form-group">
                    <label for="major">Major <span style="color:var(--muted);font-weight:400;">(optional)</span></label>
                    <select id="major" name="majorId" class="form-control">
                        <option value="">— Select your major —</option>
                        <option value="1">Computer Science</option>
                        <option value="2">Software Engineering</option>
                        <option value="3">Data Science</option>
                        <option value="4">Electrical Engineering</option>
                        <option value="5">Mechanical Engineering</option>
                        <option value="6">Business Administration</option>
                        <option value="7">Economics</option>
                        <option value="8">Mathematics</option>
                        <option value="9">Physics</option>
                        <option value="10">Biology</option>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary btn-block" style="margin-top:0.5rem;">
                    Create Account
                </button>
            </form>

            <p class="form-footer">
                Already have an account? <a href="login.jsp">Log in</a>
            </p>
        </div>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
