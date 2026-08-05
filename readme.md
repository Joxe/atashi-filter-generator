# Introduction

This is a filter generator for Path of Exile written in GDScript which aims to have you work in a single layout file and a single config file to generate multiple filters that all look kinda the same but switch on and off things based on the configuration that was applied. This should let you create one layout which shows certain items for an SSF filter but hides them for a Trade filter.

The primary issue that this project is trying to solve is that when you go "I want my 6 sockets items to have a blue icon" you should only have to change one file to apply that change to all your filters.

# How to use

![UI Design is my passion](./git_content/screenshot.png)

## From a built executable

1. Start the executable
2. Click `Open Config` and select the config file of your choice, my config should be available in the root directory as `filter-config.json`
3. Click `Select Output Directory` and select where the filters should be written to. You can select the PoE directory but a warning message will show as this tool *overwrites* any existing file when generating. Always back up your existing filters if you write directory to the PoE directory.
4. Click `Generate Filters`, the text output should show what's being generated.
5. Check if the filters work in game.

You can leave the executable running and make changes to either the layout or config and do quick iteration of your filters, no need to restart in between each run.

## From Godot Engine

1. Download Godot from [their Website](https://godotengine.org/), I have been using version 4.7.1 but newer versions should probably be fine since the complexity of the project is rather low
2. Clone or otherwise download the git repository
3. Open `project.godot` in your newly downloaded Godot Engine
4. Press the play button in the top right (or F5) to start and then follow the built executable steps

## How do I write a layout and config file?

The file types are normal JSON files so any way that makes those work. I personally write them manually in a text editor. The layout and config that I use are included in the repository so you can use those as examples but I have also created some documentation for [layouts](./documentation/layout.md) and [configs](./documentation/config.md) that you can read.

# What is bad about this?

A lot, at the time of writing I've only really put like 10 hours of work into this so while it works it works only up to the point where it generates *my* filters in the way I want them. I'm sure that as soon as another person uses this they will run into a lot of issues.

Many filter features are not available just for the reason that I'm not using them, for example there is no way of handling filter sounds since I simply don't use them in my filters. The filter that is generated also contains a lot of repeated code that probably could be cleaned up using the `Continue` keyword, but doing so increases the complexity a lot so I have not spent any time trying to solve that. The generator doesn's try to be smart and join rules that would have the same result or something like that so if you write 15 rules that look the same, the generator will generate 15 blocks of filter code for you.

Error checking of the generated filter is very sparse to non-existant. My thought process on this one is that PoE itself already has this error check and it's quick enough to generate -> reload filters -> fix issues that the generator itself doesn't need to reinvent the wheel that GGG already invented. That said, there could be a use for layout error checking in the future like having rules that contradict each other, making sure that you don't hide Mirrors of Kalandra and things like that. At the time of writing, any error checks like that does not exist and it's up to you to write a good layout and vet the generated code.

I don't personally mind working directly in JSON files, but some certainly do. The silver lining is that you could technically write a program that generates the layout (and maybe that's something that the Godot program can do in the future?) but at that point, do we really need the middle step of the layout file? In my experience the layout file is also oftentimes larger than the resulting filter so if you are only ever using one filter you probably set yourself up to more work using this tool.

# Why is this better than FilterBlade?

It's not, NeverSink does a fantastic job for the PoE community and you should probably use that instead. But I do like the fact that I can apply the same layout changes on multiple filters and that I can run it locally rather than on the web. I personally also enjoy working in a text file rather than having to relearn FilterBlade's UI every 6 months or so when I need to update my filter. There also isn't really anything that prevents you from reusing the same layout for both PoE 1 and PoE 2 (besides a lot of work writing conditions) so you can technically get the same look and feel of your filter between the two games.

# Why Godot, are you stupid?

I don't know Python or any web programming and didn't feel like writing C#. It is pretty nice that Godot is a self-contained scripting engine, though, no installation is needed and it won't ingrain itself into the rest of your system. Godot also makes works on Windows, Linux and Mac without requiring any installation, just a download of an executable. Godot kind of also feels a bit easier than C# when it comes to JSON parsing, but that's probably personal preference. If this project expands in the future it might also be a nice thing to have a renderer available. It would be really nice to be able to render a preview of your filters like FilterBlade does.