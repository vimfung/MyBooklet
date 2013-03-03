package cn.vimfung.mybooklet.framework.command
{
	import air.update.ApplicationUpdater;
	import air.update.ApplicationUpdaterUI;
	import air.update.events.UpdateEvent;
	
	import flash.events.ErrorEvent;
	
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	/**
	 * 版本检测 
	 * @author Administrator
	 * 
	 */	
	public class CheckVersionCommand extends SimpleCommand implements ICommand
	{
		public function CheckVersionCommand()
		{
			super();
		}
		
		private var _updater:ApplicationUpdaterUI;
		
		/**
		 * @inheritDoc 
		 * 
		 */		
		public override function execute(notification:INotification):void
		{
			_updater = new ApplicationUpdaterUI();
			_updater.updateURL = "http://www.mybooklet.t15.org/update/gnotes-update.xml";
			_updater.isCheckForUpdateVisible = false;
			_updater.addEventListener(UpdateEvent.INITIALIZED, updateInitializeHandler);
			_updater.addEventListener(ErrorEvent.ERROR, updateErrorHandler);
			_updater.initialize();
		}
		
		/**
		 * 初始化完成事件 
		 * @param event 事件对象
		 * 
		 */		
		private function updateInitializeHandler(event:UpdateEvent):void
		{
			event.target.removeEventListener(ErrorEvent.ERROR, updateErrorHandler);
			event.target.removeEventListener(UpdateEvent.INITIALIZED, updateInitializeHandler);
			
			_updater.checkNow();
		}
		
		/**
		 * 错误事件 
		 * @param event 事件对象
		 * 
		 */
		private function updateErrorHandler(event:ErrorEvent):void
		{
			event.target.removeEventListener(ErrorEvent.ERROR, updateErrorHandler);
			event.target.removeEventListener(UpdateEvent.INITIALIZED, updateInitializeHandler);
		}
	}
}