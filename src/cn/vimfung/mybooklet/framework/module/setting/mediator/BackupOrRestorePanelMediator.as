package cn.vimfung.mybooklet.framework.module.setting.mediator
{
	import cn.vimfung.common.db.SqliteDatabaseEvent;
	import cn.vimfung.common.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.setting.notification.BackupNotification;
	import cn.vimfung.mybooklet.framework.module.setting.notification.RestoreNotification;
	import cn.vimfung.mybooklet.framework.module.setting.ui.BackupOrRestorePanel;
	import cn.vimfung.mybooklet.framework.ui.TipsProgressPanel;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.display.DisplayObject;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.managers.PopUpManager;
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	/**
	 * 备份面板访问器 
	 * @author Administrator
	 * 
	 */	
	public class BackupOrRestorePanelMediator extends Mediator implements IMediator
	{
		public static const NAME:String = "BackupOrRestorePanelMediator";
		
		public function BackupOrRestorePanelMediator(viewComponent:BackupOrRestorePanel)
		{
			super(BackupOrRestorePanelMediator.NAME, viewComponent);
			
			getBackupList();
		}
		
		private var _facade:GNFacade = GNFacade.getInstance();
		private var _tipsPanel:IFlexDisplayObject;
		private var _restoreResult:Boolean;
		
		/**
		 * 还原备份 
		 * @param path 备份路径
		 * 
		 */		
		public function restore(path:String):void
		{
//			_restoreResult = false;
//			(this.facade as GNoteFacade).sendNotification(GNoteFacade.RESTORE_DATA, path);
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_BEGIN, path);
			_facade.postNotification(notification);
		}
		
		/**
		 * 备份数据 
		 * @param path 备份路径
		 * 
		 */		
		public function backup(path:File):void
		{
			var backupNotification:BackupNotification = new BackupNotification(BackupNotification.BACKUP_BEGIN, path);
			_facade.postNotification(backupNotification);
		}
		
		/**
		 * @inheritDoc
		 */		
		public override function listNotificationInterests():Array
		{
			return [BackupNotification.BACKUP_BEGIN, 
				BackupNotification.BACKUP_COMPLETE, 
				BackupNotification.BACKUP_ERROR, 
				BackupNotification.BACKUP_PROGRESS,
				RestoreNotification.RESTORE_BEGIN,
				RestoreNotification.RESTORE_COMPLETE,
				RestoreNotification.RESTORE_ERROR,
				RestoreNotification.RESTORE_DATA_NOT_EXISTS,
				RestoreNotification.RESTORE_PROGRESS];
		}
		
		/**
		 * @inheritDoc
		 */		
		public override function handleNotification(notification:INotification):void
		{
			var err:Error;
			var progressInfo:ProgressInfo;
			switch (notification.getName())
			{
				case BackupNotification.BACKUP_BEGIN:
					_tipsPanel = _facade.popup(TipsProgressPanel, true);
					(_tipsPanel as TipsProgressPanel).progressBar.label = "正在备份,请稍后...";
					break;
				case BackupNotification.BACKUP_PROGRESS:
					if(_tipsPanel != null)
					{
						progressInfo = notification.getBody() as ProgressInfo;
						(_tipsPanel as TipsProgressPanel).progressBar.setProgress(progressInfo.progress, progressInfo.total);
					}
					break;
				case BackupNotification.BACKUP_COMPLETE:
					_facade.removePopup(_tipsPanel);
					_facade.alert("备份数据完毕了!");
					
					//刷新备份列表
					this.getBackupList();
					break;
				case BackupNotification.BACKUP_ERROR:
					err = notification.getBody() as Error;
					_facade.removePopup(_tipsPanel);
					_facade.alert("备份数据失败哦!\n" + err.message);
					break;
				case RestoreNotification.RESTORE_BEGIN:
					_tipsPanel = _facade.popup(TipsProgressPanel, true);
					(_tipsPanel as TipsProgressPanel).progressBar.label = "正在还原,请稍后...";
					break;
				case RestoreNotification.RESTORE_PROGRESS:
					if(_tipsPanel != null)
					{
						progressInfo = notification.getBody() as ProgressInfo;
						(_tipsPanel as TipsProgressPanel).progressBar.setProgress(progressInfo.progress, progressInfo.total);
					}
					break;
				case RestoreNotification.RESTORE_COMPLETE:
					_facade.removePopup(_tipsPanel);
					_facade.alert("成功还原数据!");
					break;
				case RestoreNotification.RESTORE_ERROR:
					_facade.removePopup(_tipsPanel);
					err = notification.getBody() as Error;
					_facade.alert("还原失败!" + err.message);
					break;
				case RestoreNotification.RESTORE_DATA_NOT_EXISTS:
					_facade.removePopup(_tipsPanel);
					_facade.alert("备份文件不存在，无法还原数据!");
					//刷新备份列表
					this.getBackupList();
					break;
			}
		}
		
		/**
		 * 获取备份列表 
		 * 
		 */		
		private function getBackupList():void
		{
			var token:SqliteDatabaseToken = _facade.systemDatabase.execute("SELECT * FROM notes_backup ORDER BY createTime DESC");
			token.addEventListener(SqliteDatabaseEvent.RESULT, getBackupListResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getBackupListErrorHandler);
		}
		
		/**
		 * 获取备份列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getBackupListResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getBackupListResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getBackupListErrorHandler);

			(this.viewComponent as BackupOrRestorePanel).dgBackupList.dataProvider = new ArrayCollection(event.recordset);
		}
		
		/**
		 * 获取备份列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getBackupListErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getBackupListResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getBackupListErrorHandler);
		}
	}
}