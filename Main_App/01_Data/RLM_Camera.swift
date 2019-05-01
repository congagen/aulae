import Foundation
import RealmSwift


class RLM_Camera: Object {
    
    @objc dynamic var wantsHdr: Bool = true
    @objc dynamic var wantsExposureAdaptation: Bool = true
    
    @objc dynamic var wantsDepthOfField: Bool = true
    @objc dynamic var focusDistance: Double = 0.5
    @objc dynamic var fStop: Double = 0.5
    @objc dynamic var apertureBladeCount: Int = 1
    @objc dynamic var focalBlurSampleCount: Int = 1
    @objc dynamic var colorGrading: Int = 1

    @objc dynamic var contrast: Double = 0.5
    @objc dynamic var saturation: Double = 0.5
    
    @objc dynamic var exposureOffset: Double = 0.5
    @objc dynamic var averageGray: Double = 0.5
    @objc dynamic var whitePoint: Double = 0.5
    @objc dynamic var minimumExposure: Double = 0.5
    @objc dynamic var maximumExposure: Double = 0.5

    @objc dynamic var colorFringeIntensity: Double = 0.5
    @objc dynamic var colorFringeStrength: Double = 0.5
    @objc dynamic var vignettingIntensity: Double = 0.5
    @objc dynamic var vignettingPower: Double = 0.5
    @objc dynamic var bloomIntensity: Double = 0.5
    @objc dynamic var bloomThreshold: Double = 0.5
    @objc dynamic var bloomBlurRadius: Double = 0.5
    
    @objc dynamic var screenSpaceAmbientOcclusionIntensity: Double = 0.5
    @objc dynamic var screenSpaceAmbientOcclusionRadius: Double = 0.5
    @objc dynamic var screenSpaceAmbientOcclusionBias: Double = 0.5
    @objc dynamic var screenSpaceAmbientOcclusionDepthThreshold: Double = 0.5
    @objc dynamic var screenSpaceAmbientOcclusionNormalThreshold: Double = 0.5
    
}
