# CoxAutomotiveChallenge

Leverage a remote API to get a list of vehicles and derive the dealerships where these vehicles are available for sale.

While there's three screens, I actually only implemented two and reused the Results view to display both dealers and their vehicles.  I tested the interface out on iPad Pro, iPhone 11 Pro Max

I opted to use CoreData for persistence and caching (it's been a couple years since I've done hardcore CD work, so I was happy to get a refresher which included making use of newer NSPersistentContainer instances), plus I also used DispatchGroups (something that's asked about often during job interviews but I've never found a practical reason to use it until now) to hold off on continuing to load dealer information and update the UI until everything was finished processing from the backend.

The meat of the backend API work is seen in the SwaggerManager.swift file, while the ResultsTableViewController actually does the work of displaying dealers & vehicles (which isn't derived from a UITableViewController but instead is a UIViewController with a table view in it, the point being that I could potentially add in extra UI elements later on beyond the navigation controller & navigation bar).

The data model can be seen in the "Model.xcdatamodeld" file.  With a bit more time, I certainly would have added 1 to many relationships from the dealer to the vehicles they have in stock.  
