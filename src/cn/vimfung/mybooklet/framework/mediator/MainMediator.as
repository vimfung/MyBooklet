package cn.vimfung.mybooklet.framework.mediator
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.IApplication;
	import cn.vimfung.mybooklet.framework.model.Module;
	import cn.vimfung.mybooklet.framework.notification.SystemNotification;
	import cn.vimfung.mybooklet.framework.ui.TipsProgressPanel;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.ModuleEvent;
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	/**
	 * 主界面中间访问器 
	 * @author Administrator
	 * 
	 */	
	public class MainMediator extends Mediator implements IMediator
	{
		public function MainMediator()
		{
			super(MainMediator.NAME, FlexGlobals.topLevelApplication);
		}
		
		public static const NAME:String = "MainMediator";
		
		/**
		 * 获取视图 
		 * @return 视图对象
		 * 
		 */		
		public function get view():IApplication
		{
			return this.viewComponent as IApplication;
		}
		
		/**
		 * @inheritDoc
		 */		
		public override function listNotificationInterests():Array
		{
			return [SystemNotification.MAIN_MODULES_UPDATE,
					SystemNotification.FULL_SCREEN];
		}
		
		/**
		 * @inheritDoc
		 */	
		public override function handleNotification(notification:INotification):void
		{ 
			switch(notification.getName())
			{
				case SystemNotification.MAIN_MODULES_UPDATE:
				{
					this.view.navigationBar.dataProvider = new ArrayCollection((this.facade as GNFacade).mainModuleList);
					if(this.view.navigationBar.selectedIndex == -1)
					{
						this.view.navigationBar.selectedIndex = 0;
						var gnFacade:GNFacade = this.facade as GNFacade;
						var module:Module = gnFacade.mainModuleList[0] as Module;
						var systemNotification:SystemNotification = new SystemNotification(SystemNotification.OPEN_MODULE, module);
						gnFacade.postNotification(systemNotification);
					}
					break;
				}
				case SystemNotification.FULL_SCREEN:
				{
					if (notification.getBody())
					{
						//全屏模式
						this.view.currentState = "FullScreen";
					}
					else
					{
						//普通模式
						this.view.currentState = "Normal";
					}
					break;
				}
			}
		}
	}
}