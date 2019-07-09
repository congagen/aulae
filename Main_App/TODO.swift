
// URGENT:

//      ContentNode Action Menu: Chat Option Bug

//      If !Topic Feed -> FeedID = FeedURL
//      Handle Only Local..
//      Enable Direct Links
//      Marker Default -> Image

//      Loding Spinner + Retry Schedule if [Data is missing || Still in transit]
//      Custom Icon for topic sources
//      ObjId: SourceURL + ObjUrl + ObjId  (Handle ObjID count > 1?)
//      Version / UTX Bugs
//      Version / UTX Docs

//      Feed Radius?
//      XYZ billboard?

//      Source API -> Source List ( Max number? )

//      Instance Mgmt
//      Make un-selectable Non-Blocking
//      Floor / Wall Mode
//      SCN / Particle Systems?

//      API Param isInteractive -> Selectable,?

//      Launchscreen Logo
//      Marker images?
//      Docs: Init Chat Session Message
//      Blank Camera Input Bug -> Refresh (Assert Cam)?

//      Viewport Object Selection (Select obj if distance < N)

//      Selectable Chat Text
//      Chat View Mode Button

//      Audio Bugs
//      Lib/Source Manager -> CollectionView? Reorder

//      Audio Bug
//      Selection Bugs
//      Refresh Bugs
//      QR Lag bug
//      iPad Support

// Feature:
//      Add custom content in mapview

//      Prevent Node selection if touches > 1
//      Add Source Button in Main View
//      Greeting Cards

//      Map Update

//      Fix Map Radius 
//      Remove Source Menu Option
//      Viewver Bugs

//      ArViewer -> [objUUID: CustomScale]
//      If distance < 1-5M -> Place @ floor
//      Orient all XYZ
//      Demo Content -> Icon Animations
//      Handle Non Square Images
//      Share Photo Cancel Button TintColor?

//      SETTINGS -> LOCATION SHARING
//      Demo Content
//      Lng -> Long

// ----------------------------------------------------------------------------------------------

// Menu Link / Direct Link
//
//      Content Display Modes:  Floor / Wall / World Position / Static
//      Extensions: Target: Info: URL Types
//      Duplicate feed ID Bug (?)

// Feeds:
//      Feed Feeds / RSS / ?
//      Update feed/items if deef version id !=
//      Remove/Invalidate removed FeedItems
//      Feed Update Timeout / Error Thresh

// Feeds JSON SCHEMA:
//      Object Settings:
//         Animate:            { Hoover: SPEED, DISTANCE} / {Rotate: SPEED, DISTANCE} / {Wander: SPEED, DISTANCE }
//         ARView Positioning: GPS / CAM OFFSET
//         ARView Text:        Tapped Action -> Show Text?
//         Content Type:       SCN

// MapView:
//        Beacon Icons
//        Timer Updadate

// TabBar:
//        Icons:            Map View Feeds Settings

// NavigationBar:
//        Refresh Buttons: Spin Animations


// ----------------------------------------------------------------------------------------------
// BUGS:

// FEED MGMT: DELETE FEED:
// -> UpdateFeed:
//    2019-02-22 10:32:47.605167+0100 aulae[7703:1403447] *** Terminating app due to uncaught exception 'RLMException', reason: 'Object has been deleted or invalidated.'
//    *** First throw call stack:
//    (0x1f8219ea4 0x1f73e9a50 0x103070448 0x102768b8c 0x10276b728 0x1027558fc 0x105ef7824 0x105ef8dc8 0x105f06a78 0x1f81a9ce4 0x1f81a4bac 0x1f81a40e0 0x1fa41d584 0x2253b8c00 0x102753464 0x1f7c62bb4)
//    libc++abi.dylib: terminating with uncaught exception of type NSException
