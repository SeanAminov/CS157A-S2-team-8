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

public class DeleteAccountServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        // need to manually clean up tables that don't have ON DELETE CASCADE
        // DesiredCourses, TakenCourses, and ScheduleCourses don't cascade
        // the rest (Schedules, Transcripts, FilterPreferences, TimeBlocks) do cascade from Users

        // order matters here because of foreign key constraints
        String deleteScheduleCourses =
            "DELETE FROM ScheduleCourses " +
            "WHERE schedule_id IN (SELECT schedule_id FROM Schedules WHERE user_id = ?)";

        String deleteTakenCourses =
            "DELETE FROM TakenCourses " +
            "WHERE transcript_id IN (SELECT transcript_id FROM Transcripts WHERE user_id = ?)";

        String deleteDesiredCourses =
            "DELETE FROM DesiredCourses WHERE user_id = ?";

        // after cleaning up the non-cascading tables, delete the user
        // this will automatically remove Schedules, Transcripts, FilterPreferences, TimeBlocks
        String deleteUser = "DELETE FROM Users WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection()) {
            // turn off auto-commit so everything succeeds or fails together
            conn.setAutoCommit(false);

            try {
                // clean up schedule courses first (depends on schedules)
                try (PreparedStatement ps = conn.prepareStatement(deleteScheduleCourses)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // clean up taken courses (depends on transcripts)
                try (PreparedStatement ps = conn.prepareStatement(deleteTakenCourses)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // clean up desired courses
                try (PreparedStatement ps = conn.prepareStatement(deleteDesiredCourses)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // finally delete the user row itself
                try (PreparedStatement ps = conn.prepareStatement(deleteUser)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                conn.commit();

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }

        } catch (SQLException e) {
            req.setAttribute("error", "Could not delete account: " + e.getMessage());
            req.getRequestDispatcher("dashboard.jsp").forward(req, resp);
            return;
        }

        // account is gone, kill the session and send them to the home page
        session.invalidate();
        resp.sendRedirect("index.html");
    }
}
