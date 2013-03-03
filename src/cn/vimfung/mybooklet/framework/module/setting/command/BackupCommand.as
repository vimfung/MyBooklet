package cn.vimfung.mybooklet.framework.module.setting.command
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.Constant;
	import cn.vimfung.mybooklet.framework.module.setting.notification.BackupNotification;
	
	import com.coltware.airxzip.ZipEvent;
	import com.coltware.airxzip.ZipFileWriter;
	
	import flash.data.SQLStatement;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	/**
	 * 备份数据命令 
	 * @author Administrator
	 * 
	 */	
	public class BackupCommand extends SimpleCommand implements ICommand
	{
		public function BackupCommand()
		{
			super();
		}
		
		/**
		 * 备份文件 
		 */		
		private var _backupFile:File;
		private var _gnFacade:GNFacade = GNFacade.getInstance();

		private var _attachFiles:Array;
		private var _total:int;
		private var _current:int;
		
		private var _zipFileWriter:ZipFileWriter;
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function execute(notification:INotification):void
		{
			_backupFile = notification.getBody() as File;
			_attachFiles = new Array();
			
			setTimeout(this.zipFile, 10);
		}
		
		/**
		 * 压缩数据调度
		 * @param event 事件
		 * 
		 */		
		private function zipDataCompressHandler(event:ZipEvent):void
		{
			_current++;
			
			//派发进度信息
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.total = _total;
			progressInfo.progress = _current;
			var backupNotification:BackupNotification = new BackupNotification(BackupNotification.BACKUP_PROGRESS, progressInfo);
			_gnFacade.postNotification(backupNotification);
		}
		
		/**
		 * 压缩文件完成 
		 * @param event 事件
		 * 
		 */		
		private function zipFileCreatedHandler(event:ZipEvent):void
		{
			event.target.removeEventListener(ZipEvent.ZIP_FILE_CREATED,zipFileCreatedHandler);
			event.target.removeEventListener(ZipEvent.ZIP_DATA_COMPRESS, zipDataCompressHandler);
			
			//完成压缩
			this.outputZipFile();
		}
		
		/**
		 * 初始化压缩文件 
		 * 
		 */		
		private function initZipFiles():void
		{
			_attachFiles.push(Constant.DatabaseFile);
			//查找所有附件
			this.findAttach(Constant.AttachmentPath);
		}
		
		/**
		 * 压缩文件 
		 * 
		 */		
		private function zipFile():void
		{
			_zipFileWriter = new ZipFileWriter();
			_zipFileWriter.addEventListener(ZipEvent.ZIP_DATA_COMPRESS, zipDataCompressHandler);
			_zipFileWriter.addEventListener(ZipEvent.ZIP_FILE_CREATED, zipFileCreatedHandler); 
			_zipFileWriter.openAsync(_backupFile);
			
			this.initZipFiles();
			_total = _attachFiles.length;
			
			_current = 0;
			for (var i:int = 0; i < _attachFiles.length; i++)
			{
				var file:File = _attachFiles[i];
				_zipFileWriter.addFile(file, Constant.DocumentPath.getRelativePath(file));
			}
			_zipFileWriter.close();
		}
		
		/**
		 * 查找附件 
		 * @param parentPath 父级路径
		 * 
		 */		
		private function findAttach(parentPath:File):void
		{
			var files:Array = parentPath.getDirectoryListing();
			for (var i:int = 0; i < files.length; i++)
			{
				var file:File = files[i];
				if(file.isDirectory)
				{
					this.findAttach(file);
				}
				else
				{
					_attachFiles.push(file);
				}
			}
		}
		
		/**
		 * 输出备份文件 
		 * 
		 */		
		private function outputZipFile():void
		{
			//写入数据库
			var parameters:Dictionary = new Dictionary();
			parameters[":url"] = _backupFile.nativePath;
			parameters[":createTime"] = new Date();
			var token:SqliteDatabaseToken = _gnFacade.systemDatabase.execute("INSERT INTO notes_backup(url, createTime) values(:url, :createTime)", parameters);
			token.addEventListener(SqliteDatabaseEvent.RESULT, addBackupRecordResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, addBackupRecordFaultHandler);
		}
		
		/**
		 * 加入备份记录返回 
		 * @param event 事件
		 * 
		 */		
		private function addBackupRecordResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, addBackupRecordResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, addBackupRecordFaultHandler);
			
			var backupNotification:BackupNotification = new BackupNotification(BackupNotification.BACKUP_COMPLETE);
			_gnFacade.postNotification(backupNotification);
		}
		
		/**
		 * 加入备份记录失败 
		 * @param event 事件
		 * 
		 */		
		private function addBackupRecordFaultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, addBackupRecordResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, addBackupRecordFaultHandler);
			
			var backupNotification:BackupNotification = new BackupNotification(BackupNotification.BACKUP_COMPLETE, event.error);
			_gnFacade.postNotification(backupNotification);
		}
	}
}