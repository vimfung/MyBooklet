package cn.vimfung.mybooklet.framework.module.setting.notification
{
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.observer.Notification;
	
	/**
	 * 备份通知 
	 * @author Administrator
	 * 
	 */	
	public class BackupNotification extends Notification implements INotification
	{
		public function BackupNotification(name:String, body:Object=null, type:String=null)
		{
			super(name, body, type);
		}
		
		/**
		 * 备份开始 
		 */		
		public static const BACKUP_BEGIN:String = "backupBegin";
		
		/**
		 * 备份完成 
		 */		
		public static const BACKUP_COMPLETE:String = "backupComplete";
		
		/**
		 * 备份失败 
		 */		
		public static const BACKUP_ERROR:String = "backupError";
		
		/**
		 * 备份进度 
		 */		
		public static const BACKUP_PROGRESS:String = "backupProgress";
	}
}