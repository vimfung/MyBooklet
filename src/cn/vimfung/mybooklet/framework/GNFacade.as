package cn.vimfung.mybooklet.framework
{
	import avmplus.FLASH10_FLAGS;
	
	import cn.vimfung.gnotes.kit.ISystemManager;
	import cn.vimfung.mybooklet.framework.command.CheckVersionCommand;
	import cn.vimfung.mybooklet.framework.command.OpenModuleCommand;
	import cn.vimfung.mybooklet.framework.command.SystemStartupCommand;
	import cn.vimfung.mybooklet.framework.db.DocumentDatabase;
	import cn.vimfung.mybooklet.framework.db.SystemDatabase;
	import cn.vimfung.mybooklet.framework.notification.SystemNotification;
	import cn.vimfung.mybooklet.framework.patch.ImportUsedTagPatch;
	
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.managers.PopUpManager;
	
	import org.puremvc.as3.interfaces.IFacade;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.facade.Facade;
	
	/**
	 * 应用前置器 
	 * @author Administrator
	 * 
	 */	
	public class GNFacade extends Facade implements IFacade,ISystemManager
	{
		public function GNFacade()
		{
			super();
			
			_systemDatabase = new SystemDatabase();
			_documentDatabase = new DocumentDatabase();
			
			//启动系统
			var notification:SystemNotification = new SystemNotification(SystemNotification.STARTUP);
			this.postNotification(notification);
		}
		
		/**
		 * 检测版本标识 
		 */		
		public static const CHECK_VER_FLAG:String = "CHECK_VER_FLAG";

		/**
		 * 最后一次检测版本时间 
		 */		
		public static const LAST_CHECK_VER_TIME:String = "LAST_CHECK_VER_TIME";
		
		/**
		 * 获取共享前置器实例 
		 * @return 前置器对象
		 * 
		 */		
		public static function getInstance():GNFacade
		{
			if(instance == null)
			{
				instance = new GNFacade();
			}
			
			return instance as GNFacade;
		}
		
		private var _systemDatabase:SystemDatabase;
		private var _documentDatabase:DocumentDatabase;
		private var _mainModuleList:Array;
		
		private var _fullscreen:Boolean;
		private var _checkVerFlag:Number;		//版本更新通知：-1 从不  0 每次  1 每小时  2 每天 3 每月 4 每三个月
		private var _lastCheckVerTime:Number;	//最后一次版本检测时间。
		
		/**
		 * 获取版本更新通知标识
		 * @return 更新通知标识
		 * 
		 */		
		public function get checkVerFlag():Number
		{
			return _checkVerFlag;
		}
		
		/**
		 * 设置版本更新通知标识
		 * @param value 更新通知标识
		 * 
		 */		
		public function set checkVerFlag(value:Number):void
		{
			_checkVerFlag = value;
		}

		/**
		 * 获取最后一次版本检测时间 
		 * @return 检测时间（单位毫秒）
		 * 
		 */		
		public function get lastCheckVerTime():Number
		{
			return _lastCheckVerTime;
		}
		
		/**
		 * 设置最后一次版本检测时间
		 * @param value 检测时间（单位毫秒）
		 * 
		 */		
		public function set lastCheckVerTime(value:Number):void
		{
			_lastCheckVerTime = value;
		}
		
		/**
		 * 获取全屏标识 
		 * @return 全屏标识
		 * 
		 */		
		public function get fullscreen():Boolean
		{
			return _fullscreen;
		}
		
		/**
		 * 设置全屏标识 
		 * @param value 全屏标识
		 * 
		 */		
		public function set fullscreen(value:Boolean):void
		{
			_fullscreen = value;
			
			var notif:SystemNotification = new SystemNotification(SystemNotification.FULL_SCREEN, _fullscreen);
			this.postNotification(notif);
		}
		
		/**
		 * 获取系统数据库 
		 * @return 系统数据库
		 * 
		 */		
		public function get systemDatabase():SystemDatabase
		{
			return _systemDatabase;
		}
		
		/**
		 * 获取文档数据库 
		 * @return 文档数据库
		 * 
		 */		
		public function get documentDatabase():DocumentDatabase
		{
			return _documentDatabase;
		}
		
		/**
		 * 获取主模块列表 
		 * @return 主模块列表
		 * 
		 */		
		public function get mainModuleList():Array
		{
			return _mainModuleList;
		}
		
		/**
		 * 设置主模块列表 
		 * @param value 主模块列表
		 * 
		 */		
		public function set mainModuleList(value:Array):void
		{
			_mainModuleList = value;
			
			var notification:SystemNotification = new SystemNotification(SystemNotification.MAIN_MODULES_UPDATE);
			this.postNotification(notification);
		}
		
		/**
		 * 弹出提示消息
		 * @param message 消息
		 * @param title 标题
		 * @param okButton 确定按钮
		 * @param cancelButton 取消按钮
		 * @param closeHandler 关闭事件处理器
		 * 
		 */		
		public function alert(message:String, title:String = "提示", okButton:String = "知道了", cancelButton:String = null, closeHandler:Function = null):void
		{
			var buttons:int = Alert.OK;
			
			if(okButton != null)
			{
				Alert.okLabel = okButton;
			}
			if(cancelButton != null)
			{
				Alert.cancelLabel = cancelButton;
				buttons |= Alert.CANCEL;
			}
			
			Alert.show(message, title, buttons, null, closeHandler);
		}
		
		/**
		 * 弹出视图 
		 * @param viewType 视图类型
		 * @param modal 模态
		 * @return 视图对象
		 * 
		 */		
		public function popup(viewType:Class, modal:Boolean = false):IFlexDisplayObject
		{
			var displayObject:IFlexDisplayObject = PopUpManager.createPopUp(FlexGlobals.topLevelApplication as DisplayObject, viewType, modal);
			PopUpManager.centerPopUp(displayObject);
			
			return displayObject;
		}
		
		/**
		 * 移除弹出视图 
		 * @param view 弹出视图
		 * 
		 */		
		public function removePopup(view:IFlexDisplayObject):void
		{
			PopUpManager.removePopUp(view);
		}
		
		/**
		 * 初始化 
		 * 
		 */		
		protected override function initializeController():void
		{
			super.initializeController();
			
			this.registerCommand(SystemNotification.STARTUP, SystemStartupCommand);
			this.registerCommand(SystemNotification.OPEN_MODULE, OpenModuleCommand);
			this.registerCommand(SystemNotification.CHECK_VERSION, CheckVersionCommand);
		}
		
		/**
		 * 派发通知 
		 * @param notification 通知对象
		 * 
		 */		
		public function postNotification(notification:INotification):void
		{
			this.sendNotification(notification.getName(), notification.getBody(), notification.getType());
		}
	}
}