# YAMon-v4
YA Fork of YAMon v4 !

Welcome to this Github YAMon (unofficial) fork

This is a forked version of YAMon with modifications.

The first and most important modification is to the install script, it should now work.
Use __install.original.sh__, but keep reading...

The original installer has been fixed and works as it did before the https:///usage-monitoring.com site changes. It is still available here but as it fetches the same files as in this repo then it can be consider redundant, usable but redundant. It will work only while the parent site remains up too. And with Al's long absence this could ?? be a problem.

For now though, it is usable. If you want the original usage-monitoring.com sites version then use  __install.original.sh__  It should now work around the http / https issues.!

If you want the files in this repo here, then run the install.sh script

So...You have choices, and only you can decide!

There have been a few modifications to the files here and to use them, you need to install them ( using __install.sh__ ).

I've since added Activ8me (Australia) csv files as an option for monthly downloads. It works! But...

Because of that change, I can't use the js/util4.0.js file from usage-monitoring.com and as the existing html page ignores the modified local version, we have to turn off / bypass some hard coded URLs.

The default configuration of YAMon always fetches the .js files from the parent site, run your browsers inspector  inspect(Q)  (or whatever it's called) and you'll see what's happening. No doubt that code made sense when changes could be rolled out to everyone from a centrally controlled server - but it seems that option is closed.  (As an aside - Al C. deserves a medal for supporting so many installation types/models. The central server would have made that task easier instead of impossible. However now it's unecessary and will remain that way until it restarts, if it ever does.)

There is a config option "_doLocalFiles=1" that can be set in the config.file but the html page never reads/uses it. Thaty switch could be manually copied into the html page, but ease of configurationis alawys a better option.

To do that, I've repurposed the 'dev / current' tick box under the html __Settings__ tab - in the __Debug__ section, see __Use this servers JS & CSS files__. If that box is ticked then we now use the local version,(not __dev__.elopment as it was before) and the __current__ option remains as the original "fetch from usage-monitoring.com/current" switch when __unticked__.

Fresh out of the box, that box is unticked. If you want to use your local verion of files, then tick it! If you want to continue to use Als server then leave it. If you had database keys, that's the only way you can access the site - and I have no idea if that is still an option - it's before my time. 


For old, but still relevant installation tips & tricks for a manual install - which we are doing, see 
       https://usage-monitoring.com/installv4.php

 Please report any issues from this repo as github issues via the link on this repo...
     https://github.com/glennmckechnie/YAMon-v4

Tested on an __OpenWRT One__ with the __opkg iptables-zz-legacy__ installed.

It's running, with an occasional misfire. (On occasion the hourly file gets mangled, but the raw data back up has all the required values to rebuild the br0ken file. It's still early days in the testing stakes, and it did show me what I needed to know - what was using all my data ...several things!

I run noScript in the firefox browser, and despite adding an exception for my YAMon installation, the javascript doesn't always fire up. If I bypass NoScript completely, it will fire up and continue running whichever state NoScript is in!  But it does work, and apppears to be more informative than the nlbwmon package  (nlbwmon 2024.02.21~c7616bcf-r1	~21.66 KiB	OpenWrt Traffic Usage Monitor)  __YMMV__


============The following notes are from the original README.md file at the official repo ============

__The Official repository for YAMon v4__

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
