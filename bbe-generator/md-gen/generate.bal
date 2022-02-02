// imports
import ballerina/io;
import ballerina/file;
import ballerina/regex;

// directories
string mdbookDir = "./bbe-generator/outputs/mdbook";
string mdBookName = "Ballerina By Examples";

// add file content
public function addContent(string title, json example) returns error? {
    // BBE information
    string name = check example.name;
    string url = check example.url;

    // resources of the BBE
    json resourcesJSON = check example.resources;
    json[] resources = <json[]> resourcesJSON; 

    if resources.length() == 0 {
        return ();
    }

    // file path for the BBE
    string mdFile = mdbookDir + "/" + mdBookName + "/src/categories/" + title + "/" + url + ".md";

    // read the md file
    // string mdContent = check io:fileReadString(mdFile) + "\n\n";
    string mdContent = "# " + name + "\n\n";

    // description of the BBE
    // remove //
    string descriptionTemp = check example.description;
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

// update the string for SUMMARY.md from json
public function updateBook(json category) returns string|error {
    // md content
    string categoryContent = "";
    
    // title of the category
    string titleTemp = check category.name;
    string[] splittedTitle = regex:split(titleTemp," ");
    string title = "";
    foreach string s in splittedTitle {
        title += s.toLowerAscii() + "-";
    }
    title = title.substring(0,title.length()-1);

    // add the category title
    categoryContent += "- [" + titleTemp + "]" + "(categories/" + title + "/README.md)\n";
    
    // samples of the category file
    json examplesJSON = check category.examples;
    json[] examples = <json[]> examplesJSON;

    // add subtitles
    foreach json example in examples {
        string subtitle = check example.name;
        string url = check example.url;

        categoryContent += "\t- [" + subtitle + "]" + "(categories/" + title + "/" + url + ".md)\n";

        // add content
        check addContent(title, example);
    }

    return categoryContent;
}

// generates the SUMMARY.md file
public function main() returns error? {
    // file content for SUMMARY.md
    string mdContent = "# Ballerina By Examples\n\n";

    // read content from the intermediate.json
    string dirIntermediate = check file:joinPath(mdbookDir, "intermediate.json");
    json intermediateContent = check io:fileReadJson(dirIntermediate);

    // access the categories
    json categoriesTemp = check intermediateContent.categories;
    json[] categories = <json[]> categoriesTemp;

    foreach json c in categories {
        string|error catContent = updateBook(c);

        if catContent is error {
            panic error("Couldn't generate SUMMARY.md due to an Error");
        } else {
            mdContent += catContent;
        }
    }

    // save navigation to SUMMARY.md
    string dirSummary = check file:joinPath(mdbookDir, "/" + mdBookName + "/src/SUMMARY.md");
    check io:fileWriteString(dirSummary, mdContent);
}