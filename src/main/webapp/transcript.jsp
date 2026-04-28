<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map" %>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    String major = (String) request.getAttribute("major");
    String totalCredits = (String) request.getAttribute("totalCredits");
    List<Map<String, String>> matched =
        (List<Map<String, String>>) request.getAttribute("matched");
    List<String> unmatched = (List<String>) request.getAttribute("unmatched");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Transcript &mdash; FindMyProfessors</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .upload-container {
            max-width: 800px;
            margin: 2rem auto;
            padding: 0 1.5rem;
        }
        .upload-card {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            padding: 2rem;
            margin-bottom: 1.5rem;
        }
        .upload-card h3 {
            margin-bottom: 0.75rem;
            font-size: 1.1rem;
        }
        .warning-box {
            background: #fef9c3;
            border: 1px solid #fde68a;
            border-radius: var(--radius);
            padding: 0.75rem 1rem;
            font-size: 0.85rem;
            color: #854d0e;
            margin-bottom: 1rem;
        }
        .results-table {
            width: 100%;
            border-collapse: collapse;
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            overflow: hidden;
        }
        .results-table th,
        .results-table td {
            padding: 0.6rem 1rem;
            text-align: left;
            font-size: 0.88rem;
            border-bottom: 1px solid var(--border);
        }
        .results-table th {
            background: var(--blue-light);
            font-weight: 600;
        }
        .stat-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
            margin-bottom: 1.5rem;
        }
        .stat-box {
            background: var(--blue-light);
            border-radius: var(--radius);
            padding: 1rem;
            text-align: center;
        }
        .stat-box .label {
            font-size: 0.8rem;
            color: var(--muted);
            text-transform: uppercase;
            font-weight: 600;
        }
        .stat-box .value {
            font-size: 1.4rem;
            font-weight: 700;
            color: var(--blue);
        }
        .unmatched-list {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
        }
        .unmatched-tag {
            background: #fef2f2;
            color: #991b1b;
            padding: 0.3rem 0.6rem;
            border-radius: 4px;
            font-size: 0.82rem;
            font-weight: 500;
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

    <div class="upload-container">
        <div class="page-header">
            <h1>Upload Transcript</h1>
            <p>Upload your unofficial SJSU transcript to automatically track completed courses.</p>
        </div>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        <% if (success != null) { %>
            <div class="alert alert-success"><%= success %></div>
        <% } %>

        <!-- upload form -->
        <div class="upload-card">
            <h3>Select Transcript PDF</h3>
            <div class="warning-box">
                Please make sure your transcript PDF is complete and no pages have values
                cut off. Scanned images or incomplete files will not be processed correctly.
            </div>
            <form action="uploadTranscript" method="post" enctype="multipart/form-data">
                <div class="form-group">
                    <input type="file" name="transcript" accept=".pdf" class="form-control" required>
                </div>
                <button type="submit" class="btn btn-primary">Upload and Process</button>
            </form>
        </div>

        <!-- show results after processing -->
        <% if (major != null || totalCredits != null) { %>
        <div class="upload-card">
            <h3>Transcript Summary</h3>
            <div class="stat-grid">
                <div class="stat-box">
                    <div class="label">Major</div>
                    <div class="value" style="font-size:1rem;"><%= major != null ? major : "Not found" %></div>
                </div>
                <div class="stat-box">
                    <div class="label">Total Credits</div>
                    <div class="value"><%= totalCredits != null ? totalCredits : "N/A" %></div>
                </div>
            </div>
        </div>
        <% } %>

        <% if (matched != null && !matched.isEmpty()) { %>
        <div class="upload-card">
            <h3>Matched Courses (<%= matched.size() %>)</h3>
            <table class="results-table">
                <thead>
                    <tr>
                        <th>Course Code</th>
                        <th>Course Name</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Map<String, String> course : matched) { %>
                    <tr>
                        <td><strong><%= course.get("code") %></strong></td>
                        <td><%= course.get("name") %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% } %>

        <% if (unmatched != null && !unmatched.isEmpty()) { %>
        <div class="upload-card">
            <h3>Unrecognized Courses (<%= unmatched.size() %>)</h3>
            <p style="font-size:0.85rem; color:var(--muted); margin-bottom:0.75rem;">
                These courses were found in your transcript but are not in our database yet.
            </p>
            <div class="unmatched-list">
                <% for (String code : unmatched) { %>
                    <span class="unmatched-tag"><%= code %></span>
                <% } %>
            </div>
        </div>
        <% } %>
    </div>

    <footer class="footer">
        &copy; 2026 FindMyProfessors &mdash; CS157A Team 8
    </footer>

</body>
</html>
