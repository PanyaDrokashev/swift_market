import Foundation

struct BDUINode: Decodable {
    let type: BDUIComponentType
    let style: BDUIStyle?
    let layout: BDUILayout?
    let content: BDUIContent?
    let action: BDUIAction?
    let subviews: [BDUINode]
}
