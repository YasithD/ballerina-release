// imports
import ballerina/regex;
import ballerina/io;

// file paths
string intermediatePath = "./intermediate.json";
string bbeMDFilePath = "./src/bbes/";

public function main() returns error? {
    // read the intermediate JSON file
    json intermediateJSON = check io:fileReadJson(intermediatePath);
    json bbeJSON = check intermediateJSON.BBEs;

    // bbe json files
    json[] bbes = <json[]> bbeJSON;

    foreach json bbe in bbes {
        // BBE name
        string bbeName = check bbe.bbeName;

        // resources of the BBE
        json resourcesJSON = check bbe.resources;
        json[] resources = <json[]> resourcesJSON; 

        if resources.length() == 0 {
            continue;
        }

        // file path for the BBE
        string mdFile = bbeMDFilePath + bbeName + ".md";

        // read the md file
        // string mdContent = check io:fileReadString(mdFile) + "\n\n";
        string mdContent = "";
        string[]|error mdContentTemp = io:fileReadLines(mdFile);

        if mdContentTemp is error {
            continue;
        } else {
            mdContent += mdContentTemp[0] + "\n\n";
        }

        // description of the BBE
        // remove //
        string descriptionTemp = check bbe.description;
        string[] splitted = regex:split(descriptionTemp, "//");
        
        string description = "";
        foreach string s in splitted {
            description += s;
        }
        mdContent += description + "\n\n";

        foreach int i in 0..<resources.length() {
            // resource seperation
            if i != 0 {
                mdContent += "\n\n***\n\n";
            }

            // bal file
            string balContent = check resources[i].bal;
            string bal = "";
            if balContent.length() != 0 {
                bal = "```go\n" + balContent + "\n```\n\n";
            } 

            // output file
            string outputContent = check resources[i].output;
            string output = "";
            if balContent.length() == 0 {
                output = "```go\n" + outputContent + "\n```";
            } else {
                output = "#### Output\n\n```go\n" + outputContent + "\n```";
            }

            mdContent += bal + output;
        }

        // write to md file
        check io:fileWriteString(mdFile, mdContent);        
    }
}