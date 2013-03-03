package cn.vimfung.mybooklet.framework.module.setting.command
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.Constant;
	import cn.vimfung.mybooklet.framework.module.setting.notification.RestoreNotification;
	
	import com.coltware.airxzip.ZipEntry;
	import com.coltware.airxzip.ZipErrorEvent;
	import com.coltware.airxzip.ZipEvent;
	import com.coltware.airxzip.ZipFileReader;
	
	import flash.data.SQLStatement;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.getTimer;
	
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	import spark.components.Application;
	
	/**
	 * 还原数据命令 
	 * @author Administrator
	 * 
	 */	
	public class RestoreCommand extends SimpleCommand implements ICommand
	{
		public function RestoreCommand()
		{
			super();
		}
		
		private var _gnFacade:GNFacade;
		private var _backupZipFile:File;
		private var _currentIndex:int;
		
		private var _zipFileReader:ZipFileReader;
		private var _entries:Array;
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function execute(notification:INotification):void
		{
			_gnFacade = this.facade as GNFacade;
			
			_backupZipFile = new File(notification.getBody() as String);
			if(_backupZipFile.exists)
			{
				_zipFileReader = new ZipFileReader();
				_zipFileReader.addEventListener(ZipEvent.ZIP_DATA_UNCOMPRESS, zipDataUncompressHandler);
				_zipFileReader.addEventListener(ZipErrorEvent.ZIP_NO_SUCH_METHOD, noSuchMethodHandler);
				_zipFileReader.open(_backupZipFile);
				
				_entries = _zipFileReader.getEntries();
				
				//关闭连接
				_gnFacade.documentDatabase.addEventListener(SqliteDatabaseEvent.CLOSE, closeDatabaseSuccessHandler);
				_gnFacade.documentDatabase.addEventListener(SqliteDatabaseEvent.ERROR, closeDatabaseFailHandler);
				_gnFacade.documentDatabase.disconnect();
			}
			else
			{
				//删除无效的备份记录
				var parameters:Dictionary = new Dictionary();
				parameters[":url"] = notification.getBody();
				
				var token:SqliteDatabaseToken = _gnFacade.systemDatabase.execute("DELETE FROM notes_backup WHERE url = :url", parameters);
				token.addEventListener(SqliteDatabaseEvent.RESULT, delBackupRecordResultHandler);
				token.addEventListener(SqliteDatabaseEvent.ERROR, delBackupRecordFaultHandler);
			}
		}
		
		/**
		 * 恢复原来的内容 
		 * 
		 */		
		private function recoverTmpContent():void
		{
			//删除原有文档目录
			var docPath:File = Constant.DocumentPath;
			docPath.addEventListener(Event.COMPLETE, removeDocPathCompleteHandler);
			docPath.addEventListener(IOErrorEvent.IO_ERROR, removeDocPathErrorHandler);
			docPath.deleteDirectoryAsync(true);
		}
		
		/**
		 * 删除临时内容 
		 * 
		 */		
		private function removeTmpContent():void
		{
			var tmpDocPath:File = File.documentsDirectory.resolvePath("GNotes_tmp");
			tmpDocPath.addEventListener(Event.COMPLETE, removeTmpContentCompleteHandler);
			tmpDocPath.addEventListener(IOErrorEvent.IO_ERROR, removeTmpContentErrorHandler);
			tmpDocPath.deleteDirectoryAsync(true);
		}
		
		/**
		 * 删除临时文件完成 
		 * @param event 事件
		 * 
		 */		
		private function removeTmpContentCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, removeTmpContentCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, removeTmpContentErrorHandler);
			
			//还原成功
			_gnFacade.documentDatabase.connect();
			
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_COMPLETE);
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 删除临时文件失败 
		 * @param event 事件
		 * 
		 */		
		private function removeTmpContentErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, removeTmpContentCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, removeTmpContentErrorHandler);
			
			//还原成功
			_gnFacade.documentDatabase.connect();
			
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_COMPLETE);
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 删除文档成功 
		 * @param event 事件
		 * 
		 */		
		private function removeDocPathCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, removeDocPathCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, removeDocPathErrorHandler);
			
			//恢复备份
			var tmpDocPath:File = File.documentsDirectory.resolvePath("GNotes_tmp");
			tmpDocPath.addEventListener(Event.COMPLETE, recoverContentCompleteHandler);
			tmpDocPath.addEventListener(IOErrorEvent.IO_ERROR, recoverContentErrorHandler);
			tmpDocPath.moveToAsync(Constant.DocumentPath, true);
		}
		
		/**
		 * 删除文档失败 
		 * @param event 事件
		 * 
		 */		
		private function removeDocPathErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, removeDocPathCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, removeDocPathErrorHandler);
			
			//失败
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_ERROR, new Error("还原失败，但在恢复时出现异常!请关闭应用，将文档目录下的GNotes_tmp目录更名为GNotes即可恢复备份!", event.errorID));
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 恢复内容完成 
		 * @param event 事件
		 * 
		 */		
		private function recoverContentCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, recoverContentCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, recoverContentErrorHandler);
			
			//重新连接数据库
			_gnFacade.documentDatabase.connect();
			
			//还原失败
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_ERROR, new Error("还原失败，已恢复为当前状态!", 0));
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 恢复内容失败 
		 * @param event 事件
		 * 
		 */		
		private function recoverContentErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, recoverContentCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, recoverContentErrorHandler);
			
			//失败
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_ERROR, new Error("还原失败，但在恢复时出现异常!请关闭应用，将文档目录下的GNotes_tmp目录更名为GNotes即可恢复备份!", event.errorID));
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 关闭数据库成功 
		 * @param event 事件对象
		 * 
		 */		
		private function closeDatabaseSuccessHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.CLOSE, closeDatabaseSuccessHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, closeDatabaseFailHandler);
			
			//派发进度信息
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.progress = 1;
			progressInfo.total = _entries.length + 2;
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_PROGRESS, progressInfo);
			_gnFacade.postNotification(notification);
			
			//将当前文档目录进行更名
			var tmpDocPath:File = File.documentsDirectory.resolvePath("GNotes_tmp");
			var docPath:File = Constant.DocumentPath;
			docPath.addEventListener(Event.COMPLETE, docPathMoveCompleteHandler);
			docPath.addEventListener(IOErrorEvent.IO_ERROR, docPathMoveErrorHandler);
			docPath.moveToAsync(tmpDocPath, true);
		}
		
		/**
		 * 关闭数据库失败 
		 * @param event 事件对象
		 * 
		 */		
		private function closeDatabaseFailHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.CLOSE, closeDatabaseSuccessHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, closeDatabaseFailHandler);
			
			_gnFacade.documentDatabase.connect();
			
			//派发通知
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_ERROR, event.error);
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 文档路径迁移成功 
		 * @param event 事件
		 * 
		 */		
		private function docPathMoveCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, docPathMoveCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, docPathMoveErrorHandler);
			
			//派发进度信息
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.progress = 2;
			progressInfo.total = _entries.length + 2;
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_PROGRESS, progressInfo);
			_gnFacade.postNotification(notification);
			
			//还原
			this.restoreFile();
		}
		
		/**
		 * 文档路径迁移失败 
		 * @param event 事件
		 * 
		 */		
		private function docPathMoveErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, docPathMoveCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, docPathMoveErrorHandler);
			
			//派发通知
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_ERROR, new Error(event.text, event.errorID));
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 还原文件 
		 * 
		 */		
		private function restoreFile():void
		{
			for each(var entry:ZipEntry in _entries)
			{
				if(!entry.isDirectory())
				{
					_zipFileReader.unzipAsync(entry);
				}
			}
		}
		
		/**
		 * 解压文件调度 
		 * @param event 事件
		 * 
		 */		
		private function zipDataUncompressHandler(event:ZipEvent):void
		{
			var entry:ZipEntry = event.entry;
			
			var fs:FileStream = new FileStream();
			fs.open(Constant.DocumentPath.resolvePath(entry.getFilename()), FileMode.WRITE);
			try
			{
				fs.writeBytes(event.data);
			}
			finally
			{
				fs.close();
			}
			
			_currentIndex ++;
			
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.progress = _currentIndex + 2;
			progressInfo.total = _entries.length + 2;
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_PROGRESS, progressInfo);
			_gnFacade.postNotification(notification);
			
			if(_currentIndex == _entries.length)
			{
				this.removeTmpContent();
			}
		}
		
		/**
		 * 没有相应方法 
		 * @param event 事件
		 * 
		 */		
		private function noSuchMethodHandler(event:ZipErrorEvent):void
		{
			//还原内容
			this.recoverTmpContent();
		}
		
		/**
		 * 删除备份记录返回 
		 * @param event 事件
		 * 
		 */		
		private function delBackupRecordResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, delBackupRecordResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, delBackupRecordFaultHandler);
			
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_DATA_NOT_EXISTS);
			_gnFacade.postNotification(notification);
		}
		
		/**
		 * 删除备份记录失败 
		 * @param event 事件
		 * 
		 */		
		private function delBackupRecordFaultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, delBackupRecordResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, delBackupRecordFaultHandler);
			
			var notification:RestoreNotification = new RestoreNotification(RestoreNotification.RESTORE_ERROR, event.error);
			_gnFacade.postNotification(notification);
			
		}
	}
}