package test;

import org.mindrot.jbcrypt.BCrypt;

public class BCryptTest {

    public static void main(String[] args) {
        System.out.println("Testing jBCrypt setup...");
        
        String password = "testpassword123";
        
        // 1. Generate the hash
        String hash = BCrypt.hashpw(password, BCrypt.gensalt());
        System.out.println("Success! Generated Hash: " + hash);
        
        // 2. Verify the hash
        if (BCrypt.checkpw(password, hash)) {
            System.out.println("Password match verified. The library is working perfectly!");
        } else {
            System.out.println("Something went wrong with the verification.");
        }
    }
}