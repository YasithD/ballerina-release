// imports
import ballerina/io;
import ballerina/regex;
import ballerina/file;

// BBE content json record
public type jsonContent record {
    string bbeName;
    json? category;
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
string examplesPath = "./examples";
string outputPath = "../outputs/intermediate.json";

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

// category finder
public function categoryFinder(string bbeName) returns json?|error {
    // read index.json
    string dirIndexJSON = check file:joinPath(examplesPath, "/index.json");
    json indexJSON = check io:fileReadJson(dirIndexJSON);
    json[] categories = <json[]> indexJSON;

    // iterate categories
    foreach int i in 0..<categories.length() {
        json sampleTemp = check categories[i].samples;
        json[] samples = <json[]> sampleTemp;
 
        // iterate through the subtitles
        foreach json sample in samples {
            // url
            string url = check sample.url;
            if url == bbeName {
                // category name
                string categoryName = check categories[i].title;

                // json for category
                json catInfo = {
                    "name": categoryName,
                    "sequence": i+1
                };

                return catInfo;
            }
        }
    } 
}

// generate the BBEs
// provide the path to the BBE folder
public function generateBBE(string examplesPath) returns error? {

    // read examples directory
    file:MetaData[] directories = check file:readDir(examplesPath);

    // bbe content
    json[] bbes = [];
    
    foreach file:MetaData dir in directories {
        // absolute path and relative path
        string absDir = dir.absPath;
        string relDir = check file:relativePath(absolutePath, absDir);

        // skip if not a directory
        if relDir.includes("index.json") || relDir.includes("meta.json") {continue;}

        // split directory
        string[] paths = check file:splitPath(relDir);
        string bbeName = paths[1];

        // files inside the BBE
        file:MetaData[] files = check file:readDir(relDir);

        // find the category
        json? category = check categoryFinder(bbeName);
        
        // json content for
        jsonContent bbeContent = {
            bbeName: bbeName,
            category: category,
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

        // add bbe's content to the json file
        bbes.push(bbeContentJson);

    }

    // intermediate JSON file
    json intermediate = {
        "title": "intermediate json",
        "BBEs": bbes
    };

    // write to intermediate json
    check io:fileWriteJson(outputPath, intermediate);
    io:println("Intermediate JSON file created");
}

public function main() returns error? {
    // generate BBEs
    check generateBBE(examplesPath);
}