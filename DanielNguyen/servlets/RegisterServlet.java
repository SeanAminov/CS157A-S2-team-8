package com.fmp.servlet;

import com.fmp.db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

import org.mindrot.jbcrypt.BCrypt;

public class RegisterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect("register.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String email           = req.getParameter("email");
        String password        = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");
        String majorIdStr      = req.getParameter("majorId");

        // Basic validation
        if (email == null || email.isBlank()) {
            req.setAttribute("error", "Email is required.");
            req.getRequestDispatcher("register.jsp").forward(req, resp);
            return;
        }
        if (password == null || password.length() < 6) {
            req.setAttribute("error", "Password must be at least 6 characters.");
            req.getRequestDispatcher("register.jsp").forward(req, resp);
            return;
        }
        if (!password.equals(confirmPassword)) {
            req.setAttribute("error", "Passwords do not match.");
            req.getRequestDispatcher("register.jsp").forward(req, resp);
            return;
        }

        Integer majorId = null;
        if (majorIdStr != null && !majorIdStr.isBlank()) {
            try { majorId = Integer.parseInt(majorIdStr); } catch (NumberFormatException ignored) {}
        }

        String checkSql  = "SELECT user_id FROM Users WHERE email = ?";
        String insertSql = "INSERT INTO Users (role, email, password_hash, date_created, major_id) VALUES ('student', ?, ?, ?, ?)";
        
        
        try (Connection conn = DBConnection.getConnection()) {

            // Check for duplicate email
            try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setString(1, email.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        req.setAttribute("error", "An account with that email already exists.");
                        req.getRequestDispatcher("register.jsp").forward(req, resp);
                        return;
                    }
                }
            }

            // Insert new user
            // NOTE: store a proper hash here in production (e.g. BCrypt)
            try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                ps.setString(1, email.trim());
                
                String hashed_password = BCrypt.hashpw(password, BCrypt.gensalt());
                
                ps.setString(2, hashed_password);   // swap for hashed password when ready
                ps.setString(3, LocalDate.now().toString());
                if (majorId != null) {
                    ps.setInt(4, majorId);
                } else {
                    ps.setNull(4, java.sql.Types.INTEGER);
                }
                ps.executeUpdate();
            }

            resp.sendRedirect("login.jsp?registered=true");

        } catch (SQLException e) {
            req.setAttribute("error", "Database error: " + e.getMessage());
            req.getRequestDispatcher("register.jsp").forward(req, resp);
        }
    }
}
