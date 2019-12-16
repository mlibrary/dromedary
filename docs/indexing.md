# Indexing (new) MED data

## Overview

Deployment of both code and data is done from a unix-like command line. This can
be in a terminal window on you Macintosh or from any server we use in the
library (e.g., malt).

To deploy new data, there are just a few steps:

* [Deploy new _code_](docs/deploying.md) if need be (almost certainly not)
* Get the new data as a .zip file and upload it to the development machine
* _Prepare_ the new data for indexing
* _Index_ the new data

## 1. Get the new data as a zip file and put it on the dev server

[2019-12-16 the dev server is "nectar"]

When new data is ready, Paul will announce that it's ready to go
and in Box.

* Got to [the box folder](https://umich.box.com/s/ah2imm5webu32to343p2n6xur828zi5w) 
where we keep everything and click on the "Download" button. This will put a 
file called "In_progress_MEC_files.zip" wherever things download for you.
* Copy that file to the development box. Right now the dev server is `nectar`,
but if things change just substitute the new machine.

You now have the new files on your desktop/laptop. We need to get them
to the dev server. 

_If you have a program you use to upload/download from servers_ go ahead
and use it. If not, the shell command on a Mac would be:

```bash
scp ~/Downloads/In_progress_MEC_files.zip nectar:/hydra-dev/dromedary-data/build
```

If this doesn't make sense or you get errors (maybe you're not allowed to
log into nectar?) ask A&E for help.

## Prepare the new data for later indexing (do this *once*)

We need to turn the raw data into something the program can use.

_This only needs to be done once_. All three instances 
(testing/staging/production) can use the same prepared data.

(You can just copy and paste this)

```bash
ssh deployhost exec dromedary-testing bin/dromedary newdata prepare /hydra-dev/dromedary-data/build/In_progress_MEC_files.zip
```

You'll see log messages scroll by as the code churns through the raw data and works on it.
