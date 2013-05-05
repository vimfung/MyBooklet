package cn.vimfung.mybooklet.framework.module.subscript.mediator
{
	import cn.vimfung.mybooklet.framework.module.subscript.notification.SubscriptNotification;
	import cn.vimfung.mybooklet.framework.module.subscript.ui.SubscriptWindow;
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	/**
	 * 订阅窗口中介 
	 * @author Administrator
	 * 
	 */	
	public class SubscriptWindowMediator extends Mediator implements IMediator
	{
		public function SubscriptWindowMediator(window:SubscriptWindow=null)
		{
			super(NAME, window);
			
			_subscriptWindow = window;
		}
		
		public static const NAME:String = "SubscriptWIndowMediator";
		
		private var _subscriptWindow:SubscriptWindow;
		
		/**
		 * @inheritDoc 
		 */		
		public override function listNotificationInterests():Array
		{
			return [SubscriptNotification.REMOVE_RSS];
		}
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case SubscriptNotification.REMOVE_RSS:
					var rssItemData:Object = notification.getBody();
					_subscriptWindow.removeItem(rssItemData);
					break;
			}
		}
	}
}