const { fetchCourses } = require("./fetchCourses");
const { fetchRatings } = require("./fetchRatings");

async function main() {
  console.log("Fetching courses...");
  await fetchCourses();

  console.log("Fetching professor ratings...");
  await fetchRatings();

  console.log("Done!");
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
