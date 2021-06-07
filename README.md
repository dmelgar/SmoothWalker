# Creating a Mobility Health App

Create a health app that allows a clinical care team to send and receive mobility data.

## Overview

- Note: This sample code project is associated with WWDC20 session [10664: Getting Started in HealthKit](https://developer.apple.com/wwdc20/10664/) and WWDC20 session [10184: Synchronizing Your Health Data with HealthKit](https://developer.apple.com/wwdc20/10184/).

## Configure the Sample Code Project

Before you run the sample code project in Xcode:

* Download the latest version of Xcode with the iOS 14 SDK. The sample code project requires this version of Xcode.
* Confirm that CareKit is included as a dependency in Swift Packages.


## Design comments 6/6/2021

New branch adds walking speed by day, week, and month.


Overall existing code organization is less than ideal. I would have preferred to write a new app rather than update the sample.
There is poor encapsulation of data and function across a variety of classes.
- Use of utility functions not associated with any object is a concern. An improved approach would be to extend existing classes
or move functions to be methods of classes whose responsibility is appropriate for that function.
- Overall design spreads app specific details across several classes. 
- Preferred approach for cells is to have a model which ensapsulates the data which is needed to drive the UI. The data source
populates this model objects and passes it to the cell. This would allow the cell to be general purpose. In this case it could allow a chart
cell that could be populated with a variety of data. In the current approach the cell is responsible for obtaining specific data. This
is fragile, tightly coupled and prevents easy extensibility for broader use cases.
- Having a model to represent cell data could also support similar encapsulation and extensibility for table view call. 

- FeedItemCollectionViewCell.swift is misnamed. It should be DataTypeCollectionViewCell.swift as it is the name of the class contained therein.

- Overall project organization groups files by type rather than function. I'd suggest organizing functionally or by view, such 
as classes associated with each tab. This allows easier navigation of all the files associated with a tab. Providing such encapsulation allows
additional tabs to be added or removed more easily and all associated files to be readily found.

- Healthkit queries are spread among multiple views. Depending on future enhancement plans, a single
healthkit data manager class could be created to consolidate queries and provides a central repository of query results. This could allow query
results to be consolidated so that the different tabs only represent different views (table vs chart vs graph) of the same data. This could also be
used to centralize background query processing to keep the various views updated in real time.

