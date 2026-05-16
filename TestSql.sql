SELECT Professors.first_name, Professors.last_name, Courses.course_name, Sections.start_time, Sections.end_time FROM Sections, Professors, Courses
WHERE Sections.professor_id = Professors.professor_id
    AND Sections.course_id = Courses.course_id
    AND Professors.first_name LIKE "Ching%";