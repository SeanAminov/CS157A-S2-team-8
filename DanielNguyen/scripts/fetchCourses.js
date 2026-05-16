const cheerio = require("cheerio");
const fs = require("fs");
const path = require("path");
const { getDb } = require("./db");
require("dotenv").config();

/**
 * Parses a course cell text like "CS 157A (Section 01)" into
 * { courseCode: "CS 157A", sectionNum: "01" }
 */
function parseCourseCell(text) {
  const match = text.match(/^([\w]+\s[\w]+)\s*\(Section\s*(\d+)\)$/i);
  if (!match) return { courseCode: text.trim(), sectionNum: "" };
  return {
    courseCode: match[1].trim(),
    sectionNum: match[2].trim(),
  };
}

/**
 * Parses a time string like "09:00AM" into 24h "09:00"
 */
function to24h(timeStr) {
  if (!timeStr) return null;
  const match = timeStr.match(/^(\d{1,2}):(\d{2})(AM|PM)$/i);
  if (!match) return timeStr;
  let [, h, m, period] = match;
  h = parseInt(h, 10);
  if (period.toUpperCase() === "PM" && h !== 12) h += 12;
  if (period.toUpperCase() === "AM" && h === 12) h = 0;
  return `${String(h).padStart(2, "0")}:${m}`;
}

/**
 * The schedule file is saved as a Chrome "view-source" page.  Chrome wraps
 * every line of the original HTML in a <tr><td class="line-number">…</td>
 * <td class="line-content">…</td></tr> pair.  The content cell contains the
 * original HTML as a mix of escaped tags (<span class="html-tag">&lt;td&gt;…)
 * and plain text nodes for the actual cell values.
 *
 * Strategy: read the text content of each line-content cell (which strips all
 * the span wrappers and gives us the visible text of that line), then group
 * the lines by the original <tr>…</tr> boundaries to reconstruct rows.
 *
 * Returns an array of string arrays: each inner array is the text values of
 * the 14 <td> cells in one course row.
 */
function parseCourseRows(viewSourceHtml) {
  const $ = cheerio.load(viewSourceHtml);

  // Collect the text of every line-content cell in document order.
  // text() strips all child elements and gives us only the visible characters.
  const lines = [];
  $("td.line-content").each((_, el) => {
    lines.push($(el).text().trim());
  });

  const rows = [];
  let current = null;

  for (const line of lines) {
    if (line === "<tr>") {
      current = [];
      continue;
    }
    if (line === "</tr>") {
      if (current && current.length > 0) rows.push(current);
      current = null;
      continue;
    }
    if (current === null) continue;

    // Lines that are just a tag (e.g. "<td>", "</td>", "<br>") carry no value.
    // Lines that start with "<td>" and end with "</td>" contain a cell value.
    const tdMatch = line.match(/^<td>([\s\S]*?)<\/td>$/);
    if (tdMatch) {
      // Strip any remaining HTML tags (e.g. <a href="...">text</a>) and decode entities
      const cellText = tdMatch[1]
        .replace(/<[^>]+>/g, "")
        .replace(/&nbsp;/g, " ")
        .replace(/&amp;/g, "&")
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .trim();
      current.push(cellText);
    }
  }

  return rows;
}

function parseInstructorName(instructorRaw) {
  // Split on newlines first (before collapsing whitespace) so we can
  // take just the first meaningful name when the cell has multiple lines.
  const firstLine =
    String(instructorRaw ?? "")
      .split("\n")
      .map((l) => l.replace(/\s+/g, " ").trim())
      // Drop the PeopleSoft cell label and known non-name placeholders
      .filter(
        (l) =>
          l &&
          !/^instructor$/i.test(l) &&
          !/^(to be announced|tba|staff)$/i.test(l),
      )[0] ?? "";

  if (!firstLine) return { firstName: "Unknown", lastName: "Unknown" };

  // Strip a leading "Instructor" prefix that gets merged when there is no
  // whitespace between the label and the name (e.g. "InstructorRob Ashcom")
  const name = firstLine.replace(/^Instructor\s*/i, "").trim();

  // "Last, First [Middle]" format
  const commaMatch = name.match(/^([^,]+),\s*(.+)$/);
  if (commaMatch) {
    return {
      lastName: commaMatch[1].trim(),
      firstName: commaMatch[2].trim(),
    };
  }

  // "First [Middle] Last" format (what SJSU PeopleSoft actually uses)
  const parts = name.split(" ").filter(Boolean);
  if (parts.length === 1) return { firstName: "Unknown", lastName: parts[0] };
  return {
    firstName: parts.slice(0, -1).join(" "),
    lastName: parts[parts.length - 1],
  };
}

/**
 * Gets or inserts a professor by name, returns professor_id.
 * department_id defaults to 1 (Computer Science) — update as needed
 * once you have richer data from RateMyProfessors.
 */
async function getOrCreateProfessor(db, firstName, lastName) {
  // Base case: if professor is "To be Announced", do NOT create professor entry
  if (firstName === "To be" && lastName === "Announced") {
    return { firstName: "Unknown", lastName: "Unknown" };
  }

  await db.execute(
    `INSERT INTO Professors (first_name, last_name, department_id) VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE first_name = first_name`,
    [firstName, lastName, 1],
  );
  const [rows] = await db.execute(
    "SELECT professor_id FROM Professors WHERE first_name = ? AND last_name = ?",
    [firstName, lastName],
  );
  return rows[0].professor_id;
}

/**
 * Gets or inserts a course by course_code, returns course_id.
 */
async function getOrCreateCourse(db, courseCode, courseName) {
  await db.execute(
    `INSERT INTO Courses (course_code, course_name, credits, department_id) VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE course_code = course_code`,
    [courseCode, courseName, "3", 1],
  );
  const [rows] = await db.execute(
    "SELECT course_id FROM Courses WHERE course_code = ?",
    [courseCode],
  );
  return rows[0].course_id;
}

async function fetchCourses() {
  const localFile = path.join(__dirname, "2026_sjsu_spring.php.html");
  console.log(`Parsing local file: ${localFile}`);
  const viewSourceHtml = fs.readFileSync(localFile, "utf-8");

  // Extract rows directly from the Chrome viewer DOM (avoids HTML-reconstruction issues)
  const courseRows = parseCourseRows(viewSourceHtml);
  const db = await getDb();

  let insertedSections = 0;
  let skippedSections = 0;

  // Each row is an array of 14 cell text values:
  //   0:  "CS 157A (Section 01)"
  //   1:  class number "26515"
  //   2:  format "In Person" | "Online" | "Hybrid"
  //   3:  course name
  //   4:  notes (usually empty)
  //   5:  credits " 3.0"
  //   6:  type "SEM" | "LEC" | "LAB" …
  //   7:  days "TR" | "MW" | "MWF" …
  //   8:  time "06:00PM-07:15PM"
  //   9:  instructor name
  //  10:  room "SH120"
  //  11:  dates "01/22/26-05/11/26"
  //  12:  seats available
  //  13:  filler
  const promises = [];

  for (const cells of courseRows) {
    if (cells.length < 13) continue;

    // Course rows always start with "DEPT NNN (Section NN)"
    const { courseCode, sectionNum } = parseCourseCell(cells[0]);
    if (!courseCode || !/^[A-Z]/.test(courseCode)) continue;

    const rawFormat = cells[2];
    const courseName = cells[3];
    const rawDays = cells[7];
    const rawTime = cells[8]; // "06:00PM-07:15PM"
    const rawInstructor = cells[9];
    const room = cells[10];

    // Normalise format
    let format;
    if (/online/i.test(rawFormat)) {
      format = "Online";
    } else if (/hybrid/i.test(rawFormat)) {
      format = "Hybrid";
    } else {
      format = "In-Person";
    }

    // Parse time range "06:00PM-07:15PM"
    const timeMatch = rawTime.match(/^([\d:]+[AP]M)-([\d:]+[AP]M)$/i);
    const startTime = timeMatch ? to24h(timeMatch[1]) : null;
    const endTime = timeMatch ? to24h(timeMatch[2]) : null;

    // Skip rows with no scheduled time (TBA, async online, etc.)
    if (!startTime || !rawDays) continue;

    const { firstName: profFirstName, lastName: profLastName } =
      parseInstructorName(rawInstructor);

    promises.push(
      (async () => {
        try {
          const courseId = await getOrCreateCourse(db, courseCode, courseName);
          const profId = await getOrCreateProfessor(
            db,
            profFirstName.trim(),
            profLastName.trim(),
          );

          await db.execute(
            `INSERT INTO Sections (term, days, start_time, end_time, location, format, professor_id, course_id)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               days = VALUES(days),
               start_time = VALUES(start_time),
               end_time = VALUES(end_time),
               location = VALUES(location),
               format = VALUES(format)`,
            [
              process.env.SJSU_TERM || "Spring 2026",
              rawDays,
              startTime,
              endTime,
              room,
              format,
              profId,
              courseId,
            ],
          );
          insertedSections++;
        } catch (err) {
          console.warn(
            `  Skipped section for ${courseCode} §${sectionNum} (${rawInstructor}): ${err.message}`,
          );
          skippedSections++;
        }
      })(),
    );
  }

  await Promise.all(promises);

  console.log(
    `Done. Inserted/updated: ${insertedSections} sections, skipped: ${skippedSections}`,
  );
}

module.exports = { fetchCourses };
