//
//  PersonalPasterView.swift
//  Fashion
//
//  Created by AlphaZ on 2018/8/3.
//  Copyright © 2018年 AlphaZ. All rights reserved.
//

import UIKit

class PersonalPasterView: PasterView {

    static let height:CGFloat = 192
    static let width:CGFloat = height

    typealias PasterViewSelectedBlock = (_ :PersonalPasterView) -> Void
    var block:PasterViewSelectedBlock?

 
    class func add(to superView:UIView, delegate:PasterViewDelegate, img:UIImage, block:@escaping PasterViewSelectedBlock) -> PersonalPasterView {

        let randomCenter = CGRect.randomCenterWith(in: superView.frame, w: PersonalPasterView.width, h: PersonalPasterView.height)
        let contentView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: PersonalPasterView.width, height: PersonalPasterView.height))
        contentView.isUserInteractionEnabled = false
        contentView.image = img

        let view = PersonalPasterView.init(contentView: contentView)
        view.center = randomCenter
        view.backgroundColor = UIColor.clear
        view.setImage(UIImage.init(named: "paster_delete")!, forHandler: PasterViewHandler.close)
        view.setImage(UIImage.init(named: "paster_rotate")!, forHandler: PasterViewHandler.rotate)
        view.setImage(UIImage.init(named: "paster_mirror")!, forHandler: PasterViewHandler.flip)
        view.outlineBorderColor = UIColor.white
        view.showEditingHandlers = true
        view.delegate = delegate
        view.block = block

        superView.addSubview(view)

        return view
    }
 

}

