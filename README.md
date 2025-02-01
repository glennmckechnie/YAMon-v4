# YAMon-v4
YA Fork of YAMon v4 !

       Welcome to this Github YAMon (unofficial) fork

This is a forked version of YAMon with modifications.

The first and most important modification is to the install script, it should now work.

The original installer has been fixed and works as it did before the https:///usage-monitoring.com
site changes. It is still available here but as it fetches the same files as in
this repo then it can be consider redundant, usable but redundant. It will work only while the
parent site remains up. And with Al's long absence this could ?? be a problem.

For now though, it is usable. If you want the original usage-moitoring.com sites version then use
 install.original.sh  It should now work around the http / https issues.!

If you want the files in this repo, here then run install.sh

So...You have choices, only you decide!

There have been a few modifications here.

I've since added Activ8me (Australia) csv files as an option for monthly downloads. It works! But...

Because of that change, I can't use the js/util4.0.js file from usage-monitoring.com and as the existing html page ignores the local version, we have to turn off / bypass some coded URLs.

The default configuration of YAMon always fetches the .js files from the parent site, run your browsers inspector  inspect(Q)  (or whatever it's called) and you'll see what's happening. That code made sense when chnages could be rolled out to everyone from a centrally controlled server - but it seems that option is closed.  (As an aside - Al C. deserves a medal for supporting so many installation types./ models the central server would have made it easier instead of impossible. A sterling job)

There is a config option "_doLocalFiles=1" that can be set in the config.file but the html page never reads/uses it. It could be manually copied into the html page, but a configurable option is always good.
To do that, I've repurposed the 'dev / current' tick box under the html settings tab - section Debug ...__Use this servers JS & CSS files__. iIf ticked then we now use the local version, not __dev__(elopment), and __current__ remains as the original "fetch from usage-monitoring.com/current" unticked as it was before.

Fresh out of the box, that box is unticked. If you want to use your local verion of files, then tick it!



For old, but still relevant installation tips & tricks for a manual install - what we are doing, see 
       https://usage-monitoring.com/installv4.php

 Please report any issues from this repo as github issues via the link on this repo...
     https://github.com/glennmckechnie/YAMon-v4


========================

                The Official repository for YAMon v4

See https://usage-monitoring.com/v4Install+Validate.php for instructions on how to install YAMon and validate the installation.
What is YAMon?
It is a tool that reports usage for every device connecting to your router. Traffic can be rolled-up into arbitrary logical groupings (e.g., by family or roommate name, by device location or function, etc.) A rich and robust set of features and reports driven by an active user-base.

Why YAMon?
Are you trying to figure out why you are exceeding your month usage cap?
Are you trying to figure out who is hogging all of your data?
Are you sure your kids are shutting off their devices at bedtime?
That's why!! More info: http://usage-monitoring.com/about.php

To download YAMon: http://usage-monitoring.com/download.php

Questions about installing: http://usage-monitoring.com/help/?c=Install
Questions about errors: http://usage-monitoring.com/help/?c=Errors
General questions: http://usage-monitoring.com/help/?c=General

More info: questions@usage-monitoring.com

# License

Copyright (C) 2020 by Al Caughey (al@caughey.ca)

Permission to use and/or distribute this software for any purpose without fee is hereby granted.

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
