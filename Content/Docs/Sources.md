
#### Supported file formats:
	Images: Jpg (1:1), Png (1:1)
	Animation: Gif (1:1), USDZ
	3D: USDZ
	Audio: Mp3

---

#### Sources  (JSON File / API Response):

	Required:

        "id":
                Type: String   |   Default: ““
                Effect: Source Id

        "name":
                Type: String   |   Default: ““
                Effect: Source Name

        "version":
                Type: String   |   Default: ““
                Effect: Refresh parameter

        "updated_utx":
                Type: Number   |   Default: 0
                Effect: Refresh parameter

	Optional:

        "info":
                Type: String   |   Default: ““
                Effect: Source description

        "thumb_url":
                Type: String   |   Default: ““
                Effect: Source manager image


	“content”: { ““: {} }:

        "name":
                Type: String   |   Default: ““
                Effect: Object name

        "info":
                Type: String   |   Default: ““
                Effect: Object info

        "type":  
                Type: String   |   Default: “marker“
                Effect: Content type

                Options:  
                     “image” / “gif” / “usdz“
                     “text“ / “marker“ / “audio“

        "url":
                Type: String   |   Default: ““
                Effect: Content url

        "scale":
                Type: Number   |   Default: 1.0
                Effect: Object scale

        "world_scale":
                Type: Boolean   |   Default: True
                Effect: Distance scaling / Static

        "world_position":
                Type: Boolean   |   Default: True
                Effect:  XYZ / LatLong position

        "local_orientation":
                Type: Boolean   |   Default: False
                Effect: Apply local device orientation

        "lat" / "lng" / "alt":
                Type: Number   |   Default: 0.0 / 0.0 / 0.0
                Effect: Latitude / Longitude / Altitude position

        "x_pos" / "y_pos" / "z_pos":  
                Type: Number   |   Default: 0.0 / 0.0 / 0.0
                Effect: XYZ position

        "radius":
                Type: Number   |   Default: 0
                Effect: View radius (requires lat/long)

        "billboard":
                Type: Boolean   |   Default: True
                Effect: Toggles billboard mode

        "instance":
                Type: Boolean   |   Default: False
                Effect: Reuse local content if present

        "content_link":
                Type: String   |   Default: ““
                Effect: Action menu option ( URL -> Web-browser )

        “hex_color“:
                Type: String    |   Default: “7122e8“
                Effect: Color for text and marker objects

        "text":
                Type: String   |   Default: ““
                Effect: Text content for text objects

        "font":
                Type: String   |   Default: ““
                Effect: Font for text objects

        "chat_url":
                Type: String   |   Default: ““
                Effect: Action menu option and chat functionality
