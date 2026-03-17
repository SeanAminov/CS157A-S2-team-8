import java.sql.*;

public class MysqlCon {
    public static void main(String args[]) {
        try {
            // 1. Load the MySQL Driver
            // Class.forName("com.mysql.jdbc.Driver"); 

            // 2. Connect to the database
            // TODO: Change "Wu" to your actual database name and put your MySQL password
            Connection con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/xxx?autoReconnect=true&useSSL=false", 
                "root", 
                "xxx"
            );

            // 3. Execute a query to test the connection
            // TODO: Change "Wu.Student" to your actual database and table name
            Statement stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("select * from Nguyen.Student");

            // 4. Print the data instances (Step 5 in your instructions)
            while(rs.next()) { 
            	System.out.println(rs.getInt(1) + " " + rs.getString(2) + " " + rs.getString(3));            
            }
            
            // 5. Close the connection
            con.close();
            
        } catch(Exception e) {
            System.out.println(e);
        }
    }
}
