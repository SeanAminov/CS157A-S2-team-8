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

public class DashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        int desiredCount = 0;
        float creditsCompleted = 0;

        try (Connection conn = DBConnection.getConnection()) {

            String desiredSql = "SELECT COUNT(*) FROM DesiredCourses WHERE user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(desiredSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) desiredCount = rs.getInt(1);
                }
            }

            String creditsSql =
                "SELECT total_credits FROM Transcripts WHERE user_id = ?";
             
            try (PreparedStatement ps = conn.prepareStatement(creditsSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) creditsCompleted = rs.getFloat(1);
                }
            }

        } catch (SQLException e) {
            req.setAttribute("error", "Failed to load dashboard data: " + e.getMessage());
        }

        req.setAttribute("desiredCount", desiredCount);
        req.setAttribute("creditsCompleted", creditsCompleted);

        req.getRequestDispatcher("dashboard.jsp").forward(req, resp);
    }
}
