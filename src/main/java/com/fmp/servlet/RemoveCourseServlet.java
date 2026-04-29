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
import java.sql.SQLException;

public class RemoveCourseServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        String courseIdStr = req.getParameter("courseId");
        boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));

        if (courseIdStr == null || courseIdStr.isBlank()) {
            if (isAjax) { resp.sendError(HttpServletResponse.SC_BAD_REQUEST); return; }
            resp.sendRedirect("myCourses");
            return;
        }

        int courseId;
        try {
            courseId = Integer.parseInt(courseIdStr);
        } catch (NumberFormatException e) {
            if (isAjax) { resp.sendError(HttpServletResponse.SC_BAD_REQUEST); return; }
            resp.sendRedirect("myCourses");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "DELETE FROM DesiredCourses WHERE user_id = ? AND course_id = ?")) {
            ps.setInt(1, userId);
            ps.setInt(2, courseId);
            ps.executeUpdate();
        } catch (SQLException e) {
            if (isAjax) { resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR); return; }
        }

        if (isAjax) {
            resp.setStatus(HttpServletResponse.SC_OK);
        } else {
            resp.sendRedirect("myCourses");
        }
    }
}
