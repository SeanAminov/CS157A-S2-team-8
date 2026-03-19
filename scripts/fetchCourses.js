const axios = require("axios");
const cheerio = require("cheerio");
const fs = require("fs");
const path = require("path");
const { getDb } = require("./db");
require("dotenv").config();

const SJSU_URL =
  "https://cmsweb.cms.sjsu.edu/psc/CSJPRD/EMPLOYEE/SA/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL";

// These are session-based and will expire. Refresh them by copying a new
// request from your browser's DevTools (Network tab) after logging in to MySJSU.
const HEADERS = {
  accept: "*/*",
  "accept-language": "en-US,en;q=0.9",
  "content-type": "application/x-www-form-urlencoded",
  cookie: process.env.SJSU_COOKIE,
  Referer: SJSU_URL,
};

// The POST body copied from the browser request.
// ICStateNum may need to increment if you chain multiple requests in one session.
const BODY =
  "ICAJAX=1&ICNAVTYPEDROPDOWN=1&ICType=Panel&ICElementNum=0&ICStateNum=6" +
  "&ICAction=%23ICSave&_gs_page=SSR_SS_WARNING&_gs_cs=&ICModelCancel=0" +
  "&ICXPos=0&ICYPos=0&ResponsetoDiffFrame=-1&TargetFrameName=None" +
  "&FacetPath=None&ICFocus=&ICSaveWarningFilter=0&ICChanged=-1" +
  "&ICSkipPending=0&ICAutoSave=0&ICResubmit=0" +
  "&ICSID=" +
  encodeURIComponent(process.env.SJSU_ICSID || "") +
  "&ICActionPrompt=false&ICPanelName=&ICFind=&ICAddCount=&ICAppClsData=";

/**
 * Parses a course title string like "CS 100W - Technical Writing Workshop"
 * into { courseCode: "CS 100W", courseName: "Technical Writing Workshop" }
 */
function parseCourseTitle(title) {
  const match = title.match(/^([A-Z]+\s[\w]+)\s*-\s*(.+)$/);
  if (!match) return { courseCode: title.trim(), courseName: title.trim() };
  return {
    courseCode: match[1].trim(),
    courseName: match[2].trim(),
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

  const [rows] = await db.execute(
    "SELECT professor_id FROM Professors WHERE first_name = ? AND last_name = ?",
    [firstName, lastName],
  );
  if (rows.length > 0) return rows[0].professor_id;

  const [result] = await db.execute(
    "INSERT INTO Professors (first_name, last_name, department_id) VALUES (?, ?, ?)",
    [firstName, lastName, 1],
  );
  return result.insertId;
}

/**
 * Gets or inserts a course by course_code, returns course_id.
 */
async function getOrCreateCourse(db, courseCode, courseName) {
  const [rows] = await db.execute(
    "SELECT course_id FROM Courses WHERE course_code = ?",
    [courseCode],
  );
  if (rows.length > 0) return rows[0].course_id;

  const [result] = await db.execute(
    "INSERT INTO Courses (course_code, course_name, credits, department_id) VALUES (?, ?, ?, ?)",
    [courseCode, courseName, "3", 1],
  );
  return result.insertId;
}

async function fetchCourses() {
  let html;
  if (process.env.USE_LOCAL === "true") {
    const localFile = path.join(__dirname, "test-response.html");
    console.log(`Using local file: ${localFile}`);
    html = fs.readFileSync(localFile, "utf-8");
  } else {
    if (!process.env.SJSU_COOKIE) {
      throw new Error(
        "SJSU_COOKIE is not set in .env. Copy fresh cookies from your browser after logging in to MySJSU.",
      );
    }
    console.log("Fetching SJSU class sections...");
    ({ data: html } = await axios.post(SJSU_URL, BODY, { headers: HEADERS }));
  }

  const $ = cheerio.load(html);
  const db = await getDb();

  let insertedSections = 0;
  let skippedSections = 0;

  // Each course group is a collapsible with an aria-label like "CS 100W - Technical Writing Workshop"
  $("a.ui-collapsible-heading-toggle[aria-label]").each(async (_, el) => {
    const rawTitle = $(el).attr("aria-label");
    const { courseCode, courseName } = parseCourseTitle(rawTitle);

    // Find the collapsible content div that follows this heading
    const contentDiv = $(el)
      .closest(".ui-collapsible")
      .find(".ui-collapsible-content");

    // Each row in the meeting pattern table is a section
    contentDiv.find("tr[id^='trSSR_CLSRCH_MTG1']").each(async (_, row) => {
      const cells = $(row).find("td");

      // Column order observed in PeopleSoft class search results:
      // 0: Section number, 1: Class number, 2: Days/Times, 3: Room,
      // 4: Instructor, 5: Dates, 6: Status, 7: Units, 8: Format
      const sectionNum = $(cells[0]).text().trim();
      const daysTime = $(cells[2]).text().trim(); // e.g. "MoWeFr 9:00AM-9:50AM"
      const room = $(cells[3]).text().trim();
      const instructor = $(cells[4]).text(); // keep newlines so parseInstructorName can split on them
      const units = $(cells[7]).text().trim();
      const format = $(cells[8]).text().trim(); // e.g. "In Person"

      if (!sectionNum || !daysTime) return;

      // Parse days and time range out of daysTime string
      // HTML format: "MoWe 6:00PM - 7:15PM" (spaces around dash)
      const timeMatch = daysTime.match(
        /([A-Za-z]+)\s+([\d:]+[AP]M)\s*-\s*([\d:]+[AP]M)/i,
      );
      const days = timeMatch ? timeMatch[1] : daysTime;
      const startTime = timeMatch ? to24h(timeMatch[2]) : null;
      const endTime = timeMatch ? to24h(timeMatch[3]) : null;

      // Skip sections with no scheduled time (TBA, online async, etc.)
      if (!startTime) return;

      const { firstName: profFirstName, lastName: profLastName } =
        parseInstructorName(instructor);

      try {
        const courseId = await getOrCreateCourse(db, courseCode, courseName);
        const profId = await getOrCreateProfessor(
          db,
          profFirstName,
          profLastName,
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
            days,
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
          `  Skipped section for ${courseCode} (${instructor}): ${err.message}`,
        );
        skippedSections++;
      }
    });
  });

  // Give async forEach time to flush (cheerio .each is sync but db calls are async)
  await new Promise((r) => setTimeout(r, 3000));

  console.log(
    `Done. Inserted/updated: ${insertedSections} sections, skipped: ${skippedSections}`,
  );
}

module.exports = { fetchCourses };
