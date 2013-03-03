package cn.vimfung.mybooklet.framework.command
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.mediator.MainMediator;
	import cn.vimfung.mybooklet.framework.model.Module;
	import cn.vimfung.gnotes.kit.IApplicationInstance;
	
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.events.ModuleEvent;
	
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	/**
	 * 打开模块命令 
	 * @author Administrator
	 * 
	 */	
	public class OpenModuleCommand extends SimpleCommand implements ICommand
	{
		public function OpenModuleCommand()
		{
			super();
		}
		
		private var _gnFacade:GNFacade;
		private var _mainMediator:MainMediator;
		private var _module:Module;
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function execute(notification:INotification):void
		{
			_gnFacade = this.facade as GNFacade;
			_mainMediator = this.facade.retrieveMediator(MainMediator.NAME) as MainMediator;
			_module = notification.getBody() as Module;
			
			if(_module != null && _module.url != "")
			{
				var applicationInstance:IApplicationInstance = _mainMediator.view.contentView.child as IApplicationInstance;
				if(applicationInstance != null)
				{
					applicationInstance.onClose();
				}
				
				_mainMediator.view.contentView.addEventListener(ModuleEvent.READY, moduleReadyHandler);
				_mainMediator.view.contentView.addEventListener(ModuleEvent.ERROR, moduleErrorHandler);
				_mainMediator.view.contentView.url = _module.url;
			}
			else
			{
				_gnFacade.alert("此功能存在异常哦!\n");
			}
		}
		
		/**
		 * 模块加载完毕 
		 * @param event 事件
		 * 
		 */		
		private function moduleReadyHandler(event:ModuleEvent):void
		{
			event.target.removeEventListener(ModuleEvent.READY, moduleReadyHandler);
			event.target.removeEventListener(ModuleEvent.ERROR, moduleErrorHandler);
			
			try
			{
				var applicationInstance:IApplicationInstance = _mainMediator.view.contentView.child as IApplicationInstance;
				if(_module.useCount == 0)
				{
					//属于首次运行，调用初始化
					applicationInstance.onInitialize(_gnFacade);
				}
				
				//增加使用次数
				_module.useCount ++;
				var parameters:Dictionary = new Dictionary();
				parameters[":id"] = _module.id;
				_gnFacade.systemDatabase.execute("UPDATE sys_module SET useCount = useCount + 1 WHERE id = :id", parameters, true);
				
				//显示应用
				applicationInstance.onOpen(_gnFacade);
			}
			catch(err:Error)
			{
				_gnFacade.alert("此功能存在异常哦!\n" + err.message);
			}
		}
		
		/**
		 * 模块加载异常 
		 * @param event 事件
		 * 
		 */		
		private function moduleErrorHandler(event:ModuleEvent):void
		{
			event.target.removeEventListener(ModuleEvent.READY, moduleReadyHandler);
			event.target.removeEventListener(ModuleEvent.ERROR, moduleErrorHandler);
			
			_gnFacade.alert("此功能存在异常哦!\n" + event.errorText);
		}
	}
}