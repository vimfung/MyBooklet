package cn.vimfung.mybooklet.framework.notification
{
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.observer.Notification;
	
	/**
	 * 系统通知 
	 * @author Administrator
	 * 
	 */	
	public class SystemNotification extends Notification implements INotification
	{
		public function SystemNotification(name:String, body:Object=null, type:String=null)
		{
			super(name, body, type);
		}
		
		/**
		 * 系统启动 
		 */		
		public static const STARTUP:String = "system_startup";
		
		/**
		 * 主模块列表更新 
		 */		
		public static const MAIN_MODULES_UPDATE:String = "mainModulesUpdate";
		
		/**
		 * 检测版本 
		 */		
		public static const CHECK_VERSION:String = "checkVersion";
		
		/**
		 * 打开模块 
		 */		
		public static const OPEN_MODULE:String = "openModule";
	}
}