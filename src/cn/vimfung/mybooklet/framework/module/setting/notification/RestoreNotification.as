package cn.vimfung.mybooklet.framework.module.setting.notification
{
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.observer.Notification;
	
	/**
	 * 还原数据通知 
	 * @author Administrator
	 * 
	 */	
	public class RestoreNotification extends Notification implements INotification
	{
		public function RestoreNotification(name:String, body:Object=null, type:String=null)
		{
			super(name, body, type);
		}
		
		/**
		 * 还原开始 
		 */		
		public static const RESTORE_BEGIN:String = "restoreBegin";
		
		/**
		 * 还原完成 
		 */		
		public static const RESTORE_COMPLETE:String = "restoreComplete";
		
		/**
		 * 还原失败 
		 */		
		public static const RESTORE_ERROR:String = "restoreError";
		
		/**
		 * 还原进度 
		 */		
		public static const RESTORE_PROGRESS:String = "restoreProgress";
		
		/**
		 * 还原数据不存在 
		 */		
		public static const RESTORE_DATA_NOT_EXISTS:String = "restoreDataNotExists";
	}
}