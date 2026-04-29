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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class BuildScheduleServlet extends HttpServlet {

    private static final int MAX_SCHEDULES = 50;

    // Only characters that represent actual meeting days
    private static final String VALID_DAY_CHARS = "MTWRFS";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        String term = req.getParameter("term");

        try (Connection conn = DBConnection.getConnection()) {

            // select available terms (currently just spring 2026)
            List<String> availableTerms = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT DISTINCT term FROM Sections ORDER BY term DESC")) {
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) availableTerms.add(rs.getString("term"));
                }
            }
            if (term == null && !availableTerms.isEmpty()) term = availableTerms.get(0);

            // select user's desired courses
            List<Map<String, Object>> desiredCourses = new ArrayList<>();
            List<Integer> desiredIds = new ArrayList<>();
            String desiredSql =
                "SELECT c.course_id, c.course_code, c.course_name, c.credits " +
                "FROM DesiredCourses dc JOIN Courses c ON dc.course_id = c.course_id " +
                "WHERE dc.user_id = ? ORDER BY c.course_code";
            try (PreparedStatement ps = conn.prepareStatement(desiredSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        int cid = rs.getInt("course_id");
                        desiredIds.add(cid);
                        Map<String, Object> row = new HashMap<>();
                        row.put("courseId",   cid);
                        row.put("courseCode", rs.getString("course_code"));
                        row.put("courseName", rs.getString("course_name"));
                        row.put("credits",    rs.getString("credits"));
                        desiredCourses.add(row);
                    }
                }
            }

            // selected all sections based on desired courses
            Map<Integer, List<Map<String, Object>>> courseToSections = new LinkedHashMap<>();
            List<Map<String, Object>> missedCourses = new ArrayList<>();

            if (term != null && !desiredIds.isEmpty()) {

                for (Map<String, Object> dc : desiredCourses) {
                    courseToSections.put((Integer) dc.get("courseId"), new ArrayList<>());
                }

                StringBuilder inClause = new StringBuilder();
                for (int i = 0; i < desiredIds.size(); i++) {
                    inClause.append(i == 0 ? "?" : ",?");
                }

                String sectionSql =
                    "SELECT s.section_id, s.course_id, s.term, s.days, s.start_time, s.end_time, " +
                    "       s.location, s.format, " +
                    "       p.first_name, p.last_name, p.rating, " +
                    "       c.course_code, c.course_name " +
                    "FROM Sections s " +
                    "JOIN Professors p ON s.professor_id = p.professor_id " +
                    "JOIN Courses c   ON s.course_id    = c.course_id " +
                    "WHERE s.term = ? AND s.course_id IN (" + inClause + ")";

                try (PreparedStatement ps = conn.prepareStatement(sectionSql)) {
                    ps.setString(1, term);
                    for (int i = 0; i < desiredIds.size(); i++) ps.setInt(2 + i, desiredIds.get(i));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int cid = rs.getInt("course_id");
                            Map<String, Object> s = new HashMap<>();
                            s.put("sectionId",     rs.getInt("section_id"));
                            s.put("courseId",      cid);
                            s.put("days",          rs.getString("days"));
                            s.put("startTime",     rs.getString("start_time"));
                            s.put("endTime",       rs.getString("end_time"));
                            s.put("location",      rs.getString("location"));
                            s.put("format",        rs.getString("format"));
                            s.put("professorName", rs.getString("first_name") + " " + rs.getString("last_name"));
                            Object rating = rs.getBigDecimal("rating");
                            s.put("rating",        rating != null ? rating.toString() : null);
                            s.put("courseCode",    rs.getString("course_code"));
                            s.put("courseName",    rs.getString("course_name"));
                            List<Map<String, Object>> bucket = courseToSections.get(cid);
                            if (bucket != null) bucket.add(s);
                        }
                    }
                }

                // Courses with no sections for this term cannot be scheduled
                for (Map<String, Object> dc : desiredCourses) {
                    int cid = (Integer) dc.get("courseId");
                    if (courseToSections.get(cid).isEmpty()) {
                        missedCourses.add(dc);
                        courseToSections.remove(cid);
                    }
                }
            }

            // backtracking — find every conflict free combination (capped at MAX_SCHEDULES)
            List<List<Map<String, Object>>> schedules = new ArrayList<>();
            if (!courseToSections.isEmpty()) {
                List<List<Map<String, Object>>> sectionsList = new ArrayList<>(courseToSections.values());
                backtrack(sectionsList, 0, new ArrayList<>(), schedules);
            }

            req.setAttribute("schedules",      schedules);
            req.setAttribute("availableTerms", availableTerms);
            req.setAttribute("selectedTerm",   term);
            req.setAttribute("desiredCourses", desiredCourses);
            req.setAttribute("missedCourses",  missedCourses);

        } catch (SQLException e) {
            req.setAttribute("error", "Failed to build schedules: " + e.getMessage());
        }

        req.getRequestDispatcher("schedule.jsp").forward(req, resp);
    }

    // ── Backtracking ────────────────────────────────────────────────────────────

    private void backtrack(List<List<Map<String, Object>>> allSections,
                           int idx,
                           List<Map<String, Object>> current,
                           List<List<Map<String, Object>>> results) {
        if (results.size() >= MAX_SCHEDULES) return;
        if (idx == allSections.size()) {
            results.add(new ArrayList<>(current));
            return;
        }
        for (Map<String, Object> section : allSections.get(idx)) {
            if (!conflictsWithAny(section, current)) {
                current.add(section);
                backtrack(allSections, idx + 1, current, results);
                current.remove(current.size() - 1);
            }
        }
    }

    private boolean conflictsWithAny(Map<String, Object> s, List<Map<String, Object>> picked) {
        for (Map<String, Object> p : picked) {
            if (conflicts(s, p)) return true;
        }
        return false;
    }

    private boolean conflicts(Map<String, Object> a, Map<String, Object> b) {
        String da = (String) a.get("days");
        String db = (String) b.get("days");
        // Sections with non-standard days (TBA, ONLINE, etc.) never conflict
        if (!isInPersonDays(da) || !isInPersonDays(db)) return false;
        if (!sharesDay(da, db)) return false;

        int as = parseTime((String) a.get("startTime"));
        int ae = parseTime((String) a.get("endTime"));
        int bs = parseTime((String) b.get("startTime"));
        int be = parseTime((String) b.get("endTime"));
        return !(ae <= bs || be <= as);
    }

    /**
     * Returns true only if every character in days is a recognized day code.
     * Strings like "TBA" or "ONLINE" contain non-day characters and return false.
     */
    private boolean isInPersonDays(String days) {
        if (days == null || days.isBlank()) return false;
        for (char c : days.toCharArray()) {
            if (VALID_DAY_CHARS.indexOf(c) < 0) return false;
        }
        return true;
    }

    private boolean sharesDay(String d1, String d2) {
        for (char c : d1.toCharArray()) {
            if (d2.indexOf(c) >= 0) return true;
        }
        return false;
    }

    /** Returns minutes since midnight, handling "H:MM AM/PM" and "HH:MM:SS" formats. */
    private int parseTime(String t) {
        if (t == null || t.isBlank()) return 0;
        t = t.trim();
        boolean pm = t.toUpperCase().contains("PM");
        boolean am = t.toUpperCase().contains("AM");
        t = t.replaceAll("(?i)\\s*(am|pm)\\s*", "").trim();
        String[] parts = t.split(":");
        try {
            int h = Integer.parseInt(parts[0].trim());
            int m = parts.length > 1 ? Integer.parseInt(parts[1].trim()) : 0;
            if (pm && h != 12) h += 12;
            if (am && h == 12) h = 0;
            return h * 60 + m;
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
