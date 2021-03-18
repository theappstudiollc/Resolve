//
//  Extensions-SpriteKit.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//	   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SpriteKit

extension SK3DNode {
	
	func calculatedFrame(forPoint point: CGPoint) -> CGRect {
		let size = CGSize(width: frame.size.width * xScale, height: frame.size.height * yScale)
		let origin = CGPoint(x: point.x - size.width * 0.5, y: point.y - size.height * 0.5)
		return CGRect(origin: origin, size: size)
	}
}

extension SKSpriteNode {
	
	func calculatedFrame(forPoint point: CGPoint) -> CGRect {
		let size = CGSize(width: frame.size.width * xScale, height: frame.size.height * yScale)
		let origin = CGPoint(x: point.x - size.width * anchorPoint.x, y: point.y - size.height * anchorPoint.y)
		return CGRect(origin: origin, size: size)
	}
}
