# Project Description:

FindMyProfessors is a web platform that helps SJSU students create their ideal class schedule. Our goal is to help students have an easier time coming up with a class schedule that fits their needs. While SJSU does provide a course schedule generator for students (MyScheduler), it requires students to manually input the classes they want, and it does not take into account student ratings from RateMyProfessor. Currently, when students are making their schedule, they must cross-reference between the course catalog and external ratings, which is very tedious and time-consuming.

FindMyProfessors will solve this by giving students a more intuitive and easier experience in building their schedule. The platform will provide students with suggested courses to take based on their past classes and their program’s roadmap, and generates schedules that take into account professors’ ratings. FindMyProfessors will also let students find the classes offered per term, and find the different professors with their ratings attached. This gives the students the option to manually find their own classes instead of generating one, while still providing a more seamless experience by providing each professor’s course rating upfront.

# Function Requirements:

FindMyProfessors offers several functions to the main users (students) to create their ideal class schedule. With the system’s main purpose in serving students, the normal user will have the most functions. Developers and admins will also have the same functions, along with additional permissions to quickly update information without having to modify code or touch the backend directly. These are the specific features that the system will provide to the user.

## User View:

### Create Account

System shall allow users to create an account to customize their schedule
Inputs:
SJSU email address (format validated (must contain @sjsu.edu))
Password (stored as hash)
Password must contain at least 8 characters, one number, one symbol
Verify account does not exist, confirm account creation
Output: Confirmation of account creation
If account does exist, show error message

### Account Login

System shall allow users to access system using their credentials
Inputs:
Email: checked against database credentials
Password: checked against stored hash
Output: After verification user will be able to access schedule builder
If credentials are invalid, display error message

### Account Logout

System allows users to leave their active session. This ensures that protected data remains hidden when user is done
Input: User click log out
Output: Access to the schedule builder terminated and redirected to the home page

### Delete Account

Users may permanently delete their account and data from the database
System will remove:
User credentials
User saved schedules

### Change Password

Users may change their password upon email verification
New password will be hashed and replace the old password
New password may not be same as old password, otherwise display error message

### Search and Select Major

Users may select their major of choice to bring up a checklist of classes they may want/need to take. Class list scraped from SJSU major requirement site
System will associate majors with user accounts for future access. Will also remove existing major if user is already associated
Inputs:
Major name (text)
Output:
Display of a checklist of classes required for the major

### Search and Add Class

Users may add classes they want to take manually
Inputs:
Class code (optional)
Class name (optional)
Professor name (optional)
Output: Application shows the classes marked
System adds class to user’s class list

### Remove Class

Users may remove classes they do not want to take manually
System removes class from user’s class list

### Upload Transcript

User may upload transcript to be parsed for streamlined class list customization
Input:
PDF file (error if not pdf)
System will extract total credits, current major, and completed courses
Output: System will mark classes from transcript as completed on user’s class list, and show suggested next classes to take

### Customized Filtering

User may add custom time blocks and filters to create their ideal schedule
Inputs:
Time range
Minimum professor rating
Core classes
Must have classes
Output: Displays the filtered classes
System will store blocks with user entity for future use

### Generate Schedule

User may create customized schedule based on desired classes and additional filtering
System will generate all possible schedules based on user input and display
If no schedules are possible display time conflicts for user to edit

### Save Schedule

Store generated schedule under user account

### View Schedules

System retrieves all stored schedules under user account for display

## Developer View:

### Edit Professor Ratings

Developers will be able to update professor ratings
Changes are stored in the rating table

### Remove Course

Developers will be able to remove courses that are no longer available
Removes the course from the course table

### Add Course

Developers will be able to add newly added courses
Adds course to the course table
Inputs:
Course title
Term
Section
Time
Professor

### Modify Course

Developers will be able to modify the course information in case there are changes
