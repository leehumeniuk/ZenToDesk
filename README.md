# ZenToDesk

ZenToDesk.rb

Ruby script to transfer tickets from ZenDesk to Desk.com

Prerequisites:
ZenDesk account > export tickets to xml (Tickets.xml) - I suggest splitting the xml into smaller files
Desk.com account > Desk site url > user credentials
successLog.txt file
errorLog.txt file

ZenToDeskUpdate.rb

Ruby script to update all transferred tickets with appropriate email chain replies. This must be done to ensure HTTP request buffer is not breached - keeps requests small.

COMING SOON!
