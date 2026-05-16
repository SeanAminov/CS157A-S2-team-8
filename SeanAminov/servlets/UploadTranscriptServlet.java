package com.fmp.servlet;

import com.fmp.db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@MultipartConfig(
    maxFileSize = 5 * 1024 * 1024,   // 5 MB max
    maxRequestSize = 5 * 1024 * 1024
)
public class UploadTranscriptServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }
        req.getRequestDispatcher("transcript.jsp").forward(req, resp);
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
        Part filePart = req.getPart("transcript");

        // make sure they actually uploaded a file
        if (filePart == null || filePart.getSize() == 0) {
            req.setAttribute("error", "Please select a PDF file to upload.");
            req.getRequestDispatcher("transcript.jsp").forward(req, resp);
            return;
        }

        // check that it's a PDF
        String fileName = filePart.getSubmittedFileName();
        if (fileName == null || !fileName.toLowerCase().endsWith(".pdf")) {
            req.setAttribute("error", "Only PDF files are accepted.");
            req.getRequestDispatcher("transcript.jsp").forward(req, resp);
            return;
        }

        // extract text from the PDF using PDFBox
        String pdfText;
        try (InputStream input = filePart.getInputStream();
             PDDocument doc = PDDocument.load(input)) {

            PDFTextStripper stripper = new PDFTextStripper();
            pdfText = stripper.getText(doc);

        } catch (Exception e) {
            req.setAttribute("error", "Could not read the PDF file. Make sure it is not corrupted.");
            req.getRequestDispatcher("transcript.jsp").forward(req, resp);
            return;
        }

        // warn if the PDF has very little text (might be cut off or scanned)
        if (pdfText == null || pdfText.trim().length() < 100) {
            req.setAttribute("error",
                "This PDF appears to have missing or cut-off content. " +
                "Please make sure no pages are missing and the transcript is text-based (not a scanned image).");
            req.getRequestDispatcher("transcript.jsp").forward(req, resp);
            return;
        }

        // parse the transcript text
        String major = parseMajor(pdfText);
        String totalCredits = parseTotalCredits(pdfText);
        List<String> courseCodes = parseCourseCodes(pdfText);

        if (courseCodes.isEmpty()) {
            req.setAttribute("error",
                "No courses were found in this transcript. " +
                "Please make sure the full transcript is included and no pages have values cut off.");
            req.getRequestDispatcher("transcript.jsp").forward(req, resp);
            return;
        }

        // match each course code against the database
        List<Map<String, String>> matched = new ArrayList<>();
        List<String> unmatched = new ArrayList<>();

        String findCourseSql = "SELECT course_id, course_code, course_name FROM Courses WHERE course_code = ?";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                // if the user already uploaded a transcript before, clean it up
                deleteOldTranscript(conn, userId);

                // get next transcript id (table doesn't have auto increment)
                int transcriptId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COALESCE(MAX(transcript_id), 0) + 1 FROM Transcripts")) {
                    ResultSet rs = ps.executeQuery();
                    rs.next();
                    transcriptId = rs.getInt(1);
                }

                // insert the new transcript row
                String insertTranscript =
                    "INSERT INTO Transcripts (transcript_id, upload_date, total_credits, current_major, user_id) " +
                    "VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insertTranscript)) {
                    ps.setInt(1, transcriptId);
                    ps.setString(2, LocalDate.now().toString());
                    ps.setString(3, totalCredits != null ? totalCredits : "0");
                    ps.setString(4, major != null ? major : "Undeclared");
                    ps.setInt(5, userId);
                    ps.executeUpdate();
                }

                // try to match each course and insert into TakenCourses
                String insertTaken = "INSERT INTO TakenCourses (transcript_id, course_id) VALUES (?, ?)";
                Set<Integer> insertedCourseIds = new HashSet<>(); // track duplicates

                for (String code : courseCodes) {
                    Integer courseId = findCourse(conn, findCourseSql, code);

                    // if no match and code ends with X, strip the X and try the base course
                    // e.g. MATH 42X means "MATH 42 + workshop required", so the actual course is MATH 42
                    if (courseId == null && code.matches(".*\\d+X$")) {
                        String baseCode = code.substring(0, code.length() - 1);
                        courseId = findCourse(conn, findCourseSql, baseCode);
                    }

                    if (courseId != null) {
                        // skip if we already inserted this course (e.g. 42X and 42W both map to same course)
                        if (insertedCourseIds.contains(courseId)) {
                            continue;
                        }
                        insertedCourseIds.add(courseId);

                        try (PreparedStatement ps = conn.prepareStatement(insertTaken)) {
                            ps.setInt(1, transcriptId);
                            ps.setInt(2, courseId);
                            ps.executeUpdate();
                        }

                        Map<String, String> course = new LinkedHashMap<>();
                        course.put("code", code);
                        // grab the name from DB for display
                        course.put("name", getCourseName(conn, courseId));
                        matched.add(course);
                    } else {
                        unmatched.add(code);
                    }
                }

                conn.commit();

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }

        } catch (SQLException e) {
            req.setAttribute("error", "Database error: " + e.getMessage());
            req.getRequestDispatcher("transcript.jsp").forward(req, resp);
            return;
        }

        // pass results to the JSP
        req.setAttribute("matched", matched);
        req.setAttribute("unmatched", unmatched);
        req.setAttribute("major", major);
        req.setAttribute("totalCredits", totalCredits);
        req.setAttribute("success", "Transcript uploaded successfully! " +
            matched.size() + " courses matched, " + unmatched.size() + " not found in database.");
        req.getRequestDispatcher("transcript.jsp").forward(req, resp);
    }

    // pull the major from a line like "MAJOR: BS Computer Science"
    private String parseMajor(String text) {
        Pattern p = Pattern.compile("MAJOR:\\s*(?:BS|BA|MS|MA)?\\s*(.+)");
        Matcher m = p.matcher(text);
        if (m.find()) {
            return m.group(1).trim();
        }
        return null;
    }

    // grab total credits from the last "ALL COLLEGE:" line
    private String parseTotalCredits(String text) {
        String[] lines = text.split("\\n");
        String credits = null;
        for (int i = 0; i < lines.length; i++) {
            if (lines[i].contains("ALL COLLEGE:")) {
                // the numbers are on the same line or the next line
                Pattern p = Pattern.compile("(\\d+\\.\\d+)");
                Matcher m = p.matcher(lines[i]);
                if (m.find()) {
                    credits = m.group(1); // first number is the UA/total credits
                }
            }
        }
        return credits;
    }

    // find all course codes from the transcript text
    // lines look like: CS     146   Data Struct & Alg    3.0   3.0   3.0   B+   9.9
    private List<String> parseCourseCodes(String text) {
        List<String> codes = new ArrayList<>();
        String[] lines = text.split("\\n");
        boolean inProgress = false;

        // pattern matches lines starting with a dept code + course number
        // e.g. "CS     46B", "MATH   42W", "POLS   170V"
        Pattern coursePattern = Pattern.compile("^([A-Z]{2,4})\\s+(\\d+\\w*)\\s+");

        for (String line : lines) {
            line = line.trim();

            // stop when we hit the in-progress section
            if (line.contains("IN PROGRESS") || line.contains("ENROLLED")) {
                inProgress = true;
            }
            if (inProgress) continue;

            // skip AP credit lines
            if (line.startsWith("AP ")) continue;

            // skip summary lines
            if (line.startsWith("SEMESTER") || line.startsWith("SJSU") ||
                line.startsWith("ALL COLLEGE") || line.startsWith("EXTERNAL")) continue;

            Matcher m = coursePattern.matcher(line);
            if (m.find()) {
                String dept = m.group(1);
                String num = m.group(2);
                String code = dept + " " + num;

                // avoid duplicates
                if (!codes.contains(code)) {
                    codes.add(code);
                }
            }
        }
        return codes;
    }

    // look up a course by its code, returns null if not found
    private Integer findCourse(Connection conn, String sql, String code) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("course_id");
                }
            }
        }
        return null;
    }

    // get the course name for display
    private String getCourseName(Connection conn, int courseId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT course_name FROM Courses WHERE course_id = ?")) {
            ps.setInt(1, courseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("course_name");
            }
        }
        return "";
    }

    // remove old transcript and taken courses for this user
    private void deleteOldTranscript(Connection conn, int userId) throws SQLException {
        // find existing transcript
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT transcript_id FROM Transcripts WHERE user_id = ?")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int oldId = rs.getInt("transcript_id");
                    // delete taken courses first (no cascade)
                    try (PreparedStatement del = conn.prepareStatement(
                            "DELETE FROM TakenCourses WHERE transcript_id = ?")) {
                        del.setInt(1, oldId);
                        del.executeUpdate();
                    }
                }
            }
        }
        // now delete the transcript row itself
        try (PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM Transcripts WHERE user_id = ?")) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        }
    }
}
