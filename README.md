# YAMon-v4

**2025-02-24**

Fixed a couple of show stopping bugs, both existing and mine! 

And... after dogfooding it on an  **Openrt One** unit I can say that it does work. 

It's still a little messy to get up and running and the **validation.sh** script is still your friend - run it after the setup script is finished.
With the OpenWrt One router, you need to install the _iptables-legacy_ package. I installed **bash** but that's probably not essential.

After downloading the zip file, unpack it and rename the resulting directory to **YAMon4**. 
Then **cd YAMon4** and run **install.sh**, which will then launch **setup4.0.7.sh** where you will populate the **config.file** and be given the option to start it.

To start YAMon, execute the init script - _/etc/init.d/yamon4 (start | stop)_ or **bash start.sh reboot** 
To stop YAMon, execute **bash pause.sh** AND also stop the **cron** daemon; or inactivate the crontab entries
To clear the iptables entries, run **clear-iptables.sh**


<hr>

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

I've since added the __Activ8me (Australia)__ ISPs csv files as an option for monthly downloads. It works! But I can't use it without changing the way YAMon accesses its files.

YAMon fetches the 2 main javascipt files from the parent site so I can't use my modified js/util4.0.js file. The existing html page doesn't know anything about my modified local version unless I turn off / bypass some hard coded URLs.

To see the default configuration of YAMon in action, run your browsers inspector inspect(Q) for firefox - F12 key -,  and you'll see what's happening. No doubt configuring the code that way made sense when changes could be rolled out to everyone from a centrally controlled server - and while the server remains, there are no longer any code updates.  (As an aside - Al C. deserves a medal for supporting so many installation types/models. The central server would have made that task easier instead of impossible.)

That said, there is a config option "_doLocalFiles=1" that can be set in the config.file but the html page never reads/uses it, it's not implemented anywhere that I could find. I can't see the origins of that code, or if there was anything further to it. Thaty switch could be manually copied into the html page, but ease of configuration is alawys a better option.

To make it easier and implement that switching function, I've repurposed the 'dev / current' tick box which is under the html __Settings__ tab - in the __Debug__ section :  __Use this servers JS & CSS files__. Originally that selected between Als /dev/ or /current/ versions. Now though, if that box is ticked then we use our local version, (not __dev__.elopment as it was before) and the old __current__ option remains as the original "fetch from usage-monitoring.com/current" switch when it is __unticked__.

Fresh out of the box - a new installation -  that box is unticked. If you want to use your local verion of files, then __tick__ it! If you want to continue to use Als server then leave it unticked. For instance, You would do that if you had database keys, that's the only way you can access the site. I have no idea if that function is still active. it's before my time. 


For old, but still relevant installation tips & tricks for a manual install - which we are doing, see 
       https://usage-monitoring.com/installv4.php

 Please report any issues from this repo as github issues via the link on this repo...
     https://github.com/glennmckechnie/YAMon-v4

Tested on an __OpenWRT One__ with the __opkg iptables-zz-legacy__ installed.

- This github installation method __install.sh__ requires that the github repo is unpacked into __/opt/YAMon__ and __install.sh__ is run from there.

- Run the validate.sh script when finished and make sure it matches.

- Read.. https://usage-monitoring.com/v4Install+Validate.php

It's running, with an occasional misfire. On occasion the hourly file gets mangled, but the raw data back up has all the required values to rebuild the br0ken file. It's still early days in the testing stakes, and it did show me what I needed to know - what was using all my data ... several things!

I run noScript in the firefox browser, and despite adding an exception for my YAMon installation, the javascript doesn't always fire up. If I bypass NoScript completely, it will then fire up and continue running whichever state NoScript is in!  

But it does work, and apppears to be more informative than the nlbwmon package  (nlbwmon 2024.02.21~c7616bcf-r1	~21.66 KiB	OpenWrt Traffic Usage Monitor)  __YMMV__

Added Als original copyright licence as a file. My trivial changes use the same licence.

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
