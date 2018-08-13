//
//  TextPasterView.swift
//  Fashion
//
//  Created by AlphaZ on 2018/8/7.
//  Copyright © 2018年 AlphaZ. All rights reserved.
//

import UIKit

class TextPasterView: PasterView {
    
    static let defaultText = "默认文字"
    static let shadowColor = UIColor.black
    static let size = CGSize(width: 235, height: 56)

    override init(contentView: UIView) {
        super.init(contentView: contentView)
        self.outlineBorderColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContentView(image:UIImage) {
        if let imgV = self.contentView as? UIImageView {
            imgV.image = image
        }
    }
    
    class  func imageFromView(view:UIView) -> UIImage? {
        let scale:CGFloat = 15
        var size = view.frame.size
        size = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.scaleBy(x: scale, y: scale)
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
