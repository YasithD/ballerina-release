// imports
import ballerina/io;
import ballerina/regex;
import ballerina/time;
import ballerina/file;

// BBE content json record
public type jsonContent record {
    string name;
    string url;
    json[] resources;
    string description;
    string metatags;
};

// Resource record
public type resourceContent record {
    string tag;
    string balFileName;
    string bal;
    string outputFileName;
    string output;
};

// Absolute Path
string absolutePath = check file:getAbsolutePath("./");

// Directories - Inputs
configurable string examplesDir = "./bbe-generator/json-gen/examples";
configurable string outputDir = "./bbe-generator/outputs";

// read a JSON file
public function read(string fileName) returns json|error {
    return check io:fileReadJson(fileName);
}

// write to a JSON file
public function write(string fileName, json content) returns error? {
    check io:fileWriteJson(fileName, content);
}

// check record
public function findRecord(string tag, resourceContent[] resources) returns resourceContent? {
    foreach int i in 0 ..<resources.length() {
        // if tag is found
        if resources[i].tag == tag {
            resourceContent r = resources.remove(i);
            return r;
        }
    }

    return ();
}

// find bbe
// returns the absolute directory if found
public function findBBE(string url, string examplesDir) returns string?|error {
    // read examples directory
    file:MetaData[] directories = check file:readDir(examplesDir);

    foreach file:MetaData dir in directories {
        // absolute path and relative path
        string absDir = dir.absPath;
        string[] pathsSplitted = check file:splitPath(absDir);
        string bbeName = pathsSplitted[pathsSplitted.length()-1];

        if bbeName == url {
            return absDir;
        }
    }

    return ();
}

// generate the BBEs
// provide the path to the BBE folder
public function generateBBE(string examplesDir) returns error? {
    // read index.json
    string dirIndexJSON = check file:joinPath(examplesDir, "/index.json");
    json indexJSON = check io:fileReadJson(dirIndexJSON);
    json[] categories = <json[]> indexJSON;

    // bbe content
    json[] bbes = [];

    // not found bbes
    string[] notFound = [];

    foreach json category in categories {
        // subcategories of the category
        json[] subcategories = [];

        // title of the category
        string title = check category.title;

        // samples of the category
        json samplesTemp = check category.samples;
        json[] samples = <json[]> samplesTemp;

        foreach json sample in samples {
            // sample info
            string name = check sample.name;
            string url = check sample.url;

            // get the absolute directory of the bbe
            string? absDir = check findBBE(url, examplesDir);

            if absDir == () {
                // if bbe is not found
                notFound.push(name);  
                continue;              
            } else {
                // relative path
                string relDir = check file:relativePath(absolutePath, absDir);

                // files inside the BBE
                file:MetaData[] files = check file:readDir(relDir);

                // json content for
                jsonContent bbeContent = {
                    name: name,
                    url: url,
                    resources: [],
                    description: "",
                    metatags: ""
                };

                // resources arrays
                resourceContent[] recordArray = [];
                json[] jsonArray = [];

                foreach file:MetaData f in files {
                    // absolute path and relative path of files
                    string absPath = f.absPath;
                    string relPath = check file:relativePath(absolutePath, absPath);

                    // file checking
                    if relPath.includes(".bal") {
                        string fileContent = check io:fileReadString(relPath);

                        // bal file name
                        string[] splittedDirectory = check file:splitPath(relPath);
                        string balFileName = splittedDirectory[2];

                        // tag
                        string fileName = regex:split(balFileName, "\\.")[0];
                        string[] fileNameSplitted = regex:split(fileName, "_");
                        string tag = fileNameSplitted[int:max(0,fileNameSplitted.length())-1];

                        // check whether the record is already created
                        resourceContent? bbeResource = findRecord(tag, recordArray);

                        // if a record is found
                        if bbeResource != () {
                            bbeResource.balFileName = balFileName;
                            bbeResource.bal = fileContent;

                            // push the record
                            recordArray.push(bbeResource);
                        } else {
                            // create new record

                            // resource format
                            resourceContent bbeResourceNew = {
                                tag: tag, 
                                balFileName: balFileName,
                                bal: fileContent,
                                outputFileName: "",
                                output: ""
                            };

                            recordArray.push(bbeResourceNew);
                        }                

                    } else if relPath.includes(".out") {
                        string fileContent = check io:fileReadString(relPath);

                        // output file name
                        string[] splittedDirectory = check file:splitPath(relPath);
                        string outputFileName = splittedDirectory[2];

                        // tag
                        string fileName = regex:split(outputFileName, "\\.")[0];
                        string[] fileNameSplitted = regex:split(fileName, "_");
                        string tag = fileNameSplitted[int:max(0,fileNameSplitted.length())-1];

                        // check whether the record is already created
                        resourceContent? bbeResource = findRecord(tag, recordArray);

                        // if a record is found
                        if bbeResource != () {
                            bbeResource.outputFileName = outputFileName;
                            bbeResource.output = fileContent;

                            // push the record
                            recordArray.push(bbeResource);
                        } else {
                            // create new record
                            // resource format
                            resourceContent bbeResourceNew = {
                                tag: tag, 
                                balFileName: "",
                                bal: "",
                                outputFileName: outputFileName,
                                output: fileContent
                            };

                            recordArray.push(bbeResourceNew);
                        }                

                    } else if relPath.includes(".description") {
                        string fileContent = check io:fileReadString(relPath);
                        bbeContent.description = fileContent;

                    } else if relPath.includes(".metatags") {
                        string fileContent = check io:fileReadString(relPath);
                        bbeContent.metatags = fileContent;
                    } 
                }

                // change record array into a json array
                foreach resourceContent r in recordArray {
                    jsonArray.push(r.toJson());
                }

                // add the json array to bbe content
                bbeContent.resources = jsonArray;

                // json of bbe content
                json bbeContentJson = bbeContent.toJson();
                
                // add the sample to subcategories
                subcategories.push(bbeContentJson);
            }        
        } 

        // json file with category information
        json bbeCatContent = {
            "name": title,
            "examples": subcategories
        };

        // add bbe's content to the json file
        bbes.push(bbeCatContent);
    }

    // intermediate JSON file
    json intermediate = {
        "title": "intermediate json",
        "categories": bbes
    };

    // printing the not found bbes
    if notFound.length() != 0 {
        foreach string name in notFound {
            io:println(`Couldn't find BBE: ${name}`);
        }
    }

    // write to intermediate json
    string intermediatePath = check file:joinPath(outputDir, "intermediate.json");
    check io:fileWriteJson(intermediatePath, intermediate);
    io:println("Intermediate JSON file created");
}

public function main() returns error? {
    // starting time
    time:Utc startTime = time:utcNow();

    // generate BBEs
    check generateBBE(examplesDir);

    // ending time
    time:Utc endingTime = time:utcNow();

    // elapsed time
    time:Seconds elapsedTime = time:utcDiffSeconds(endingTime, startTime);
    io:println(`Executed in: ${elapsedTime}s`);
}