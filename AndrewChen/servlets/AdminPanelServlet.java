package com.fmp.servlet;

import com.fmp.db.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AdminPanelServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // make sure user is logged in before they can search
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }
        
        String role = (String) session.getAttribute("userRole");
        if (!"admin".equals(role)) {
            resp.sendRedirect("dashboard");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        // keyword is the main text search (course code, name, or professor)
        String keyword = req.getParameter("keyword");

        // filter parameters - these narrow down results beyond the keyword search
        // to reuse these filters in schedule generation:
        //   1. read the same parameter names from the request
        //   2. apply the same WHERE clause logic to your query
        //   3. use the same List<Object> approach for PreparedStatement params
        String departmentParam = req.getParameter("department");
        String formatParam     = req.getParameter("format");
        String daysParam       = req.getParameter("days");
        String minRatingParam  = req.getParameter("minRating");
        String hideTakenParam  = req.getParameter("hideTaken");

        // load dropdown options from the database so filters show real values
        try (Connection conn = DBConnection.getConnection()) {
            req.setAttribute("departments", loadDepartments(conn));
            req.setAttribute("formats", loadDistinctValues(conn,
                "SELECT DISTINCT format FROM Sections ORDER BY format"));
            req.setAttribute("dayOptions", loadDistinctValues(conn,
                "SELECT DISTINCT days FROM Sections ORDER BY days"));
        } catch (SQLException e) {
            // if we can't load filter options, page still works - just no dropdowns
        }

        // pass filter values back to JSP so dropdowns stay selected after search
        req.setAttribute("keyword", keyword);
        req.setAttribute("selectedDept", departmentParam);
        req.setAttribute("selectedFormat", formatParam);
        req.setAttribute("selectedDays", daysParam);
        req.setAttribute("selectedRating", minRatingParam);
        req.setAttribute("hideTaken", hideTakenParam);

        // check if user actually submitted something (keyword or any filter)
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        boolean hasFilters = (departmentParam != null && !departmentParam.isEmpty())
                          || (formatParam != null && !formatParam.isEmpty())
                          || (daysParam != null && !daysParam.isEmpty())
                          || (minRatingParam != null && !minRatingParam.isEmpty())
                          || "on".equals(hideTakenParam);

        // if nothing was searched or filtered, just show the empty page
        if (!hasKeyword && !hasFilters) {
            req.getRequestDispatcher("adminpanel.jsp").forward(req, resp);
            return;
        }

        if (keyword != null) keyword = keyword.trim();

        // base query: join Sections with Courses, Professors, and Departments
        // LEFT JOIN on DesiredCourses checks if the user already added each section
        // changed by SeanAminov: DesiredCourses now uses section_id instead of course_id
        // so users can add multiple sections of the same course
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT c.course_id, c.course_code, c.course_name, c.credits, ");
        sql.append("       s.section_id, s.term, s.days, s.start_time, s.end_time, ");
        sql.append("       s.location, s.format, ");
        sql.append("       p.first_name, p.last_name, p.rating, ");
        sql.append("       CASE WHEN dc.section_id IS NOT NULL THEN 1 ELSE 0 END AS already_added ");
        sql.append("FROM Sections s ");
        sql.append("INNER JOIN Courses c ON s.course_id = c.course_id ");
        sql.append("INNER JOIN Professors p ON s.professor_id = p.professor_id ");
        sql.append("INNER JOIN Departments d ON c.department_id = d.department_id ");
        sql.append("LEFT JOIN DesiredCourses dc ON dc.section_id = s.section_id AND dc.user_id = ? ");

        // collect PreparedStatement parameters in order
        // first param is always userId for the DesiredCourses LEFT JOIN
        List<Object> params = new ArrayList<>();
        params.add(userId);

        // each active filter adds an AND condition to the query
        // to add a new filter later, follow this same pattern:
        //   1. check if the parameter is set (not null/empty)
        //   2. append the condition string to the conditions list
        //   3. add the parameter value to the params list
        List<String> conditions = new ArrayList<>();

        // keyword search - matches against course code, course name, or professor name
        if (hasKeyword) {
            // match from the start of each word, not the middle
            // e.g. "CS" matches "CS 146" but not "Dynamics" or "Physics"
            String startsWith = keyword + "%";
            conditions.add("(c.course_code LIKE ? OR c.course_name LIKE ? "
                         + "OR p.first_name LIKE ? OR p.last_name LIKE ?)");
            params.add(startsWith);
            params.add(startsWith);
            params.add(startsWith);
            params.add(startsWith);
        }

        // department filter - only show courses from a specific department
        if (departmentParam != null && !departmentParam.isEmpty()) {
            try {
                conditions.add("d.department_id = ?");
                params.add(Integer.parseInt(departmentParam));
            } catch (NumberFormatException ignored) {
                // bad input, skip this filter
            }
        }

        // format filter - In-Person, Online, Hybrid, etc.
        if (formatParam != null && !formatParam.isEmpty()) {
            conditions.add("s.format = ?");
            params.add(formatParam);
        }

        // days filter - MW, TR, MWF, etc.
        if (daysParam != null && !daysParam.isEmpty()) {
            conditions.add("s.days = ?");
            params.add(daysParam);
        }

        // minimum professor rating filter - only show sections with rating >= value
        if (minRatingParam != null && !minRatingParam.isEmpty()) {
            try {
                conditions.add("p.rating >= ?");
                params.add(Double.parseDouble(minRatingParam));
            } catch (NumberFormatException ignored) {
                // bad input, skip this filter
            }
        }

        // hide courses the user already took (based on uploaded transcript)
        // uses a subquery to find course_ids from the user's TakenCourses
        if ("on".equals(hideTakenParam)) {
            conditions.add("c.course_id NOT IN ("
                + "SELECT tc.course_id FROM TakenCourses tc "
                + "INNER JOIN Transcripts t ON tc.transcript_id = t.transcript_id "
                + "WHERE t.user_id = ?)");
            params.add(userId);
        }

        // combine all conditions with WHERE ... AND ...
        if (!conditions.isEmpty()) {
            sql.append("WHERE ");
            sql.append(String.join(" AND ", conditions));
            sql.append(" ");
        }

        sql.append("ORDER BY c.course_code, s.days");

        // run the query and collect results
        List<Map<String, Object>> results = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            // set each parameter in order - type matters for PreparedStatement
            for (int i = 0; i < params.size(); i++) {
                Object val = params.get(i);
                if (val instanceof Integer) {
                    ps.setInt(i + 1, (Integer) val);
                } else if (val instanceof Double) {
                    ps.setDouble(i + 1, (Double) val);
                } else {
                    ps.setString(i + 1, (String) val);
                }
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("courseId",     rs.getInt("course_id"));
                    row.put("courseCode",   rs.getString("course_code"));
                    row.put("courseName",   rs.getString("course_name"));
                    row.put("credits",      rs.getString("credits"));
                    row.put("sectionId",    rs.getInt("section_id"));
                    row.put("term",         rs.getString("term"));
                    row.put("days",         rs.getString("days"));
                    row.put("startTime",    rs.getString("start_time"));
                    row.put("endTime",      rs.getString("end_time"));
                    row.put("location",     rs.getString("location"));
                    row.put("format",       rs.getString("format"));
                    row.put("professor",    rs.getString("first_name") + " " + rs.getString("last_name"));
                    row.put("rating",       rs.getBigDecimal("rating"));
                    row.put("alreadyAdded", rs.getInt("already_added") == 1);
                    results.add(row);
                }
            }

        } catch (SQLException e) {
            req.setAttribute("error", "Search failed: " + e.getMessage());
        }

        req.setAttribute("results", results);
        req.getRequestDispatcher("adminpanel.jsp").forward(req, resp);
    }

    // helper methods to load filter dropdown options from the database
    // in schedule generation, you can use these same queries to populate filter dropdowns

    /** load all departments as id -> name pairs for the department dropdown */
    private Map<Integer, String> loadDepartments(Connection conn) throws SQLException {
        Map<Integer, String> depts = new LinkedHashMap<>();
        String sql = "SELECT department_id, department_name FROM Departments ORDER BY department_name";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                depts.put(rs.getInt("department_id"), rs.getString("department_name"));
            }
        }
        return depts;
    }

    /**
     * Run a SELECT DISTINCT query and return the results as a list of strings.
     * Used to get unique format types (Online, In-Person, etc.) and day patterns (MW, TR, etc.)
     */
    private List<String> loadDistinctValues(Connection conn, String sql) throws SQLException {
        List<String> values = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                values.add(rs.getString(1));
            }
        }
        return values;
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
  
        HttpSession session = request.getSession(false);
        
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String role = (String) session.getAttribute("userRole");
        if (!"admin".equals(role)) {
            response.sendRedirect("dashboard");
            return;
        }
        
        String action = request.getParameter("action");
        String keyword = request.getParameter("keyword");
        
        try (Connection conn = DBConnection.getConnection()) {
        	if(action.equals("delete")) {
                int sectionId = Integer.parseInt(request.getParameter("sectionId"));
                String sql = "DELETE FROM Sections WHERE section_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                	stmt.setInt(1,  sectionId);
                	stmt.executeUpdate();
                }
        	}
            
        	else if (action.equals("modify")) {
        	    int sectionId = Integer.parseInt(request.getParameter("sectionId"));

        	    String courseCode = request.getParameter("courseCode").trim().toUpperCase();
        	    String courseName = request.getParameter("courseName").trim();
        	    String professor  = request.getParameter("professor").trim();
        	    String days       = request.getParameter("days");
        	    String startTime  = request.getParameter("startTime");
        	    String endTime    = request.getParameter("endTime");
        	    String format     = request.getParameter("format");
        	    String deptIdParam = request.getParameter("departmentId");

        	    // find or create course
        	    int courseId = -1;
        	    String findCourse = "SELECT course_id FROM Courses WHERE course_code = ?";
        	    try (PreparedStatement ps = conn.prepareStatement(findCourse)) {
        	        ps.setString(1, courseCode);
        	        try (ResultSet rs = ps.executeQuery()) {
        	            if (rs.next()) courseId = rs.getInt("course_id");
        	        }
        	    }

        	    if (courseId == -1) {
        	        int deptId = (deptIdParam != null && !deptIdParam.isEmpty())
        	                     ? Integer.parseInt(deptIdParam) : 1;
        	        String insertCourse = "INSERT INTO Courses (course_code, course_name, credits, department_id) VALUES (?, ?, ?, ?)";
        	        try (PreparedStatement ps = conn.prepareStatement(insertCourse, PreparedStatement.RETURN_GENERATED_KEYS)) {
        	            ps.setString(1, courseCode);
        	            ps.setString(2, courseName);
        	            ps.setInt(3, 3);
        	            ps.setInt(4, deptId);
        	            ps.executeUpdate();
        	            try (ResultSet keys = ps.getGeneratedKeys()) {
        	                if (keys.next()) courseId = keys.getInt(1);
        	            }
        	        }
        	    }

        	    // find or create professor
        	    int professorId = -1;
        	    String[] nameParts = professor.split(" ", 2);
        	    String firstName = nameParts[0];
        	    String lastName  = nameParts.length > 1 ? nameParts[1] : "";

        	    String findProf = "SELECT professor_id FROM Professors WHERE first_name = ? AND last_name = ?";
        	    try (PreparedStatement ps = conn.prepareStatement(findProf)) {
        	        ps.setString(1, firstName);
        	        ps.setString(2, lastName);
        	        try (ResultSet rs = ps.executeQuery()) {
        	            if (rs.next()) professorId = rs.getInt("professor_id");
        	        }
        	    }

        	    if (professorId == -1) {
        	        String insertProf = "INSERT INTO Professors (first_name, last_name, rating, department_id) VALUES (?, ?, ?, ?)";
        	        try (PreparedStatement ps = conn.prepareStatement(insertProf, PreparedStatement.RETURN_GENERATED_KEYS)) {
        	            ps.setString(1, firstName);
        	            ps.setString(2, lastName);
        	            ps.setDouble(3, 0.0);
        	            ps.setInt(4, 1);
        	            ps.executeUpdate();
        	            try (ResultSet keys = ps.getGeneratedKeys()) {
        	                if (keys.next()) professorId = keys.getInt(1);
        	            }
        	        }
        	    }
        	    
        	    
        	    // update the section
        	    String sql = "UPDATE Sections "
        	               + "SET course_id = ?, professor_id = ?, days = ?, start_time = ?, end_time = ?, format = ? "
        	               + "WHERE section_id = ?";
        	    try (PreparedStatement stmt = conn.prepareStatement(sql)) {
        	        stmt.setInt(1, courseId);
        	        stmt.setInt(2, professorId);
        	        stmt.setString(3, days);
        	        stmt.setString(4, startTime);
        	        stmt.setString(5, endTime);
        	        stmt.setString(6, format);
        	        stmt.setInt(7, sectionId);
        	        stmt.executeUpdate();
        	    }
        	}
        	
        	else if (action.equals("add")) {
        		String term = request.getParameter("term".trim());        	    
        		String courseCode  = request.getParameter("courseCode").trim().toUpperCase();
        	    String courseName  = request.getParameter("courseName").trim();
        	    String professor   = request.getParameter("professor").trim();
        	    String days        = request.getParameter("days");
        	    String startTime   = request.getParameter("startTime");
        	    String endTime     = request.getParameter("endTime");
        	    String format      = request.getParameter("format");
        	    String location    = request.getParameter("location");
        	    String deptIdParam = request.getParameter("departmentId");

        	    int courseId = -1;
        	    String findCourse = "SELECT course_id FROM Courses WHERE course_code = ?";
        	    try (PreparedStatement ps = conn.prepareStatement(findCourse)) {
        	        ps.setString(1, courseCode);
        	        try (ResultSet rs = ps.executeQuery()) {
        	            if (rs.next()) courseId = rs.getInt("course_id");
        	        }
        	    }

        	    if (courseId == -1) {
        	        int deptId = (deptIdParam != null && !deptIdParam.isEmpty())
        	                     ? Integer.parseInt(deptIdParam) : 1;
        	        String insertCourse = "INSERT INTO Courses (course_code, course_name, credits, department_id) VALUES (?, ?, ?, ?)";
        	        try (PreparedStatement ps = conn.prepareStatement(insertCourse, PreparedStatement.RETURN_GENERATED_KEYS)) {
        	            ps.setString(1, courseCode);
        	            ps.setString(2, courseName);
        	            ps.setInt(3, 3);
        	            ps.setInt(4, deptId);
        	            ps.executeUpdate();
        	            try (ResultSet keys = ps.getGeneratedKeys()) {
        	                if (keys.next()) courseId = keys.getInt(1);
        	            }
        	        }
        	    }

        	    int professorId = -1;
        	    String[] nameParts = professor.split(" ", 2);
        	    String firstName = nameParts[0];
        	    String lastName  = nameParts.length > 1 ? nameParts[1] : "";

        	    String findProf = "SELECT professor_id FROM Professors WHERE first_name = ? AND last_name = ?";
        	    try (PreparedStatement ps = conn.prepareStatement(findProf)) {
        	        ps.setString(1, firstName);
        	        ps.setString(2, lastName);
        	        try (ResultSet rs = ps.executeQuery()) {
        	            if (rs.next()) professorId = rs.getInt("professor_id");
        	        }
        	    }

        	    if (professorId == -1) {
        	        String insertProf = "INSERT INTO Professors (first_name, last_name, rating, department_id) VALUES (?, ?, ?, ?)";
        	        try (PreparedStatement ps = conn.prepareStatement(insertProf, PreparedStatement.RETURN_GENERATED_KEYS)) {
        	            ps.setString(1, firstName);
        	            ps.setString(2, lastName);
        	            ps.setDouble(3, 0.0);
        	            ps.setInt(4, 1);

        	            ps.executeUpdate();
        	            try (ResultSet keys = ps.getGeneratedKeys()) {
        	                if (keys.next()) professorId = keys.getInt(1);
        	            }
        	        }
        	    }

        	    String insertSection = "INSERT INTO Sections (term, days, start_time, end_time, location, format, professor_id, course_id) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
			   try (PreparedStatement ps = conn.prepareStatement(insertSection)) {
			       ps.setString(1, term);
			       ps.setString(2, days);
			       ps.setString(3, startTime);
			       ps.setString(4, endTime);
			       ps.setString(5, location);
			       ps.setString(6, format);
			       ps.setInt(7, professorId);
			       ps.setInt(8, courseId);
			       ps.executeUpdate();
			   }
        	}
        	
        	else if (action.equals("updateRating")) {
        	    int sectionId = Integer.parseInt(request.getParameter("sectionId"));
        	    double rating = Double.parseDouble(request.getParameter("rating"));

        	    // get the professor_id from the section, then update their rating
        	    String findProf = "SELECT professor_id FROM Sections WHERE section_id = ?";
        	    int professorId = -1;
        	    try (PreparedStatement ps = conn.prepareStatement(findProf)) {
        	        ps.setInt(1, sectionId);
        	        try (ResultSet rs = ps.executeQuery()) {
        	            if (rs.next()) professorId = rs.getInt("professor_id");
        	        }
        	    }

        	    if (professorId != -1) {
        	        String updateRating = "UPDATE Professors SET rating = ? WHERE professor_id = ?";
        	        try (PreparedStatement ps = conn.prepareStatement(updateRating)) {
        	            ps.setDouble(1, rating);
        	            ps.setInt(2, professorId);
        	            ps.executeUpdate();
        	        }
        	    }
        	}
        } 
        catch (SQLException e) {
            throw new ServletException(e);
        }
        
        if (keyword == null) {
        	keyword = "";
        }
        
        response.sendRedirect("adminPanel?keyword=" + URLEncoder.encode(keyword, "UTF-8"));
    }
}
