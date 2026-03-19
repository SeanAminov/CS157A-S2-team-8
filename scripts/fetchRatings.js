const axios = require("axios");
const { getDb } = require("./db");

const RMP_GRAPHQL_URL = "https://www.ratemyprofessors.com/graphql";
const RMP_AUTH = "Basic dGVzdDp0ZXN0"; // RMP's public static token

async function searchProfessor(name) {
  const { data } = await axios.post(
    RMP_GRAPHQL_URL,
    {
      query: `
        query SearchTeacher($name: String!) {
          newSearch {
            teachers(query: $name, schoolID: "U2Nob29sLTExMQ==") {
              edges {
                node {
                  firstName
                  lastName
                  avgRating
                  numRatings
                  department
                }
              }
            }
          }
        }
      `,
      variables: { name },
    },
    { headers: { Authorization: RMP_AUTH } },
  );
  return data?.data?.newSearch?.teachers?.edges ?? [];
}

async function fetchRatings() {
  const db = await getDb();
  const [professors] = await db.execute(
    "SELECT professor_id, first_name, last_name FROM Professors",
  );

  for (const prof of professors) {
    const results = await searchProfessor(
      `${prof.first_name} ${prof.last_name}`,
    );
    if (results.length === 0) continue;

    const { avgRating, numRatings } = results[0].node;
    await db.execute(
      `UPDATE Professors SET avg_rating = ?, num_ratings = ? WHERE professor_id = ?`,
      [avgRating, numRatings, prof.professor_id],
    );
    console.log(`Updated ${prof.first_name} ${prof.last_name}: ${avgRating}`);
  }
}

module.exports = { fetchRatings };
