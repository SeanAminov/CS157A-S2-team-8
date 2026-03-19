const axios = require("axios");
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

async function searchProfessorAtSJSU(name) {
  const { data } = await axios.post(
    RMP_GRAPHQL_URL,
    {
      query: SEARCH_QUERY,
      operationName: "TeacherSearchResultsPageQuery",
      variables: {
        query: { text: name, schoolID: SJSU_SCHOOL_ID, fallback: false },
        schoolID: SJSU_SCHOOL_ID,
        includeSchoolFilter: true,
      },
    },
    {
      headers: {
        "Content-Type": "application/json",
        Authorization: "null",
        Origin: "https://www.ratemyprofessors.com",
        Referer: `https://www.ratemyprofessors.com/search/professors/?q=${encodeURIComponent(name)}`,
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
      },
    },
  );

  const edges = data?.data?.search?.teachers?.edges ?? [];

  // RMP already filters by SJSU school ID, so take the first result
  return edges[0]?.node ?? null;
}

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function fetchRatings() {
  const db = await getDb();
  const [professors] = await db.execute(
    "SELECT professor_id, first_name, last_name FROM Professors",
  );

  for (const prof of professors) {
    const fullName = `${prof.first_name} ${prof.last_name}`;

    try {
      const teacher = await searchProfessorAtSJSU(fullName);

      if (!teacher) {
        console.log(`No SJSU match found for ${fullName}`);
      } else {
        const { avgRating } = teacher;
        await db.execute(
          `UPDATE Professors SET rating = ? WHERE professor_id = ?`,
          [avgRating, prof.professor_id],
        );
        console.log(`Updated ${fullName}: rating=${avgRating}`);
      }
    } catch (err) {
      console.error(`Failed to fetch rating for ${fullName}:`, err.message);
    }

    // Pause between requests to avoid rate limiting
    await delay(1000);
  }
}

module.exports = { fetchRatings };
