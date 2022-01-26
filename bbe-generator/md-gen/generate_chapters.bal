// imports
import ballerina/io;
import ballerina/regex;

// directories
string dirSummary = "./src/SUMMARY.md";
string dirIndex = "./index.json";

// update the string for SUMMARY.md from json
public function updateString(json category) returns string|error {
    // md content
    string categoryContent = "";
    
    // title of the category
    string titleTemp = check category.title;
    string[] splittedTitle = regex:split(titleTemp," ");
    string title = "";
    foreach string s in splittedTitle {
        title += s.toLowerAscii() + "-";
    }
    title = title.substring(0,title.length()-1);

    // add the category title
    categoryContent += "- [" + titleTemp + "]" + "(categories/" + title + ".md)" + "\n";
    
    // samples of the category file
    json samplesJSON = check category.samples;
    json[] samples = <json[]> samplesJSON;

    // add subtitles
    foreach json sample in samples {
        string subtitle = check sample.name;
        string url = check sample.url;

        categoryContent += "\t- [" + subtitle + "]" + "(bbes/" + url + ".md)" + "\n";
    }

    return categoryContent;
}

// generates the SUMMARY.md file
public function main() returns error? {
    // file content for SUMMARY.md
    string mdContent = "# Ballerina By Examples\n\n";

    // read content from the index.json
    json indexContent = check io:fileReadJson(dirIndex);

    // access the categories
    json[] categories = <json[]> indexContent;

    foreach json c in categories {
        string|error catContent = updateString(c);

        if catContent is error {
            panic error("Couldn't generate SUMMARY.md due to an Error");
        } else {
            mdContent += catContent;
        }
    }

    // // save navigation to SUMMARY.md
    check io:fileWriteString(dirSummary, mdContent);
}