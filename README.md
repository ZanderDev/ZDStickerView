
### 贴纸小控件

		贴纸控件，Sticker，包含双指和单指（旋转、缩放、移动、删除、镜像功能）（美图秀秀类似）


- github：https://github.com/ZanderDev/ZDStickerView.git （@zd 完善demo）
 
 
 
- 手势代理方法

	
	
	- 判断自视图是否拦截响应，不再传递手势
	
			func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {}
	
	
	- 判断是否可以同时响应
	
			func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {}
			
			
			
- 参考：
	-  https://github.com/ZanderDev/StickerView