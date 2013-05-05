package cn.vimfung.mybooklet.framework.module.subscript.notification
{
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.observer.Notification;
	
	/**
	 * 订阅通知对象 
	 * @author Administrator
	 * 
	 */	
	public class SubscriptNotification extends Notification implements INotification
	{
		public function SubscriptNotification(name:String, body:Object=null, type:String=null)
		{
			super(name, body, type);
		}
		
		/**
		 * 移除订阅源
		 */		
		public static const REMOVE_RSS:String = "remove_rss";
	}
}