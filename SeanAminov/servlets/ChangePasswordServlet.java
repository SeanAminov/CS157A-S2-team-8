package com.fmp.servlet;

import com.fmp.db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ChangePasswordServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // make sure user is logged in
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }
        req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        String currentPassword = req.getParameter("currentPassword");
        String newPassword = req.getParameter("newPassword");
        String confirmPassword = req.getParameter("confirmPassword");

        // basic checks
        if (currentPassword == null || currentPassword.isBlank()) {
            req.setAttribute("error", "Current password is required.");
            req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
            return;
        }
        if (newPassword == null || newPassword.length() < 6) {
            req.setAttribute("error", "New password must be at least 6 characters.");
            req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
            return;
        }
        if (!newPassword.equals(confirmPassword)) {
            req.setAttribute("error", "New passwords do not match.");
            req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
            return;
        }

        // grab the current hash from the database to verify old password
        String selectSql = "SELECT password_hash FROM Users WHERE user_id = ?";
        String updateSql = "UPDATE Users SET password_hash = ? WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection()) {

            // verify the current password is correct
            String storedHash = null;
            try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        storedHash = rs.getString("password_hash");
                    }
                }
            }

            if (storedHash == null || !BCrypt.checkpw(currentPassword, storedHash)) {
                req.setAttribute("error", "Current password is incorrect.");
                req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
                return;
            }

            // make sure new password isn't the same as old one
            if (BCrypt.checkpw(newPassword, storedHash)) {
                req.setAttribute("error", "New password cannot be the same as your current password.");
                req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
                return;
            }

            // hash the new password and update
            String newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, newHash);
                ps.setInt(2, userId);
                ps.executeUpdate();
            }

            req.setAttribute("success", "Password updated successfully.");
            req.getRequestDispatcher("changepassword.jsp").forward(req, resp);

        } catch (SQLException e) {
            req.setAttribute("error", "Database error: " + e.getMessage());
            req.getRequestDispatcher("changepassword.jsp").forward(req, resp);
        }
    }
}
