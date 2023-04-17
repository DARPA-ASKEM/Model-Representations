const { globSync } = require('glob');
const Ajv = require('ajv');
const fs = require('fs');
const addFormats = require('ajv-formats');
const path = require('node:path');

const ajv = new Ajv();
addFormats(ajv);

const baseSchemaFile = 'base_schema.json';
const schemaFiles = globSync("*/*.json");

const validate = (schemaFile, objectFile) => {
    const object = JSON.parse(fs.readFileSync(objectFile));
    const schema = JSON.parse(fs.readFileSync(schemaFile));
    const validated = ajv.validate(schema, object);
    const passValue = (validated ? 'PASS' : 'FAIL');
    console.log(`${objectFile} <- ${schemaFile} : ${passValue}`)
    return validated;
}

let passed = true;
for (let schemaFile of schemaFiles) {
    // TODO: Validate each model schema matches the base schema.
    const exampleFiles = globSync(path.join(path.dirname(schemaFile), "examples/*.json"));
    for (let exampleFile of exampleFiles) {
        const baseSchemaPassed = validate(baseSchemaFile, exampleFile);
        const filePassed = validate(schemaFile, exampleFile);
        // The validation is true only if everything passes all the times. One failure and you're out!
        passed = passed & baseSchemaPassed & filePassed;
    }
}

// Returns a response code if all examples validate, otherwise a 1.
if (!passed) {
    console.log('\nError validating schemas. See above.');
    process.exit(1);
}
else {
    console.log('\nAll schemas validated.');
    process.exit(0);
}