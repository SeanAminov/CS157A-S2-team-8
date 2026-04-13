package com.fmp.servlet;

import com.fmp.db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SearchCoursesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // make sure user is logged in before they can search
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String keyword = req.getParameter("keyword");

        // if no search term yet, just show the empty search page
        if (keyword == null || keyword.trim().isEmpty()) {
            req.getRequestDispatcher("search.jsp").forward(req, resp);
            return;
        }

        keyword = keyword.trim();
        int userId = (Integer) session.getAttribute("userId");

        // join sections with courses and professors so we can search across all three
        // also check if the user already added each course to their desired list
        String sql =
            "SELECT c.course_id, c.course_code, c.course_name, c.credits, " +
            "       s.section_id, s.term, s.days, s.start_time, s.end_time, " +
            "       s.location, s.format, " +
            "       p.first_name, p.last_name, p.rating, " +
            "       CASE WHEN dc.course_id IS NOT NULL THEN 1 ELSE 0 END AS already_added " +
            "FROM Sections s " +
            "INNER JOIN Courses c ON s.course_id = c.course_id " +
            "INNER JOIN Professors p ON s.professor_id = p.professor_id " +
            "LEFT JOIN DesiredCourses dc ON dc.course_id = c.course_id AND dc.user_id = ? " +
            "WHERE c.course_code LIKE ? " +
            "   OR c.course_name LIKE ? " +
            "   OR CONCAT(p.first_name, ' ', p.last_name) LIKE ? " +
            "ORDER BY c.course_code, s.days";

        List<Map<String, Object>> results = new ArrayList<>();
        String wildcard = "%" + keyword + "%";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.setString(2, wildcard);
            ps.setString(3, wildcard);
            ps.setString(4, wildcard);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("courseId",     rs.getInt("course_id"));
                    row.put("courseCode",   rs.getString("course_code"));
                    row.put("courseName",   rs.getString("course_name"));
                    row.put("credits",      rs.getString("credits"));
                    row.put("sectionId",    rs.getInt("section_id"));
                    row.put("term",         rs.getString("term"));
                    row.put("days",         rs.getString("days"));
                    row.put("startTime",    rs.getString("start_time"));
                    row.put("endTime",      rs.getString("end_time"));
                    row.put("location",     rs.getString("location"));
                    row.put("format",       rs.getString("format"));
                    row.put("professor",    rs.getString("first_name") + " " + rs.getString("last_name"));
                    row.put("rating",       rs.getBigDecimal("rating"));
                    row.put("alreadyAdded", rs.getInt("already_added") == 1);
                    results.add(row);
                }
            }

        } catch (SQLException e) {
            req.setAttribute("error", "Search failed: " + e.getMessage());
        }

        req.setAttribute("results", results);
        req.setAttribute("keyword", keyword);
        req.getRequestDispatcher("search.jsp").forward(req, resp);
    }
}
