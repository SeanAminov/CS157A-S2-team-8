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

        // accept either sectionId (new) or courseId (legacy) so Daniel's pages still work
        String sectionIdStr = req.getParameter("sectionId");
        String courseIdStr  = req.getParameter("courseId");
        String keyword = req.getParameter("keyword");
        String redirectTo = req.getParameter("redirect");
        boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));

        String fallback = "myCourses".equals(redirectTo) ? "myCourses"
                        : "search?keyword=" + (keyword != null ? keyword : "");

        // figure out which id was passed
        String idStr = (sectionIdStr != null && !sectionIdStr.isBlank()) ? sectionIdStr : courseIdStr;
        if (idStr == null || idStr.isBlank()) {
            resp.sendRedirect(fallback);
            return;
        }

        int sectionId;
        try {
            sectionId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            resp.sendRedirect(fallback);
            return;
        }

        // check if this section is already in the user's desired list
        String checkSql = "SELECT 1 FROM DesiredCourses WHERE user_id = ? AND section_id = ?";
        String insertSql = "INSERT INTO DesiredCourses (user_id, section_id) VALUES (?, ?)";

        try (Connection conn = DBConnection.getConnection()) {

            // see if the user already added this section
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                checkPs.setInt(1, userId);
                checkPs.setInt(2, sectionId);

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
                insertPs.setInt(2, sectionId);
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
