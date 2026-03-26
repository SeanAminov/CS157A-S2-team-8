const axios = require("axios");
const fs = require("fs");
const path = require("path");
const { getDb } = require("./db");

const RMP_GRAPHQL_URL = "https://www.ratemyprofessors.com/graphql";
const SJSU_SCHOOL_ID = "U2Nob29sLTg4MQ==";

const SEARCH_QUERY = `
  query TeacherSearchResultsPageQuery(
    $query: TeacherSearchQuery!
    $schoolID: ID
    $includeSchoolFilter: Boolean!
  ) {
    search: newSearch {
      ...TeacherSearchPagination_search_2MvZSr
    }
    school: node(id: $schoolID) @include(if: $includeSchoolFilter) {
      __typename
      ... on School {
        name
      }
      id
    }
  }

  fragment CardFeedback_teacher on Teacher {
    wouldTakeAgainPercent
    avgDifficulty
  }

  fragment CardName_teacher on Teacher {
    firstName
    lastName
  }

  fragment CardSchool_teacher on Teacher {
    department
    school {
      name
      id
    }
  }

  fragment TeacherBookmark_teacher on Teacher {
    id
    isSaved
  }

  fragment TeacherCard_teacher on Teacher {
    id
    legacyId
    avgRating
    numRatings
    ...CardFeedback_teacher
    ...CardSchool_teacher
    ...CardName_teacher
    ...TeacherBookmark_teacher
  }

  fragment TeacherSearchPagination_search_2MvZSr on newSearch {
    teachers(query: $query, first: 5, after: "") {
      didFallback
      edges {
        cursor
        node {
          ...TeacherCard_teacher
          id
          __typename
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
      resultCount
    }
  }
`;

async function searchProfessorAtSJSU(firstName, lastName) {
  const fullName = `${firstName} ${lastName}`;
  const { data } = await axios.post(
    RMP_GRAPHQL_URL,
    {
      query: SEARCH_QUERY,
      operationName: "TeacherSearchResultsPageQuery",
      variables: {
        query: { text: fullName, schoolID: SJSU_SCHOOL_ID, fallback: true },
        schoolID: SJSU_SCHOOL_ID,
        includeSchoolFilter: true,
      },
    },
    {
      headers: {
        "Content-Type": "application/json",
        Authorization: "null",
        Origin: "https://www.ratemyprofessors.com",
        Referer: `https://www.ratemyprofessors.com/search/professors/?q=${encodeURIComponent(fullName)}`,
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
      },
    },
  );

  const edges = data?.data?.search?.teachers?.edges ?? [];

  // still need to match bc rmp returns similar professors
  const sjsuMatch = edges.find(
    ({ node }) =>
      (node.school?.id === SJSU_SCHOOL_ID ||
        node.school?.name?.toLowerCase().includes("san jose state")) &&
      node.firstName?.toLowerCase() === firstName.toLowerCase() &&
      node.lastName?.toLowerCase() === lastName.toLowerCase(),
  );

  return sjsuMatch ? sjsuMatch.node : 0; // use 0 to represent no review found
}

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function escapeCsvField(value) {
  if (value === null || value === undefined) return "";
  const str = String(value);
  if (str.includes(",") || str.includes('"') || str.includes("\n")) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

const CSV_PATH = path.join(__dirname, "professor_ratings.csv");
const CSV_HEADER =
  "professor_id,first_name,last_name,avg_rating,num_ratings,avg_difficulty,would_take_again_percent";

function appendCsvRow(row) {
  fs.appendFileSync(CSV_PATH, row + "\n", "utf8");
}

function loadAlreadyFetched() {
  if (!fs.existsSync(CSV_PATH)) return new Set();
  const lines = fs.readFileSync(CSV_PATH, "utf8").trim().split("\n");
  const fetched = new Set();
  for (const line of lines.slice(1)) {
    const id = line.split(",")[0];
    if (id) fetched.add(Number(id));
  }
  return fetched;
}

async function fetchRatings() {
  const db = await getDb();
  const [professors] = await db.execute(
    "SELECT professor_id, first_name, last_name FROM Professors",
  );

  if (!fs.existsSync(CSV_PATH)) {
    fs.writeFileSync(CSV_PATH, CSV_HEADER + "\n", "utf8");
    console.log(`Created ${CSV_PATH}`);
  }

  const alreadyFetched = loadAlreadyFetched();
  const remaining = professors.filter(
    (p) => !alreadyFetched.has(p.professor_id),
  );
  console.log(
    `${alreadyFetched.size} already fetched, ${remaining.length} remaining.`,
  );

  for (const prof of remaining) {
    const fullName = `${prof.first_name} ${prof.last_name}`;

    try {
      const teacher = await searchProfessorAtSJSU(
        prof.first_name,
        prof.last_name,
      );

      if (teacher === 0) {
        await db.execute(
          `UPDATE Professors SET rating = 0 WHERE professor_id = ?`,
          [prof.professor_id],
        );
        console.log(`No SJSU match found for ${fullName}, set rating to 0`);
        appendCsvRow(
          [prof.professor_id, prof.first_name, prof.last_name, 0, "", "", ""]
            .map(escapeCsvField)
            .join(","),
        );
      } else {
        const { avgRating, numRatings, avgDifficulty, wouldTakeAgainPercent } =
          teacher;
        await db.execute(
          `UPDATE Professors SET rating = ? WHERE professor_id = ?`,
          [avgRating ?? 0, prof.professor_id],
        );
        console.log(`Updated ${fullName}: rating=${avgRating ?? 0}`);
        appendCsvRow(
          [
            prof.professor_id,
            prof.first_name,
            prof.last_name,
            avgRating ?? 0,
            numRatings ?? "",
            avgDifficulty ?? "",
            wouldTakeAgainPercent ?? "",
          ]
            .map(escapeCsvField)
            .join(","),
        );
      }
    } catch (err) {
      console.error(`Failed to fetch rating for ${fullName}:`, err.message);
      appendCsvRow(
        [
          prof.professor_id,
          prof.first_name,
          prof.last_name,
          "ERROR",
          "",
          "",
          "",
        ]
          .map(escapeCsvField)
          .join(","),
      );
    }

    const ms = 1500 + Math.random() * 2000;
    console.log(`  Waiting ${(ms / 1000).toFixed(2)}s before next request...`);
    await delay(ms);
  }

  console.log(`\nDone. Ratings saved to ${CSV_PATH}`);
}

module.exports = { fetchRatings };
