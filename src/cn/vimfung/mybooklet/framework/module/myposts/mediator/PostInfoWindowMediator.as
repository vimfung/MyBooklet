package cn.vimfung.mybooklet.framework.module.myposts.mediator
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.notification.PostNotification;
	import cn.vimfung.mybooklet.framework.module.myposts.ui.PostInfoWindow;
	
	import flash.utils.Dictionary;
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	/**
	 * 添加/编辑文章窗口中介 
	 * @author Administrator
	 * 
	 */	
	public class PostInfoWindowMediator extends Mediator implements IMediator
	{
		public function PostInfoWindowMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		/**
		 * 获取文章信息窗口 
		 * @return 文章信息窗口
		 * 
		 */		
		public function get postInfoWindow():PostInfoWindow
		{
			return this.viewComponent as PostInfoWindow;
		}
		
		/**
		 * @inheritDoc 
		 */		
		public override function listNotificationInterests():Array
		{
			return [PostNotification.BEGIN_IMPORT_URL_POST,
				PostNotification.IMPORT_URL_POST_LOAD_ERROR,
				PostNotification.IMPORT_URL_POST_LOAD_PROGRESS,
				PostNotification.IMPORT_URL_POST_LOAD_SUCCESS];
		}
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function handleNotification(notification:INotification):void
		{
			var postInfoWindow:PostInfoWindow = this.postInfoWindow;
			
			switch(notification.getName())
			{
				case PostNotification.BEGIN_IMPORT_URL_POST:
				{
					postInfoWindow.showTip("正在导入内容...");
					break;
				}
				case PostNotification.IMPORT_URL_POST_LOAD_ERROR:
				{
					postInfoWindow.hideTip();
					
					var error:Error = notification.getBody() as Error;
					(this.facade as GNFacade).alert("载入文章内容时出现异常:" + error.message);
					break;
				}
				case PostNotification.IMPORT_URL_POST_LOAD_PROGRESS:
				{
					var progressInfo:ProgressInfo = notification.getBody() as ProgressInfo;
					postInfoWindow.setProgress(progressInfo.total, progressInfo.progress);
					break;
				}
				case PostNotification.IMPORT_URL_POST_LOAD_SUCCESS:
				{
					var contentInfo:Object = notification.getBody();
					
					postInfoWindow.files.splice(0);
					var fileMap:Dictionary = contentInfo.files;		//取得文件映射表
					for (var i:String in fileMap)
					{
						postInfoWindow.files.push(fileMap[i]);
					}
					
					postInfoWindow.hideTip();
					postInfoWindow.rteConnect.htmlText = contentInfo.content;
					break;
				}
			}
		}
	}
}