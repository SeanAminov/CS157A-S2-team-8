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

public class AddCourseServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        String courseIdStr = req.getParameter("courseId");
        String keyword = req.getParameter("keyword");
        String redirectTo = req.getParameter("redirect"); // optional override for where to land after add
        boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));

        String fallback = "myCourses".equals(redirectTo) ? "myCourses"
                        : "search?keyword=" + (keyword != null ? keyword : "");

        if (courseIdStr == null || courseIdStr.isBlank()) {
            resp.sendRedirect(fallback);
            return;
        }

        int courseId;
        try {
            courseId = Integer.parseInt(courseIdStr);
        } catch (NumberFormatException e) {
            resp.sendRedirect(fallback);
            return;
        }

        // first check if this course is already in the user's desired list
        String checkSql = "SELECT 1 FROM DesiredCourses WHERE user_id = ? AND course_id = ?";
        String insertSql = "INSERT INTO DesiredCourses (user_id, course_id) VALUES (?, ?)";

        try (Connection conn = DBConnection.getConnection()) {

            // see if the user already added this course
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                checkPs.setInt(1, userId);
                checkPs.setInt(2, courseId);

                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next()) {
                        resp.sendRedirect(fallback);
                        return;
                    }
                }
            }

            // not a duplicate, go ahead and insert
            try (PreparedStatement insertPs = conn.prepareStatement(insertSql)) {
                insertPs.setInt(1, userId);
                insertPs.setInt(2, courseId);
                insertPs.executeUpdate();
            }

        } catch (SQLException e) {
            if (isAjax) { resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR); return; }
            req.setAttribute("error", "Could not add course: " + e.getMessage());
        }

        if (isAjax) {
            resp.setStatus(HttpServletResponse.SC_OK);
        } else {
            resp.sendRedirect(fallback);
        }
    }
}
