# PrimoCache Backup-Detect
Periodically checks for a running backup-process and pauses PrimoCache during the backup, so that the cache will not be tainted by reading the whole disk

## What?
While PrimoCache tries to Cache frequently used data and leave the seldomly accessed data on a slow spinning disk, running backups can interfere with this logic. Many backup Programs cannot *read around* the cache so the whole disk while be read while performing a backup.

This will ultimately lead to many data in the Cache which should not be there. So one has to manually pause the Cache while the backup is running and resume it once that is finished.

This is awfully annoying so here is a small tool to do that automatically!

## How?
The Program **PrimoCacheBackupDetect** will run in the background and periodically check if the configured backup-process is running and, if wanted, also has a large enough memory footprint which will indicate, that the backup is indeed running.
If that is true, the Program will pause the PrimoCache via CLI and resume it, once the backup-process stops or falls again below the above mentioned threshold for memory consumption.

## Usage
**Important The PrimoCache GUI must not be running because the PrimoCache CLI cannot perform its tasks otherwise!**

Simply download a current release and run the .exe file. The Program will instantly startup and dock itself within your systray.
With default Settings it is configured to detect *Ashampoo Backup 2018* as this is the Backup-Software I currently use.

### Configuring another Backup-Software
Place the provided .ini File in the same directory as the .exe and change it according to your needs:

Option | Default-Value | Description
------ | ------------- | -----------
Interval | 10000 | Time in milliseconds between each check
Process | backupService-ab.exe | The name of the backup-process (case-sensitive)
Threshold | 50000000 | If this is set higher than **0** the backup-process must also have a memory-footprint this large (in bytes) so the program detects a running backup
PauseCmd | "C:\Program Files\PrimoCache\rxpcc.exe" pause -s -a | Command to be issued as soon as a running backup is detected (keep the quotation marks if the Path to the command contains spaces!)
ResumeCmd | "C:\Program Files\PrimoCache\rxpcc.exe" resume -s -a | Command to be issued as soon as the backup process finishes (keep the quotation marks if the Path to the command contains spaces!)

### Configuring the Memory-Threshold
This functionality is needed for a backup-software like *Ashampoo Backup 2018* where the backup-process is always running even if no backup is currently performed.

You can simply configure your process and an arbitrary threshold in the .ini File and then run the Program. Click on the Icon in the systray and select **Check Process**.

The Program will then output some Details about the process (if it is running) along with the memory-footprint. After that another message will be displayed, if the process reached the configured memory-threshold. Do this multiple times and write down numbers for the memory-footprint while the process is running and while it is idle.
The correct threshold should be configured to a value between the average while running and idling.

### Autostart the Program on boot
Place the .exe and the .ini Files in a directory of your choice (they shall remain there). Then run the Program from that location. Click on the Icon in the systray and select **Set Autostart on Boot**
This will create a scheduled task which will start the Program each time you logon to your computer.

### Remove Autostart
Simpy click on the Icon in the systray and select **Remove Autostart**
This will remove the previously created scheduled task.

## Compiling
Clone this repository and compile the Program using [AutoIt v3](https://www.autoitscript.com/site/)

## Thanks
Many Thanks to [PsaltyDS](http://www.autoitscript.com/forum) for his great UDF [_ProcessListProperties()](https://www.autoitscript.com/forum/topic/70538-_processlistproperties/)

## Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
