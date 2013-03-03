package cn.vimfung.mybooklet.framework.command
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.mediator.MainMediator;
	import cn.vimfung.mybooklet.framework.model.Module;
	import cn.vimfung.mybooklet.framework.module.myposts.Constant;
	import cn.vimfung.mybooklet.framework.notification.SystemNotification;
	import cn.vimfung.mybooklet.framework.patch.ChangeModuleInfoPatch;
	import cn.vimfung.mybooklet.framework.patch.IPatchObject;
	import cn.vimfung.mybooklet.framework.patch.ImportTagPinyinPatch;
	import cn.vimfung.mybooklet.framework.patch.ImportUsedTagPatch;
	import cn.vimfung.mybooklet.framework.patch.InitModuleInfoPatch;
	import cn.vimfung.mybooklet.framework.ui.TipsProgressPanel;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLTableSchema;
	import flash.display.Loader;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	import flashx.textLayout.factory.TruncationOptions;
	
	import mx.controls.Alert;
	import mx.controls.HTML;
	import mx.controls.ProgressBar;
	
	import org.puremvc.as3.core.Model;
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	import spark.components.DropDownList;
	import spark.components.Image;
	import spark.components.RadioButton;
	import spark.components.RichText;
	import spark.components.TextArea;
	import spark.components.TextInput;
	import spark.components.TitleWindow;
	
	/**
	 * 系统启动命令 
	 * @author Administrator
	 * 
	 */	
	public class SystemStartupCommand extends SimpleCommand implements ICommand
	{
		public function SystemStartupCommand()
		{
			super();
		}
		
		private var _gnFacade:GNFacade;
		private var _mainMediator:MainMediator;
		
		private var _docDbReady:Boolean = false;
		private var _sysDbReady:Boolean = false;
		
		private var _patchFiles:Array = null;
		private var _patchedList:Array = null;
		private var _patchObject:Object = null;
		private var _tipsPanel:TipsProgressPanel = null;
		private var _patchProgress:int = 0;
		
		/**
		 * 补丁列表 
		 */		
		private var _patchList:Array = [
			{name:InitModuleInfoPatch.NAME, type:InitModuleInfoPatch},			//初始化模块信息
			{name:ImportUsedTagPatch.NAME, type:ImportUsedTagPatch},			//转换文件中的标签到常用标签列表
			{name:ImportTagPinyinPatch.NAME, type:ImportTagPinyinPatch},		//转换标签的拼音索引
			{name:ChangeModuleInfoPatch.NAME, type:ChangeModuleInfoPatch}		//变更模块信息
		];
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function execute(notification:INotification):void
		{	
			this.initSystem();
			
			_sysDbReady = _gnFacade.systemDatabase.initialized;
			_docDbReady = _gnFacade.documentDatabase.initialized;
			
			if (!_sysDbReady)
			{
				_gnFacade.systemDatabase.addEventListener(SqliteDatabaseEvent.INITIALIZE, dbInitHandler);
			}
			if (!_docDbReady)
			{
				_gnFacade.documentDatabase.addEventListener(SqliteDatabaseEvent.INITIALIZE, dbInitHandler);
			}
			this.checkDbReady();
			
		}
		
		/**
		 * 初始化系统环境 
		 * 
		 */		
		private function initSystem():void
		{
			_gnFacade = this.facade as GNFacade;
			
			//注册类型
			var window:TitleWindow;
			var textinput:TextInput;
			var dropdownlist:DropDownList;
			var html:HTML;
			var textarea:TextArea;
			var progressbar:ProgressBar;
			var richtext:RichText;
			var image:Image;
			var radioButton:RadioButton;
			
			Alert.okLabel = "确定";
			Alert.cancelLabel = "取消";
			Alert.yesLabel = "是";
			Alert.noLabel = "否";
		}
		
		/**
		 * 检测数据库是否就绪 
		 * 
		 */		
		private function checkDbReady():void
		{
			if(_sysDbReady && _docDbReady)
			{
				//注册视图访问器
				_mainMediator = new MainMediator();
				_gnFacade.registerMediator(_mainMediator);
				
				//获取补丁列表
				var patchListToken:SqliteDatabaseToken = _gnFacade.systemDatabase.createCommandToken("SELECT name FROM sys_patch");
				patchListToken.addEventListener(SqliteDatabaseEvent.RESULT, getPatchListResultHandler);
				patchListToken.addEventListener(SqliteDatabaseEvent.ERROR, getPatchListFaultHandler);
				patchListToken.start();
			}
		}
		
		/**
		 * 数据库初始化事件 
		 * @param event 事件
		 * 
		 */		
		private function dbInitHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.INITIALIZE, dbInitHandler);

			if (event.target == _gnFacade.systemDatabase)
			{
				_sysDbReady = true;
			}
			else if (event.target == _gnFacade.documentDatabase)
			{
				_docDbReady = true;
			}
			
			this.checkDbReady();
		}
		
		/**
		 * 更新补丁 
		 * 
		 */		
		private function updatePatch():void
		{
			if(_patchFiles.length == 0)
			{
				_gnFacade.removePopup(_tipsPanel);
				
				//检测版本更新
				var notif:SystemNotification = new SystemNotification(SystemNotification.CHECK_VERSION);
				_gnFacade.postNotification(notif);
				
				//获取主功能模块
				var token:SqliteDatabaseToken = _gnFacade.systemDatabase.execute("SELECT * FROM sys_module WHERE type = 1 ORDER BY sortIndex");
				token.addEventListener(SqliteDatabaseEvent.RESULT, getMainMenuModuleResultHandler);
				token.addEventListener(SqliteDatabaseEvent.ERROR, getMainMenuModuleFaultHandler);
				return;
			}
			
			_patchObject = _patchFiles.shift();
			var patchCls:Class = _patchObject.type;
			var patch:IPatchObject = new patchCls() as IPatchObject;
			patch.addEventListener(PatchEvent.PATCH_SUCCESS, patchSucHandler);
			patch.addEventListener(PatchEvent.PATCH_FAIL, patchFaiHandler);
			patch.start(_gnFacade);
		}
		
		/**
		 * 筛选尚未打入补丁 
		 * @param item 附件信息
		 * @param index 位置索引
		 * @param array 数据对象
		 * @return true表示包含该元素，否则不包含。
		 * 
		 */		
		private function filterUnpatchsCallback(item:*, index:int, array:Array):Boolean
		{
			return _patchedList.indexOf(item.name) == -1 ? true : false;
		}
		
		/**
		 * 获取补丁列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getPatchListResultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, getPatchListResultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, getPatchListFaultHandler);
			
			//筛选尚未打入补丁
			_patchedList = new Array();
			if(event.recordset != null)
			{
				for (var i:int = 0; i < event.recordset.length; i++)
				{
					_patchedList.push(event.recordset[i].name);
				}
			}

			_patchFiles = _patchList.filter(filterUnpatchsCallback);
			
			//检测是否有补丁
			if(_patchFiles.length > 0)
			{
				//显示进度
				_tipsPanel = _gnFacade.popup(TipsProgressPanel, true) as TipsProgressPanel;
			}
			
			//检测系统补丁信息
			updatePatch();
		}
		
		/**
		 * 获取补丁列表失败
		 * @param event 事件
		 * 
		 */		
		private function getPatchListFaultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getPatchListResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getPatchListFaultHandler);
			
			_gnFacade.alert("初始化系统异常哦!\n" + event.error.message);
		}
		
		/**
		 * 补丁成功 
		 * @param event 事件
		 * 
		 */		
		private function patchSucHandler(event:PatchEvent):void
		{
			event.target.removeEventListener(PatchEvent.PATCH_SUCCESS, patchSucHandler);
			event.target.removeEventListener(PatchEvent.PATCH_FAIL, patchFaiHandler);
			
			//写入补丁列表
			var params:Dictionary = new Dictionary();
			params[":name"] = event.name;
			params[":patchTime"] = new Date();
			_gnFacade.systemDatabase.execute("INSERT INTO sys_patch(name, patchTime) VALUES(:name, :patchTime)", params, true);
			
			_patchProgress ++;
			_tipsPanel.progressBar.setProgress(_patchProgress, _patchFiles.length + _patchProgress);
			_patchObject = null;
			
			//继续下一个补丁
			updatePatch();
		}
		
		/**
		 * 补丁失败 
		 * @param event 事件
		 * 
		 */		
		private function patchFaiHandler(event:PatchEvent):void
		{
			event.target.removeEventListener(PatchEvent.PATCH_SUCCESS, patchSucHandler);
			event.target.removeEventListener(PatchEvent.PATCH_FAIL, patchFaiHandler);
			
			_gnFacade.alert("打入补丁失败!\n" + event.error.message);
		}
		
		/**
		 * 获取主菜单模块列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getMainMenuModuleResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getMainMenuModuleResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getMainMenuModuleFaultHandler);
			
			var list:Array = new Array();
			for(var i:int = 0; i < event.recordset.length; i++)
			{
				list.push(Module.createModule(event.recordset[i]));
			}
			_gnFacade.mainModuleList = list;
		}
		
		/**
		 * 获取主菜单模块失败 
		 * @param event 事件
		 * 
		 */		
		private function getMainMenuModuleFaultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getMainMenuModuleResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getMainMenuModuleFaultHandler);
			
			_gnFacade.alert("初始化系统异常哦!\n" + event.error.message);
		}
	}
}