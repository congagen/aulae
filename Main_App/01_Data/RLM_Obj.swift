import RealmSwift
import Foundation

class RLM_Obj: Object {
    
    @objc dynamic var title:       String = ""
    @objc dynamic var name:        String = ""
    @objc dynamic var version:     Int = 0

    @objc dynamic var feedId:      String = ""
    @objc dynamic var uuid:        String = ""
    
    @objc dynamic var type:        String = ""
    @objc dynamic var contentUrl:  String = ""
    
    @objc dynamic var info:        String = ""
    
    @objc dynamic var demo:        Bool = false
    @objc dynamic var active:      Bool = true
    @objc dynamic var deleted:     Bool = false

    @objc dynamic var contentLink: String = ""
    @objc dynamic var directLink:  Bool   = false
    
    @objc dynamic var fileName:    String = ""
    @objc dynamic var filePath:    String = ""
    
    @objc dynamic var text:        String = ""
    @objc dynamic var font:        String = ""
    
    @objc dynamic var instance:    Bool = false
    
    @objc dynamic var hex_color:   String = "7259ff"
    @objc dynamic var style:       Int = 0
    @objc dynamic var mode:        String = "free"
    
    @objc dynamic var rotate:      Double = 0
    @objc dynamic var hoover:      Double = 0
    
    @objc dynamic var radius:      Double = 0
    @objc dynamic var scale:       Double = 1.0
    @objc dynamic var world_position: Bool = true
    @objc dynamic var world_scale: Bool = true
    @objc dynamic var billboard:   Bool   = true
    @objc dynamic var localOrient: Bool   = false

    @objc dynamic var lat:         Double = 0
    @objc dynamic var lng:         Double = 0
    @objc dynamic var alt:         Double = 0

    @objc dynamic var x_pos:       Double = 0
    @objc dynamic var y_pos:       Double = 0
    @objc dynamic var z_pos:       Double = 0
    
}
