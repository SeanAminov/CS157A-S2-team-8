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
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class MyCoursesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        try (Connection conn = DBConnection.getConnection()) {

            // Select every course the user has completed
            List<Map<String, Object>> completedCourses = new ArrayList<>();
            String completedSql =
                "SELECT c.course_id, c.course_code, c.course_name, c.credits " +
                "FROM TakenCourses tc " +
                "JOIN Transcripts t ON tc.transcript_id = t.transcript_id " +
                "JOIN Courses c ON tc.course_id = c.course_id " +
                "WHERE t.user_id = ? " +
                "ORDER BY c.course_code";
            try (PreparedStatement ps = conn.prepareStatement(completedSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = new HashMap<>();
                        row.put("courseId",   rs.getInt("course_id"));
                        row.put("courseCode", rs.getString("course_code"));
                        row.put("courseName", rs.getString("course_name"));
                        row.put("credits",    rs.getString("credits"));
                        completedCourses.add(row);
                    }
                }
            }

            // Select every course the user wants
            List<Map<String, Object>> desiredCourses = new ArrayList<>();
            Set<Integer> desiredCourseIds = new HashSet<>();
            String desiredSql =
                "SELECT c.course_id, c.course_code, c.course_name, c.credits " +
                "FROM DesiredCourses dc " +
                "JOIN Courses c ON dc.course_id = c.course_id " +
                "WHERE dc.user_id = ? " +
                "ORDER BY c.course_code";
            try (PreparedStatement ps = conn.prepareStatement(desiredSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        int cid = rs.getInt("course_id");
                        Map<String, Object> row = new HashMap<>();
                        row.put("courseId",   cid);
                        row.put("courseCode", rs.getString("course_code"));
                        row.put("courseName", rs.getString("course_name"));
                        row.put("credits",    rs.getString("credits"));
                        desiredCourses.add(row);
                        desiredCourseIds.add(cid);
                    }
                }
            }

            // Select user's declared major
            Integer majorId = null;
            String majorName = null;
            String majorSql =
                "SELECT u.major_id, m.major_name " +
                "FROM Users u " +
                "LEFT JOIN Majors m ON u.major_id = m.major_id " +
                "WHERE u.user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(majorSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int mid = rs.getInt("major_id");
                        if (!rs.wasNull()) majorId = mid;
                        majorName = rs.getString("major_name");
                    }
                }
            }

            // Select roadmap courses still needed, ordering it by year
            List<Map<String, Object>> roadmapCourses = new ArrayList<>();
            if (majorId != null) {
                String roadmapSql =
                    "SELECT c.course_id, c.course_code, c.course_name, c.credits, " +
                    "       mr.year, mr.semester, mr.slot_order " +
                    "FROM MajorRequirements mr " +
                    "JOIN Courses c ON mr.course_id = c.course_id " +
                    "WHERE mr.major_id = ? " +
                    "  AND mr.course_id NOT IN (" +
                    "    SELECT tc.course_id " +
                    "    FROM TakenCourses tc " +
                    "    JOIN Transcripts t ON tc.transcript_id = t.transcript_id " +
                    "    WHERE t.user_id = ?" +
                    "  ) " +
                    "ORDER BY mr.year, FIELD(mr.semester, 'Fall', 'Spring'), mr.slot_order";
                try (PreparedStatement ps = conn.prepareStatement(roadmapSql)) {
                    ps.setInt(1, majorId);
                    ps.setInt(2, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Map<String, Object> row = new HashMap<>();
                            row.put("courseId",   rs.getInt("course_id"));
                            row.put("courseCode", rs.getString("course_code"));
                            row.put("courseName", rs.getString("course_name"));
                            row.put("credits",    rs.getString("credits"));
                            row.put("year",       rs.getInt("year"));
                            row.put("semester",   rs.getString("semester"));
                            row.put("slotOrder",  rs.getInt("slot_order"));
                            roadmapCourses.add(row);
                        }
                    }
                }
            }

            req.setAttribute("completedCourses",  completedCourses);
            req.setAttribute("desiredCourses",    desiredCourses);
            req.setAttribute("desiredCourseIds",  desiredCourseIds);
            req.setAttribute("roadmapCourses",    roadmapCourses);
            req.setAttribute("majorName",         majorName);
            req.setAttribute("majorId",           majorId);

        } catch (SQLException e) {
            req.setAttribute("error", "Failed to load courses: " + e.getMessage());
        }

        req.getRequestDispatcher("mycourses.jsp").forward(req, resp);
    }
}
