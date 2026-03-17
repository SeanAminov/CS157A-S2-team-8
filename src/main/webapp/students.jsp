<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>Database Test</title>
</head>
<body>
    <h2>Student List from Database:</h2>

    <%
    try {
        // 1. Load the Driver
        Class.forName("com.mysql.jdbc.Driver"); 

        // 2. Connect to the DB (UPDATE THESE HIGHLIGHTED PARTS)
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/xxx?autoReconnect=true&useSSL=false", // Change to own DB name
            "root", 
            "xxx" // Change to your own password 
        );

        // 3. Execute the query (UPDATE YOUR TABLE NAME IF NEEDED)
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("select * from student");

        // 4. Print the data to the web page
        while(rs.next()){ 
            out.println("<br>" + rs.getInt(1) + " " + rs.getString(2) + " " + rs.getString(3));
        }
        
        // 5. Close connection
        con.close();
        
    } catch(Exception e) {
        out.println("<br>Error: " + e.getMessage());
    }
    %>

</body>
</html>