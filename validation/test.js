const { globSync } = require("glob");
const Ajv = require("ajv");
const fs = require("fs");
const addFormats = require("ajv-formats");
const path = require("node:path");

const ajv = new Ajv();
addFormats(ajv);

const testPath = process.argv.length > 2 ? process.argv[2] : "../";

const baseSchemaFile = `${testPath}base_schema.json`;
const metadataSchemaFile = `${testPath}metadata_schema.json`
const schemaFiles = globSync(`${testPath}*/*.json`);

const validate = (schemaFile, objectFile) => {
    const object = JSON.parse(fs.readFileSync(objectFile));
    const schema = JSON.parse(fs.readFileSync(schemaFile));
    const validated = ajv.validate(schema, object);
    const passValue = validated ? "PASS" : "FAIL";
    console.log(`${objectFile} <- ${schemaFile} : ${passValue}`);
    return validated;
};

let passed = true;
let testCount = 0;
let passCount = 0;
for (let schemaFile of schemaFiles) {
    // TODO: Validate each model schema matches the base schema.
    const exampleFiles = globSync(
        path.join(path.dirname(schemaFile), "examples/*.json")
    );
    for (let exampleFile of exampleFiles) {
        testCount++;
        const baseSchemaPassed = validate(baseSchemaFile, exampleFile);
        const metadataSchemaPassed = validate(metadataSchemaFile, exampleFile);
        const filePassed = validate(schemaFile, exampleFile);
        // The validation is true only if everything passes all the times. One failure and you're out!
        const testPassed = baseSchemaPassed & metadataSchemaPassed & filePassed;
        if (testPassed) {
            passCount++;
        } else {
            passed = false;
        }
    }
}

// Returns a response code if all examples validate, otherwise a 1.
console.log(`\n${passCount} out of ${testCount} tests passed.`);
if (!passed) {
    console.log("\nError validating schemas. See above.");
    process.exit(1);
} else {
    console.log("\nAll schemas validated.");
    process.exit(0);
}
