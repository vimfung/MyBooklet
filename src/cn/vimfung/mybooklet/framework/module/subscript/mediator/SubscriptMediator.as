package cn.vimfung.mybooklet.framework.module.subscript.mediator
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.notification.PostNotification;
	import cn.vimfung.mybooklet.framework.module.subscript.ISubscript;
	import cn.vimfung.mybooklet.framework.notification.SystemNotification;
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	/**
	 * 订阅中介 
	 * @author Administrator
	 * 
	 */	
	public class SubscriptMediator extends Mediator implements IMediator
	{
		public function SubscriptMediator(subscript:ISubscript=null)
		{
			super(SubscriptMediator.NAME, subscript);
		}
		
		public static const NAME:String = "SubscriptMediator";
		
		/**
		 * 获取订阅模块对象 
		 * @return 
		 * 
		 */		
		public function get subscript():ISubscript
		{
			return this.viewComponent as ISubscript;
		}
		
		/**
		 * 刷新当前订阅列表 
		 * 
		 * @param result	返回事件
		 */		
		public function refreshCurentRssList(result:Function = null):void
		{
			this.subscript.refreshCurrentRssList(result);
		}
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case SystemNotification.FULL_SCREEN:
				{
					//全屏
					if (notification.getBody())
					{
						this.subscript.currentState = "FullScreen";
					}
					else
					{
						this.subscript.currentState = "Normal";
					}
					break;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 * 
		 */	
		public override function listNotificationInterests():Array
		{
			return [SystemNotification.FULL_SCREEN,
					PostNotification.IMPORT_URL_POST_LOAD_ERROR,
					PostNotification.IMPORT_URL_POST_LOAD_PROGRESS,
					PostNotification.IMPORT_URL_POST_LOAD_SUCCESS];
		}
	}
}